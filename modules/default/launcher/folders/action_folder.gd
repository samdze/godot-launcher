extends "../folder.gd"

const action_entry = preload("../entries/action_entry.gd")


# Override and build the folder structure based on your implementation.
# Returns an array of LauncherEntries.
func load_directory() -> Array:
	var entries = []
	
	# Read the action.config file and get the data needed to load and launch files.
	var file : File = File.new()
	var result = file.open(directory + "/action.config", File.READ)
	if result != OK:
		printerr("Failed to read action.config file inside folder " + directory)
		return []
	
	var config = {
		"ROM": "",
		"ROM_SO": "",
		"EXT": [],
		"EXCLUDE": [],
		"FILETYPE": "file",
		"LAUNCHER": "",
		"TITLE": "Game",
		"SO_URL": "",
		"RETRO_CONFIG": ""
	}
	
	var contents = file.get_as_text()
	for l in contents.split("\n"):
		var key_value = l.split("=")
		if key_value.size() > 1:
			if key_value[0] == "EXT" or key_value[0] == "EXCLUDE":
				config[key_value[0]] = Array(key_value[1].split(","))
			else:
				config[key_value[0]] = key_value[1]
	
	var roms_directory = config.ROM
	
	var dir = Directory.new()
	var res = dir.open(roms_directory)
	if res != OK:
		printerr("Directory ", roms_directory, " not found.")
	else:
		dir.list_dir_begin(true, true)
		var file_name : String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				if config.EXT.has(file_name.get_extension()):
#					var underscore_index = file_name.find("_")
#					var entry_name = file_name.substr(underscore_index + 1).replace(".sh", "")
					var entry = action_entry.new()
					# TODO: check if file is executable
					entry.init_from_config(config, file_name)
					
					entries.append(entry)
			
			file_name = dir.get_next()
	
	return entries


# Override this function to check if "dir" is loadable using this folder script.
static func _is_directory_loadable(dir : String) -> bool:
	var action_file = File.new()
	return action_file.file_exists(dir + "/action.config")
