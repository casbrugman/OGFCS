extends Node

const NAME = "OGFCS"
const VERSION = "0.0.0"

const screenshot_dir = "user://screenshots"

var file:File = File.new()
var dir:Directory = Directory.new()

signal print_logo
signal print_text
signal print_error
signal print_alert
signal print_color
signal remove_last_print

signal loaded_map
signal started_game
signal joined_game
signal exit
signal restart
signal fullscreen
signal maximize

signal _loaded_map

var console
var mode: GameMode
var main: Node
var world: Node
var universe: Node
var ui:GameUI
var window
var config:GameConfig
var addons: GameAddons
var server: GameServer
var client: GameClient
var peer: GamePeer
var downloader: GameDownloader

var prefabs = {
	"universe": preload("res://Universe.tscn"),
	"main": preload("res://Main.tscn")
}

var current_mode_path: String
var current_options: Dictionary

var _loader
var _last_load_percent

var output_history: Array = []

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	if get_node("/root/Main") != null:
		get_node("/root/Main").connect("ready", self, "_core_ready")

func _core_ready():
	if config.get_value("start", "reset"):
		config.reset()
	
	addons.load_addons(addons.get_enabled_addons())
		
	OS.window_fullscreen = config.get_value("window", "fullscreen")
		
	print_logo(config.get_value("console", "logo") + "	v" + VERSION)
	
	universe = prefabs.universe.instance()
	universe.connect("ready", self, "start")
	main.add_child(universe)
	
func start():
	if config.get_value("start", "use_autoexec"):
		print_text("Game.gd: Executing autoexec..")
		eval(config.get_value("start", "autoexec"))
	else:
		server.ip = config.get_value("start", "host_ip")
		server.max_players = config.get_value("start", "host_max_players")
		server.message = config.get_value("start", "host_message")
		downloader.host_adddons = config.get_value("start", "host_addons")
		
		var err = yield(start_game(config.get_value("start", "mode"), config.get_value("start", "options")), "completed")
		if err != OK:
			ui.show_main_menu()
	
func _input(event):
	if event.is_action_pressed("fullscreen"):
		fullscreen(!OS.window_fullscreen)
	if event.is_action_pressed("screenshot"):
		screenshot()
	
func _process(_delta):
	
	#Only used when resource loader loads interactive
	if _loader != null:
		var err = _loader.poll()
	
		if err == ERR_FILE_EOF: # Finished loading.
			var resource = _loader.get_resource()
			_loader = null
			emit_signal("_loaded_map", resource)
		elif err == OK:
			var percent = int(float(_loader.get_stage()) / float(_loader.get_stage_count()) * 100)
			if _last_load_percent != percent:
				print_text("Game.gd LOADING MAP: %s%%.." % percent)
				_last_load_percent = percent
		else:
			_loader = null
			
func load_map(path: String = "res://modes/menu/Mode.gd", options: Dictionary = {"MAP": "res://maps/Start/Map.tscn"}) -> int:
	print_text("Game.gd: Loading mode:'%s' with options:'%s'.." % [path, options])
	
	yield(get_tree(), "idle_frame")

	if !ResourceLoader.exists(path, "GDScript"):
		print_alert("Game.gd ALERT: file: '%s' doesnt exist, loading 'res://modes/noclip.gd'.." % path)
		path = "res://modes/noclip/Mode.gd"
	if !ResourceLoader.exists(path, "GDScript"):
		print_error("Game.gd ERROR: could not load map, res://modes/noclip.gd does not exist!")
		return ERR_FILE_NOT_FOUND
		
	var script: GDScript = load(path)
	
	for child in world.get_children():
		world.remove_child(child)
		child.queue_free()
		
	mode = GameMode.new()
	mode.name = "Mode"
	mode.pause_mode = Node.PAUSE_MODE_STOP
	
	world.add_child(mode)
	mode.set_script(script)
		
	mode.init_mode(options)
	
	current_mode_path = path
	current_options = options
	
	emit_signal("loaded_map")
	
	return OK

func start_game(path: String, options: Dictionary) -> int:
	print_text("Game.gd: Starting game on mode:'%s' with options:'%s'.." % [path, options])
	
	yield(get_tree(), "idle_frame")
	
#	var err = peer.listen()
#	if err != OK:
#		print_error("Game.gd ERROR: could not start game: could not start a ping server! code:'%s'" % err)
#		return err
	
	var err = server.start_server()
	if err != OK:
		print_error("Game.gd ERROR: could not start game: could not start a rpc server! code:'%s'" % err)
		if err == ERR_CANT_CREATE:
			print_alert("Game.gd ALERT: please make sure there is not already a server running on port:'%s'!" % server.port)
		return err

	err = yield(load_map(path, options),"completed")
	
	if err != OK:
		print_error("Game.gd ERROR: could not load mode with path:'%s' and options:'%s'! code:'%s'"% [path, options, err])
		server.stop_server()
		return err
		
	print_text("Game.gd: Started mode..")
		
	emit_signal("started_game")
	
	get_tree().paused = false
	
	mode.start_mode(options)
	
	return err
	
