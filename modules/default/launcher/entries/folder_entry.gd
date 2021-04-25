extends LauncherEntry

var name : String

export(String) var directory


func exec():
	emit_signal("move_requested", directory)
	executed(OK)
	return OK


func init_from_directory(dir, entry_name):
	directory = dir
	name = entry_name


func get_label() -> String:
	return name
