extends WindowContent

var img_info = preload("res://ui/window/info32.png")

func _ready():
	window.set_resizeable(false)

func set_alert(message: String, info: bool = false):
	$VBoxContainer2/HBoxContainer/Message.text = message
	
	if info:
		window.title.text = "Info"
		$VBoxContainer2/HBoxContainer/TextureRect.texture = img_info
	
func _on_Button_pressed():
	window.queue_free()
