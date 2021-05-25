extends Control

signal started_listening()
signal event_received(event)

onready var button_icon : TextureRect = $LabelContainer/CenterContainer/Icon
onready var mapping_button : Button = $Mapping
onready var button_label : Label = $Mapping/Label
onready var button_press_icon : TextureRect = $Mapping/ButtonPress


func _ready():
	connect("focus_entered", self, "focus")
	connect("focus_exited", self, "unfocus")
	button_press_icon.modulate = get_color("font_color_hover", "Button")
	button_press_icon.hide()
#	mapping_button.connect("toggled", self, "_toggled")


func focus():
	mapping_button.pressed = true
	button_press_icon.show()
	emit_signal("started_listening")


func unfocus():
	mapping_button.pressed = false
	button_press_icon.hide()


func _gui_input(event):
	if mapping_button.pressed:
		# Event checking and emit signal
		accept_event()
		if event.is_pressed() and not event.is_echo() and (event is InputEventKey or event is InputEventJoypadButton):
			emit_signal("event_received", event)
