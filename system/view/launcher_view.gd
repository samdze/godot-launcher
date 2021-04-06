extends View

const empty_entry = preload("res://system/view/entries/empty_entry.tscn")
const command_entry = preload("res://system/view/entries/command_entry.tscn")
const folder_entry = preload("res://system/view/entries/folder_entry.tscn")

var last_focused_entry : Control = null

var menu_directory : String = "/home/cpi/apps/Menu"
#var menu_directory = "C:/Development/android-studio"
var apps_directory : String = "res://apps"
# Bash scripts and other types of file are not imported and must be loaded from the filesystem
var gloabl_apps_directory : String = "/home/cpi/launchergodot/apps"

var current_directory : String = ""
var selection_stack = []
var default_entry_y = 0
var entry_highlight_shift_y = -22

onready var entries_container = $HBoxContainer
onready var tween = $Tween



func _init():
	show_top_bar = true
	show_bottom_bar = true


func _ready():
	load_directory(menu_directory)


func _focus():
	_update_promtps()


func _active_window_changed(window_id):
	Launcher.get_ui().loading_overlay.set_loading(false)


func _update_promtps():
	if current_directory == menu_directory:
		Launcher.get_ui().bottom_bar.set_prompts([BottomBar.ICON_NAV, BottomBar.PROMPT_NAV], [BottomBar.ICON_BUTTON_A, BottomBar.PROMPT_ENTER])
	else:
		Launcher.get_ui().bottom_bar.set_prompts([BottomBar.ICON_NAV, BottomBar.PROMPT_NAV], [BottomBar.ICON_BUTTON_A, BottomBar.PROMPT_ENTER, BottomBar.ICON_BUTTON_B, BottomBar.PROMPT_BACK])


func move_to_directory(directory : String):
	if directory.find(menu_directory) >= 0:
		# Check if it's a direct subdirectory.
		# If it is, add the current selected entry index to the selection stack.
		# If it's not, clear the selection stack because going back from the new directory doesn't bring to the old one.
		if directory.count("/") == current_directory.count("/") + 1:
			selection_stack.push_back(last_focused_entry.get_index() if last_focused_entry != null else 0)
		else:
			selection_stack.clear()
		
		return load_directory(directory)
	return FAILED


func back_directory():
	if current_directory != menu_directory:
		var parent_dir = current_directory.left(current_directory.rfind("/"))
		print("Going back to " + parent_dir)
		
		var selected_entry = selection_stack.pop_back() if selection_stack.size() > 0 else 0
		return load_directory(parent_dir, selected_entry)
	return FAILED


