extends "../entry.gd"


func _set_label(value):
	self.text = value


func _set_icon(icon):
	
	pass


func init(script : LauncherEntry):
	.init(script)
	_set_label(entry_script.get_label())
	_set_icon(entry_script.get_icon())
