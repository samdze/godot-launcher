extends Control

signal step_completed(succeeded)

const config_strings = ["Configuration", "Configuración", "セットアップ", "Configurazione", "Konfiguration", "设置", "Конфигурация"]

onready var config_label = $Header/LargeLabel
onready var tween = $Tween

var string_index = 0


func enable():
	show()
	config_label.modulate.a = 0
	
	_config_next_string()


func disable():
	tween.remove_all()
	hide()


func _config_next_string():
	config_label.text = config_strings[string_index]
	tween.interpolate_property(config_label, "modulate:a", config_label.modulate.a, 1, 0.4, Tween.TRANS_LINEAR)
	tween.interpolate_property(config_label, "modulate:a", 1, 0, 0.4, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 1.8)
	tween.interpolate_callback(self, 2.4, "_config_next_string")
	tween.start()
	
	string_index += 1
	if string_index >= config_strings.size():
		string_index = 0
