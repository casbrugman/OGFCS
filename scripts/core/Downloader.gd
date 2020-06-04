extends Node

class_name GameDownloader

const TIMEOUT_TIME = 5
const MAX_PACKET_SIZE = 50000

signal send_file

var host_adddons setget _set_host_addons
var _host_addons: bool

var current_looking_hash
var current_looking_file
var current_looking_ip
var current_looking_port
var current_looking_size
var current_file_info
var current_file_data
var current_timer: float

var last_percent

var hosted_files = {}

var file = File.new()
var dir = Directory.new()

func _ready():
	Game.downloader = self
	
	_set_host_addons(true)
	
	Game.peer.connect("packet", self, "_packet_handler")
	
func save_file(ip: String, port: int, file_path: String, save_path: String, _override: bool = Game.config.get_value("downloader", "override_files")) -> int:
	yield(get_tree(), "idle_frame")
	
	var err
	if dir.file_exists(save_path):
		if _override:
			err = dir.remove(save_path)
			if err != OK:
				Game.print_error("Downloader.gd ERROR: could not delete file with path: %s! code: %s" % [save_path, err])
				return err
		else:
			Game.print_error("Downloader.gd ERROR: file already exists in path: %s and overriding is set to false!" % save_path)
			return ERR_INVALID_PARAMETER
	
	
	var file_data = yield(retrieve_file(ip, port, file_path), "completed")
	if file_data == null:
		return FAILED
		
	if file_data is int:
		return FAILED
	
	err = file.open(save_path, File.WRITE)
	if err != OK:
		Game.print_error("Downloader.gd ERROR: could not create file with path: %s! code: %s" % [save_path, err])
		file.close()
		return err
		
	file.store_buffer(file_data)
	file.close()
	
	return OK
		
func retrieve_file(ip: String, port: int, file_path: String):
	var file_info = yield(retrieve_file_info(ip, port, file_path), "completed")
	
	if file_info == null || file_info is int:
		Game.print_error("Downloader.gd ERROR: could not request file info!")
		return FAILED
		
	if current_looking_hash != null:
		Game.print_alert("Downloader.gd ALERT: Cancelled earlier file download..")
	
	current_looking_file = file_path
	current_looking_size = file_info["SIZE"]
	current_file_data = null
	current_looking_ip = ip
	current_looking_port = port

	var err = Game.peer.send_packet(ip, port, "REQUEST_FILE", file_path)
	
	if err is GDScriptFunctionState: 
		err = yield(err, "completed")
	
	if err != OK:
		Game.print_error("Downloader.gd ERROR: could not send packet to request file!")
		
		current_looking_file = null
		current_looking_size = null
		current_looking_ip = null
		current_looking_port = null
		
		return err

	current_timer = 0
	var step = 0.1
	
	while (current_file_data == null || current_file_data.size() < current_looking_size) && current_timer < TIMEOUT_TIME:
		yield(get_tree().create_timer(step), "timeout")
		current_timer += step
		
	var data
	
	if current_file_data == null:
		Game.print_error("Downloader.gd ERROR: could not retrieve file, timed out.")
	else:
		var hasher = HashingContext.new()
		hasher.start(HashingContext.HASH_SHA256)
		hasher.update(current_file_data)
		var hash_string = hasher.finish().hex_encode()
		
		if hash_string == file_info["HASH"]:
			data = current_file_data
			Game.print_text("Downloader.gd: Downloaded file %s.." % file_info["PATH"].split("/")[file_info["PATH"].split("/").size() - 1])
		else:
			Game.print_error("Downloader.gd ERROR: retrieving file failed, retrieved file has incorrect checksum.")
	
	current_looking_file = null
	current_looking_size = null
	current_looking_ip = null
	current_looking_port = null

	return data

func retrieve_file_info(ip: String, port: int, file_path: String):
	yield(get_tree(), "idle_frame")

	if current_looking_file != null:
		Game.print_alert("Downloader.gd ALERT: Cancelled earlier file info lookup..")
	
	current_looking_ip = ip
	current_looking_port = port
	current_looking_file = file_path
	
	var err = Game.peer.send_packet(ip, port, "REQUEST_FILE_INFO", file_path)
	
	if err is GDScriptFunctionState: 
		err = yield(err, "completed")
		
	if err != OK:
		Game.print_error("Downloader.gd ERROR: could not send packet to request file info. code:%s" % err)
		return err
	
	var timer = 0
	var step = 0.1
	while current_file_info == null && timer < TIMEOUT_TIME:
		yield(get_tree().create_timer(step), "timeout")
		timer += step
	
	var info = current_file_info
	
	current_file_info = null
	current_looking_port = null
	current_looking_ip = null
	current_looking_file = null

	return info
		
