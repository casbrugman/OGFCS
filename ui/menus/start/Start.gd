extends WindowContent

var current_mode
var current_mode_menu

var default_min_size = Vector2()

func _ready():
	$VBoxContainer/VBoxContainer/OptionButton.refresh()
	
	$VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/GridContainer/LineEdit.text = str(Game.config.get_value("server", "default_ping_listen_port"))
	$VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/GridContainer/LineEdit2.text = str(Game.config.get_value("server", "default_rpc_host_port"))
	$VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/GridContainer/LineEdit4.text = str(Game.config.get_value("server", "default_max_players"))
	$VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/GridContainer2/CheckBox2.pressed = Game.config.get_value("server", "default_use_websockets")
	$VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/TextEdit.text = Game.config.get_value("server", "default_message")
	
func _on_Button_pressed():
	var selectedMode = $VBoxContainer/VBoxContainer/OptionButton.paths[$VBoxContainer/VBoxContainer/OptionButton.selected]
	var modeSettings = current_mode_menu.get_settings()
	var ping_port = int($VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/GridContainer/LineEdit.text)
	var rpc_port = int($VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/GridContainer/LineEdit2.text)
	var ip = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/GridContainer/LineEdit3.text
	var max_players = int($VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/GridContainer/LineEdit4.text)
	var host_addons = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/GridContainer/CheckBox.pressed
	var websocket = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/GridContainer2/CheckBox2.pressed
	var message = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/TextEdit.text
	
	if !$VBoxContainer/GridContainer/CheckBox.pressed:
		ip = Game.server.LOCALHOST  
	
	Game.peer.port = ping_port
	Game.peer.ip = ip
	Game.downloader.host_adddons = host_addons
	Game.server.max_players = max_players
	Game.server.port = rpc_port
	Game.server.ip = ip
	Game.server.message = message
	
	if websocket:
		Game.server.mode = Game.server.MODE_WEBSOCKET
	else:
		Game.server.mode = Game.server.MODE_CLASSIC
	
	var err = yield(Game.start_game(selectedMode, modeSettings),"completed")
	if err == OK:
		window.queue_free()

func _on_OptionButton_item_selected(id):
	for child in $VBoxContainer/ModeMenuContainer.get_children():
		$VBoxContainer/ModeMenuContainer.remove_child(child)
		child.queue_free()
	
	$VBoxContainer/HBoxContainer/Button.disabled = true
	
	var path = $VBoxContainer/VBoxContainer/OptionButton.paths[id]
	
	current_mode = load(path).new()
	
	if current_mode is GameMode:
		current_mode_menu = current_mode.menu
		current_mode_menu.connect("setting_changed", self, "_on_Mode_setting_changed")
		$VBoxContainer/ModeMenuContainer.add_child(current_mode_menu)
		
func _on_Mode_setting_changed():
	if current_mode is GameMode:
		if current_mode_menu.valid:
			$VBoxContainer/HBoxContainer/Button.disabled = false
		else:
			$VBoxContainer/HBoxContainer/Button.disabled = true

func _on_CheckBox_toggled(button_pressed):
	if button_pressed:
		$VBoxContainer/PanelContainer/MarginContainer.show()
		
		yield(get_tree(), "idle_frame")
		
		rect_min_size = rect_size
	else:
		$VBoxContainer/PanelContainer/MarginContainer.hide()
		$VBoxContainer.rect_size = $VBoxContainer.rect_min_size
		rect_min_size = Vector2()
		rect_size = rect_min_size
		
		yield(get_tree(), "idle_frame")
		
		rect_min_size = rect_size
	
func _disable_host_resourcepacks_confirmed():
	$VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/GridContainer/CheckBox.pressed = false

func _on_CheckBox_button_up():
	if !$VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/GridContainer/CheckBox.pressed:
		$VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/GridContainer/CheckBox.pressed = true
		var confirm = yield(Game.ui.windows.confirm("Are you sure you want to disable hosting your enabled resourcepacks? If a joining player does not have the required resourcepacks enabled then the players game will crash."), "completed")
		confirm.connect("confirm", self, "_disable_host_resourcepacks_confirmed")
