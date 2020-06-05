extends Node

class_name GameConfig

const PATH = "user://config.cfg"
const CHECK_TIME = 1

var file: File = File.new()
var dir: Directory = Directory.new()

var config: ConfigFile
var values
var load_time: int

signal config_reloaded

var timer = 0

func _process(delta):
	if timer >= CHECK_TIME:
		
		yield(get_tree(), "idle_frame")
		
		if load_time != file.get_modified_time(PATH):
			get_config()
		timer = 0
		
	timer += delta

func _ready():
	Game.config = self
	get_config()

func get_config():
	config = ConfigFile.new()
	var err = config.load(PATH)
	if err != OK:
		if file.file_exists(PATH):
			Game.print_error("Config.gd ERROR: Could not load config in '%s'.. code:'%s'" % [PATH, err])
			Game.print_alert("Config.gd ALERT: Please delete file: '%s' to reset config.." % (OS.get_user_data_dir() + "/" + PATH.split("//")[1]))
			config = null
			return err
		else:
			err = config.save(PATH)
			if err != OK:
				Game.print_error("Config.gd ERROR: could not create config in '%s'.. code:'%s'" % [PATH, err])
				config = null
				return err
			config.load(PATH)
			reset_values()
			Game.print_text("Config.gd: Created new config in '%s'.." % PATH)
			
	load_time = file.get_modified_time(PATH)
	values = {}
	
	set_input_map(get_value("input", "map"))
	
	emit_signal("config_reloaded")
	return err
	
func get_value(section: String, key: String):
	if values.has(section):
		if values[section].has(key):
			return values[section][key]
			
	var value = _get_value(section, key)
	
	if values.has(section):
		values[section][key] = value
	else:
		values[section] = {
			key: value
		}
	
	return values[section][key]
			
func _get_value(section: String, key: String):
	if config == null:
		if default_values.has(section):
			var dict_section = default_values[section]
			if dict_section.has(key):
				return default_values[section][key]
			else:
				Game.print_error("Config.gd ERROR: No default value found in section:'%s' with key:'%s'!" % [section, key])
		else:
			Game.print_error("Config.gd ERROR: No default value found in section:'%s' with key:'%s'!" % [section, key])
		return null
		
	var value = config.get_value(section, key)
	if value == null:
		if default_values.has(section):
			var dict_section = default_values[section]
			if dict_section.has(key):
				Game.call_deferred("print_alert", "Config.gd ALERT: No value found in section:'%s' with key:'%s', saving default value." % [section, key])
				set_value(section, key, default_values[section][key])
				return default_values[section][key]
			else:
				Game.print_error("Config.gd ALERT: No value found in section:'%s' with key:'%s', and no default found!" % [section, key])
		else:
			Game.print_error("Config.gd ALERT: No value found in section:'%s' with key:'%s', and no default found!" % [section, key])
	return value

func set_value(section, key, value) -> int:
	config.set_value(section, key, value)
	var err = config.save(PATH)
	if err != OK:
		Game.print_error("Config.gd ERROR: Could not save config, value not saved. code:'%s'" % err)
	return err
	
func reset() -> int:
	var err = delete_config()
	if err != OK:
		Game.print_error("Config.gd ERROR: Config not deleted, cant create new one. code:'%s'" % err)
		return err
		
	reset_values()
	
	return err
		
func reset_values():
	for section in default_values:
		var section_dict = default_values[section]
		for key in section_dict:
			var value = section_dict[key]
			set_value(section, key, value)
			
	values = {}
	
func delete_config() -> int:
	if file.file_exists(PATH):
		var err = dir.remove(PATH)
		if err != OK:
			Game.print_error("Config.gd ERROR: Could not delete config. code:'%s'" % err)
			return err
		return err
	else:
		Game.print_alert("Config.gd ALERT: Could not delete config, config not found.")
		return OK
		
func ui_scale():
	return pow(2,round(OS.window_size.y * OS.window_size.x / 3000000))
	
