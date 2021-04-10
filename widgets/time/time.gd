extends Widget

onready var time = $MarginContainer/Time


func _ready():
	_update_status()


func _update_status():
	var date = OS.get_datetime()
	
	time.text = str(date.hour).pad_zeros(2) + ":" + str(date.minute).pad_zeros(2)
	update()
