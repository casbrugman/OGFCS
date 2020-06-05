extends Control

class_name WindowContainer

enum {ALIGN_X_LEFT, ALIGN_X_CENTER, ALIGN_X_RIGHT}
enum {ALIGN_Y_TOP, ALIGN_Y_CENTER, ALIGN_Y_BOTTOM}

var window_prefab = preload("res://ui/window/Window.tscn")
var window_alert = preload("res://ui/window/WindowAlert.tscn")
var window_confirm = preload("res://ui/window/WindowConfirm.tscn")

func create_window(prefab: PackedScene):
	var window = window_prefab.instance()
	window.init(prefab.instance())
	add_child(window)
	
	yield(get_tree(), "idle_frame")
	window.center()
	
	for child in get_children():
		if child != window:
			if window.rect_position == child.rect_position:
				window.rect_position.x += 20
				window.rect_position.y += 20
	
	return window
	
func alert(message: String, info: bool = false):
	var window = yield(create_window(window_alert), "completed")
	window.content.set_alert(message, info)
	window.center()
	return window
	
func confirm(message: String):
	var window = yield(create_window(window_confirm), "completed")
	window.content.set_confirm(message)
	window.center()
	return window
