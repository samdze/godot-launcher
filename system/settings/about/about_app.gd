extends App


func _focus():
	emit_signal("status_visibility_change_requested", true)
	emit_signal("title_change_requested", tr("DEFAULT.ABOUT"))
	emit_signal("mode_change_requested", System.Mode.OPAQUE)
	grab_focus()
	Launcher.emit_event("prompts", [[], [BottomBar.ICON_BUTTON_B, tr("DEFAULT.PROMPT_BACK")]])


func _app_input(event : InputEvent):
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		Launcher.get_ui().app.back_app()


static func _get_component_name():
	return "About"
