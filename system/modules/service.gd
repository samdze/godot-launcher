extends Node
class_name Service


# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass


# Override this function to react to system events.
func _event(name, arguments):
	
	pass


# Override this function to give this Service a name for the modules system
static func _get_component_name():
	return "Default Service"


# Override this function to give this Service tags for the modules system
static func _get_component_tags():
	return []


# Override this function to expose user-editable settings to the Settings App
static func _get_settings():
	return []


static func _get_component_type():
	return Component.Type.SERVICE
