extends LauncherEntry

var debug = true

func get_label():
	return "Reload"


func exec():
	var result = OS.execute("bash", ["-c", "godot-tools" + ("-debug" if debug else "") +" ~/launchergodot/project.godot -q -v > /tmp/godot-importer.log 2>&1"], true)
	if result == OK:
		Engine.get_main_loop().quit()
	executed(result)
	return result
