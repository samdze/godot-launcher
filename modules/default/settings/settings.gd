extends App

var last_focused_item : Control = null
var current_directory : String = ""
var selection_stack = []
var pages_controls = {}
var pages_folders = {}

var pending_changes = {}

onready var reload_message : Control = $ConstraintContainer/ReloadAndSettings/ReloadContainer
onready var reload_label : Label = $ConstraintContainer/ReloadAndSettings/ReloadContainer/MarginContainer/SmallLabel
onready var scroll_container : ScrollContainer = $ConstraintContainer/ReloadAndSettings/SettingsView
onready var options_container : VBoxContainer = $ConstraintContainer/ReloadAndSettings/SettingsView/VBoxContainer


func _ready():
	reload_label.add_color_override("font_color", get_color("font_color_hover", "Button"))
	reload_message.hide()
	
	# Load settings and create them
	pages_controls[""] = []
	var settings = Settings.get_exported_settings()
	for exported in settings:
		print("Exported setting: " + str(exported.sections_keys) + " - " + exported.label + " - " + str(exported.control))
		var control : SettingEditor = exported.control.instance()
		
		var path = exported.label
		
		var path_split = path.split("/")
		var i = 0
		var path_label = ""
		while i < path_split.size():
			if not pages_controls.has(path_label):
				pages_controls[path_label] = []
			if i == path_split.size() - 1:
				# This is the last label of the control
				var name_label = path_split[i]
				control._initialize_setting(exported.sections_keys, name_label)
				pages_controls[path_label].append(control)
			else:
				var current_path = path_label
				path_label += "/" + path_split[i]
				
				if not pages_folders.has(path_label):
					pages_folders[path_label] = true
					var folder_button = preload("folder_button.tscn").instance()
					folder_button._initialize_setting([], path_split[i])
					folder_button.init_from_directory(path_label)
					pages_controls[current_path].append(folder_button)
			i += 1
		
		
#		var slash_found = path.rfind("/")
#		if slash_found > -1:
#			var dir = "/" + path.left(slash_found)
#			var label = path.right(slash_found + 1)
#			control._initialize_setting(exported.sections_keys, label)
#			if not pages_controls.has(dir):
#				pages_controls[dir] = []
#			print(dir)
#			print(label)
#			var folder_button = preload("folder_button.tscn").instance()
#			folder_button._initialize_setting([], dir)
#			folder_button.init_from_directory(dir)
#			pages_controls[""].append(folder_button)
#			pages_controls[dir].append(control)
#		else:
#			control._initialize_setting(exported.sections_keys, exported.label)
#			pages_controls[""].append(control)
	
	_load_directory("")


func _load_directory(directory, selected_entry = 0):
	current_directory = directory
	
	if get_focus_owner() != null and is_a_parent_of(get_focus_owner()):
		get_focus_owner().release_focus()
	for c in options_container.get_children():
		var value : Control = c
		value.disconnect("gui_input", self, "_options_gui_input")
		value.disconnect("focus_entered", self, "_item_focused")
		value.disconnect("value_changed", self, "_value_changed")
		value.disconnect("move_request", self, "_move_request")
		options_container.remove_child(value)
	
	for c in pages_controls[current_directory]:
		options_container.add_child(c)
	var i = 0
	for c in options_container.get_children():
		var value : Control = c
		value.connect("gui_input", self, "_options_gui_input")
		value.connect("focus_entered", self, "_item_focused", [value])
		value.connect("value_changed", self, "_value_changed", [value])
		value.connect("move_request", self, "_move_request")
		value.focus_neighbour_left = value.get_path()
		value.focus_neighbour_right = value.get_path()
		if i > 0:
			value.focus_neighbour_top = options_container.get_child(i - 1).get_path()
		else:
			value.focus_neighbour_top = options_container.get_child(options_container.get_child_count() - 1).get_path()
		if i < options_container.get_child_count() - 1:
			value.focus_neighbour_bottom = options_container.get_child(i + 1).get_path()
		else:
			value.focus_neighbour_bottom = options_container.get_child(0).get_path()
		i += 1
	
	scroll_container.scroll_vertical = 0
	
	selected_entry = clamp(selected_entry, 0, options_container.get_child_count() - 1)
	if selected_entry >= 0:
		options_container.get_child(selected_entry).call_deferred("grab_focus")


