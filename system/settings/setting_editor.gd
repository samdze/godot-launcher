extends Control
class_name SettingEditor

signal value_changed(section_key, value, reload_needed)
signal move_requested(to_directory)


# Override this function to configure the SettingEditor to handle the passed configuration entry
func _initialize_setting(sections_keys : Array, label : String):
	
	pass
