extends App


func _focus():
	emit_signal("window_mode_request", false)
	emit_signal("title_change_request", tr("DEFAULT.ABOUT"))
	emit_signal("display_mode_request", Launcher.Mode.OPAQUE)
	grab_focus()
	System.emit_event("prompts", [[], [Desktop.Input.B, tr("DEFAULT.PROMPT_BACK")]])


func _app_input(event : InputEvent):
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		System.get_launcher().app.back_app()


static func _get_component_name():
	return "About"
