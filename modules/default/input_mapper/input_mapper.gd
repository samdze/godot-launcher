extends App

const map_entry = preload("button_map_entry.tscn")

var previous_mapping = {}
var mapping_order = [
	"A", "B", "X", "Y", "→", "↑", "←", "↓", "MENU", "START", "OPTION"
]
var actions_order = [
	"ui_accept", "ui_cancel", "ui_button_x", "ui_button_y", "ui_right",
	"ui_up", "ui_left", "ui_down", "ui_menu", "ui_start"
]
var map_index = 0
var listening = false
var last_item_focused = null

onready var list_container = $ScrollContainer/HBoxContainer/ButtonsList
onready var button_label = $ScrollContainer/HBoxContainer/MappingButton/HBoxContainer/PressLabel


func _ready():
	mapping_order = [
		"A",
		"B",
		"X",
		"Y",
		tr("DEFAULT.INPUT_BUTTON_RIGHT"),
		tr("DEFAULT.INPUT_BUTTON_UP"),
		tr("DEFAULT.INPUT_BUTTON_LEFT"),
		tr("DEFAULT.INPUT_BUTTON_DOWN"),
		"MENU",
		"START"
	]
	
	for c in list_container.get_children():
		list_container.remove_child(c)
		c.queue_free()
	var i = 0
	for action in actions_order:
		var entry = map_entry.instance()
		entry.connect("event_received", self, "_event_received", [entry, i])
		entry.connect("started_listening", self, "_started_listening", [entry, i])
		entry.connect("focus_entered", self, "_entry_focus_entered", [entry])
		list_container.add_child(entry)
		
		entry.name_label.text = mapping_order[i]
		var action_list = InputMap.get_action_list(action)
		if action_list.size() > 0:
			entry.mapping_button.text = action_list[0].as_text()
		i += 1
	# Configure the mapping buttons
	i = 0
	for c in list_container.get_children():
		c.focus_neighbour_left = c.get_path()
		c.focus_neighbour_right = c.get_path()
		if i > 0:
			c.focus_neighbour_top = list_container.get_child(i - 1).get_path()
		else:
			c.focus_neighbour_top = list_container.get_child(list_container.get_child_count() - 1).get_path()
		if i < list_container.get_child_count() - 1:
			c.focus_neighbour_bottom = list_container.get_child(i + 1).get_path()
		else:
			c.focus_neighbour_bottom = list_container.get_child(0).get_path()
		i += 1


func _focus():
	emit_signal("status_visibility_change_requested", true)
	emit_signal("title_change_requested", tr("DEFAULT.INPUT_SETTINGS"))
	emit_signal("mode_change_requested", System.Mode.OPAQUE)
	
#	previous_mapping.clear()
#	for a in InputMap.get_actions():
#		previous_mapping[a] = InputMap.get_action_list(a)
#		InputMap.action_erase_events(a)
	
	map_index = 0
	
	if last_item_focused != null:
		last_item_focused.grab_focus()
	elif list_container.get_child_count() > 0:
		list_container.get_child(0).grab_focus()
	else:
		grab_focus()
#	_update_prompt()
	Launcher.emit_event("prompts", [[BottomBar.ICON_NAV_V, tr("DEFAULT.PROMPT_NAVIGATION")], [BottomBar.ICON_BUTTON_A, tr("DEFAULT.PROMPT_REMAP"), BottomBar.ICON_BUTTON_B, tr("DEFAULT.PROMPT_BACK")]])


func _unfocus():
	# Restoring the previous mapping if the new mapping is not completed.
#	if map_index < mapping_order.size():
#		for action in previous_mapping.keys():
#			InputMap.action_erase_events(action)
#			for e in previous_mapping[action]:
#				InputMap.action_add_event(action, e)
#	previous_mapping.clear()
	pass


func _event_received(event, entry, action_index):
	InputMap.action_add_event(actions_order[action_index], event)
	Settings.set_value("system/input-" + actions_order[action_index], event)
	entry.mapping_button.text = event.as_text()
	listening = false
	Launcher.emit_event("prompts", [[BottomBar.ICON_NAV_V, tr("DEFAULT.PROMPT_NAVIGATION")], [BottomBar.ICON_BUTTON_A, tr("DEFAULT.PROMPT_REMAP"), BottomBar.ICON_BUTTON_B, tr("DEFAULT.PROMPT_BACK")]])


func _started_listening(entry, action_index):
	entry.mapping_button.text = tr("DEFAULT.INPUT_WAITING")
	listening = true
	Launcher.emit_event("prompts", [[], []])


func _entry_focus_entered(entry):
	last_item_focused = entry


func _update_prompt():
	if map_index < list_container.get_child_count():
		list_container.get_child(map_index).get_node("Mapping").grab_focus()
	if map_index <= mapping_order.size() - 1:
		button_label.text = mapping_order[map_index]
	else:
		button_label.text = "✓"


func _app_input(event : InputEvent):
#	if map_index < mapping_order.size():
#		if event.is_pressed() and not event.is_echo() and (event is InputEventJoypadButton or event is InputEventKey):
#			if event is InputEventKey:
#				var key_event : InputEventKey = event as InputEventKey
#				print("Event is " + key_event.get_class() + ": " + key_event.as_text()+ " scancode: " + str(key_event.scancode) + " unicode: " + str(key_event.unicode))
#				if key_event.unicode != 0:
#					print("Adding event...")
#					_update_next_mapping(key_event)
#			elif event is InputEventJoypadButton:
#				var joy_event : InputEventJoypadButton = event as InputEventJoypadButton
#				pass
	if not listening and event.is_action_pressed("ui_cancel"):
		Launcher.get_ui().app.back_app()


func _update_next_mapping(event):
	InputMap.action_add_event(actions_order[map_index], event)
	list_container.get_child(map_index).get_node("Mapping").text = event.as_text()
	map_index += 1
	_update_prompt()


# Called when the App is about to be destroyed and freed from memory.
# Do your cleanup here if needed.
func _destroy():
	pass


static func _get_component_name():
	return "Input Mapper"


# Override this function to expose user-editable settings to the Settings app
static func _get_settings():
	return [
		Setting.export([], TranslationServer.translate("DEFAULT.FOLDER_SYSTEM") + "/" + TranslationServer.translate("DEFAULT.INPUT_SETTINGS"), load("res://modules/default/input_mapper/settings/input_map_button.tscn"))
	]
