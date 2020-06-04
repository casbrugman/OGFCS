extends Tree

var nodes: Dictionary = {}
var treeItems: Dictionary = {}

func _ready():
	var root = create_item()
	root.set_text(0, Game.mode.editor.map_name)
	root.set_tooltip(0 , "")
	
	nodes[Game.mode.editor] = root
	treeItems[root] = Game.mode.editor
	
	build_tree(Game.mode.editor.map, root)
	
	connect("item_selected", self, "_item_selected")
	
	Game.mode.editor.connect("node_selected", self, "_node_selected")
	
func build_tree(parent: Node, root: TreeItem):
	for child in parent.get_children():
		var new_item = create_item(root)
		new_item.set_text(0, child.name)
		new_item.set_tooltip(0 , " ")
		treeItems[new_item] = child
		nodes[child] = new_item
		build_tree(child, new_item)
		
func _node_selected(node: Node):
	var item: TreeItem = nodes[node]
	
	var current_item = item
	while current_item != null:
		current_item.collapsed = false
		current_item = current_item.get_parent()
	
	item.select(0)
	ensure_cursor_is_visible()
	
func _item_selected():
	var node = treeItems[get_selected()]
	Game.mode.editor.emit_signal("node_selected", node)
