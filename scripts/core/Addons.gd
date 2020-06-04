extends Node

class_name GameAddons

var addon_folder: String
var downloads_folder: String

func _ready():
	addon_folder = Game.config.get_value("addons", "addon_folder")
	downloads_folder = Game.config.get_value("addons", "downloads_folder")

	check_dir(addon_folder)
	check_dir(downloads_folder)
		
	Game.addons = self
	
func check_dir(path: String):
	var dir = Directory.new()
	
	if !dir.dir_exists(path):
		Game.print_alert("Addons.gd ALERT: no %s directory, creating one.." % path)
		var err = dir.make_dir(path)
		if err != OK:
			Game.print_error("Addons.gd ERROR: could not create directory! code:'%s'" % err)
			return err
		
func save_addons_configuration(addons: Dictionary) -> int:
	var err = Game.config.set_value("addons", "saved", addons)
	if err != OK:
		Game.print_error("Addons.gd ERROR: could not save addon configuration. code:'%s'" % err)
		return err
	return err
		
func get_addons() -> Dictionary:
	return get_addons_folder(addon_folder)
	
func get_downloaded_addons() -> Dictionary:
	return get_addons_folder(downloads_folder)
	
func get_addons_folder(folder_path: String):
	var addons = {}
	
	var dir = Directory.new()
	var file = File.new()
	
	var err = dir.open(folder_path)
	if err != OK:
		Game.print_error("Addons.gd ERROR: could not open folder: '%s'. code:'%s'" % [folder_path, err])
		return addons
		
	err = dir.list_dir_begin()
	
	if err != OK:
		Game.print_error("Addons.gd ERROR: could not list folder: '%s'. code:'%s'" % [folder_path, err])
		return addons
	
	var currentDir: String = dir.get_next()
	
	while currentDir != "":
		if !dir.current_is_dir() && !currentDir.begins_with(".") && (currentDir.ends_with(".pck") || currentDir.ends_with(".zip")):
			
			var path = dir.get_current_dir() + "/%s" % currentDir
			
			err = file.open(path, file.READ)
			
			addons[path] = {
				"NAME": currentDir,
				"PATH": path,
				"HASH": file.get_sha256(path),
				"ENABLED": is_enabled(path),
				"SIZE": file.get_len()
			}
			
			file.close()
			
		currentDir = dir.get_next()
		
	dir.list_dir_end()
	return addons
	
func get_enabled_addons():
	var enabled_addons = {}
	var addons = get_addons()
	for addon in addons:
		if addons[addon]["ENABLED"]:
			enabled_addons[addon] = addons[addon]
	
	return enabled_addons

func is_enabled(path: String) -> bool:
	var file = File.new()
	
	var addons = Game.config.get_value("addons", "saved")
	
	if addons.has(path):
		var config = addons[path]
		
		if config["ENABLED"]:
			if file.get_sha256(path) == config["HASH"]:
				return true
			else:
				Game.print_alert("Addons.gd ALERT: file:'%s' has changed and is automatically disabled for security reasons." % path)
				config["ENABLED"] = false
				addons[path] = config
				Game.config.set_value("addons", "saved", addons)
				return false
	return false

func load_addons(addons: Dictionary):
	for addon_key in addons:
		var addon = addons[addon_key]
		
		var success = ProjectSettings.load_resource_pack(addon["PATH"])

		if success:
			if addon.has("NAME"):
				Game.print_text("Addons.gd: loaded addon:'%s'" % addon["NAME"])
		else:
			Game.print_error("Addons.gd ERROR: failed loading addon with path:'%s'" % addon["PATH"])

func check_addons(addons: Dictionary) -> Dictionary:
	var own_addons = get_addons()
	var downloaded_addons = get_downloaded_addons()
	
	var missing_and_disabled_addons = {
		"NEED_ENABLING": {},
		"NEED_DOWNLOADING": {}
	}
	
	for addon_key in addons:
		var addon = addons[addon_key]
		if addon["ENABLED"]:
			
			var download_path = downloads_folder + "/" + addon["NAME"]
			
			#Check if user already has addon & enbled
			if own_addons.has(addon_key) && addon["HASH"] == own_addons[addon_key]["HASH"]:
				if !own_addons[addon_key]["ENABLED"]:
					missing_and_disabled_addons["NEED_ENABLING"][addon_key] = addon

			#Check if user already has downloaded addon
			elif downloaded_addons.has(download_path) && addon["HASH"] == downloaded_addons[download_path]["HASH"]:
				missing_and_disabled_addons["NEED_ENABLING"][downloaded_addons[download_path]["PATH"]] = downloaded_addons[download_path]

			else:
				#Download addon
				missing_and_disabled_addons["NEED_DOWNLOADING"][addon_key] = addon
				
	return missing_and_disabled_addons
			
func download_addons(ip: String, port: int, addons: Dictionary) -> int:
	Game.print_text("Addons.gd: Downloading %s addons.." % addons.size())
	
	var count = 1
	for addon_key in addons:
		var addon = addons[addon_key]
		var save_path = downloads_folder + "/" + addon["NAME"]
		
		Game.print_text("Addons.gd: Downloading addon: %s (%s/%s).." % [addon["NAME"], count, addons.size()])
		
		var err = yield(Game.downloader.save_file(ip, port, addon["PATH"], save_path), "completed")
		if err != OK:
			Game.print_alert("Addons.gd: ALERT: could not download addon")
			return null
			
		addon["PATH"] = save_path
			
		count += 1
		
	return addons
			
func get_maps() -> Array:
	var found = find_pattern_in_folder(["Map.tscn", "Map.scn"], "res://")
	return found + find_pattern_in_folder(["Map.tscn", "Map.scn"], "user://")
	
func get_modes() -> Array:
	var paths = find_pattern_in_folder([["://modes", "Mode.gd"], ["://maps/","/modes/", "Mode.gd"], ["://scripts", "Mode.gd"]])
	paths += find_pattern_in_folder([["://modes", "Mode.gd"], ["://maps/","/modes/", "Mode.gd"], ["://scripts", "Mode.gd"]], "user://")
	
	var i = 0
	for path in paths:
		if path.ends_with(".remap"):
			paths.remove(i)
		i += 1
	return paths
	
func find_pattern_in_folder(patterns: Array, path: String = "res://") -> Array:
	var dir = Directory.new()
	var found = []
	
	var err = dir.open(path)
	if err != OK:
		Game.print_error("Addons.gd ERROR: could not open folder: '%s'. code:'%s'" % [path, err])
		return err
		
	err = dir.list_dir_begin(true, true)
	if err != OK:
		Game.print_error("Addons.gd ERROR: could not list folder: '%s'. code:'%s'" % [addon_folder, err])
		return err
		
	var current_dir: String = dir.get_next()

	while current_dir != "":
		var current_path = path + current_dir
		
		if dir.current_is_dir() && !current_dir.begins_with("."):
			var found_r = find_pattern_in_folder(patterns, current_path + "/")
			for found_r_path in found_r:
				found.append(found_r_path)
		else:
			for pattern in patterns:
				if !pattern is Array:
					pattern = [pattern]
				
				var valid = true
				for condition in pattern:
					if !condition in current_path:
						valid = false
						
				if valid:
					found.append(current_path)
			
		current_dir = dir.get_next()
		pass
		
	dir.list_dir_end()
	
	return found
