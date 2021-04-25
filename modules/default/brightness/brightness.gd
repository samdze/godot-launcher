extends Widget

var output

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
	
	_update_status(Config.get_value_or_default("settings", "brightness", null))


func _widget_selected():
	slider.grab_focus()
	Launcher.get_ui().bottom_bar.set_prompts(
		[BottomBar.ICON_NAV_H, BottomBar.PROMPT_ADJUST],
		[BottomBar.ICON_BUTTON_B, BottomBar.PROMPT_BACK])


func _controls_gui_input(event : InputEvent, control):
	if event.is_action_pressed("ui_cancel"):
		emit_signal("unfocus_controls_requested")


func _update_status(default = null):
	_value_changed(default if default != null else _get_value())


func _update_icon(value):
	var y = 0
	var div = 9.0 / 5.0
	
	value = clamp(value - 1, 0, 9)
	y = min(floor(value / div), 4) * atlas_cell_size.y
	
	if icon.region.position.y != y:
		icon.region.position.y = y
		update()


func _update_controls(value):
	slider.value = value
	label.text = str(value)


func _get_value() -> int:
	var out = []
	var result : int = 1
	OS.execute("bash", ["-c", "cat /proc/driver/backlight"], true, out)
	if out.size() > 0:
		result = clamp(int(out[0].strip_edges()), 1, 9)
	return result


func _set_value(value : int) -> int:
	value = clamp(value, 0, 9)
	OS.execute("bash", ["-c", "echo " + str(value) + " > /proc/driver/backlight"])
	return value


func _value_changed(value):
	value = _set_value(value)
	Config.set_value("settings", "brightness", value)
	
	_update_controls(value)
	_update_icon(value)


func _get_widget_controls():
	return controls


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if controls: controls.queue_free()
