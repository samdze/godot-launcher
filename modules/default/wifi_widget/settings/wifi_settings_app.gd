extends App

enum Operation { SCAN, CONNECT }
enum Encryption { OFF, ON }

class NetworkDetails extends Reference:
	var id : int
	var name : String
	var encryption  = Encryption.OFF
	var quality : int
	var password : String

var processing = false
var thread : Thread = null
var semaphore : Semaphore = null
var ssid_regex : RegEx
var encryption_regex : RegEx
var quality_regex: RegEx

var last_focused_hotspot : Control = null
var should_exit = false
var operation = null
var connecting_network : NetworkDetails = null

onready var hotspots_container = $MarginContainer/ScrollContainer/HotspotsContainer


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

# Called when the App gains focus, setup the App here.
# Signals like bars_visibility_change_requested and title_change_requested are best called here.
func _focus():
	emit_signal("status_visibility_change_requested", true)
	emit_signal("title_change_requested", tr("DEFAULT.WIFI_SETTINGS"))
	emit_signal("mode_change_requested", System.Mode.OPAQUE)
	Launcher.emit_event("prompts", [
		[BottomBar.ICON_NAV_V, tr("DEFAULT.PROMPT_NAVIGATION")],
		[BottomBar.ICON_BUTTON_A, tr("DEFAULT.PROMPT_SELECT"), BottomBar.ICON_BUTTON_Y, tr("DEFAULT.PROMPT_SCAN"), BottomBar.ICON_BUTTON_B, tr("DEFAULT.PROMPT_BACK")]
	])
	if last_focused_hotspot != null:
		last_focused_hotspot.grab_focus()


# Called when the App loses focus
func _unfocus():
	
	pass


# Called when the App is focuses and receives an input.
# Override this function instead of _input to receive global events.
func _app_input(event : InputEvent):
	if event.is_action_pressed("ui_cancel") and not processing:
		accept_event()
		Launcher.get_ui().app.back_app()
	if event.is_action_pressed("ui_button_y") and not processing:
		accept_event()
		_scan_hotspots()


func _hotspot_pressed(network_details : NetworkDetails):
	if network_details.encryption == Encryption.OFF:
		network_details.password = ""
		_hotspot_connect_attempt(true, network_details)
	else:
		var keyboard = Modules.get_loaded_component_from_settings("system/keyboard_app").resource.instance()
		keyboard.title = tr("DEFAULT.WIFI_PASSWORD")
		keyboard.connect("text_entered", self, "_password_entered", [network_details])
		Launcher.get_ui().app.add_app(keyboard)


func _password_entered(confirmed, password : String, network_details : NetworkDetails):
	if not confirmed:
		return
	network_details.password = password
	_hotspot_connect_attempt(true, network_details)


func _hotspot_connect_attempt(confirmed, network_details : NetworkDetails):
	if not confirmed:
		return
	processing = true
	Launcher.emit_event("set_loading", [true])
	operation = Operation.CONNECT
	connecting_network = network_details
	
	semaphore.post()


func _hotspot_focused(hotspot : Control):
	last_focused_hotspot = hotspot


func _scan_hotspots():
	processing = true
	Launcher.emit_event("set_loading", [true])
	operation = Operation.SCAN
	semaphore.post()


func _scan_completed(networks_details : Array):
	processing = false
	Launcher.emit_event("set_loading", [false])
	
	for c in hotspots_container.get_children():
		hotspots_container.remove_child(c)
		c.queue_free()
	for n in networks_details:
		var button : Button = preload("hotspot_button.tscn").instance()
		hotspots_container.add_child(button)
		button.hotspot_name.text = n.name
		button.quality.text = str(n.quality) + "%"
		button.protection_icon.visible = n.encryption == Encryption.ON
	
	# Configure the entries
	var i = 0
	for c in hotspots_container.get_children():
		c.connect("pressed", self, "_hotspot_pressed", [networks_details[i]])
		c.connect("focus_entered", self, "_hotspot_focused", [c])
		c.focus_neighbour_left = c.get_path()
		c.focus_neighbour_right = c.get_path()
		if i > 0:
			c.focus_neighbour_top = hotspots_container.get_child(i - 1).get_path()
		else:
			c.focus_neighbour_top = c.get_path()
		if i < hotspots_container.get_child_count() - 1:
			c.focus_neighbour_bottom = hotspots_container.get_child(i + 1).get_path()
		else:
			c.focus_neighbour_bottom = c.get_path()
		i += 1
	
	if hotspots_container.get_child_count() > 0:
		hotspots_container.get_child(0).grab_focus()


func _connection_attempted(result):
	processing = false
	Launcher.emit_event("set_loading", [false])
	print("Connection attempted with result: " + str(result))
	
	if result == 0:
		Launcher.emit_event("notification", [tr("DEFAULT.WIFI_CONNECTION_SUCCESS").format([connecting_network.name]), "success"])
	else:
		Launcher.emit_event("notification", [tr("DEFAULT.WIFI_CONNECTION_FAILED").format([connecting_network.name]), "error"])
	connecting_network = null


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
			
			var networks_amount = output[0].split("\n").size() - 2 if output.size() > 0 else 0
			print("Found " + str(networks_amount) + " networks")
			
			var networks_details = []
			for i in range(networks_amount):
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
						
				var entry : NetworkDetails = NetworkDetails.new()
				entry.id = i
				entry.name = name
				entry.encryption = Encryption.ON if encryption_method != "Off" else Encryption.OFF
				entry.quality = quality
				entry.password = ""
				print("Adding entry: " + str(entry))
				networks_details.append(entry)
				
			print("Final result: " + str(networks_details))
			call_deferred("_scan_completed", networks_details)
		elif operation == Operation.CONNECT:
			var result = -1
			if connecting_network != null:
				if not connecting_network.password.empty():
					OS.execute("bash", ["-c", "wicd-cli -y -n " + str(connecting_network.id) + " -p apsk -s " +  connecting_network.password], true, output, true)
					print("Set password property: " + str(output))
				if connecting_network.id >= 0:
					result = OS.execute("bash", ["-c", "wicd-cli -y -n " + str(connecting_network.id) + " -c"], true, output, true)
					print("Connection attempt: " + str(output))
			
			call_deferred("_connection_attempted", result)


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		should_exit = true
		semaphore.post()
		thread.wait_to_finish()
