extends Control

onready var windows: WindowContainer = $Windows

var scale = 1 setget _set_scale
var auto_scale = true

func _ready():
	auto_scale = Game.config.get_value("ui", "auto_scale")
	
	if auto_scale:
		_set_scale(Game.config.ui_scale())
	else:
		_set_scale(Game.config.get_value("ui", "scale"))
	
	get_tree().connect("screen_resized", self, "_screen_resized")
	
func _input(event):
	if event.is_action_pressed("editor_capture_mouse"):
		if get_focus_owner() != null:
			get_focus_owner().release_focus()
	
func _set_scale(value: float):
	rect_scale = Vector2(value, value)
	anchor_bottom = 1 / value
	anchor_right = 1 / value
	scale = value
	
func _screen_resized():
	_set_scale(Game.config.ui_scale())
