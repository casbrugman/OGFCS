extends WindowContent

func _ready():
	window.func_close = funcref(self, "close")
	
	if OS.get_name() == "HTML5":
		$VBoxContainer/HBoxContainer2/Exit.disabled = true
		$VBoxContainer/HBoxContainer2/Restart.disabled = true
	
func _on_Join_pressed():
	Game.ui.windows.create_window(Game.ui.prefabs.menu_join)

func _on_Start_pressed():
	Game.ui.windows.create_window(Game.ui.prefabs.menu_start)

func _on_Mods_pressed():
	Game.ui.windows.create_window(Game.ui.prefabs.menu_addons)
	
func _on_Settings_pressed():
	Game.ui.open_file(Game.config.PATH)

func _on_Exit_pressed():
	Game.exit()
	
func close():
	Game.ui.hide_main_menu()

func _on_Reset_pressed():
	var confirm = yield(Game.ui.windows.confirm("Are you sure you want to reset ALL setttings?"), "completed")
	confirm.connect("confirm", self, "reset_confirmed")
	
func reset_confirmed():
	var err = Game.config.reset()
	if err == OK:
		Game.ui.windows.alert("Settings have been reset, Some settings may require you to restart the game to take effect.", true)

func _on_Restart_pressed():
	Game.restart()

func _on_Leave_pressed():
	var confirm = yield(Game.ui.windows.confirm("Are you sure you want to leave this game and return to the main menu?"), "completed")
	confirm.connect("confirm", Game, "start")

func _on_Console_pressed():
	Game.ui.show_console()
