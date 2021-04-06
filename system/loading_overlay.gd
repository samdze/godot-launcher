extends ColorRect
class_name LoadingOverlay

var loading = false


func _ready():
	hide()


func is_loading():
	return loading


func set_loading(value):
	loading = value
	if loading:
		show()
		_start_tween()
	else:
		hide()
		_stop_tween()


func _start_tween():
	$Tween.interpolate_property($CenterContainer/Pivot/Sprite, "rotation_degrees", 0, 360, 4.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()


func _stop_tween():
	$Tween.remove_all()
	$Tween.stop_all()
