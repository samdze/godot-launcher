extends Reference
class_name LauncherEntry

signal executed(error)
signal move_requested(to_directory)

var path : String


# Extend this class and override this method to define what happens when this entry is selected.
# Call "executed(error)" at the end of the method or when you're done if it's an asynchronous task.
# In "executed(error)", error should be OK or FAILED.
# Return OK if the execution is successful.
# Return FAILED otherwise.
func exec():
	
	executed(OK)
	return OK


# Override this function and return the entry label to show to the user.
func get_label() -> String:
	
	return ""


# Override this function and return the entry icon to show the user.
# By default, a png file in the same directory and with the same name as the
# script is searched and returned if found.
func get_icon() -> Texture:
	var icon_path = get_script().resource_path.get_basename() + ".png"
	if ResourceLoader.has(icon_path):
		return ResourceLoader.load(get_script().resource_path.get_basename() + ".png") as Texture
	return null


# Call this function in exec() or when the asynchronous task this entry performs is completed.
func executed(error):
	emit_signal("executed", error)


# Should be called by UI entries each frame when the entry is running.
# You can perform custom logic here until you call executed(error).
func _process(delta):
	
	pass
