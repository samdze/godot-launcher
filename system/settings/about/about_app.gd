extends App


func _focus():
	emit_signal("bars_visibility_change_requested", true, true)
	emit_signal("title_change_requested", "About")
	emit_signal("mode_change_requested", LauncherUI.Mode.OPAQUE)
	grab_focus()
	Launcher.get_ui().bottom_bar.set_prompts([], [BottomBar.ICON_BUTTON_B, BottomBar.PROMPT_BACK])


func _app_input(event : InputEvent):
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		Launcher.get_ui().app.back_app()


static func _get_component_name():
	return "About"
