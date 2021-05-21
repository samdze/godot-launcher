extends SettingEditor

var directory


# Override this function to configure the SettingEditor to handle the passed configuration entry
func _initialize_setting(section_key : Array, label : String):
	self.text = label


func init_from_directory(to_directory : String):
	directory = to_directory


# Button exposes this function on its own
func _pressed():
	emit_signal("move_request", directory)
