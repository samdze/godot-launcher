extends LauncherEntry


func get_label():
	return "Settings"


func exec():
	var settings_app = Modules.get_loaded_component_from_config("system", "settings_app", "default/settings").resource
	Launcher.get_ui().app.add_app(settings_app.instance())
	executed(OK)
	return OK