func send_file(ip: String, port: int, file_path: String) -> int:
	var err = file.open(file_path, File.READ)
	if err != OK:
		Game.print_error("Downloader.gd ERROR: could not open requested file with path: %s! code: %s" % [file_path % err])
		file.close()
		return err
		
	var file_data = file.get_buffer(file.get_len())
	
	file.close()
	
	var split_count = ceil(file_data.size() / float(MAX_PACKET_SIZE))
	
	var pointer_begin = 0
	var pointer_end = MAX_PACKET_SIZE
	
	for _i in range(split_count):
		
		yield(get_tree(), "idle_frame")
		
		if pointer_end > file_data.size():
			pointer_end = file_data.size()
			
		var sub_data = file_data.subarray(pointer_begin, pointer_end - 1)
		
		var packet = {
			"FILE_PATH": file_path,
			"FILE_DATA_PART": sub_data
		}
		
		err = Game.peer.send_packet(ip, port, "FILE_DATA", packet)
		
		if err is GDScriptFunctionState: 
			err = yield(err, "completed")
		
		if err != OK:
			Game.print_error("Downloader.gd ERROR: could not send file data! code: %s" % err)
			return err
			
		pointer_begin += MAX_PACKET_SIZE
		pointer_end += MAX_PACKET_SIZE
		
	emit_signal("send_file")
		
	return OK
	
func _packet_handler(packet):
	match packet["HEADER"]:
		"REQUEST_FILE":
			if hosted_files.has(packet["CONTENT"]):
				send_file(packet["IP"], packet["PORT"], packet["CONTENT"])
				
		"REQUEST_FILE_INFO":
			if hosted_files.has(packet["CONTENT"]):
				
				var err = file.open(packet["CONTENT"], File.READ)
				if err != OK:
					Game.print_error("Downloader.gd ERROR: could not open requested file with path: %s" % packet["CONTENT"])
					return
					
				var file_info = {
					"PATH": packet["CONTENT"],
					"SIZE": file.get_len(),
					"HASH": file.get_sha256(packet["CONTENT"])
				}
				
				err = Game.peer.send_packet(packet["IP"], packet["PORT"], "FILE_INFO", file_info)
				
				if err is GDScriptFunctionState: 
					err = yield(err, "completed")
				
		"FILE_INFO":
			if packet["IP"] == current_looking_ip && packet["PORT"] == current_looking_port:
				var file_info = packet["CONTENT"]
				
				if file_info["PATH"] == current_looking_file:
					current_file_info = file_info
					
		"FILE_DATA":
			if packet["IP"] == current_looking_ip && packet["PORT"] == current_looking_port && packet["CONTENT"]["FILE_PATH"] == current_looking_file:
				if current_file_data == null:
					current_file_data = PoolByteArray()
					
				current_file_data.append_array(packet["CONTENT"]["FILE_DATA_PART"])
				
				var percent = round(float(current_file_data.size()) / float(current_looking_size) * 100)
				
				if percent != last_percent:
					if Game.output_history[Game.output_history.size() - 1]["TEXT"].begins_with("Downloader.gd: Downloading file:"):
						Game.remove_last_print()
					Game.print_text("Downloader.gd: Downloading file: %s%%.." % percent)
					last_percent = percent
				
				current_timer = 0
				
				if current_file_data.size() < current_looking_size:
					Game.peer.send_packet(packet["IP"], packet["PORT"], "REQUEST_NEXT_FILE_PART")
							
func _set_host_addons(value: bool):
	if value:
		var addons = Game.addons.get_enabled_addons()
		for addon_key in addons:
			hosted_files[addons[addon_key]["PATH"]] = {}
	else:
		var addons = Game.addons.get_addons()
		for addon_key in addons:
			if hosted_files.has(addons[addon_key]["PATH"]):
				hosted_files.erase(addons[addon_key]["PATH"])
	
	host_adddons = value
