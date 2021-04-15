extends Widget

var thread
var mutex
var sound_semaphore

var running
var output = []
var percentage_regex : RegEx

var controls
var slider : HSlider
var label : Label

export(Vector2) var atlas_cell_size = Vector2(18, 18)


func _ready():
	controls = preload("controls.tscn").instance()
	slider = controls.get_node("HSlider")
	slider.connect("value_changed", self, "_value_changed")
	slider.connect("gui_input", self, "_controls_gui_input", [slider])
	label = controls.get_node("MediumLabel")
	
	running = true
	percentage_regex = RegEx.new()
	percentage_regex.compile("\\[(\\d+)%\\]")
	
	mutex = Mutex.new()
	sound_semaphore = Semaphore.new()
	
	thread = Thread.new()
	thread.start(self, "_sound_thread_func")
	
	_update_status()


func _widget_selected():
	slider.grab_focus()


func _controls_gui_input(event : InputEvent, control):
	if event.is_action_pressed("ui_cancel"):
		emit_signal("unfocus_controls_requested")


func _update_status():
	if mutex.try_lock() == OK:
		var sound_status = output.duplicate()
		mutex.unlock()
		
		var percentage = 0
		var hotspot = null
		if sound_status.size() > 0:
			percentage = int(sound_status[0])
		
		_update_icon(percentage)
		_update_controls(percentage)
		sound_semaphore.post()


func _update_icon(percentage):
	var y = 0
	if percentage >= 0:
		y = min(floor(percentage / 33.3) + 1, 3) * atlas_cell_size.y
	
	if icon.region.position.y != y:
		icon.region.position.y = y
		update()


func _update_controls(percentage):
	print("SOUND: updating controls with "+str(percentage))
	slider.value = percentage
	# Rounding the value to the nearest multiple of 5.
	label.text = str(int((percentage + 2.5) / 5) * 5) + "%"


func _sound_thread_func(args):
	while true:
		sound_semaphore.wait()
		
		mutex.lock()
		var should_exit = not running
		mutex.unlock()
		
		if should_exit:
			break
		
		mutex.lock()
		output = []
#		OS.execute("bash", ["-c", "\"amixer sget Master | grep 'Mono:' | awk -F'[][]' '{ print $2 }'\""], true, output, false)
#		OS.execute("amixer", ["\"sget Master | grep 'Mono:' | awk -F'[][]' '{ print $2 }'\""], true, output, false)
#		OS.execute("amixer", ["sget Master | grep 'Mono:'"], true, output, false)
		OS.execute("bash", ["-c", "amixer sget Master | grep 'Mono:'"], true, output, false)
		print("Sound GET command output is: "+str(output))
		if output.size() > 0:
			var res = percentage_regex.search(output[0])
			if res != null:
				output[0] = res.get_string(1)
		print("Sound after processing is: "+str(output))
		# Output now should be a number representing the volume percentage.
		mutex.unlock()


func _value_changed(value):
	mutex.lock()
#	print("SOUND: trying to set to " + str(value))
	OS.execute("bash", ["-c", "amixer set Master " + str(value) + "%"], true)
#	print("Sound SET command output is: "+str(output))
	_update_controls(value)
	_update_icon(value)
	mutex.unlock()


func _exit_tree():
	mutex.lock()
	running = false
	mutex.unlock()

	sound_semaphore.post()

	thread.wait_to_finish()


func _get_widget_controls():
	return controls


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if controls: controls.queue_free()
