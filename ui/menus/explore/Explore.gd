extends Control

var dir = Directory.new()

var save_path

func _ready():
	save_path = Game.config.get_value("explore", "save_folder")
	
	if !dir.dir_exists(save_path):
		var err = dir.make_dir(save_path)
		if err != OK:
			Game.print_error("Explore.gd ERROR: Could not create directory with path: '%s'. code: '%s'" % [save_path, err])
			return err
			
	$VBoxContainer/PanelContainer2/Tree.refresh(!$VBoxContainer/PanelContainer/PanelContainer/VBoxContainer/HBoxContainer/CheckBox.pressed)

func _on_CheckBox_pressed():
	$VBoxContainer/PanelContainer2/Tree.refresh(!$VBoxContainer/PanelContainer/PanelContainer/VBoxContainer/HBoxContainer/CheckBox.pressed)

func _on_Button_pressed():
	OS.shell_open(OS.get_user_data_dir() + "/" + save_path.split("//")[1])
