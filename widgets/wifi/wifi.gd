extends Widget

export(Vector2) var atlas_cell_size = Vector2(18, 18)

var thread
var mutex
var wifi_semaphore

var running
var output = []

func _ready():
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
		if wifi_status.size() >= 12:
			percentage = int(wifi_status[6].split("\"")[1])
		
		_update_icon(percentage)
		wifi_semaphore.post()


func _update_icon(percentage):
	var y = 0
	if percentage >= 0:
		y = atlas_cell_size.y + min(floor(percentage / 25), 3) * atlas_cell_size.y
	
	if icon.region.position.y != y:
		icon.region.position.y = y
		update()


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
