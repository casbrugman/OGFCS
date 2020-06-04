extends Node

class_name MapEditor

onready var ui = $UI
onready var map = $Map
onready var gizmos = $Gizmos

var map_name

signal node_selected

var prefabs = {
	"viewer": preload("res://modes/explore/viewer/viewer.tscn"),
	"menu_scene_tree": preload("res://modes/explore/menus/scenetree_viewer/SceneTreeViewer.tscn"),
	"node_gizmo": preload("res://modes/explore/gizmos/nodes/NodeGizmo.tscn"),
}

var icons = {
	"camera": preload("res://modes/explore/gizmos/nodes/icons/camera.png"),
	"light": preload("res://modes/explore/gizmos/nodes/icons/light.png"),
	"mesh": preload("res://modes/explore/gizmos/nodes/icons/mesh.png"),
	"none": preload("res://modes/explore/gizmos/nodes/icons/none.png"),
	"spatial": preload("res://modes/explore/gizmos/nodes/icons/spatial.png"),
}

func _ready():
	setup_children(map)
	
	var window_scene_tree: Window = yield(ui.windows.create_window(prefabs.menu_scene_tree), "completed")
	window_scene_tree.rect_position = Vector2(60, 60)
	window_scene_tree.button_close.hide()
	
func setup_children(parent: Node):
	for child in parent.get_children():
		child.pause_mode = Node.PAUSE_MODE_STOP
		
		if child is Camera:
			create_gizmo(icons.camera, child)
		elif child is MeshInstance:
			create_gizmo(icons.mesh, child)
		elif child is Light:
			create_gizmo(icons.light, child)
		elif child is Spatial:
			create_gizmo(icons.spatial, child)
			
		setup_children(child)
		
func create_gizmo(icon, node: Spatial):
	var new_gizmo = prefabs.node_gizmo.instance()
	
	new_gizmo.texture = icon
	new_gizmo.node = node
		
	gizmos.add_child(new_gizmo)
	
	
func select_node(node: Node):
	emit_signal("node_selected", node)
