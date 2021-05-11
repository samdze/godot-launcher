extends Node

var config : ConfigFile

var settings = {}
var settings_objects = {}
var settings_definitions = {}
var settings_exports = []

var listeners = {}


func _ready():
	config = ConfigFile.new()
	var result = config.load("res://settings.conf")
	
#	config.set_value("system", "language", config.get_value("system", "language", "en"))
	TranslationServer.set_locale(config.get_value("system", "language", "en"))
	
	for section in config.get_sections():
		for key in config.get_section_keys(section):
			var setting = Setting.new()
			setting.section_key = section + "/" + key
			settings_objects[setting.section_key] = setting
	
	config.save("res://settings.conf")


func add_settings_definitions(owner, settings : Array):
	self.settings[owner] = settings
	for s in settings:
		if settings_definitions.has(s.section_key):
			printerr("Setting " + s.section_key + " of " + str(owner) + " is already defined by another Component!")
		else:
			var setting = Setting.new()
			setting.section_key = s.section_key
			settings_objects[s.section_key] = setting
			settings_definitions[s.section_key] = s
			# Update the setting if non-existent
			get_value(s.section_key, s.default)


func add_settings_exports(owner, settings : Array):
	for s in settings:
		var has_settings = true
		for sec_key in s.sections_keys:
			if not settings_definitions.has(sec_key):
				printerr("Trying to export a Setting that has no definition: " + sec_key)
				has_settings = false
				break
		if has_settings:
			settings_exports.append(s)


func connect_setting(section_key : String, target : Object, func_name : String, binds : Array = [], flags : int = 0):
	if settings_objects.has(section_key):
		settings_objects[section_key].connect("changed", target, func_name, binds, flags)
	else:
		printerr("Non-existent Setting " + section_key + "!")


func disconnect_setting(section_key : String, target : Object, func_name : String):
	if settings_objects.has(section_key):
		settings_objects[section_key].disconnect("changed", target, func_name)
	else:
		printerr("Non-existent Setting " + section_key + "!")


#func remove_exported_settings(owner):
#	self.settings.erase(owner)


#func update():
#	settings_definitions.clear()
#	settings_exports.clear()
#	for a in settings.values():
#		for s in a:
#			# s is a dictionary defining an exported setting
#			# { "section": "settings", "key": "wallpaper", "label": "Wallpaper", "control": preload("res://system/components/medium_label.tscn") }
#			settings_definitions[s.section + "/" + s.key] = s


func get_value(section_key : String, default = null):
	if settings_objects.has(section_key):
		return settings_objects[section_key].get_value()
	
	if default != null:
		var setting = Setting.new()
		setting.section_key = section_key
		setting.set_value(default)
		settings_objects[section_key] = setting
	return default
	
#	var pair = section_key.split("/")
#	var value = config.get_value(pair[0], pair[1], default)
#	config.set_value(pair[0], pair[1], value)
#	return value


func set_value(section_key : String, value):
	if settings_objects.has(section_key):
		settings_objects[section_key].set_value(value)
	else:
		var setting = Setting.new()
		setting.section_key = section_key
		setting.set_value(value)
		settings_objects[section_key] = setting
	
#	var pair = section_key.split("/")
#	config.set_value(pair[0], pair[1], value)


func reset_to_default(section_key : String):
	if settings_definitions.has(section_key):
		set_value(section_key, settings_definitions[section_key].default)


func save():
	config.save("res://settings.conf")


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		save()


func get_settings() -> Dictionary:
	return settings


func get_exported_settings() -> Array:
	return settings_exports


func get_defined_settings() -> Dictionary:
	return settings_definitions
