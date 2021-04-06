extends LauncherEntry



func _ready():
	_set_label("Quit")


func exec():
	get_tree().quit()
	executed(OK)
	return OK
