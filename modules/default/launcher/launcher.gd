extends App

const Entry = preload("entry.gd")

# Folder loaders that will try to load folders entry, order matters.
const folder_loaders = [
	preload("folders/action_folder.gd"),
	preload("folders/default_folder.gd")
]
const apps_loader = preload("folders/default_folder.gd")

const icons_view = preload("views/icons_view.tscn")
const list_view = preload("views/list_view.tscn")

var running_app : PackedScene
var last_focused_entry : Control = null

var menu_directory : String = "/home/cpi/apps/Menu"
var apps_directory : String = "res://apps"

var current_directory : String = ""
var selection_stack = []
var executing = false

var current_view = null


func _ready():
	if OS.has_feature("x86_64"):
		menu_directory = "E:\\Documenti\\Git\\apps\\Menu"
	
	running_app = Modules.get_loaded_component_from_settings("system/running_app").resource
	
	load_directory(menu_directory)


func _focus():
	emit_signal("window_mode_request", false)
	emit_signal("title_change_request", "GameShell")
	emit_signal("display_mode_request", Launcher.Mode.OPAQUE)
	_update_promtps()
	if last_focused_entry != null:
		last_focused_entry.grab_focus()


func _unfocus():
	if last_focused_entry != null:
		last_focused_entry.release_focus()


func _active_window_changed(window_id):
	if window_id != WindowManager.library.get_window_id():
		executing = false
		System.emit_event("set_loading", [false])
		print("[GODOT] Adding a new app to the apps stack...")
		var running_instance = running_app.instance()
		running_instance.app_window_id = window_id
		System.get_launcher().app.add_app(running_instance)
		print("[GODOT] New app added to the apps stack.")


func _update_promtps():
	if current_directory == menu_directory:
		var res = System.emit_event("prompts", [[Desktop.Input.MOVE, tr("DEFAULT.PROMPT_NAVIGATION")], [Desktop.Input.A, tr("DEFAULT.PROMPT_OPEN")]])
	else:
		var res = System.emit_event("prompts", [[Desktop.Input.MOVE, tr("DEFAULT.PROMPT_NAVIGATION")], [Desktop.Input.A, tr("DEFAULT.PROMPT_OPEN"), Desktop.Input.B, tr("DEFAULT.PROMPT_BACK")]])


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
	current_view.connect("move_request", self, "move_to_directory")
	
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
		System.emit_event("set_loading", [true])
		entry.connect("executed", self, "_execution_terminated", [entry])
		
		var result = entry.exec()
		print("App id returned: "+str(result))


func _app_input(event):
#	if event.is_pressed():
#		System.emit_event("notification", ["System-wide notifications available!", "success"])
	if not executing and event.is_action_pressed("ui_cancel"):
		accept_event()
		back_directory()
	# TODO: to remove
#	if event.is_action_pressed("ui_menu"):
#		get_tree().quit()


func _execution_terminated(error, entry : Entry):
#	entry.disconnect("executed", self, "_execution_terminated")
	System.emit_event("set_loading", [false])
	executing = false
	if last_focused_entry != null and last_focused_entry.is_inside_tree():
		last_focused_entry.grab_focus()
	if is_inside_tree():
		_update_promtps()
	update()


static func _get_component_name():
	return "GameShell Launcher"


static func _get_component_tags():
	return [Component.TAG_LAUNCHER]


static func _get_settings():
	return [
		Setting.create("system/icons", "default/icons"),
		Setting.create("system/running_app", "default/running"),
		
		Setting.export(["system/icons"], TranslationServer.translate("DEFAULT.FOLDER_LAUNCHER") + "/" + TranslationServer.translate("DEFAULT.ICONS"), load("res://system/settings/editors/dropdown_icons.tscn")),
		Setting.export(["system/running_app"], TranslationServer.translate("DEFAULT.FOLDER_LAUNCHER") + "/" + TranslationServer.translate("DEFAULT.RUNNING_APP"), load("res://system/settings/editors/dropdown_running_app.tscn")),
		Setting.export([], TranslationServer.translate("DEFAULT.SWITCH_LAUNCHER"), load("res://modules/default/launcher/settings/switch_launcher_button.tscn"))
	]
