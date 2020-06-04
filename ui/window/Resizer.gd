extends Control

enum {TYPE_N, TYPE_NW, TYPE_W, TYPE_SW, TYPE_S, TYPE_SE, TYPE_E, TYPE_NE}

onready var window = get_parent().get_parent()
	
var dragPos = null
var dragType = null
var startRect = null
var startPos = null
var lastPos = Vector2()

func input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			startRect = window.rect_size
			startPos = window.rect_position
			dragPos = get_global_mouse_position() / Game.ui.scale
		else:
			startRect = null
			startPos = null
			dragPos = null
	if event is InputEventMouseMotion:
		if dragPos != null:
			
			var newSize = window.rect_size
			var newPos = window.rect_position
			var mousePos = get_global_mouse_position() / Game.ui.scale
			
			#resize
			if dragType == TYPE_N || dragType == TYPE_NW || dragType == TYPE_NE:
				newSize.y = startRect.y - mousePos.y + dragPos.y
				newPos.y = mousePos.y - dragPos.y + startPos.y
				
			if dragType == TYPE_W || dragType == TYPE_NW || dragType == TYPE_SW:
				newSize.x = startRect.x - mousePos.x + dragPos.x
				newPos.x = mousePos.x - dragPos.x  + startPos.x
				
			if dragType == TYPE_S || dragType == TYPE_SE || dragType == TYPE_SW:
				newSize.y = mousePos.y - dragPos.y + startRect.y
				
			if dragType == TYPE_E || dragType == TYPE_SE || dragType == TYPE_NE:
				newSize.x = mousePos.x - dragPos.x + startRect.x
				
				
			#min size
			if newSize.x < window.content.rect_min_size.x + 5:
				newSize.x = window.content.rect_min_size.x + 5
#				newPos.x = lastPos.x

			if newSize.y < window.content.rect_min_size.y + 21:
				newSize.y = window.content.rect_min_size.y + 21
#				newPos.y = lastPos.y
				
			lastPos = newPos
			
			window._set_position(newPos.round())
			window._set_size(newSize.round())
					
			

func _on_w_gui_input(event):
	dragType = TYPE_W
	input(event)

func _on_s_gui_input(event):
	dragType = TYPE_S
	input(event)

func _on_e_gui_input(event):
	dragType = TYPE_E
	input(event)

func _on_n_gui_input(event):
	dragType = TYPE_N
	input(event)

func _on_nw_gui_input(event):
	dragType = TYPE_NW
	input(event)

func _on_sw_gui_input(event):
	dragType = TYPE_SW
	input(event)

func _on_se_gui_input(event):
	dragType = TYPE_SE
	input(event)

func _on_ne_gui_input(event):
	dragType = TYPE_NE
	input(event)
