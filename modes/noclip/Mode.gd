extends GameMode

var player = preload("res://objects/noclip/Noclip.tscn")

func start_mode(options):
	var newPlayer = player.instance()
	newPlayer.get_node("viewpoint/Camera").current = true
	add_child(newPlayer)
	
