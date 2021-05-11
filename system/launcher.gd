extends Control
class_name System

enum Mode { OPAQUE, TRANSPARENT }

export(int, 30, 600) var standby_time = 300

var mode = Mode.OPAQUE setget _set_mode
var status_showing = false

var status
var first_app : PackedScene

onready var services_container : Node = $Services
onready var app : AppHandler = $App
onready var background : Panel = $BackgroundLayer/Background
onready var tween : Tween = $Tween


func _ready():
	# Configure the launcher for testing
	if OS.has_feature("x86_64"):
		var ev = InputEventKey.new()
		ev.pressed = true
		ev.scancode = KEY_SLASH
		InputMap.action_add_event("alt_start", ev)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	WindowManager.library.connect("active_window_changed", self, "_active_window_changed")
	WindowManager.library.connect("window_mapped", self, "_window_mapped")
	WindowManager.library.connect("window_unmapped", self, "_window_unmapped")
	WindowManager.library.connect("window_name_changed", self, "_window_name_changed")
	
	WindowManager.library.start()
	
	# Create loaded services
	var services = Modules.get_loaded_components(Component.Type.SERVICE)
	for s in services:
		var service = s.resource.instance()
		if service != null:
			services_container.add_child(service)
	
	status = Modules.get_loaded_component_from_settings("system/status").resource.instance()
	first_app = Modules.get_loaded_component_from_settings("system/launcher_app").resource
	
	# Listen to Status signals, when you want to close or kill an app
	add_child(status)
	status.connect("open_requested", self, "_status_open_requested")
	status.connect("close_requested", self, "_status_close_requested")
	status.connect("home_requested", self, "_status_home_requested", [], CONNECT_DEFERRED)
	
	# Listen to the App Handler signals, when Apps want to change the title or the bars visibility
	app.connect("title_change_requested", self, "_title_change_requested")
	app.connect("status_visibility_change_requested", self, "_status_visibility_change_requested")
	app.connect("mode_change_requested", self, "_mode_change_requested")
	
	app.add_app(first_app.instance())
	app.focus()


func _set_mode(value):
	mode = value
	match value:
		Mode.OPAQUE:
			print("Switching to OPAQUE mode.")
			var root = get_tree().root
			root.transparent_bg = false
			background.show()
		Mode.TRANSPARENT:
			print("Switching to TRANSPARENT mode.")
			var root = get_tree().root
			root.transparent_bg = true
			background.hide()
#	update()
#	overlay_container.update()
#	get_tree()


func _status_open_requested():
	# TODO: could check if widgets can be opened, e.g. with a request to the current App
	app.unfocus()
	
	if not status_showing:
		status.open()
	status.enable()
	
	WindowManager.library.give_focus(WindowManager.library.get_window_id(), true)
#	WindowManager.library.raise_window(WindowManager.library.get_window_id())


func _status_close_requested():
	app.focus()
	
	status.disable()
	if not status_showing:
		status.close()
	
	WindowManager.library.give_focus(WindowManager.library.get_active_window(), false)


func _status_home_requested():
	# Can't close the launcher itself
	app.clear_apps(true)
#	if active_app_window_id != WindowManager.library.get_window_id():
#		#WindowManager.library.give_focus(WindowManager.library.get_active_window())
#		print("[GODOT] Trying to kill window " + str(active_app_window_id))
#		WindowManager.library.kill_window(active_app_window_id)


func _window_mapped(window_id):
	var stack = WindowManager.library.get_windows_stack()
	var stack_string = ""
	for w in stack:
		stack_string += str(w)+"; "
	
	print("[GODOT] Window mapped event: "+str(window_id) + ", stack: "+stack_string)


func _window_unmapped(window_id):
	var stack = WindowManager.library.get_windows_stack()
	var stack_string = ""
	for w in stack:
		stack_string += str(w)+"; "
	print("[GODOT] Window unmapped event: "+str(window_id) + ", stack: "+stack_string)


func _window_name_changed(window_id, name):
	if window_id == WindowManager.library.get_active_window():
		app.window_name_changed(name)


func _active_window_changed(window_id):
	print("[GODOT] Activating a new window: " + str(window_id))
	app.active_window_changed(window_id)
#
#	# TODO: debug stuff, to remove
#	var stack = WindowManager.library.get_windows_stack()
#	var stack_string = ""
#	for w in stack:
#		stack_string += str(w)+"; "
#
#	print("[GODOT] Active window changed event: "+str(window_id) + ", stack: "+stack_string)


func _title_change_requested(title):
	status.set_title(title)
	print("Set status title to " + title)


func _status_visibility_change_requested(show):
	status_showing = show
	if show:
		status.open()
	else:
		status.close()


func _mode_change_requested(mode):
	if mode != self.mode:
		_set_mode(mode)


func emit_event(name, arguments = []):
	# Results are added one by one if an array is returned.
	var results = []
	for s in services_container.get_children():
		var res = s._event(name, arguments)
		if res != null:
			if res is Array:
				results += res
			else:
				results.append(res)
	if status != null:
		var res = status._event(name, arguments)
		if res != null:
			if res is Array:
				results += res
			else:
				results.append(res)
	if app != null:
		var res = app._event(name, arguments)
		if res != null:
			if res is Array:
				results += res
			else:
				results.append(res)
	return results


static func _get_settings():
	return [
		Setting.create("system/status", "default/status"),
		Setting.create("system/launcher_app", "default/launcher"),
		Setting.create("system/settings_app", "default/settings"),
		Setting.create("system/keyboard_app", "default/keyboard"),
		Setting.create("system/language", "en"),
		Setting.create("system/theme", "default/light_theme"),
		Setting.create("system/about", "default/about")
	]
