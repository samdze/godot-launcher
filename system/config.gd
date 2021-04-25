extends Node

var config : ConfigFile


func _ready():
	config = ConfigFile.new()
	var result = config.load("res://settings.conf")
	
#	config.set_value("system", "launcher_view", config.get_value("system", "launcher_view", "default/launcher"))
#	config.set_value("system", "settings_view", config.get_value("system", "settings_view", "default/settings"))
#	config.set_value("system", "running_app_view", config.get_value("system", "running_app_view", "default/running_app"))
	
	config.save("res://settings.conf")


func get_value_or_default(section : String, key : String, default):
	var value = config.get_value(section, key, default)
	config.set_value(section, key, value)
	return value


func set_value(section : String, key : String, value):
	config.set_value(section, key, value)


func save():
	config.save("res://settings.conf")


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		save()
