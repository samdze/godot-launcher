extends View



func _ready():
	pass


func _focus():
	emit_signal("bars_visibility_change_requested", false, false)
	var window = Launcher.get_ui().window_manager.get_active_window()
	print("[GODOT] Setting view title of window " + str(window) +  "...")
	emit_signal("title_change_requested", Launcher.get_ui().window_manager.get_window_title(window))
	print("[GODOT] View title set")
	emit_signal("mode_change_requested", LauncherUI.Mode.TRANSPARENT)


func _window_name_changed(name):
	emit_signal("title_change_requested", name)


func _active_window_changed(window_id):
	if window_id != Launcher.get_ui().window_manager.get_window_id():
		_focus()
	else:
		Launcher.get_ui().view.back_view()
