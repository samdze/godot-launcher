extends View

var last_focused_item : Control = null

onready var options_container : VBoxContainer = $SettingsView/VBoxContainer


func _ready():
	var i = 0
	for c in options_container.get_children():
		var value : Control = c
		value.connect("gui_input", self, "_gui_input")
		value.connect("focus_entered", self, "_item_focused", [value])
		value.connect("value_changed", self, "_value_changed", [value])
		value.focus_neighbour_left = value.get_path()
		value.focus_neighbour_right = value.get_path()
		if i > 0:
			value.focus_neighbour_top = options_container.get_child(i - 1).get_path()
		else:
			value.focus_neighbour_top = value.get_path()
		if i < options_container.get_child_count() - 1:
			value.focus_neighbour_bottom = options_container.get_child(i + 1).get_path()
		else:
			value.focus_neighbour_bottom = value.get_path()
		i += 1


func _focus():
	emit_signal("bars_visibility_change_requested", true, true)
	emit_signal("title_change_requested", "Settings")
	emit_signal("mode_change_requested", LauncherUI.Mode.OPAQUE)
	
	if last_focused_item != null:
		last_focused_item.grab_focus()
	elif options_container.get_child_count() > 0:
		options_container.get_child(0).grab_focus()


func _item_focused(item):
	last_focused_item = item


func _gui_input(event : InputEvent):
	if event.is_action_pressed("ui_cancel"):
		Launcher.get_ui().view.back_view()
		accept_event()


func _value_changed(section, key, value, option):
	print("Setting config value ("+ section +", "+ key + ") " + value)
	Config.set_value(section, key, value)


static func _get_component_name():
	return "Settings"


static func _get_component_tags():
	return [Modules.TAG_SETTINGS]
