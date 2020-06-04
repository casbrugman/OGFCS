extends Node

class_name GamePeer

const PRINT_PACKETS = false
const TIMEOUT_TIME = 5

signal packet

var port: int
var ip: String
var host_addons: bool

var current_retrieving_info = {}

var server: WebSocketServer

var peers = {}

func _ready():
	Game.peer = self
	
	port = Game.config.get_value("server", "default_ping_listen_port")
	ip = Game.config.get_value("server", "default_ping_listen_ip")
	host_addons = Game.config.get_value("server", "default_host_addons")
	
	connect("packet", self, "_packet_handler")
	
	listen()
	
func _server_client_connected(id, _proc):
	var peer = server.get_peer(id)

	if peers.has(peer.get_connected_host()):
		peers[peer.get_connected_host()][peer.get_connected_port()] = peer
	else:
		peers[peer.get_connected_host()] = {
			peer.get_connected_port(): peer
		}

func _process(_delta):
	if server != null:
		server.poll()
	
	for _ip in peers:
		for _port in peers[_ip]:
			var peer = peers[_ip][_port]
			if peer is WebSocketClient:
				peer.poll()
				peer = peer.get_peer(1)
			
			for i in peer.get_available_packet_count():
				var packet = peer.get_var()
			
				if typeof(packet) == TYPE_DICTIONARY && packet["NAME"] == Game.NAME:
					packet["IP"] = _ip
					packet["PORT"] = _port
			
					if PRINT_PACKETS:
						print("RECEIVE:", packet)
			
					emit_signal("packet", packet)
	
func _exit_tree():
	if server != null:
		server.stop()
	
	for _ip in peers:
		for port in peers[_ip]:
			var peer = peers[_ip][port]
			
			if peer is WebSocketClient:
				peer = peer.get_peer(1)
				
				
			peer.close(1000, "Disconnected")

func listen(_port: int = port, _ip: String = ip) -> int:
	port = _port
	ip = _ip
	
	if server != null:
#		server.disconnect("client_connected", self, "_server_client_connected")
		server.stop()
		
	server = WebSocketServer.new()

	var err = server.listen(port)
	if err != OK:
		Game.print_error("Peer.gd ERROR: could not listen on port:'%s' and ip:'%s'. code:'%s'.." % [port, ip, err])
		if err == ERR_CANT_CREATE:
			Game.print_alert("Peer.gd ALERT: please make sure there is not already a server running on port:'%s'!" % port)
		return err
		
	server.connect("client_connected", self, "_server_client_connected")
	
	Game.print_text("Peer.gd: listening on port:'%s' and ip:'%s'.." % [port, ip])
		
	return err
	
func connect_to_peer(_ip: String, _port: int):
	yield(get_tree(), "idle_frame")
	
	var peer = WebSocketClient.new()
	
	if peers.has(_ip):
		peers[_ip][_port] = peer
	else:
		peers[_ip] = {
			_port: peer
		}
		
	var addr: String = "ws://%s:%s" % [_ip, _port]
	
	var err = peer.connect_to_url(addr)
	
	if err != OK:
		Game.print_alert("Peer.gd ALERT: could not connect to peer with address:'%s'. code:'%s' " % ["ws://%s:%s" % [_ip, _port], err])
		
		peers[_ip].erase(_port)
		if [_ip].size() == 0:
			peers.erase(_ip)
			
		return err
	
	var poll_time = 0.1
	var time_polling = 0
	
	while peer.get_connection_status() == peer.CONNECTION_CONNECTING && time_polling < TIMEOUT_TIME:
		yield(get_tree().create_timer(poll_time), "timeout")
		time_polling += poll_time
		
	if peer.get_connection_status() == peer.CONNECTION_CONNECTED:
		return peer
	else:
		Game.print_alert("Peer.gd ALERT: could not connect to peer with address:'%s': connection timeout.." % "ws://%s:%s" % [_ip, _port])
		
		peers[_ip].erase(_port)
		if [_ip].size() == 0:
			peers.erase(_ip)
		
		return ERR_TIMEOUT
		
func send_packet(_ip: String, _port: int, header, content = null) -> int:
	var peer
	
	if peers.has(_ip) && peers[_ip].has(_port):
		peer = peers[_ip][_port]
		
		if peer is WebSocketClient:
			peer = peer.get_peer(1)
	
		if !peer.is_connected_to_host():
			Game.print_alert("Peer.gd ALERT: peer with address:'%s' disconnected, reconnecting.." % "ws://%s:%s" % [_ip, _port])
			
			peer = yield(connect_to_peer(_ip, _port), "completed")
	else:
		peer = yield(connect_to_peer(_ip, _port), "completed")
		
		if peer is int:
			Game.print_alert("Peer.gd ALERT: could not send packet, could not connect to peer. code:'%s'" % peer)
			return peer
	
	var packet = {
		"NAME": Game.NAME,
		"HEADER": header,
		"CONTENT": content
	}
	
	if PRINT_PACKETS:
		print("SEND:%s,%s:%s" % [packet, _ip, _port])
		
	if peer is WebSocketClient:
			peer = peer.get_peer(1)
	
	var err = peer.put_var(packet)
	if err != OK:
		Game.print_error("Peer.gd ERROR: could not send packet with content:'%s'! code:'%s'" % [packet, err])
		return err
		
	return OK
		
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
					"SERVER_HASH": (OS.get_unique_id() + str(OS.get_process_id())).sha256_text(),
					"SERVER_MODE": Game.server.mode,
					})
			
				if err is GDScriptFunctionState: 
					err = yield(err, "completed")
		"INFO":
			if current_retrieving_info.has(packet["IP"]):
				if current_retrieving_info[packet["IP"]].has(packet["PORT"]):
					#TODO fix ping
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
