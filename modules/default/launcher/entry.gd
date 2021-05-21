extends Control

signal executed(error)
signal move_request(to_directory)

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
	entry_script.connect("move_request", self, "move_request")
	set_process(true)
	var result = entry_script.exec()
	return result


func _process(delta):
	entry_script._process(delta)


func executed(error):
	set_process(false)
	entry_script.disconnect("move_request", self, "move_request")
	emit_signal("executed", error)


func move_request(to_directory):
	emit_signal("move_request", to_directory)
