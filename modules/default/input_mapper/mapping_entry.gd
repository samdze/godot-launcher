extends Control

signal started_listening()
signal event_received(event)

onready var name_label = $EditorsContainer/LabelContainer/Label
onready var mapping_button : Button = $EditorsContainer/Mapping


func _ready():
	name_label.add_color_override("font_color", get_color("font_color", "Button"))
	connect("focus_entered", self, "focus")
	connect("focus_exited", self, "unfocus")
#	mapping_button.connect("toggled", self, "_toggled")


func focus():
	add_stylebox_override("panel", get_stylebox("focus"))
	name_label.add_color_override("font_color", get_color("font_color_hover", "Button"))


func unfocus():
	add_stylebox_override("panel", null)
	name_label.add_color_override("font_color", get_color("font_color", "Button"))
	mapping_button.pressed = false


func _gui_input(event):
	if mapping_button.pressed:
		# Event checking and emit signal
		if event.is_pressed() and not event.is_echo() and (event is InputEventKey or event is InputEventJoypadButton):
			mapping_button.pressed = false
			focus()
			emit_signal("event_received", event)
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		unfocus()
		mapping_button.pressed = true
		emit_signal("started_listening")
		accept_event()
