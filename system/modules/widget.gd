extends ToolButton
class_name Widget

# Emit this signal when you want to release focus from the widget controls.
signal unfocus_controls_request()


# Override this function and return a node tree representing the widget controls
# that will appear when this widget is highlighted.
# Return null if the widget has no controls.
func _get_widget_controls():
	
	return null


# Override this function to react when this widget is selected.
# You can give focus to a control in its controls and/or change input prompts on the Prompts bar.
func _widget_selected():
	
	pass


# Override this function to react to system events.
func _event(name, arguments):
	
	pass


# Override this function to give this Widget a name for the modules system
static func _get_component_name():
	return "Default Widget"


# Override this function to give this Widget tags for the modules system
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


# This function is executed after every available Component has been loaded.
# Override it to check e.g. whether Components needed for this Component to work are available in the launcher.
static func _has_dependencies():
	return true


static func _get_component_type():
	return Component.Type.WIDGET
