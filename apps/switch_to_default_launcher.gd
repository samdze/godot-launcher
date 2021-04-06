extends LauncherEntry



func _ready():
	_set_label("Switch Launcher")


func exec():
	OS.execute("bash", ["-c", "sed -i s/godot-launcher/launcher/g ~/.bashrc"], true)
	var result = OS.execute("bash", ["-c", "sudo reboot"], true)
	executed(result)
	return result