func load_directory(directory, selected_entry = 0):
	for c in entries_container.get_children():
		entries_container.remove_child(c)
		c.queue_free()
	
	# If it's the root directory load the system apps too.
	if directory == menu_directory:
		var dir = Directory.new()
		var res = dir.open(apps_directory)
		if res != OK:
			printerr("Directory ", apps_directory, " not found.")
		else:
			dir.list_dir_begin(true, true)
			var file_name : String = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					print("Found directory: " + file_name)
					var underscore_index = file_name.find("_")
					var entry_name = file_name.substr(underscore_index + 1)
					print("- Entry name is: " + entry_name)
					var entry = create_entry(folder_entry, entry_name)
					entries_container.add_child(entry)
					# TODO: doesn't work for nested folders
					entry.init_from_directory(gloabl_apps_directory + "/" + file_name, self)
				else:
					if file_name.ends_with(".sh"):
						print("Found file: " + file_name)
						var underscore_index = file_name.find("_")
						var entry_name = file_name.substr(underscore_index + 1).replace(".sh", "")
						print("- Entry name is: " + entry_name)
						var entry = create_entry(command_entry, entry_name)
						entries_container.add_child(entry)
						# TODO: doesn't work for nested folders
						# TODO: check if file is executable
						entry.init_from_file(gloabl_apps_directory, file_name)
					elif file_name.ends_with(".gd"):
						# TODO: create a separate structure to save and cache system apps scripts
						var scr = File.new()
						var result = scr.open(apps_directory + "/" + file_name, File.READ)
						if result != OK:
							printerr("File ", file_name, " not found.")
						var source = scr.get_as_text()
						var entry_script = GDScript.new()
						entry_script.source_code = source
						result = entry_script.reload()
						if result != OK:
							printerr("Error loading script ", file_name, ": ", result)
						var entry_name = file_name.replace(".gd", "")
						var entry = create_entry(empty_entry, entry_name, entry_script)
						entries_container.add_child(entry)
						
				file_name = dir.get_next()
	
	
	var dir = Directory.new()
	var res = dir.open(directory)
	if res != OK:
		printerr("Directory ", directory, " not found.")
	else:
		dir.list_dir_begin(true, true)
		var file_name : String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
				var underscore_index = file_name.find("_")
				var entry_name = file_name.substr(underscore_index + 1)
				print("- Entry name is: " + entry_name)
				var entry = create_entry(folder_entry, entry_name)
				entries_container.add_child(entry)
				entry.init_from_directory(directory + "/" + file_name, self)
			else:
				if file_name.ends_with(".sh"):
					print("Found file: " + file_name)
					var underscore_index = file_name.find("_")
					var entry_name = file_name.substr(underscore_index + 1).replace(".sh", "")
					print("- Entry name is: " + entry_name)
					var entry = create_entry(command_entry, entry_name)
					entries_container.add_child(entry)
					# TODO: check if file is executable
					entry.init_from_file(directory, file_name)
			file_name = dir.get_next()
	
	# Configure the loaded entries
	for c in entries_container.get_children():
		var index = c.get_index()
		if not c is LauncherEntry:
			continue
		
		print("Configuring entry " + str(index))
		c.connect("focus_entered", self, "_entry_focus_entered", [c])
		c.connect("focus_exited", self, "_entry_focus_exited", [c])
		c.connect("gui_input", self, "_entry_input", [c])
		if index > 0:
			c.focus_neighbour_left = entries_container.get_child(index - 1).get_path()
		else:
			c.focus_neighbour_left = entries_container.get_child(entries_container.get_child_count() - 1).get_path()
		if index < entries_container.get_child_count() - 1:
			c.focus_neighbour_right = entries_container.get_child(index + 1).get_path()
		else:
			c.focus_neighbour_right = entries_container.get_child(0).get_path()
	
	current_directory = directory
	
	if entries_container.get_child_count() > 0:
		# Select the previous selected entry if going back from a directory
		selected_entry = clamp(selected_entry, 0, entries_container.get_child_count() - 1)
		default_entry_y = entries_container.get_child(selected_entry).container.rect_position.y
		
		entries_container.notification(Container.NOTIFICATION_SORT_CHILDREN)
		
		entries_container.rect_position = Vector2(-entries_container.get_child(selected_entry).rect_position.x + 160 - 74/2, entries_container.rect_position.y)
		entries_container.get_child(selected_entry).grab_focus()
	
	_update_promtps()
	return OK


func _input(event):
	if Launcher.get_ui().mode == LauncherUI.Mode.LAUNCHER and not Launcher.get_ui().loading_overlay.is_loading() and event.is_action_pressed("ui_cancel"):
		back_directory()


func create_entry(scene : PackedScene, name, script = null):
	var entry = scene.instance()
	if script != null:
		entry.set_script(script)
	entry.label = name
	entry.name = name
	return entry


func _entry_focus_entered(entry):
	print("Entry " + entry.name + " has received focus.")
	last_focused_entry = entry
	entry.set_highlighted(true)
	tween.remove(entry.container, "rect_position:y")
	tween.interpolate_property(entry.container, "rect_position:y", entry.container.rect_position.y, default_entry_y + entry_highlight_shift_y, 0.2)
	
	tween.remove(entries_container, "rect_position")
	tween.interpolate_property(entries_container, "rect_position", entries_container.rect_position, Vector2(-entry.rect_position.x + 160 - 74/2, entries_container.rect_position.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()


func _entry_focus_exited(entry):
	entry.set_highlighted(false)
	tween.remove(entry.container, "rect_position:y")
	tween.interpolate_property(entry.container, "rect_position:y", entry.container.rect_position.y, default_entry_y, 0.2)
	tween.start()


func _entry_input(event : InputEvent, entry : LauncherEntry):
	if event.is_action_pressed("ui_accept") and not Launcher.get_ui().loading_overlay.is_loading() and Launcher.get_ui().mode == LauncherUI.Mode.LAUNCHER:
		entry.release_focus()
		Launcher.get_ui().loading_overlay.set_loading(true)
		entry.connect("executed", self, "_execution_terminated", [entry])
		
		var result = entry.exec()
		print("App id returned: "+str(result))


func _execution_terminated(error, entry : LauncherEntry):
	entry.disconnect("executed", self, "_execution_terminated")
	Launcher.get_ui().loading_overlay.set_loading(false)
	if last_focused_entry != null:
		last_focused_entry.grab_focus()
	update()
