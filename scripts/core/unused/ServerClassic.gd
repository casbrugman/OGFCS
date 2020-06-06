extends Node

class_name GameServerClassic

var peer: NetworkedMultiplayerENet

const LOCALHOST = "0:0:0:0:0:0:0:1"

var ip: String
var port: int
var max_players: int
var message: String

var connected_players: Dictionary = {}

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	
	ip = Game.config.get_value("server", "default_host_ip")
	port = Game.config.get_value("server", "default_rpc_host_port")
	max_players = Game.config.get_value("server", "default_max_players")
	message = Game.config.get_value("server", "default_message")
	
#	Game.server = self
	
func _exit_tree():
	stop_server()

func start_server() -> int:
	if peer != null:
		stop_server()
		
	if Game.client.peer != null:
		Game.client.stop_client()
		
	peer = NetworkedMultiplayerENet.new()
	
	peer.set_bind_ip(ip)
	
	var err = peer.create_server(port, max_players)
	if err != OK:
		
		Game.print_error("Server.gd ERROR: Could not create server on port:'%s'. code:'%s'" % [port, err])
		peer = null
		
		return err
	
	get_tree().set_network_peer(peer)
	
	max_players += 1
	
	Game.client.id = 1
	
	connected_players[Game.client.id] = {
		"USERNAME": Game.client.username
	}
	
	Game.print_text("Server.gd: Started server on ip:'%s' and port:'%s'.." % [ip, port])
	
	return err
	
func stop_server():
	if peer != null:
		peer.close_connection()
		Game.print_text("Server.gd: Closed connection..")
		
func _player_connected(_id):
	Game.print_color("Player with id:'%s' joined the game!" % _id, Color.green)
	
	rpc_id(_id, "receive_player_info", get_tree().get_network_unique_id(), connected_players[Game.client.id])
	
func _player_disconnected(_id):
	Game.print_color("Player with id:'%s' disconnected!" % _id, Color.yellow)
	
	if connected_players.has(_id):
		connected_players.erase(_id)
		
remote func receive_player_info(sender_id, sender_info):
	connected_players[sender_id] = sender_info
