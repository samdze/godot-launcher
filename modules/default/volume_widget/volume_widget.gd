extends Widget

var controls : Control
var slider : HSlider
var label : Label

export(Vector2) var atlas_cell_size = Vector2(18, 18)


func _ready():
	controls = preload("controls.tscn").instance()
	slider = controls.get_node("HSlider")
	slider.connect("value_changed", self, "_value_changed")
	slider.connect("gui_input", self, "_controls_gui_input", [slider])
	label = controls.get_node("MediumLabel")
	
	_update_status()


func _widget_selected():
	slider.grab_focus()
	System.emit_event("prompts", [
		[Desktop.Input.MOVE_H, tr("DEFAULT.PROMPT_ADJUST")],
		[Desktop.Input.B, tr("DEFAULT.PROMPT_BACK")]
	])


func _controls_gui_input(event : InputEvent, control):
	if event.is_action_pressed("ui_cancel"):
		emit_signal("unfocus_controls_request")


func _update_status(default = null):
	var result = System.emit_event("get_audio_volume")
	var value = 0
	if result.size() > 0:
		value = int(result[0])
	_update_icon(value)
	_update_controls(value)


func _update_icon(percentage):
	var y = 0
	if percentage >= 0:
		y = min(floor(percentage / 33.3) + 1, 3) * atlas_cell_size.y
	
	if icon.region.position.y != y:
		icon.region.position.y = y
		update()


func _update_controls(percentage):
	slider.value = percentage
	# Rounding the value to the nearest multiple of 5.
	label.text = str(int((percentage + 2.5) / 5) * 5) + "%"


func _value_changed(value):
	System.emit_event("set_audio_volume", [value])


func _event(name, arguments):
	match name:
		"audio_volume_changed":
			_update_status()
			return true


func _get_widget_controls():
	return controls


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if controls: controls.queue_free()


static func _get_component_name():
	return "Audio Volume Widget"
