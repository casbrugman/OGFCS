extends Control

class_name GameUI

var prefabs = {
	"menu_main": preload("res://ui/menus/main/Main.tscn"),
	"menu_join": preload("res://ui/menus/join/Join.tscn"),
	"menu_start": preload("res://ui/menus/start/Start.tscn"),
	"menu_addons": preload("res://ui/menus/addons/Addon.tscn"),
	"console": preload("res://ui/menus/console/Console.tscn"),
	"menu_explore": preload("res://ui/menus/explore/Explore.tscn"),
	"menu_text_edit": preload("res://ui/menus/text_edit/TextEdit.tscn")
}

var scale = 1 setget _set_scale
var auto_scale = true

var prev_mouse_mode 

onready var windows: WindowContainer = $WindowContainer
onready var console: GameConsole = $Console

func _ready():
	Game.ui = self
	
	auto_scale = Game.config.get_value("ui", "auto_scale")
	
	_screen_resized()

	Game.connect("joined_game", self , "_joined_game")
	Game.connect("started_game", self , "_started_game")
	get_tree().connect("screen_resized", self, "_screen_resized")
	
	yield(windows.create_window(prefabs.menu_main), "completed").rect_position = Vector2(150, 80)
	
	
func _input(event):
	if event.is_action_pressed("main_menu_show"):
		if console.mode == console.MODE_VISIBLE:
			hide_console()
			if windows.visible:
				show_main_menu()
			return
		if windows.visible:
			hide_main_menu()
		else:
			show_main_menu()
			
	if event.is_action_pressed("console_show"):
		if console.mode == console.MODE_VISIBLE:
			hide_console()
			if windows.visible:
				show_main_menu()
		else:
			show_console()
			
	if event.is_action_pressed("chat_input") || event.is_action_pressed("console_input"):
		if !get_focus_owner() is LineEdit && !get_focus_owner() is TextEdit:
			show_console()
			console.input.text = ""
			console.input.grab_focus()
			if event.is_action_pressed("chat_input"):
				accept_event()
				
func pause_game():
	get_tree().paused = true
#	prev_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func unpause_game():
	get_tree().paused = false
#	if prev_mouse_mode != null:
#		Input.set_mouse_mode(prev_mouse_mode)
#		prev_mouse_mode = null
	
func show_main_menu():
	pause_game()
	windows.show()
	console.set_mode(console.MODE_MAIN_MENU)
	windows.raise()
	
func hide_main_menu():
	windows.hide()
	if console.mode == console.MODE_MAIN_MENU:
		console.set_mode(console.MODE_ACTIVE)
	if !console.mode == console.MODE_VISIBLE:
		unpause_game()
	
func show_console():
	console.raise()
	pause_game()
	console.set_mode(console.MODE_VISIBLE)
	
func hide_console():
	if windows.visible:
		show_main_menu()
	else:
		console.set_mode(console.MODE_ACTIVE)
	if !windows.visible:
		unpause_game()
	
func _joined_game():
	hide_main_menu()
	
func _started_game():
	hide_main_menu()
	
func _set_scale(value: float):
	rect_scale = Vector2(value, value)
	anchor_bottom = 1 / value
	anchor_right = 1 / value
	scale = value
	
func _screen_resized():
	if auto_scale:
		_set_scale(Game.config.ui_scale())
	else:
		_set_scale(Game.config.get_value("ui", "scale"))
	
func open_file(file_path: String):
	if Game.config.get_value("ui", "use_external_text_editor"):
		OS.shell_open(OS.get_user_data_dir() + "/" + file_path.split("//")[1])
	else:
		var window: Window = yield(windows.create_window(prefabs.menu_text_edit), "completed")
		window.content.open_file(file_path)