func get_input_map(reset: bool = false):
	if reset:
		InputMap.load_from_globals()
	
	var input_map = {}
	
	for action in InputMap.get_actions():
		if !input_map.has(action):
				input_map[action] = []
				
		for event in InputMap.get_action_list(action):
			var dict = {
				"TYPE": null
			}
			
			if event is InputEventKey:
				dict["TYPE"] = "KEY"
			elif event is InputEventJoypadButton:
				dict["TYPE"] = "JOY_BUTTON"
			elif event is InputEventJoypadMotion:
				dict["TYPE"] = "JOY_MOTION"
			elif event is InputEventMouseButton:
				dict["TYPE"] = "MOUSE_BUTTON"
			else:
				Game.print_alert("Config.gd ALERT: Found unsupported InputEvent in InputMap..")
				
			for parameter in input_dict[dict["TYPE"]]:
				dict[parameter[1]] = event[parameter[0]]

			input_map[action].append(dict)
		
	return input_map
	
func set_input_map(dict: Dictionary):
	for action in dict:
		InputMap.action_erase_events(action)
		var event_array = dict[action]
		for event in event_array:
			var new_event
			
			if event["TYPE"] == "KEY":
					new_event = InputEventKey.new()
			elif event["TYPE"] == "JOY_BUTTON":
					new_event = InputEventJoypadButton.new()
			elif event["TYPE"] == "JOY_MOTION":
					new_event = InputEventJoypadMotion.new()
			elif event["TYPE"] == "MOUSE_BUTTON":
					new_event = InputEventMouseButton.new()
			else:
				Game.print_alert("Config.gd ALERT: Found unsupported InputEvent in config..")
			
			if input_dict.has(event["TYPE"]):
				for parameter in input_dict[event["TYPE"]]:
					new_event[parameter[0]] = event[parameter[1]]
	
				InputMap.action_add_event(action, new_event)

var input_dict = {
	"KEY": [
		["scancode", "KEY"],
		["alt", "ALT"],
		["shift", "SHIFT"],
		["control", "CONTROL"],
		["meta", "META"],
		["command", "COMMAND"],
	],
	"JOY_BUTTON": [
		["button_index", "INDEX"],
		["pressure", "PRESSURE"],
		["device", "DEVICE"],
	],
	"JOY_MOTION": [
		["axis", "AXIS"],
		["device", "DEVICE"],
	],
	"MOUSE_BUTTON": [
		["button_index", "INDEX"],
		["device", "DEVICE"],
	]
}
	
var default_values = {
	"addons": {
		"addon_folder": "user://addons",
		"downloads_folder": "user://downloads",
		"saved": {}
	},
	"console": {
		"logo": """     ::::::::    ::::::::   ::::::::::  ::::::::    :::::::: 
	:+:    :+:  :+:    :+:  :+:        :+:    :+:  :+:    :+: 
   +:+    +:+  +:+         +:+        +:+         +:+         
  +#+    +:+  :#:         :#::+::#   +#+         +#++:++#++   
 +#+    +#+  +#+  ++#+#  +#+        +#+                +#+    
#+#    #+#  #+#    #+#  #+#        #+#    #+#  #+#    #+#     
########    ########   ###         ########    ########""",
		"text_visible_time": 7,
	},
	"downloader": {
		"override_files": true
	},
	"explore": {
		"save_folder": "user://saved_files"
	},
	"identity": {
		"username": "niffo" + str(RandomNumberGenerator.new().randi()),
	},
	"input": {
		"map": get_input_map(true),
		"mouse_sensitivity": 200.0,
	},	
	"menu_join": {
		"saved": []
	},
	"server": {
		"default_ping_listen_port": 44534,
		"default_ping_listen_ip": "*",
		"default_rpc_host_port": 44535,
		"default_host_ip": "*",
		"default_max_players": 32,
		"default_host_addons": true,
		"default_use_websockets": false,
		"default_message": "A OGFCS server"
	},
	"start": {
		"reset": false,
		"use_autoexec": false,
		"autoexec": "",
		"mode": "res://modes/menu/Mode.gd",
		"options": {
			"MAP": "res://maps/Start/Map.tscn",
		},
		"host_ip": "0:0:0:0:0:0:0:1",
		"host_max_players": 1,
		"host_addons": false,
		"host_message": "Local main menu server"
	},
	"ui": {
		"scale": ui_scale(),
		"auto_scale": true,
		"use_external_text_editor": OS.get_name() != "HTML5"
	},
	"ui_window": {
		"header_color_0": Color(0, 0, 1),
		"header_color_1": Color(0, 1, 1),
	},
	"window": {
		"fullscreen": true
	},
}
	