func move_to_directory(directory : String):
	if current_directory == directory:
		return
	# Check if it's a direct subdirectory.
	# If it is, add the current selected entry index to the selection stack.
	# If it's not, clear the selection stack because going back from the new directory doesn't bring to the old one.
	if directory.count("/") == current_directory.count("/") + 1:
		selection_stack.push_back(last_focused_item.get_index() if last_focused_item != null else 0)
	else:
		selection_stack.clear()
	
	_load_directory(directory)


func back_directory():
	if current_directory != "":
		var parent_dir = current_directory.left(current_directory.rfind("/"))
		
		var selected_entry = selection_stack.pop_back() if selection_stack.size() > 0 else 0
		return _load_directory(parent_dir, selected_entry)


func _focus():
	emit_signal("window_mode_request", false)
	emit_signal("title_change_request", tr("DEFAULT.SETTINGS"))
	emit_signal("display_mode_request", Launcher.Mode.OPAQUE)
	
	if last_focused_item != null:
		last_focused_item.grab_focus()
	elif options_container.get_child_count() > 0:
		options_container.get_child(0).grab_focus()


func _item_focused(item):
	System.emit_event("prompts", [[Desktop.Input.MOVE_V, tr("DEFAULT.PROMPT_NAVIGATION")], [Desktop.Input.A, tr("DEFAULT.PROMPT_SELECT"), Desktop.Input.B, tr("DEFAULT.PROMPT_BACK")]])
	last_focused_item = item


func _options_gui_input(event : InputEvent):
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		if current_directory != "":
			back_directory()
		else:
			System.get_launcher().app.back_app()


func _value_changed(section_key, value, reload_needed, option):
	print("Setting config value ("+ section_key + ") " + str(value))
	if Settings.get_value(section_key) == value:
		return
	
	if reload_needed:
		var current_value
		if pending_changes.has(section_key):
			current_value = pending_changes[section_key]
		else:
			current_value = Settings.get_value(section_key)
			pending_changes[section_key] = current_value
		if value == current_value:
			pending_changes.erase(section_key)
		
		reload_message.visible = pending_changes.size() > 0
	
	Settings.set_value(section_key, value)


func _move_request(to_directory):
	accept_event()
	move_to_directory(to_directory)


func _destroy():
	if pending_changes.size() > 0:
		Engine.get_main_loop().quit()


static func _get_component_name():
	return "Settings"


static func _get_component_tags():
	return [Component.TAG_SETTINGS]


static func _get_settings_exports():
	return [
		Setting.export(["system/desktop"], TranslationServer.translate("DEFAULT.FOLDER_SYSTEM") + "/" + TranslationServer.translate("DEFAULT.DESKTOP"), load("res://system/settings/editors/dropdown_desktop.tscn")),
		Setting.export(["system/launcher_app"], TranslationServer.translate("DEFAULT.FOLDER_SYSTEM") + "/" + TranslationServer.translate("DEFAULT.LAUNCHER_APP"), load("res://system/settings/editors/dropdown_launcher_app.tscn")),
		Setting.export(["system/settings_app"], TranslationServer.translate("DEFAULT.FOLDER_SYSTEM") + "/" + TranslationServer.translate("DEFAULT.SETTINGS_APP"), load("res://system/settings/editors/dropdown_settings_app.tscn")),
		Setting.export(["system/keyboard_app"], TranslationServer.translate("DEFAULT.FOLDER_SYSTEM") + "/" + TranslationServer.translate("DEFAULT.KEYBOARD_APP"), load("res://system/settings/editors/dropdown_keyboard_app.tscn")),
		Setting.export(["system/language"], TranslationServer.translate("DEFAULT.FOLDER_SYSTEM") + "/" + TranslationServer.translate("DEFAULT.LANGUAGE"), load("res://system/settings/editors/dropdown_language.tscn")),
		Setting.export(["system/theme"], TranslationServer.translate("DEFAULT.FOLDER_SYSTEM") + "/" + TranslationServer.translate("DEFAULT.THEME"), load("res://system/settings/editors/dropdown_theme.tscn")),
		Setting.export(["system/about"], TranslationServer.translate("DEFAULT.ABOUT"), load("res://system/settings/about/settings_button.tscn"))
	]
