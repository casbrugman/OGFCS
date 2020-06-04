extends Spatial

var selected_node: Node

func _ready():
	Game.mode.editor.connect("node_selected", self, "select_node")
	
func _process(delta):
	if selected_node is Spatial:
		transform.origin = selected_node.get_global_transform().origin

func select_node(node: Node):
	selected_node = node
