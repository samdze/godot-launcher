extends Theme
class_name UITheme

export(String) var name = "Default Theme"


# Override this function to give this Theme a name for the modules system
func _get_component_name():
	return name


# Override this function to give this Theme tags for the modules system
static func _get_component_tags():
	return []


# Override this function to expose user-editable settings to the Settings app
static func _get_exported_settings():
	return []


static func _get_component_type():
	return Component.Type.THEME
