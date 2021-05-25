extends Control

signal step_completed(succeeded)

const map_entry = preload("button_icon_map_entry.tscn")
const mapping_icons = [
	"button_a", "button_b", "button_x", "button_y", "button_right", "button_up",
	"button_left", "button_down", "button_menu", "button_start", "button_home"
]
const actions_order = [
	"ui_accept", "ui_cancel", "ui_button_x", "ui_button_y", "ui_right",
	"ui_up", "ui_left", "ui_down", "ui_menu", "ui_start", "ui_home"
]

var events_to_entries = {}
var mapping = {}

onready var entries_container = $ScrollContainer/VBoxContainer


func _ready():
	var i = 0
	for action in actions_order:
		var entry = map_entry.instance()
		entry.connect("event_received", self, "_event_received", [entry, i])
		entry.connect("started_listening", self, "_started_listening", [entry, i])
#		entry.connect("focus_entered", self, "_entry_focus_entered", [entry])
		entries_container.add_child(entry)
		
		entry.button_icon.texture = get_icon(mapping_icons[i], "Control")
		var action_list = InputMap.get_action_list(action)
#		if action_list.size() > 0:
		entry.button_label.text = "" #action_list[0].as_text()
		i += 1
	# Configure the mapping buttons
#	i = 0
#	for c in entries_container.get_children():
#		c.focus_neighbour_left = c.get_path()
#		c.focus_neighbour_right = c.get_path()
#		if i > 0:
#			c.focus_neighbour_top = list_container.get_child(i - 1).get_path()
#		else:
#			c.focus_neighbour_top = list_container.get_child(list_container.get_child_count() - 1).get_path()
#		if i < list_container.get_child_count() - 1:
#			c.focus_neighbour_bottom = list_container.get_child(i + 1).get_path()
#		else:
#			c.focus_neighbour_bottom = list_container.get_child(0).get_path()
#		i += 1


func _started_listening(entry, index):
#	if entry.button_label.text != "" and events_to_entries.has(entry.button_label.text):
#		events_to_entries[entry.button_label.text].erase(entry)
	entry.button_label.text = ""


func _event_received(event : InputEvent, entry, index):
	if events_to_entries.has(event.as_text()):
		return
	
	events_to_entries[event.as_text()] = entry
	mapping[actions_order[index]] = event
	entry.button_label.text = event.as_text()
	
	if index >= entries_container.get_child_count() - 1:
		# Mapping completed
		emit_signal("step_completed", true)
	else:
		entries_container.get_child(index + 1).grab_focus()
#		InputMap.action_add_event(actions_order[index], event)
#		Settings.set_value("system/input-" + actions_order[index], event)
#		entry.button_label.text = event.as_text()
#		# Check if this event is already mapped to another button
#		if events_to_entries.has(event.as_text()):
#			events_to_entries[event.as_text()].append(entry)
#		else:
#			events_to_entries[event.as_text()] = [entry]
		
		# Duplicates check
#		for ev in events_to_entries:
#			var entries = events_to_entries[ev]
#			if entries.size() > 1:
#				for en in entries:
#					en.mapping_button.add_stylebox_override("normal", get_stylebox("error", "PanelContainer"))
#			else:
#				for en in entries:
#					en.mapping_button.add_stylebox_override("normal", get_stylebox("normal", "Button"))
#
##		for a in mapping.keys():
##			var existing_event = mapping[a]
##			if existing_event.as_text() == event.as_text():
##				entry.mapping_button.add_stylebox_override("normal", get_stylebox("error", "PanelContainer"))
#		mapping[actions_order[index]] = event
		
#		entries_container.get_child(index + 1).grab_focus()


func enable():
	show()
	events_to_entries.clear()
	mapping.clear()
	entries_container.get_child(0).call_deferred("grab_focus")


func disable():
	if is_a_parent_of(get_focus_owner()):
		get_focus_owner().release_focus()
	hide()
