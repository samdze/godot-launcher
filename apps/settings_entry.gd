extends LauncherEntry


func get_label():
	match TranslationServer.get_locale():
		"it":
			return "Impostazioni"
	return "Settings"


func exec():
	var settings_app = Modules.get_loaded_component_from_settings("system/settings_app").resource
	System.get_launcher().app.add_app(settings_app.instance())
	executed(OK)
	return OK
