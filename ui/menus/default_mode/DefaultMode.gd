extends PanelContainer

class_name DefaultModeMenu

var mode

var valid = false

signal setting_changed

func _ready():
	$VBoxContainer/HBoxContainer/OptionButton.refresh()

func _on_OptionButton_item_selected(id):
	if id > -1:
		valid = true
	else:
		valid = false
	
	emit_signal("setting_changed")

func get_settings():
	return {"MAP": $VBoxContainer/HBoxContainer/OptionButton.paths[$VBoxContainer/HBoxContainer/OptionButton.selected]}
