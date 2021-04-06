extends LauncherEntry

var debug = true

func _ready():
	_set_label("Reload")


func exec():
	var result = OS.execute("bash", ["-c", "godot-tools" + ("-debug" if debug else "") +" ~/launchergodot/project.godot -q -v > /tmp/godot-importer.log 2>&1"], true)
	if result == OK:
		get_tree().quit()
	executed(result)
	return result
