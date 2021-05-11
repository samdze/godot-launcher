extends Reference
class_name Setting

signal changed()

var section_key : String setget _set_section_key
var section_key_pair : Array


func set_value(value):
	# Does it correctly check after values are serialized?
	if not Settings.config.has_section_key(section_key_pair[0], section_key_pair[1]) or Settings.config.get_value(section_key_pair[0], section_key_pair[1]) != value:
		Settings.config.set_value(section_key_pair[0], section_key_pair[1], value)
		emit_signal("changed")


func get_value():
	return Settings.config.get_value(section_key_pair[0], section_key_pair[1])


func _set_section_key(value):
	section_key = value
	section_key_pair = section_key.split("/")


static func create(section_key : String, default) -> Init:
	var setting_init = Init.new()
	setting_init.section_key = section_key
	setting_init.default = default
	return setting_init


static func export(sections_keys : Array, label : String, control : PackedScene) -> Export:
	var setting_export = Export.new()
	setting_export.sections_keys = sections_keys
	setting_export.label = label
	setting_export.control = control
	return setting_export


class Init extends Reference:
	var section_key : String
	var default


class Export extends Reference:
	var sections_keys : Array
	var label : String
	var control : PackedScene
