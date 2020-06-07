extends Node

class_name GameDownloader

var hosted_files = {}
var host_enabled_addons: bool setget _set_host_enabled_addons

func _ready():
	Game.downloader = self
	_set_host_enabled_addons(true)
	Game.peer.connect("packet", self, "_packet_handler")
	
func _set_host_enabled_addons(value: bool):
	if value:
		var addons = Game.addons.get_enabled_addons()
		for addon_key in addons:
			hosted_files[addons[addon_key]["PATH"]] = {}
	else:
		var addons = Game.addons.get_addons()
		for addon_key in addons:
			if hosted_files.has(addons[addon_key]["PATH"]):
				hosted_files.erase(addons[addon_key]["PATH"])
	
	host_enabled_addons = value
