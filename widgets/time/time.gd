extends MarginContainer



func _ready():
	$Time.add_font_override("font", $Time.get_font("medium_font"))
	_update_status()


func _update_status():
	var date = OS.get_datetime()
	
	$Time.text = str(date.hour).pad_zeros(2) + ":" + str(date.minute).pad_zeros(2)
	update()
