extends Node
class_name Desktop

signal open_request()
signal opened()
signal close_request()
signal closed()
signal home_request()

enum Input { MOVE = 0, A, B, X, Y, RIGHT, UP, LEFT, DOWN,
	START, MENU, HOME, MOVE_V, MOVE_H }


func set_title(title):
	
	pass


func get_app_handler() -> AppHandler:
	
	return null


func open():
	
	pass


func close():
	
	pass


func take_space():
	
	pass


func free_space():
	
	pass


func enable():
	
	pass


func disable():
	
	pass


# Override this function to react to system events.
func _event(name, arguments):
	
	pass


# Override this function to give this Desktop a name for the modules system
static func _get_component_name():
	return "Default Desktop"


# Override this function to give this Desktop tags for the modules system
static func _get_component_tags():
	return []


# Override this function to create settings definitions that this Component will generate and use.
static func _get_settings_definitions():
	return []


# Override this function to expose user-editable settings to the Settings App
static func _get_settings_exports():
	return []


# Override this function to declare launcher-wide components dependencies
static func _get_dependencies():
	return []


# Override this function to check whether this Component can be used on the device
static func _is_available():
	return true


static func _get_component_type():
	return Component.Type.DESKTOP
