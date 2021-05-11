extends Widget

var percentage_regex : RegEx

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
	
	percentage_regex = RegEx.new()
	percentage_regex.compile("\\[(\\d+)%\\]")
	
	_update_status(Settings.get_value("settings/audio_volume"))


func _widget_selected():
	slider.grab_focus()
	Launcher.emit_event("prompts", [
		[BottomBar.ICON_NAV_H, tr("DEFAULT.PROMPT_ADJUST")],
		[BottomBar.ICON_BUTTON_B, tr("DEFAULT.PROMPT_BACK")]
	])


func _controls_gui_input(event : InputEvent, control):
	if event.is_action_pressed("ui_cancel"):
		emit_signal("unfocus_controls_requested")


func _update_status(default = null):
	_value_changed(default if default != null else _get_value())


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


func _get_value() -> int:
	var out = []
	OS.execute("bash", ["-c", "amixer sget Master | grep 'Mono:'"], true, out, false)
	if out.size() > 0:
		var res = percentage_regex.search(out[0])
		if res != null:
			return int(res.get_string(1))
	return 0


func _set_value(value : int) -> int:
	value = clamp(value, 0, 100)
	OS.execute("bash", ["-c", "amixer set Master " + str(value) + "%"], true)
	return value


func _value_changed(value):
	value = _set_value(value)
	Settings.set_value("settings/audio_volume", value)
	
	_update_controls(value)
	_update_icon(value)


func _get_widget_controls():
	return controls


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if controls: controls.queue_free()


static func _get_component_name():
	return "Audio Volume"


static func _get_settings():
	return [
		Setting.create("settings/audio_volume", 50),
	]
