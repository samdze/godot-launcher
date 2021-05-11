extends LauncherEntry


func get_label():
	match TranslationServer.get_locale():
		"it":
			return "Tastiera"
	return "Keyboard"


func exec():
	var keyboard_app = Modules.get_loaded_component_from_settings("system/keyboard_app").resource
	Launcher.get_ui().app.add_app(keyboard_app.instance())
	executed(OK)
	return OK
