extends LauncherEntry


func get_label():
	return "Quit"


func exec():
	Engine.get_main_loop().quit()
	executed(OK)
	return OK
