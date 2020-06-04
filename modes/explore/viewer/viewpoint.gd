extends Spatial

onready var body = get_parent()

var yaw = 0
var pitch = 0
var shake = Vector2()	
	
func _input(event):
	if Input.is_action_pressed("editor_capture_mouse") && Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	if !Input.is_action_pressed("editor_capture_mouse") && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:

			yaw = -event.relative.x * .00001 * Game.config.get_value("input", "mouse_sensitivity")
			pitch = -event.relative.y * .00001 * Game.config.get_value("input", "mouse_sensitivity")
		
func _process(delta):
	body.rotate_y(yaw)
	if rad2deg(pitch + rotation.x)  > 89:
		rotate_x(deg2rad(89 - rad2deg(rotation.x)))
	elif rad2deg(pitch + rotation.x)  < -89:
		rotate_x(deg2rad(-89 - rad2deg(rotation.x)))
	else:
		rotate_x(pitch)
		
	body.gizmo_camera.rotation.x = rotation.x
	body.gizmo_camera.rotation.y = body.rotation.y
	
	yaw = 0
	pitch = 0

