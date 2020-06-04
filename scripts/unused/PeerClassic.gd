extends Node

class_name GamePeerClassic

const PRINT_PACKETS = false
const TIMEOUT_TIME = 5

signal packet

var port: int
var ip: String
var host_addons: bool

var current_retrieving_info = {}

var peer: TCP_Server

var packet_peers = {}

func _ready():
#	Game.peer = self
	
	port = Game.config.get_value("server", "default_ping_listen_port")
	ip = Game.config.get_value("server", "default_ping_listen_ip")
	host_addons = Game.config.get_value("server", "default_host_addons")
	
	connect("packet", self, "_packet_handler")
	
	listen()

func _process(_delta):
	if peer.is_connection_available():
		var stream_peer = peer.take_connection()
		
		var packet_peer = PacketPeerStream.new()
		packet_peer.stream_peer = stream_peer
		
		if packet_peers.has(stream_peer.get_connected_host()):
			packet_peers[stream_peer.get_connected_host()][stream_peer.get_connected_port()] = packet_peer
		else:
			packet_peers[stream_peer.get_connected_host()] = {
				stream_peer.get_connected_port(): packet_peer
			}
			
	for _ip in packet_peers:
		for port in packet_peers[_ip]:
			var packet_peer: PacketPeerStream = packet_peers[_ip][port]
			
			for i in packet_peer.get_available_packet_count():
				var packet = packet_peer.get_var()
		
				if typeof(packet) == TYPE_DICTIONARY && packet["NAME"] == Game.NAME:
					packet["IP"] = _ip
					packet["PORT"] = port
					
					if PRINT_PACKETS:
						print("RECEIVE", packet)
						
					emit_signal("packet", packet)

func _exit_tree():
	peer.stop()
	
	for _ip in packet_peers:
		for port in packet_peers[_ip]:
			var packet_peer: PacketPeerStream = packet_peers[_ip][port]
			packet_peer.stream_peer.disconnect_from_host()

func listen(_port: int = port, _ip: String = ip) -> int:
	port = _port
	ip = _ip
	
	if peer != null:
		peer.stop()
		
	peer = TCP_Server.new()

	var err = peer.listen(port)
	if err != OK:
		if OS.get_name() == "HTML5":
			return err
		else:
			Game.print_error("Peer.gd ERROR: could not listen on port:'%s' and ip:'%s'. code:'%s'.." % [port, ip, err])
			return err
		
	return err
	
func connect_to_packet_peer(_ip: String, _port: int):
	yield(get_tree(), "idle_frame")
	
	var stream_peer = StreamPeerTCP.new()
	
	var err = stream_peer.connect_to_host(_ip, _port)
	
	if err != OK:
		Game.print_alert("Peer.gd ALERT: could not connect to peer with ip:'%s' and port:'%s'. code:'%s' " % [_ip, _port, err])
		return err
	
	var poll_time = 0.1
	var time_polling = 0
	
	while stream_peer.get_status() == stream_peer.STATUS_CONNECTING && time_polling < TIMEOUT_TIME:
		yield(get_tree().create_timer(poll_time), "timeout")
		time_polling += poll_time
		
	if stream_peer.get_status() == stream_peer.STATUS_CONNECTED:
		var packet_peer = PacketPeerStream.new()
		packet_peer.stream_peer = stream_peer
		
		if packet_peers.has(_ip):
			packet_peers[_ip][_port] = packet_peer
		else:
			packet_peers[_ip] = {
				_port: packet_peer
			}
			
		return packet_peer
	else:
		return ERR_CONNECTION_ERROR
		
func send_packet(_ip: String, _port: int, header, content = null) -> int:
	var packet_peer
	
	if packet_peers.has(_ip) && packet_peers[_ip].has(_port):
		packet_peer = packet_peers[_ip][_port]
		
		if !packet_peer.stream_peer.is_connected_to_host():
			Game.print_alert("Peer.gd ALERT: peer with ip:'%s' and port:'%s' disconnected, reconnecting.." % [_ip, _port])
			
			packet_peer = yield(connect_to_packet_peer(_ip, _port), "completed")
		
			if packet_peer is int:
				packet_peers[_ip].erase(_port)
				return packet_peer
	else:
		packet_peer = yield(connect_to_packet_peer(_ip, _port), "completed")
		
		if packet_peer is int:
			Game.print_alert("Peer.gd ALERT: could not send packet, could not connect to peer. code:'%s'" % packet_peer)
			return packet_peer
	
	var packet = {
		"NAME": Game.NAME,
		"HEADER": header,
		"CONTENT": content
	}
	
	if PRINT_PACKETS:
		print("SEND:", packet, _ip, _port)
	
	var err = packet_peer.put_var(packet)
	if err != OK:
		Game.print_error("Peer.gd ERROR: could not send packet with content:'%s'! code:'%s'" % [packet, err])
		return err
	return 0
		
func _packet_handler(packet):
	match packet["HEADER"]:
		"REQUEST_INFO":
			if ip != "*":
				if packet["IP"] != ip:
					return
			if get_tree().is_network_server():
				var err = send_packet(packet["IP"], packet["PORT"], "INFO", {
					"MODE": Game.current_mode_path,
					"OPTIONS": Game.current_options,
					"PORT": Game.server.port,
					"CURRENT_PLAYERS": Game.server.connected_players.size(),
					"MAX_PLAYERS": Game.server.max_players,
					"MESSAGE": Game.server.message,
					"ADDONS": Game.addons.get_enabled_addons(),
					"SERVER_HASH": (OS.get_unique_id() + str(OS.get_process_id())).sha256_text()
					})
			
				if err is GDScriptFunctionState: 
					err = yield(err, "completed")
		"INFO":
			if current_retrieving_info.has(packet["IP"]):
				if current_retrieving_info[packet["IP"]].has(packet["PORT"]):
					packet["CONTENT"]["PING"] = "--"
					current_retrieving_info[packet["IP"]][packet["PORT"]] = packet["CONTENT"]
	
func retrieve_server_info(_ip: String, _port: int):
	Game.print_text("Peer.gd: Retrieving server info from server with ip:%s and port:%s.." % [_ip, _port])
	
	if current_retrieving_info.has(_ip):
		current_retrieving_info[_ip][_port] = null
	else:
		current_retrieving_info[_ip] = {
			_port: null
		}
	
	var err = send_packet(_ip, _port, "REQUEST_INFO")
	
	if err is GDScriptFunctionState:
		err = yield(err, "completed")
	
	if err != OK:
		Game.print_alert("Peer.gd ALERT: could not request info. code:%s" % err)
		
		return null
	
	var timer = 0
	var step = 0.1
	while current_retrieving_info[_ip][_port] == null && timer < TIMEOUT_TIME:
		yield(get_tree().create_timer(step), "timeout")
		timer += step
	
	if current_retrieving_info[_ip][_port] == null:
		
		return null
	else:
		var info = current_retrieving_info[_ip][_port]

		return info
