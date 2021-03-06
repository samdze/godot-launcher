extends "../view.gd"

const ui_entry = preload("icons_entry.tscn")

var default_entry_y = 0
var highlight_entry_shift_y = -22

onready var background = $BackgroundLayer/Background
onready var entries_container = $EntriesContainer
onready var tween = $Tween


func _ready():
	background.texture = get_icon("wallpaper", "Control")


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
		c.connect("move_request", self, "_move_request")
		c.focus_neighbour_top = c.get_path()
		c.focus_neighbour_bottom = c.get_path()
		if index > 0:
			c.focus_neighbour_left = entries_container.get_child(index - 1).get_path()
		else:
			c.focus_neighbour_left = entries_container.get_child(entries_container.get_child_count() - 1).get_path()
		if index < entries_container.get_child_count() - 1:
			c.focus_neighbour_right = entries_container.get_child(index + 1).get_path()
		else:
			c.focus_neighbour_right = entries_container.get_child(0).get_path()


func select_entry(index):
	if entries_container.get_child_count() > 0:
		index = clamp(index, 0, entries_container.get_child_count() - 1)
		default_entry_y = entries_container.get_child(index).container.rect_position.y
		
		entries_container.notification(Container.NOTIFICATION_SORT_CHILDREN)
		
		entries_container.rect_position = Vector2(-entries_container.get_child(index).rect_position.x + self.rect_size.x / 2.0 - entries_container.get_child(index).rect_size.x / 2.0, entries_container.rect_position.y)
		entries_container.get_child(index).grab_focus()


func _entry_focus_entered(entry):
	entry.set_highlighted(true)
	tween.remove(entry.container, "rect_position:y")
	tween.interpolate_property(entry.container, "rect_position:y", entry.container.rect_position.y, default_entry_y + highlight_entry_shift_y, 0.2)
	
	tween.remove(entries_container, "rect_position")
	tween.interpolate_property(entries_container, "rect_position", entries_container.rect_position, Vector2(-entry.rect_position.x + self.rect_size.x / 2.0 - entry.rect_size.x / 2.0, entries_container.rect_position.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()
	
	emit_signal("entry_focused", entry)


func _entry_focus_exited(entry):
	entry.set_highlighted(false)
	tween.remove(entry.container, "rect_position:y")
	tween.interpolate_property(entry.container, "rect_position:y", entry.container.rect_position.y, default_entry_y, 0.2)
	tween.start()


func _entry_input(event : InputEvent, entry):
	if event.is_action_pressed("ui_accept"):
		emit_signal("entry_selected", entry)


func _executed(error, entry):
	emit_signal("executed", error, entry)


func _move_request(to_directory : String):
	emit_signal("move_request", to_directory)
