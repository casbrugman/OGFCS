extends Node

class_name GameMode

var menu_path = "res://ui/menus/default_mode/DefaultMode.tscn"
var menu setget , get_menu

var map: Node
	
func get_menu():
	var new_menu = load(menu_path).instance()
	new_menu.mode = self
	return new_menu
	
func get_maps():
	return Game.addons.get_maps()
	
func init_mode(options: Dictionary) -> int:
	var err = load_map(options["MAP"])
	if err != OK:
		Game.print_error("Mode.gd ERROR: Could not init mode with options: %s!" % options)
		
	return err
	
func load_map(path: String) -> int:
	var map_path
	
	var dir = Directory.new()
	
	if dir.dir_exists(path):
		if !ResourceLoader.exists("%sMap.tscn" % path, "PackedScene"):
			if !ResourceLoader.exists("%sMap.scn" % path, "PackedScene"):
				Game.print_error("Mode.gd ERROR: Could not load map, no map file found: no file named Map.tscn/scn found in folder: '%s'!" % path)
				return ERR_FILE_CANT_OPEN
			else:
				map_path = "%sMap.scn" % path
		else:
			map_path = "%sMap.tscn" % path
	else:
		if ResourceLoader.exists(path):
			map_path = path
		else:
			Game.print_error("Mode.gd ERROR: Could not load map, folder or file: '%s' doesnt exist!" % path)
			return ERR_FILE_CANT_OPEN
	
	map = load(map_path).instance()
	Game.print_text("Mode.gd: Loaded map '%s'.." % map_path)
	
	add_child(map)
	Game.print_text("Mode.gd: Added map '%s' to the scene tree.." % name)
	
	return OK

func start_mode(_options: Dictionary):
	pass
	

