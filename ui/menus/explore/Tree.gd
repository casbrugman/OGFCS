extends Tree

var path = "res://"
var save_path

var treePaths = {}

var dir = Directory.new()

func _ready():
	save_path = Game.config.get_value("explore", "save_folder")
	
	connect("item_activated", self, "_item_activated")
	
func refresh(skip_hidden: bool):
	clear()
	
	var root = create_item()
	root.set_text(0, path)
	root.set_tooltip(0 , "")
	
	build_tree(root, path, skip_hidden)
	
func build_tree(parent: TreeItem, p_path: String, skip_hidden: bool):
	var direct = Directory.new()
	var err = direct.open(p_path)
	if err != OK:
		return
	direct.list_dir_begin(true, skip_hidden)
	
	var currentDir: String = direct.get_next()
	while currentDir != "":
		if (skip_hidden && !currentDir.begins_with(".")) || !skip_hidden:
			var new_item = create_item(parent)
			new_item.set_text(0, currentDir)
			new_item.set_tooltip(0 , " ")
		
			treePaths[new_item] = p_path + currentDir
		
			if direct.current_is_dir():
				build_tree(new_item, p_path + currentDir + "/", skip_hidden)
		
		currentDir = direct.get_next()
	return
	
func _item_activated():
	var full_path = treePaths[get_selected()]
	
	if dir.file_exists(full_path):
		if !dir.dir_exists(save_path):
			var err = dir.make_dir(save_path)
			if err != OK:
				Game.print_error("Explore.gd ERROR: could not create directory with path: '%s'. code: '%s'" % [save_path, err])
				return err
		
		var err = dir.copy(full_path, save_path + "/" + get_selected().get_text(0))
		if err != OK:
			Game.print_error("Tree.gd ERROR: Could not copy file:%s to destination:%s. err:%s" % [full_path, Game.addons.temp_folder + get_selected().get_text(0), err])
			return
			
		Game.print_text("Tree.gd: Copied file from '%s' to '%s'.." % [full_path, save_path + "/" + get_selected().get_text(0)])

