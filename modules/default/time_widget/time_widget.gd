extends Widget

var weekdays = []
var months = []

var controls : Control
var label : Label

onready var margin_container = $MarginContainer
onready var time = $MarginContainer/Time


func _ready():
	margin_container.connect("resized", self, "_container_resized")
	_init_strings()
	
	controls = preload("controls.tscn").instance()
	label = controls.get_node("MediumLabel")
	_update_status()
	_container_resized()


func _update_status():
	var date = OS.get_datetime()
	
	time.text = str(date.hour).pad_zeros(2) + ":" + str(date.minute).pad_zeros(2)
	label.text = tr("DEFAULT.TIME_DATE").format({
		"weekday": weekdays[date.weekday],
		"month": months[date.month],
		"day": str(date.day),
		"year": str(date.year)
	})
	update()


func _container_resized():
	rect_min_size = margin_container.rect_size
	rect_size = margin_container.rect_size


func _get_widget_controls():
	return controls


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if controls: controls.queue_free()


func _init_strings():
	weekdays = [
		tr("DEFAULT.TIME_SUNDAY"),
		tr("DEFAULT.TIME_MONDAY"),
		tr("DEFAULT.TIME_TUESDAY"),
		tr("DEFAULT.TIME_WEDNESDAY"),
		tr("DEFAULT.TIME_THURSDAY"),
		tr("DEFAULT.TIME_FRIDAY"),
		tr("DEFAULT.TIME_SATURDAY")
	]
	months = [
		"",
		tr("DEFAULT.TIME_JANUARY"),
		tr("DEFAULT.TIME_FEBRUARY"),
		tr("DEFAULT.TIME_MARCH"),
		tr("DEFAULT.TIME_APRIL"),
		tr("DEFAULT.TIME_MAY"),
		tr("DEFAULT.TIME_JUNE"),
		tr("DEFAULT.TIME_JULY"),
		tr("DEFAULT.TIME_AUGUST"),
		tr("DEFAULT.TIME_SEPTEMBER"),
		tr("DEFAULT.TIME_OCTOBER"),
		tr("DEFAULT.TIME_NOVEMBER"),
		tr("DEFAULT.TIME_DECEMBER")
	]


static func _get_component_name():
	return "Time Widget"
