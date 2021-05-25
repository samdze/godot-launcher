extends Control

signal step_completed(succeeded)

const welcome_strings = ["Welcome", "Bienvenidos", "Bienvenu", "ようこそ", "Benvenuto", "Willkommen", "欢迎", "Добро пожаловать"]

var string_index = 0

onready var welcome_label = $Center/VBoxContainer/Welcome
onready var press_icon = $Center/VBoxContainer/ButtonPress
onready var tween = $Tween


func enable():
	show()
	welcome_label.modulate.a = 0
	press_icon.modulate.a = 0
	
	tween.interpolate_callback(self, 1.0, "_welcome_next_string")
	tween.interpolate_property(press_icon, "modulate:a", press_icon.modulate.a, 1, 0.4, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 1.0)
	tween.start()
	
	grab_focus()


func disable():
	tween.remove_all()
	hide()


func _welcome_next_string():
	welcome_label.text = welcome_strings[string_index]
	tween.interpolate_property(welcome_label, "modulate:a", welcome_label.modulate.a, 1, 0.4, Tween.TRANS_LINEAR)
	tween.interpolate_property(welcome_label, "modulate:a", 1, 0, 0.4, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 1.8)
	tween.interpolate_callback(self, 2.4, "_welcome_next_string")
	tween.start()
	
	string_index += 1
	if string_index >= welcome_strings.size():
		string_index = 0


func _gui_input(event):
	if event.is_pressed():
		accept_event()
		emit_signal("step_completed", true)
