extends Reference

var directory : String


# Override and build the folder structure based on your implementation.
# Returns an array of LauncherEntries.
func load_directory() -> Array:
	return []


#func create_entry(scene : PackedScene, name : String, script : Script = null) -> Control:
#	var entry = scene.instance()
#	if script != null:
#		entry.set_script(script)
#	entry.label = name
#	entry.name = name
#	return entry


# Override this function to check if "dir" is loadable using this folder script.
static func _is_directory_loadable(dir : String) -> bool:
	return false
