extends Node

class_name GameClient

var peer: NetworkedMultiplayerPeer

enum {CONNECTION_DISCONNECTED, CONNECTION_CONNECTING, CONNECTION_CONNECTED}

var connection_status = CONNECTION_DISCONNECTED
var mode

var id
var username setget _set_username

signal username_changed

func _ready():
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	Game.config.connect("config_reloaded", self, "_config_changed")
	
	username = Game.config.get_value("identity", "username")
	mode = Game.config.get_value("server", "default_use_websockets")
	
	Game.client = self
	
func _exit_tree():
	stop_client()
	
func start_client(ip: String, port: int) -> int:
	yield(get_tree(), "idle_frame")
	
	if peer != null:
		stop_client()
		
	if Game.server.peer != null:
		Game.server.stop_server()
	
	assert(typeof(mode) != TYPE_BOOL)
	if mode == Game.server.MODE_CLASSIC:
		peer = NetworkedMultiplayerENet.new()
			
		var err = peer.create_client(ip, port)
		if err != OK:
			Game.print_error("Client.gd ERROR: could not create client to connect to ip:'%s' and port:'%s'! code:'%s'" % [ip, port, err])
			return err
			
	elif mode == Game.server.MODE_WEBSOCKET:
		peer = WebSocketClient.new()
		
		var adress = "ws://%s:%s" % [ip, port]
		var err = peer.connect_to_url(adress, PoolStringArray(), true)
		if err != OK:
			Game.print_error("Client.gd ERROR: could not create websocket client to connect to adress:'%s'! mode'%s' code:'%s'" % [adress, mode, err])
			return err
		
	connection_status = CONNECTION_CONNECTING
	
	Game.print_text("Client.gd: Started rpc client, connecting.. ")
	
	get_tree().set_network_peer(peer)
	
	var poll_time = 0.1
	while connection_status == CONNECTION_CONNECTING:
		yield(get_tree().create_timer(poll_time), "timeout")
	
	if connection_status == CONNECTION_CONNECTED:
		id = get_tree().get_network_unique_id()
		return OK
	else:
		id = null
		Game.server.connected_players.clear()
		
		return ERR_CONNECTION_ERROR

func stop_client():
	if peer != null:
		if mode == Game.server.MODE_CLASSIC:
			peer.close_connection()
		elif mode == Game.server.MODE_WEBSOCKET:
			peer.stop()
	
func _connected_ok():
	Game.print_color("Client.gd: Joined game!", Color.green)
	connection_status = CONNECTION_CONNECTED
	
	Game.server.rpc("receive_player_info", get_tree().get_network_unique_id(), Game.server.connected_players[id])
	
func _connected_fail():
	Game.print_error("Client.gd ERROR: could not connect to rpc server!")
	connection_status = CONNECTION_DISCONNECTED
	
func _server_disconnected():
	Game.print_alert("Client.gd ALERT: Server disconnected, returning to main menu..")
	connection_status = CONNECTION_DISCONNECTED
	Game.server.connected_players.clear()
	Game.start()

func _set_username(value: String):
	if Game.server.connected_players.size() > 0:
		
		Game.server.connected_players[id] = {
			"USERNAME": value
		}
		Game.server.rpc("receive_player_info", get_tree().get_network_unique_id(), Game.server.connected_players[id])
		
		emit_signal("username_changed", value)
	
	username = value
	
func _config_changed():
	_set_username(Game.config.get_value("identity", "username"))
