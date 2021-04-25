extends App

const Entry = preload("entry.gd")

#const empty_entry = preload("entries/empty_entry.tscn")
#const command_entry = preload("entries/command_entry.tscn")
#const folder_entry = preload("entries/folder_entry.tscn")
#const script_entry = preload("entries/script_entry.gd")

# Folder loaders that will try to load folders entry, order matters.
const folder_loaders = [
	preload("folders/action_folder.gd"),
	preload("folders/default_folder.gd")
]
const apps_loader = preload("folders/default_folder.gd")

const icons_view = preload("views/icons_view.tscn")
const list_view = preload("views/list_view.tscn")

var running_app : PackedScene# = preload("res://views/running_app/running_app_view.tscn")
var last_focused_entry : Control = null

var menu_directory : String = "/home/cpi/apps/Menu"
var apps_directory : String = "res://apps"
# Bash scripts and other types of file are not imported and must be loaded from the filesystem
# TODO: convert the local apps_directory directory to a global one instead of using this hardcoded string.
var gloabl_apps_directory : String = "/home/cpi/godot-launcher/apps"

var current_directory : String = ""
var selection_stack = []
#var default_entry_y = 0
#var entry_highlight_shift_y = -22
var executing = false

var current_view = null
#onready var entries_container = $HBoxContainer
#onready var tween = $Tween


func _ready():
	running_app = Modules.get_loaded_component_from_config("system", "running_app", "default/running").resource
	load_directory(menu_directory)


func _focus():
	emit_signal("bars_visibility_change_requested", true, true)
	emit_signal("title_change_requested", "GameShell")
	emit_signal("mode_change_requested", LauncherUI.Mode.OPAQUE)
	_update_promtps()
	if last_focused_entry != null:
		last_focused_entry.grab_focus()


func _unfocus():
	if last_focused_entry != null:
		last_focused_entry.release_focus()


func _active_window_changed(window_id):
	executing = false
	Launcher.get_ui().loading_overlay.set_loading(false)
	print("[GODOT] Adding a new app to the apps stack...")
	Launcher.get_ui().app.add_app(running_app.instance())
	print("[GODOT] New app added to the apps stack.")


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
	# TODO: add check for apps_directory
	return FAILED


func back_directory():
	if current_directory != menu_directory:
		var parent_dir = current_directory.left(current_directory.rfind("/"))
#		print("Going back to " + parent_dir)
		
		var selected_entry = selection_stack.pop_back() if selection_stack.size() > 0 else 0
		return load_directory(parent_dir, selected_entry)
	return FAILED


func load_directory(directory, selected_entry = 0):
	if current_view != null:
		remove_child(current_view)
		current_view.queue_free()
	
	var entries = []
	if directory == menu_directory:
		var apps_loader_obj = apps_loader.new()
		apps_loader_obj.directory = apps_directory
		entries = entries + apps_loader_obj.load_directory()
	
	var loader_class = null
	for l in folder_loaders:
		if l._is_directory_loadable(directory):
			loader_class = l
			break
	if loader_class == null:
		return
	
	var loader = loader_class.new()
	loader.directory = directory
	entries = entries + loader.load_directory()
	
	# Choose the view to display the entries
	current_view = icons_view.instance() if loader_class == apps_loader else list_view.instance() 
	current_view.connect("entry_focused", self, "_entry_focused")
	current_view.connect("entry_selected", self, "_entry_selected")
	current_view.connect("executed", self, "_execution_terminated")
	current_view.connect("move_requested", self, "move_to_directory")
	
	add_child(current_view)
	current_view.append_entries(entries)
	# Select the previous selected entry if going back from a directory
	current_view.select_entry(selected_entry)
	
	current_directory = directory
	
	_update_promtps()
	return OK


func _entry_focused(entry):
	last_focused_entry = entry


func _entry_selected(entry):
	if not executing:
		entry.release_focus()
		executing = true
		Launcher.get_ui().loading_overlay.set_loading(true)
		entry.connect("executed", self, "_execution_terminated", [entry])
		
		var result = entry.exec()
		print("App id returned: "+str(result))


func _app_input(event):
#	if event.is_pressed():
#		Launcher.get_ui().notifications_bar.append_notification("System-wide notifications available!", Notifications.Type.SUCCESS)
	if not executing and event.is_action_pressed("ui_cancel"):
		accept_event()
		back_directory()
	# TODO: to remove
#	if event.is_action_pressed("ui_menu"):
#		get_tree().quit()


func _execution_terminated(error, entry : Entry):
#	entry.disconnect("executed", self, "_execution_terminated")
	Launcher.get_ui().loading_overlay.set_loading(false)
	executing = false
	if last_focused_entry != null:
		last_focused_entry.grab_focus()
	update()


static func _get_component_name():
	return "GameShell Launcher"


static func _get_component_tags():
	return [Component.TAG_LAUNCHER]


static func _get_exported_settings():
	return [
		{ "section": "system", "key": "running_app", "label": "Running App", "control": preload("res://system/settings/editors/dropdown_running_app.tscn") }
	]
