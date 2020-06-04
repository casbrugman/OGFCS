extends Area

var node: Spatial
var selected:bool = false

var texture setget _set_texture

const FACTOR_SPRITE_SIZE = .0025
const FACTOR_COLLISIION_RADIUS = .05
const FACTOR_OPACITY = .01

func _ready():
	Game.mode.editor.connect("node_selected", self, "_node_selected")
	
	node.connect("tree_exited", self, "_node_exited")

func _process(delta):

	transform.origin = node.get_global_transform().origin
	
	$Sprite3D.pixel_size = transform.origin.distance_to(get_viewport().get_camera().get_global_transform().origin) * FACTOR_SPRITE_SIZE
#	$CollisionShape.shape.radius = transform.origin.distance_to(get_viewport().get_camera().get_global_transform().origin) * FACTOR_COLLISIION_RADIUS
	
	if selected:
		$Sprite3D.opacity = 1
	else:
		$Sprite3D.opacity = clamp(1 + (transform.origin.distance_to(get_viewport().get_camera().get_global_transform().origin) * FACTOR_OPACITY) * -1, .1, 1)
	
func _set_texture(texture):
	$Sprite3D.texture = texture

func _on_Area_input_event(camera, event, click_position, click_normal, shape_idx):
	print(event)

func _on_Area_mouse_entered():
	print(get_parent().name)

func _node_selected(_node):
	selected = node == _node
	
func _node_exited():
	queue_free()
		
func select():
	Game.mode.editor.emit_signal("node_selected", node)
