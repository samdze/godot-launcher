extends Control

onready var button = $Button
onready var tween = $Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	tween.interpolate_property(button, "rect_position:y", button.rect_position.y, 3, 0.4, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0)
	tween.interpolate_property(button, "rect_position:y", 3, 0, 0.4, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.4)
	tween.start()
