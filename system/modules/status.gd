extends Node
class_name Status

signal open_requested()
signal opened()
signal close_requested()
signal closed()
signal home_requested()


func set_title(title):
	
	pass


func open():
	
	pass


func close():
	
	pass


func enable():
	
	pass


func disable():
	
	pass


# Override this function to react to system events.
func _event(name, arguments):
	
	pass


# Override this function to give this Status a name for the modules system
static func _get_component_name():
	return "Default Status"


# Override this function to give this Status tags for the modules system
static func _get_component_tags():
	return []


# Override this function to expose user-editable settings to the Settings App
static func _get_settings():
	return []


static func _get_component_type():
	return Component.Type.STATUS
