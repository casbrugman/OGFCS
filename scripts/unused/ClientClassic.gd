extends Node

class_name GameClientClassic

var peer: NetworkedMultiplayerPeer

enum {CONNECTION_DISCONNECTED, CONNECTION_CONNECTING, CONNECTION_CONNECTED}

var connection_status = CONNECTION_DISCONNECTED

var id
var username setget _set_username

signal username_changed

func _ready():
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	username = Game.config.get_value("identity", "username")
	
#	Game.client = self
	
func _exit_tree():
	if peer != null:
		peer.close_connection()
	
func start_client(ip: String, port: int) -> int:
	yield(get_tree(), "idle_frame")
	
	if peer != null:
		stop_client()
		
	if Game.server.peer != null:
		Game.server.stop_server()
	
	peer = NetworkedMultiplayerENet.new()
		
	var err = peer.create_client(ip, port)
	if err != OK:
		Game.print_error("Client.gd ERROR: could not create client to connect to ip:'%s' and port:'%s'! code:'%s'" % [ip, port, err])
		return err
		
	connection_status = CONNECTION_CONNECTING
	
	Game.print_text("Client.gd: Started rpc client, connecting.. ")
	
	get_tree().set_network_peer(peer)
	
	id = get_tree().get_network_unique_id()
	
	Game.server.connected_players[id] = {
		"USERNAME": username
	}
	
	var poll_time = 0.1
	while connection_status == CONNECTION_CONNECTING:
		yield(get_tree().create_timer(poll_time), "timeout")
	
	if connection_status == CONNECTION_CONNECTED:
		return OK
	else:
		id = null
		Game.server.connected_players.clear()
		
		return ERR_CONNECTION_ERROR

func stop_client():
	peer.close_connection()
	
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
