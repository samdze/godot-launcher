extends Button

onready var hotspot_name : Label = $HBoxContainer/Name
onready var quality_icon = $HBoxContainer/QualityIcon
onready var quality = $HBoxContainer/Quality
onready var protection_icon = $HBoxContainer/ProtectionIcon


func _ready():
	connect("focus_entered", self, "_focus_entered")
	connect("focus_exited", self, "_focus_exited")


func _focus_entered():
	var color = get_color("font_color_hover")
	hotspot_name.add_color_override("font_color", color)
	quality_icon.self_modulate = color
	quality.add_color_override("font_color", color)
	protection_icon.self_modulate = color


func _focus_exited():
	var color = get_color("font_color")
	hotspot_name.add_color_override("font_color", color)
	quality_icon.self_modulate = color
	quality.add_color_override("font_color", color)
	protection_icon.self_modulate = color
