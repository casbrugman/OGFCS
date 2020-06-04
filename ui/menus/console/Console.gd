extends WindowContent

class_name GameConsole

enum {MODE_VISIBLE, MODE_ACTIVE, MODE_MAIN_MENU}

var history = []
var _current_history = 0

var mode setget set_mode

func get_node(path):
	return .get_node(path)

onready var input: LineEdit = $InputContainer/LineEdit
onready var output: RichTextLabel = $Output
onready var pop_output: RichTextLabel = $VBoxContainer/Control/PopOutput
onready var logo: RichTextLabel = $VBoxContainer/Logo

var effect_dissolve = preload("res://ui/text_effects/Dissolve.gd").new()

func _ready():
	Game.connect("print_logo", self, "print_logo")
	Game.connect("print_text", self, "print_text")
	Game.connect("print_error", self, "print_error")
	Game.connect("print_alert", self, "print_alert")
	Game.connect("print_color", self, "print_color")
	Game.connect("remove_last_print", self, "remove_last_print")
	
	pop_output.install_effect(effect_dissolve)
	
	set_mode(MODE_ACTIVE)
	
	for message in Game.output_history:
		match message["TYPE"]:
			"LOGO":
				print_logo(message["TEXT"])
			"TEXT":
				print_text(message["TEXT"])
			"ALERT":
				print_alert(message["TEXT"])
			"ERROR":
				print_error(message["TEXT"])
			"COLOR":
				print_color(message["TEXT"], message["COLOR"])
				
	_current_history = history.size()
				
func _input(_event):
	if input.has_focus():
		if Input.is_key_pressed(KEY_UP):
			if !_current_history - 1 < 0:
				_current_history -= 1
				input.text = history[_current_history]
				input.caret_position = input.text.length()
			.accept_event()
		if Input.is_key_pressed(KEY_DOWN):
			if !_current_history + 1 > history.size() - 1:
				_current_history += 1
				input.text = history[_current_history]
				input.caret_position = input.text.length()
			else:
				_current_history = history.size()
				input.text = ""
				input.caret_position = input.text.length()
			.accept_event()

func _on_LineEdit_text_entered(new_text: String):
	if new_text.length() > 0:
		if new_text.begins_with("/"):
			print_text(new_text)
			Game.eval(new_text.substr(1))
		else:
			.rpc("chat", new_text, Game.client.id)
			
		history.append(new_text)
		_current_history = history.size()
	
	input.text = ""
	
sync func chat(text, id):
	print_color("[color=aqua]%s[/color]: %s" % [Game.server.connected_players[id]["USERNAME"], text], Color.white)
	
func print_logo(text):
	print_color(text, Color.white, output)
	
	logo.push_color(Color.white)
	logo.append_bbcode(">" + text)
	logo.pop()
	
	logo._resized()

func print_text(text):
	print_color(text, Color.white)
	
func print_error(text):
	print_color(text, Color.red)
	
func print_alert(text):
	print_color(text, Color.yellow)
	
func print_color(text, color: Color, label: RichTextLabel = null):
	if typeof(text) != TYPE_STRING:
		text = String(text)
	
	text = "[color=white]>[/color][color=#%s]" % color.to_html() + text + "[/color]"
	
	if output.text != "":
		output.newline()
	
	if label == null || label == output:
		output.append_bbcode(text)
	
	if mode == MODE_ACTIVE || mode == MODE_MAIN_MENU:
		if label == null || label == pop_output:
			pop_output.newline()
			
			pop_output.append_bbcode("[dissolve start=%f speed=1.0]" % float(Game.config.get_value("console", "text_visible_time") - 1) + text + "[/dissolve]")
					
		if .get_tree() != null:
			yield(.get_tree().create_timer(Game.config.get_value("console", "text_visible_time")), "timeout")
			
			pop_output.remove_line(1)
			
func remove_last_print():
	pass
#	output.remove_line(output.get_line_count() - 1)
#
#	output.visible_characters = -1
#
#	if pop_output.get_line_count() > 1:
#		pop_output.remove_line(pop_output.get_line_count() - 1)
#
#		remove_queue -= 1

func set_mode(value: int):
	if value == MODE_VISIBLE:
		$InputContainer.show()
		$Background.show()
		$Close.show()

		output.show()
		pop_output.hide()
		logo.hide()
			
	if value == MODE_ACTIVE:
		output.release_focus()
		$InputContainer.hide()
		$Background.hide()
		$Close.hide()
		
		output.hide()
		pop_output.show()
		logo.hide()
		
		pop_output.mouse_filter = pop_output.MOUSE_FILTER_IGNORE
		logo.mouse_filter = logo.MOUSE_FILTER_IGNORE
		
	if value == MODE_MAIN_MENU:
		output.release_focus()
		$InputContainer.hide()
		$Background.hide()
		$Close.hide()
		
		output.hide()
		pop_output.show()
		logo.show()
		
		pop_output.mouse_filter = pop_output.MOUSE_FILTER_STOP
		logo.mouse_filter = logo.MOUSE_FILTER_STOP
			
	mode = value

func _on_Close_pressed():
	Game.ui.hide_console()
