extends "../folder.gd"

const command_entry = preload("../entries/command_entry.gd")
const folder_entry = preload("../entries/folder_entry.gd")


# Override and build the folder structure based on your implementation.
# Returns an array of entries.
func load_directory() -> Array:
	var entries = []
	
	var file : File = File.new()
	var dir = Directory.new()
	var res = dir.open(directory)
	if res != OK:
		printerr("Directory ", directory, " not found.")
	else:
		dir.list_dir_begin(true, true)
		var file_name : String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				var underscore_index = file_name.find("_")
				var entry_name = file_name.substr(underscore_index + 1)
				
				var entry = null
				if file.file_exists(directory + "/" + file_name + "/" + entry_name):
					if file.open(directory + "/" + file_name + "/" + entry_name, File.READ) == OK:
						entry = command_entry.new()
						entry.init_from_file(directory + "/" + file_name, entry_name)
				elif file.file_exists(directory + "/" + file_name + "/" + entry_name + ".sh"):
					if file.open(directory + "/" + file_name + "/" + entry_name + ".sh", File.READ) == OK:
						entry = command_entry.new()
						entry.init_from_file(directory + "/" + file_name, entry_name + ".sh")
				if entry == null:
					entry = folder_entry.new()
					entry.init_from_directory(directory + "/" + file_name, entry_name)
				
				entry.path = directory + "/" + file_name
				entries.append(entry)
			else:
				if file_name.ends_with(".sh"):
					var underscore_index = file_name.find("_")
					var entry_name = file_name.substr(underscore_index + 1).replace(".sh", "")
					var entry = command_entry.new()
					# TODO: check if file is executable
					entry.init_from_file(ProjectSettings.globalize_path(directory), file_name)
					
					entry.path = directory + "/" + file_name
					entries.append(entry)
					
				elif file_name.ends_with(".gd"):
					# TODO: create a separate structure to save and cache apps scripts?
					var scr = File.new()
					var result = scr.open(directory + "/" + file_name, File.READ)
					if result != OK:
						printerr("File ", file_name, " not found.")
					var source = scr.get_as_text()
					var entry_script = GDScript.new()
					entry_script.source_code = source
					result = entry_script.reload()
					if result != OK:
						printerr("Error loading script ", file_name, ": ", result)
						continue
					var entry = entry_script.new()
					
					entry.path = directory + "/" + file_name
					entries.append(entry)
			
			file_name = dir.get_next()
	
	return entries


# Override this function to check if "dir" is loadable using this folder script.
static func _is_directory_loadable(dir : String) -> bool:
	return true
