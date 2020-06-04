extends Camera

const RAY_LENGTH = 100

func _process(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_from = project_ray_origin(mouse_pos)
	var ray_to = ray_from + project_ray_normal(mouse_pos) * RAY_LENGTH
	var space_state = get_world().direct_space_state
	var selection = space_state.intersect_ray(ray_from, ray_to, [], 2147483647, true, true)
	
	if Input.is_action_just_pressed("editor_select_mouse"):
		if selection.has("collider") && selection["collider"].has_method("select"):
			selection["collider"].select()
		
