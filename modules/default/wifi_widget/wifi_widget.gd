extends Widget

var thread
var mutex
var wifi_semaphore

var running
var output = []

var controls : Control
var label : Label

export(Vector2) var atlas_cell_size = Vector2(18, 18)


func _ready():
	controls = preload("controls.tscn").instance()
	label = controls.get_node("MediumLabel")
	
	running = true
	
	mutex = Mutex.new()
	wifi_semaphore = Semaphore.new()
	
	thread = Thread.new()
	thread.start(self, "_wifi_thread_func")
	
	_update_status()


func _update_status():
	if mutex.try_lock() == OK:
		var wifi_status = output.duplicate()
		mutex.unlock()
		
		if wifi_status.size() > 0:
			wifi_status = wifi_status[0].split("\n")
		
		var percentage = -1
		var hotspot = null
		var ip = null
		if wifi_status.size() >= 12:
			percentage = int(wifi_status[6].split("\"")[1])
			hotspot = wifi_status[5].split("\"")[1]
			ip = wifi_status[4].split("\"")[1]
		
		_update_icon(percentage)
		_update_controls(hotspot, ip)
		wifi_semaphore.post()


func _update_icon(percentage):
	var y = 0
	if percentage >= 0:
		y = atlas_cell_size.y + min(floor(percentage / 25), 3) * atlas_cell_size.y
	
	if icon.region.position.y != y:
		icon.region.position.y = y
		update()


func _update_controls(hotspot, ip):
	if hotspot != null and not hotspot.empty():
		label.text = tr("DEFAULT.WIFI_CONNECTED").format([hotspot]) + "\n" + ip 
	else:
		label.text = tr("DEFAULT.WIFI_DISCONNECTED")


func _wifi_thread_func(args):
	while true:
		wifi_semaphore.wait()
		
		mutex.lock()
		var should_exit = not running
		mutex.unlock()
		
		if should_exit:
			break
		
		mutex.lock()
		output = []
#		OS.execute("bash", ["-c", "wicd-cli --status | grep %"], true, output, false)
		OS.execute("bash", ["-c", "dbus-send --system --type=method_call --print-reply --dest=org.wicd.daemon /org/wicd/daemon org.wicd.daemon.GetConnectionStatus"], true, output, false)
		# Output now should be an array of lines, something like:
		#[method return time=1613172987.342963 sender=:1.6 -> destination=:1.28 serial=232 reply_serial=2
		#	struct {
		#		uint32 2
		#		array [
		#			string "192.168.1.17"		# Local ip
		#			string "VodafoneHome"		# Hotspot name
		#			string "97"					# Strength percentage
		#			string "0"
		#			string "72.2 Mb/s"			# Approximate speed?
		#		]
		#	}
		#]
		mutex.unlock()


func _exit_tree():
	mutex.lock()
	running = false
	mutex.unlock()

	wifi_semaphore.post()

	thread.wait_to_finish()


func _get_widget_controls():
	return controls


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if controls: controls.queue_free()


# Override this function to give this Widget a name for the modules system
static func _get_component_name():
	return "Wi-Fi Widget"


# Override this function to give this Widget tags for the modules system
static func _get_component_tags():
	return ["wifi"]


# Override this function to expose user-editable settings to the Settings app
static func _get_settings():
	return [
		Setting.export([], TranslationServer.translate("DEFAULT.WIFI_SETTINGS"), load("res://modules/default/wifi_widget/settings/settings_button.tscn"))
	]
#
#
#static func _init_wifi_settings(control):
#	control.connect("pressed", load("wifi.gd"), "_setting_button_pressed")
#
#
#static func _setting_button_pressed():
#	Launcher.get_ui().app.add_app(preload("settings/wifi_settings_app.tscn").instance())
