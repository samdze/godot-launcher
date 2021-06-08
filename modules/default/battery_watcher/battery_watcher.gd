extends Service

var notification_steps = []
var notification_messages = []
var notification_styles = []

var current_step : int = 0

onready var timer = $Timer


func _ready():
	notification_steps = [
		100,
		20,
		10,
		5
	]
	notification_messages = [
		tr("DEFAULT.BATTERY_FULL"),
		tr("DEFAULT.BATTERY_20_REMAINING"),
		tr("DEFAULT.BATTERY_10_REMAINING"),
		tr("DEFAULT.BATTERY_5_REMAINING")
	]
	notification_styles = [
		"success",
		"warning",
		"warning",
		"error"
	]
	
	if OS.get_power_state() != OS.POWERSTATE_UNKNOWN and OS.get_power_state() != OS.POWERSTATE_NO_BATTERY:
		var percentage = OS.get_power_percent_left()
		
		var i = 0
		while i < notification_steps.size():
			if percentage <= notification_steps[i]:
				current_step = i
			i += 1
		
		timer.connect("timeout", self, "_timer_timeout")
		timer.start()


func _timer_timeout():
	var percentage = OS.get_power_percent_left()
	
	var i = 0
	var new_step = -1
	while i < notification_steps.size():
		if percentage < notification_steps[i]:
			new_step = i
		i += 1
	
	if new_step > current_step and current_step >= 0:
		System.emit_event("notification", [notification_messages[new_step], notification_styles[new_step]])
	elif new_step == -1 and current_step == 0 and OS.get_power_state() == OS.POWERSTATE_CHARGED:
		System.emit_event("notification", [notification_messages[0], notification_styles[0]])
	current_step = new_step
	
	if OS.get_power_state() != OS.POWERSTATE_CHARGING and percentage <= 1:
		print("Low battery. Shutting down...")
		OS.execute("bash", ["-c", "sudo shutdown now"], true, [])


# Override this function to check whether this Component can be used on the device
static func _is_available():
	return OS.get_power_state() != OS.POWERSTATE_NO_BATTERY and OS.get_power_state() != OS.POWERSTATE_UNKNOWN


static func _get_component_name():
	return "Battery Watcher"
