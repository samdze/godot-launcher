extends ToolButton
class_name Widget

# Emit this signal when you want to release focus from the widget controls.
signal unfocus_controls_requested()


# Override this function and return a node tree representing the widget controls
# that will appear when this widget is highlighted.
# Return null if the widget has no controls.
func _get_widget_controls():
	
	return null


# Override this function to react when this widget is selected.
# You can give focus to a control in its controls and/or change input prompts
# on the bottom bar.
func _widget_selected():
	
	pass


# Override this function to give this Widget a name for the modules system
static func _get_component_name():
	return "Default Widget"


# Override this function to give this Widget tags for the modules system
static func _get_component_tags():
	return []


# Override this function to expose user-editable settings to the Settings app
static func _get_exported_settings():
	return []


static func _get_component_type():
	return Component.Type.WIDGET
