extends LauncherEntry


func get_label():
	match TranslationServer.get_locale():
		"it":
			return "Esci"
	return "Quit"


func exec():
	Engine.get_main_loop().quit()
	executed(OK)
	return OK
