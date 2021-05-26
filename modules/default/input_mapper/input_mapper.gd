extends App

const map_entry = preload("button_map_entry.tscn")

var previous_mapping = {}
var mapping_icons = [
	"button_a", "button_b", "button_x", "button_y", "button_right", "button_up",
	"button_left", "button_down", "button_menu", "button_start", "button_home"
]
var actions_order = [
	"ui_accept", "ui_cancel", "ui_button_x", "ui_button_y", "ui_right",
	"ui_up", "ui_left", "ui_down", "ui_menu", "ui_start", "ui_home"
]
var listening = false
var last_item_focused = null

onready var list_container = $ScrollContainer/HBoxContainer/ButtonsList


func _ready():
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
		
		entry.button_icon.texture = get_icon(mapping_icons[i], "Control")
		var action_list = InputMap.get_action_list(action)
		if action_list.size() > 0:
			var event = action_list[0]
			if event is InputEventJoypadButton:
				entry.mapping_button.text = str(event.device) + ":" + str((event as InputEventJoypadButton).button_index)
			elif event is InputEventKey:
				entry.mapping_button.text = event.as_text()
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
	emit_signal("window_mode_request", false)
	emit_signal("title_change_request", tr("DEFAULT.INPUT_SETTINGS"))
	emit_signal("display_mode_request", Launcher.Mode.OPAQUE)
	
	if last_item_focused != null:
		last_item_focused.grab_focus()
	elif list_container.get_child_count() > 0:
		list_container.get_child(0).grab_focus()
	else:
		grab_focus()
	System.emit_event("prompts", [[Desktop.Input.MOVE_V, tr("DEFAULT.PROMPT_NAVIGATION")], [Desktop.Input.A, tr("DEFAULT.PROMPT_REMAP"), Desktop.Input.B, tr("DEFAULT.PROMPT_BACK")]])


func _unfocus():
	
	pass


func _event_received(event, entry, action_index):
	InputMap.action_add_event(actions_order[action_index], event)
	Settings.set_value("system/input-" + actions_order[action_index], event)
	if event is InputEventJoypadButton:
		entry.mapping_button.text = str(event.device) + ":" + str((event as InputEventJoypadButton).button_index)
	elif event is InputEventKey:
		entry.mapping_button.text = event.as_text()
	listening = false
	System.emit_event("prompts", [[Desktop.Input.MOVE_V, tr("DEFAULT.PROMPT_NAVIGATION")], [Desktop.Input.A, tr("DEFAULT.PROMPT_REMAP"), Desktop.Input.B, tr("DEFAULT.PROMPT_BACK")]])


func _started_listening(entry, action_index):
	InputMap.action_erase_events(actions_order[action_index])
	entry.mapping_button.text = tr("DEFAULT.INPUT_WAITING")
	listening = true
	System.emit_event("prompts", [[], []])


func _entry_focus_entered(entry):
	last_item_focused = entry


func _app_input(event : InputEvent):
	if not listening and event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		System.get_launcher().app.back_app()


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
