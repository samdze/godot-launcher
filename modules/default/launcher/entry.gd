extends Control

signal executed(error)
signal move_requested(to_directory)

var entry_script : LauncherEntry


# The ready function expects the label property to be already populated.
func _ready():
	set_process(false)


func init(script : LauncherEntry):
	name = script.get_label()
	entry_script = script


# Called when this entry receives or loses input focus.
func set_highlighted(highlighted):
	
	pass


# This function is the same as the core LauncherEntry exec()
func exec():
	entry_script.connect("executed", self, "executed", [], CONNECT_ONESHOT)
	entry_script.connect("move_requested", self, "move_requested")
	set_process(true)
	var result = entry_script.exec()
	return result


func _process(delta):
	entry_script._process(delta)


func executed(error):
	entry_script.disconnect("move_requested", self, "move_requested")
	emit_signal("executed", error)


func move_requested(to_directory):
	emit_signal("move_requested", to_directory)
