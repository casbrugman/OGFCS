extends Spatial

const SPEED = 10
const SPRINT_SPEED = 1
const ACCELERATION = 12

var velocity = Vector3()
var factor = 1

onready var viewpoint = $viewpoint

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP:
				factor *= 2
			if event.button_index == BUTTON_WHEEL_DOWN:
				factor *= .5

func _process(delta):
	var direction = Vector3()
	var input = Vector3()

	#MOVE DIRECTION
	if Input.is_action_pressed("move_right"):
		input.x = 1

	if Input.is_action_pressed("move_left"):
		input.x = -1

	if Input.is_action_pressed("move_forward"):
		input.z = 1

	if Input.is_action_pressed("move_back"):
		input.z = -1

	input = input.normalized()

	#INPUT DIRECTION TO CAMERA DIRECTION
	
	direction += -viewpoint.get_global_transform().basis.z.normalized() * input.z
	direction += get_global_transform().basis.x.normalized() * input.x
	
	var target = Vector3()
	if Input.is_action_pressed("sprint"):
		target = direction * SPRINT_SPEED * factor
	else:
		target = direction * SPEED * factor
		
	velocity = velocity.linear_interpolate(target, ACCELERATION * delta)

	transform.origin += velocity * delta

		


