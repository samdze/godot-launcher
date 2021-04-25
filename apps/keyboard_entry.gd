extends LauncherEntry


func get_label():
	return "Keyboard"


func exec():
	var keyboard_app = Modules.get_loaded_component_from_config("system", "keyboard_app", "default/keyboard").resource
	Launcher.get_ui().app.add_app(keyboard_app.instance())
	executed(OK)
	return OK