func join_game(ip: String, port: int) -> int:
	print_text("Game.gd: Joining game on ip:'%s' and port:'%s'.." % [ip, port])
	
	var info = yield(peer.retrieve_server_info(ip, port), "completed")
	if info == null:
		print_error("Game.gd ERROR: could not retrieve server info: connection timed out.")
		return ERR_TIMEOUT
		
	
	var missing_and_disabled_addons = addons.check_addons(info["ADDONS"])
	if missing_and_disabled_addons["NEED_DOWNLOADING"].size() > 0:
		missing_and_disabled_addons["NEED_DOWNLOADING"] = yield(addons.download_addons(ip, port, missing_and_disabled_addons["NEED_DOWNLOADING"]), "completed")
		if missing_and_disabled_addons["NEED_DOWNLOADING"] == null:
			print_error("Game.gd ERROR: could not join game, could not download addons from server..")
			return FAILED
			
	addons.load_addons(missing_and_disabled_addons["NEED_ENABLING"])
	addons.load_addons(missing_and_disabled_addons["NEED_DOWNLOADING"])
	
	var err = yield(load_map(info["MODE"], info["OPTIONS"]), "completed")
	if err != OK:
		print_error("Game.gd ERROR: could not load map with path:'%s' and _mode:'%s'! code:'%s'" % [info["MAP"], info["MODE"], err])
		client.stop_client()
		return err
		
		
	print_text("Game.gd: Starting rpc client..")
	if info["SERVER_HASH"] == (OS.get_unique_id() + str(OS.get_process_id())).sha256_text():
		print_alert("Game.gd ALERT: you are the host of this game, not starting a rpc client..")
	else:
		Game.client.mode = info["SERVER_MODE"]
		
		err = yield(client.start_client(ip, info["PORT"]), "completed")
		if err != OK:
			print_error("Game.gd ERROR: could not start rpc client! code:'%s'" % err)
			return err
	
	
	print_text("Game.gd: Joined game!")
	
	OS.request_attention()
	emit_signal("joined_game")
	
	get_tree().paused = false

	mode.start_mode(info["OPTIONS"])
	
	return err
	
func eval(input: String):
#	var expression = Expression.new()
#
#	var err = expression.parse(input)
#	if err != OK:
#		print_error("Game.gd ERROR: " + expression.get_error_text())
#		return err
#
#	var result = expression.execute([], null, true)
#	if expression.has_execute_failed():
#		print_error("Game.gd ERROR: " + str(result))
#	else:
#		print_text(str(result))

	var script = GDScript.new()
	script.set_source_code("func eval():%s\n\t" % input)
	var err = script.reload()
	if err != OK:
		if err == ERR_PARSE_ERROR:
			print_error("Game.gd ERROR: could not execute command, syntax error!")
		else:
			print_error("Game.gd ERROR: could not reload script! code: %s" % err)

	var obj = Reference.new()
	obj.set_script(script)

	obj.eval()

func exit():
	emit_signal("exit")
	get_tree().quit()
	
func restart():
	emit_signal("restart")
	OS.shell_open(OS.get_executable_path())
	exit()
	
func fullscreen(value: bool):
	emit_signal("fullscreen", value)
	OS.window_fullscreen = value 
	
func screenshot(save_path: String = ""):
	var image = get_viewport().get_texture().get_data()
	image.flip_y()
	
	if save_path == "":
		save_path = screenshot_dir + "/%s.png" % str(OS.get_unix_time())
	
	var dir_path = save_path.split("/")
	dir_path.remove(dir_path.size() - 1)
	dir_path = dir_path.join("/")
	
	if !dir.dir_exists(dir_path):
		dir.make_dir_recursive(dir_path)
	
	var err = image.save_png(save_path)
	if err != OK:
		print_error("Game.gd ERROR: could not save screenshot at path:'%s'. code:'%s'" % [save_path, err])
	else:
		print_text("Game.gd: Saved screenshot at path:'%s'.." % save_path)
	
func minimize(value: bool):
	emit_signal("maximize", value)
	OS.window_minimized = value
		
func maximize(value: bool):
	emit_signal("maximize", value)
	OS.set_window_maximized(value)
	
func print_logo(text):
	print(text)
	output_history.append({
		"TYPE": "LOGO",
		"TEXT": text
	})
	emit_signal("print_logo", text)

func print_text(text):
	print(text)
	output_history.append({
		"TYPE": "TEXT",
		"TEXT": text
	})
	emit_signal("print_text", text)
	
func print_error(text):
	print(text)
	output_history.append({
		"TYPE": "ERROR",
		"TEXT": text
	})
	emit_signal("print_error", text)

func print_alert(text):
	print(text)
	output_history.append({
		"TYPE": "ALERT",
		"TEXT": text
	})
	emit_signal("print_alert", text)
	
func print_color(text, color:Color):
	print(text)
	output_history.append({
		"TYPE": "COLOR",
		"TEXT": text,
		"COLOR":  color
	})
	emit_signal("print_color", text, color)
	
func remove_last_print():
	output_history.erase(output_history.size() - 1)
	emit_signal("remove_last_print")
