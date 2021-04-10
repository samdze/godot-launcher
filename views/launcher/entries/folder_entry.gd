extends LauncherEntry

export(String) var directory

var view


func exec():
	var result = view.move_to_directory(directory)
	executed(result)


func init_from_directory(dir, view):
	directory = dir
	self.view = view
