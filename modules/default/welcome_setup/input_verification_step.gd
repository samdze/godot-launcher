extends Control

signal step_completed(succeeded)

const map_entry = preload("button_icon_map_entry.tscn")
const mapping_icons = [
	"button_right", "button_left", "button_up", "button_down", "button_a", "button_b",
	"button_menu", "button_start"
]
const actions_order = [
	"ui_right", "ui_left", "ui_up", "ui_down", "ui_accept", "ui_cancel", 
	"ui_menu", "ui_start"
]

var events_to_entries = {}
var mapping = {}
var error = false

onready var center_container = $CenterContainer
onready var icons_container = $CenterContainer/ButtonsIcons
onready var icons_index = $CenterContainer/IndexContainer/Index
onready var tween = $Tween


func _ready():
	var i = 0
	for action in actions_order:
		var entry = TextureRect.new()
		entry.focus_mode = Control.FOCUS_ALL
		entry.texture = get_icon(mapping_icons[i], "Control")
		entry.modulate = get_color("contrast", "Control")
		entry.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		entry.connect("focus_entered", self, "_icon_focus_entered", [entry])
		entry.connect("gui_input", self, "_icon_gui_input", [entry, action])
		icons_container.add_child(entry)
		
		entry.focus_neighbour_right = entry.get_path()
		entry.focus_neighbour_top = entry.get_path()
		entry.focus_neighbour_left = entry.get_path()
		entry.focus_neighbour_bottom = entry.get_path()
		
		i += 1


func _icon_focus_entered(entry):
	tween.interpolate_property(icons_index, "rect_position:x", icons_index.rect_position.x, entry.rect_position.x, 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.interpolate_property(icons_index, "rect_size", icons_index.rect_size, entry.rect_size, 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()


func _icon_gui_input(event : InputEvent, entry : Control, action):
	if event.is_pressed() and not event.is_echo() and (event is InputEventKey or event is InputEventJoypadButton):
		if event.is_action_pressed(action):
			entry.modulate = get_color("success", "Control")
		else:
			entry.modulate = get_color("error", "Control")
			error = true
		if entry.get_index() >= icons_container.get_child_count() - 1:
			# Completed
			if error:
				emit_signal("step_completed", false)
			else:
				emit_signal("step_completed", true)
		else:
			# Next button icon
			icons_container.get_child(entry.get_index() + 1).grab_focus()
	accept_event()


func enable():
	show()
	error = false
	for i in icons_container.get_children():
		i.modulate = get_color("contrast", "Control")
	center_container.notification(Container.NOTIFICATION_SORT_CHILDREN)
	icons_container.notification(Container.NOTIFICATION_SORT_CHILDREN)
	icons_index.rect_position.x = icons_container.get_child(0).rect_position.x
	icons_index.rect_size = icons_container.get_child(0).rect_size
	icons_container.get_child(0).call_deferred("grab_focus")


func disable():
	if get_focus_owner() != null and is_a_parent_of(get_focus_owner()):
		get_focus_owner().release_focus()
	hide()
