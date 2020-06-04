extends GameMode

var editor: MapEditor

var prefabs = {
	"editor": preload("res://modes/explore/editor/Editor.tscn"),
}

func start_mode(options):
	editor = prefabs.editor.instance()
	editor.map = editor.get_node("Map")
	editor.map_name = name
	
	for child in get_children():
		if child != editor:
			remove_child(child)
			editor.map.add_child(child)
			child.set_owner(editor)
			
	add_child(editor)
	
	get_tree().paused = true
