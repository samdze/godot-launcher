extends Widget

var controls : Control
var label : Label

export(Texture) var charging_texture
export(Texture) var battery_texture
export(Vector2) var atlas_cell_size = Vector2(18, 18)


func _ready():
	controls = preload("controls.tscn").instance()
	label = controls.get_node("MediumLabel")
	_update_status()


func _update_status():
	var percentage = OS.get_power_percent_left()
	var plugged = OS.get_power_state() == OS.POWERSTATE_NO_BATTERY or OS.get_power_state() == OS.POWERSTATE_CHARGED or OS.get_power_state() == OS.POWERSTATE_CHARGING
	
	label.text = str(percentage) + "%"
	var texture = charging_texture if plugged else battery_texture
	
	var y = 0
	if percentage < 11:
		y = 0
	elif percentage < 22:
		y = atlas_cell_size.y
	elif percentage < 33:
		y = atlas_cell_size.y * 2
	elif percentage < 44:
		y = atlas_cell_size.y * 3
	elif percentage < 55:
		y = atlas_cell_size.y * 4
	elif percentage < 66:
		y = atlas_cell_size.y * 5
	elif percentage < 77:
		y = atlas_cell_size.y * 6
	elif percentage < 88:
		y = atlas_cell_size.y * 7
	elif percentage <= 100:
		y = atlas_cell_size.y * 8
	
	if icon.region.position.y != y or icon.atlas != texture:
		icon.atlas = texture
		icon.region.position.y = y
		update()


func _get_widget_controls():
	return controls


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if controls: controls.queue_free()


static func _get_component_name():
	return "Battery Widget"
