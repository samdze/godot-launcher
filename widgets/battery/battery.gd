extends Widget

export(Texture) var charging_texture
export(Texture) var battery_texture
export(Vector2) var atlas_cell_size = Vector2(18, 18)


func _ready():
	_update_status()


func _update_status():
	var percentage = OS.get_power_percent_left()
	var plugged = OS.get_power_state() == OS.POWERSTATE_NO_BATTERY or OS.get_power_state() == OS.POWERSTATE_CHARGED or OS.get_power_state() == OS.POWERSTATE_CHARGING
	
	var texture = charging_texture if plugged else battery_texture
	
	var y = 0
	
	if percentage >= 85:
		y = atlas_cell_size.y * 8
	elif percentage >= 70:
		y = atlas_cell_size.y * 7
	elif percentage >= 60:
		y = atlas_cell_size.y * 6
	elif percentage >= 45:
		y = atlas_cell_size.y * 5
	elif percentage >= 30:
		y = atlas_cell_size.y * 4
	elif percentage >= 15:
		y = atlas_cell_size.y * 3
	elif percentage >= 5:
		y = atlas_cell_size.y * 2
	elif percentage >= 3:
		y = atlas_cell_size.y
	
	if icon.region.position.y != y or icon.atlas != texture:
		icon.atlas = texture
		icon.region.position.y = y
		update()
