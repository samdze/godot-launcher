extends Theme
class_name UITheme

export(String) var name = "Default Theme"


# Override this function to give this Theme a name for the modules system
func _get_component_name():
	return name


# Override this function to give this Theme tags for the modules system
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
	return Component.Type.THEME
