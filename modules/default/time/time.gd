extends Widget

const weekdays = [
	"Sunday",
	"Monday",
	"Tuesday",
	"Wednesday",
	"Thursday",
	"Friday",
	"Saturday"
]
const months = [
	"",
	"January",
	"February",
	"March",
	"April",
	"May",
	"June",
	"July",
	"August",
	"September",
	"October",
	"November",
	"December"
]

var controls : Control
var label : Label

onready var time = $MarginContainer/Time


func _ready():
	controls = preload("controls.tscn").instance()
	label = controls.get_node("MediumLabel")
	_update_status()


func _update_status():
	var date = OS.get_datetime()
	
	time.text = str(date.hour).pad_zeros(2) + ":" + str(date.minute).pad_zeros(2)
	label.text = weekdays[date.weekday] + " " + months[date.month] + " " + str(date.day) + " " + str(date.year)
	update()


func _get_widget_controls():
	return controls


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if controls: controls.queue_free()
