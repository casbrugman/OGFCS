extends WindowContent
	
func _ready():
	window.set_resizeable(false)
	window.add_user_signal("confirm")

func set_confirm(message: String):
	$VBoxContainer/HBoxContainer/Message.text = message
	
func _on_Button_pressed():
	window.queue_free()
	
func _on_Confirm_pressed():
	window.emit_signal("confirm")
	window.queue_free()
