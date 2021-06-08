extends Service

signal scan_completed(hotspots)
signal connection_attempted(hotspot, result)
signal connection_status_changed(status)

enum Operation { NONE, SCAN, CONNECT, STATUS }
enum Encryption { OFF = 0, ON = 1 }

class HotspotDetails extends Reference:
	var id : int
	var name : String
	var encryption  = Encryption.OFF
	var quality : int
	var password : String

var current_status = {
	"connected": false,
	"percentage": -1,
	"hotspot": null,
	"ip": null
}
var thread : Thread = null
var semaphore : Semaphore = null
var ssid_regex : RegEx
var encryption_regex : RegEx
var quality_regex: RegEx

var hotspots = []
var should_exit = false
var operation = Operation.NONE
var connecting_hotspot : HotspotDetails = null

onready var timer = $Timer


func _ready():
	ssid_regex = RegEx.new()
	ssid_regex.compile("Essid:\\s+(.+)\\n")

	encryption_regex = RegEx.new()
	encryption_regex.compile("Encryption Method:\\s+(\\w*)\\n")
	
	quality_regex = RegEx.new()
	quality_regex.compile("Quality:\\s+(\\d*)\\n")
	
	semaphore = Semaphore.new()
	thread = Thread.new()
	thread.start(self, "_thread_function", null)
	
	timer.connect("timeout", self, "_timer_timeout")
	timer.start()


func scan_hotspots() -> int:
	if operation == Operation.NONE or operation == Operation.STATUS:
		operation = Operation.SCAN
		semaphore.post()
		return OK
	return ERR_BUSY


func get_hotspots() -> Array:
	return hotspots


func get_connection_status():
	return current_status


func connect_hotspot(hotspot) -> int:
	if operation == Operation.NONE or operation == Operation.STATUS:
		operation = Operation.CONNECT
		connecting_hotspot = hotspot
		semaphore.post()
		return OK
	return ERR_BUSY


func _scan_completed(hotspots):
	self.hotspots = hotspots
	operation = Operation.NONE
	emit_signal("scan_completed", hotspots)


func _connection_attempted(hotspot, result):
	operation = Operation.NONE
	emit_signal("connection_attempted", hotspot, result)


func _status_updated(status):
	if operation == Operation.STATUS:
		operation = Operation.NONE
	if current_status.connected != status.connected or \
			current_status.percentage != status.percentage or \
			current_status.hotspot != status.hotspot or current_status.ip != status.ip:
		current_status = status
		emit_signal("connection_status_changed", current_status)


func _timer_timeout():
	if operation == Operation.NONE:
		operation = Operation.STATUS
		semaphore.post()


func _thread_function(data):
	var output = []
	
	while not should_exit:
		semaphore.wait()
		if should_exit:
			return
		
		if operation == Operation.SCAN:
			# Scan wireless hotspots and list them
			OS.execute("bash", ["-c", "wicd-cli -ySl"], true, output, true)
			print("List network result: "+ str(output))
			
			var hotspots_amount = output[0].split("\n").size() - 2 if output.size() > 0 else 0
			print("Found " + str(hotspots_amount) + " hotspots")
			
			var hotspots_details = []
			for i in range(hotspots_amount):
				OS.execute("bash", ["-c", "wicd-cli --wireless -n " + str(i) + " -d"], true, output, true)
				print("Network "+str(i) + " details result: " + str(output))
				var name = ""
				var encryption_method = "Off"
				var quality = 0
				
				var output_string = output[0] if output.size() > 0 else ""
				print(output_string)
				
				var res : RegExMatch = ssid_regex.search(output_string)
				if res != null:
					name = res.get_string(1)
				res = encryption_regex.search(output_string)
				if res != null:
					encryption_method = res.get_string(1)
				res = quality_regex.search(output_string)
				if res != null:
					quality = int(res.get_string(1))
						
				var entry : HotspotDetails = HotspotDetails.new()
				entry.id = i
				entry.name = name
				entry.encryption = Encryption.ON if encryption_method != "Off" else Encryption.OFF
				entry.quality = quality
				entry.password = ""
				print("Adding entry: " + str(entry))
				hotspots_details.append(entry)
				
			print("Final result: " + str(hotspots_details))
			call_deferred("_scan_completed", hotspots_details)
		elif operation == Operation.CONNECT:
			var result = -1
			if connecting_hotspot != null:
				if not connecting_hotspot.password.empty():
					OS.execute("bash", ["-c", "wicd-cli -y -n " + str(connecting_hotspot.id) + " -p apsk -s " +  connecting_hotspot.password], true, output, true)
					print("Set password property: " + str(output))
				if connecting_hotspot.id >= 0:
					result = OS.execute("bash", ["-c", "wicd-cli -y -n " + str(connecting_hotspot.id) + " -c"], true, output, true)
					print("Connection attempt: " + str(output))
			
			call_deferred("_connection_attempted", connecting_hotspot, result)
		elif operation == Operation.STATUS:
			output = []
			OS.execute("bash", ["-c", "dbus-send --system --type=method_call --print-reply --dest=org.wicd.daemon /org/wicd/daemon org.wicd.daemon.GetConnectionStatus"], true, output, false)
			# Output now should be an array containing one multiline string, something like:
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
			var wifi_status = {
				"connected": false,
				"percentage": -1,
				"hotspot": null,
				"ip": null
			}
			if output.size() > 0:
				output = output[0].split("\n")
			
			if output.size() >= 12:
				wifi_status.connected = true
				wifi_status.percentage = int(output[6].split("\"")[1])
				wifi_status.hotspot = output[5].split("\"")[1]
				wifi_status.ip = output[4].split("\"")[1]
			call_deferred("_status_updated", wifi_status)


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		should_exit = true
		semaphore.post()
		thread.wait_to_finish()


func _event(name, arguments):
	match name:
		_:
			pass


static func _get_component_name():
	return "Wicd Network"


static func _get_component_tags():
	return ["wifi"]


# Override this function to check whether this Component can be used on the device
static func _is_available():
	return OS.execute("bash", ["-c", "wicd-cli"], true) == 0


static func _get_settings_definitions():
	return []
