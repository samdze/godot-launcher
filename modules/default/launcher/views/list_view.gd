extends Control

signal entry_focused(entry)
signal entry_selected(entry)
signal executed(error, entry)
signal move_requested(to_directory)

const ui_entry = preload("list_entry.tscn")

onready var entries_container = $MarginContainer/ScrollContainer/VBoxContainer
#onready var tween = $Tween


func clear_entries():
	for c in entries_container.get_children():
		entries_container.remove_child(c)
		c.queue_free()


func append_entries(entries : Array):
	for e in entries:
		var entry = ui_entry.instance()
		entry.init(e)
		entries_container.add_child(entry)
	
	# Configure the loaded entries
	for c in entries_container.get_children():
		var index = c.get_index()

		c.connect("focus_entered", self, "_entry_focus_entered", [c])
		c.connect("focus_exited", self, "_entry_focus_exited", [c])
		c.connect("gui_input", self, "_entry_input", [c])
		c.connect("executed", self, "_executed", [c])
		c.connect("move_requested", self, "_move_requested")
		c.focus_neighbour_left = c.get_path()
		c.focus_neighbour_right = c.get_path()
		if index > 0:
			c.focus_neighbour_top = entries_container.get_child(index - 1).get_path()
		else:
			c.focus_neighbour_top = entries_container.get_child(entries_container.get_child_count() - 1).get_path()
		if index < entries_container.get_child_count() - 1:
			c.focus_neighbour_bottom = entries_container.get_child(index + 1).get_path()
		else:
			c.focus_neighbour_bottom = entries_container.get_child(0).get_path()


func select_entry(index):
	if entries_container.get_child_count() > 0:
		index = clamp(index, 0, entries_container.get_child_count() - 1)

		entries_container.notification(Container.NOTIFICATION_SORT_CHILDREN)
		entries_container.get_child(index).grab_focus()


func _entry_focus_entered(entry):
	emit_signal("entry_focused", entry)


func _entry_input(event : InputEvent, entry):
	if event.is_action_pressed("ui_accept"):
		emit_signal("entry_selected", entry)


func _executed(error, entry):
	emit_signal("executed", error, entry)


func _move_requested(to_directory : String):
	emit_signal("move_requested", to_directory)
