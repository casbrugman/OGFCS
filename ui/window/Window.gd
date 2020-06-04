extends Control

class_name Window

var maxImg = preload("res://ui/window/max.png")
var midImg = preload("res://ui/window/mid.png")

onready var title = $Panel/Header/Title

onready var button_min = $Panel/Header/Buttons/Min
onready var button_max = $Panel/Header/Buttons/Max
onready var button_close = $Panel/Header/Buttons/Close

var content: Control
var resizeable = true setget set_resizeable

var func_min = funcref(self, "hide")
var func_max = funcref(self, "maximize")
var func_close = funcref(self, "queue_free")

func set_content(scene: Control):
	$Panel/Content.add_child(scene)
	$Panel/Header/Title.text = scene.name
	name = scene.name
	if scene is WindowContent:
		scene.window = self
	
	content = scene
	
	content_resized()
	
	scene.connect("resized", self, "content_resized")
		
func set_resizeable(value: bool):
	if value:
		$Panel/Resizers.show()
	else:
		$Panel/Resizers.hide()
	
func _ready():
	get_tree().get_root().connect("size_changed", self, "_resized")
		
func init(_scene, _arg = null):
	set_content(_scene)
	
	raise()
	
func _process(_delta):
	pass
	
func show():
	raise()
	.show()

func _on_Close_pressed():
	func_close.call_func()
		
func _on_Max_pressed():
	func_max.call_func()
	
func _on_Min_pressed():
	func_min.call_func()
	
func maximize():
	OS.window_maximized = !OS.window_maximized
	
	if OS.window_maximized:
		$Panel/Header/Buttons/Max.icon = midImg
	else:
		$Panel/Header/Buttons/Max.icon = maxImg

var dragPos = null
func _on_Header_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			dragPos = get_global_mouse_position() / Game.ui.scale - rect_position
			raise()
		else:
			dragPos = null
			
	if event is InputEventMouseMotion:
		if dragPos != null:
			var window_size = get_viewport_rect().size / Game.ui.scale
			var pos = get_global_mouse_position() / Game.ui.scale
			var global_mouse_pos = get_global_mouse_position() / Game.ui.scale
			
			if global_mouse_pos.x > window_size.x:
				pos.x = window_size.x
			if global_mouse_pos.x < 0:
				pos.x = 0
			if global_mouse_pos.y > window_size.y:
				pos.y = window_size.y
			if global_mouse_pos.y < 0:
				pos.y = 0
			
			rect_position += pos - rect_position - dragPos
			
func content_resized():
	rect_size.x = content.rect_size.x + 5
	rect_size.y = content.rect_size.y + 21

func _resized():
	if rect_position.x + rect_size.x > get_viewport_rect().size.x / Game.ui.scale:
		rect_position.x = get_viewport_rect().size.x / Game.ui.scale - rect_size.x
		
	if rect_position.x < 0:
		rect_position.x = 0
		
	if rect_position.y + rect_size.y > get_viewport_rect().size.y / Game.ui.scale:
		rect_position.y = get_viewport_rect().size.y / Game.ui.scale - rect_size.y
		
	if rect_position.y < 0:
		rect_position.y = 0
	
func center():
	yield(get_tree(), "idle_frame")
	rect_position = get_parent().rect_size / 2 - rect_size /2
