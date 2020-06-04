extends Control

var file = File.new()

var file_path

func open_file(_file_path: String):
	file_path = _file_path
	
	file.open(file_path, file.READ)
	$VBoxContainer/PanelContainer2/TextEdit.text = file.get_as_text()
	file.close()
	$VBoxContainer/PanelContainer/PanelContainer/VBoxContainer/HBoxContainer/Label.text = file_path

func _on_Button_pressed():
	file.open(file_path, file.WRITE_READ)
	file.store_string($VBoxContainer/PanelContainer2/TextEdit.text)
	file.close()
	
func _exit_tree():
	file.close()
