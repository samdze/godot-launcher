extends Node

var exported_settings = {}
var settings = {}


func add_exported_settings(owner, settings : Array):
	exported_settings[owner] = settings


func remove_exported_settings(owner):
	exported_settings.erase(owner)


func update():
	settings.clear()
	for a in exported_settings.values():
		for s in a:
			# s is a dictionary defining an exported setting
			# { "section": "settings", "key": "wallpaper", "label": "Wallpaper", "control": preload("res://system/components/medium_label.tscn") }
			settings[s.section + "/" + s.key] = s


func get_exported_settings() -> Dictionary:
	return settings
