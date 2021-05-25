extends Control
class_name Launcher

enum Mode { OPAQUE, TRANSPARENT }

var mode = Mode.OPAQUE setget _set_mode
var fullscreen = true

var desktop : Desktop
var app : AppHandler
var first_app : PackedScene

onready var services_container : Node = $Services
onready var background : Panel = $BackgroundLayer/Background
onready var tween : Tween = $Tween


func _ready():
	# Configure the launcher for testing
	if OS.has_feature("x86_64"):
#		OS.window_resizable = true
		
		var ev = InputEventKey.new()
		ev.pressed = true
		ev.scancode = KEY_SLASH
		InputMap.action_add_event("ui_home", ev)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Create loaded services
	var services = Modules.get_loaded_components(Component.Type.SERVICE)
	for s in services:
		var service = s.resource.instance()
		if service != null:
			services_container.add_child(service)
	
	desktop = Modules.get_loaded_component_from_settings("system/desktop").resource.instance()
	first_app = Modules.get_loaded_component_from_settings("system/launcher_app").resource
	
	# Listen to Desktop signals, when you want to close or kill an app
	add_child(desktop)
	desktop.connect("open_request", self, "_status_open_request")
	desktop.connect("close_request", self, "_status_close_request")
	desktop.connect("home_request", self, "_desktop_home_request", [], CONNECT_DEFERRED)
	desktop.free_space()
	
	# Listen to the App Handler signals, when Apps want to change the title or the bars visibility
	app = desktop.get_app_handler()
	app.connect("title_change_request", self, "_title_change_request")
	app.connect("window_mode_request", self, "_window_mode_request")
	app.connect("display_mode_request", self, "_display_mode_request")
	
	app.add_app(first_app.instance())
	app.focus()


func get_desktop() -> Desktop:
	return desktop


func get_app_handler() -> AppHandler:
	return app


func get_services() -> Array:
	return services_container.get_children()


func is_fullscreen():
	return 


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


func _status_open_request():
	app.unfocus()
	
	if fullscreen:
		desktop.open()
	desktop.enable()
	
	WindowManager.library.give_focus(WindowManager.library.get_window_id(), true)
#	WindowManager.library.raise_window(WindowManager.library.get_window_id())


func _status_close_request():
	app.focus()
	
	desktop.disable()
	if fullscreen:
		desktop.close()
	
	WindowManager.library.give_focus(WindowManager.library.get_active_window(), false)


func _desktop_home_request():
	# Can't close the launcher itself
	app.clear_apps(true)


#func _window_mapped(window_id):
#	var stack = WindowManager.library.get_windows_stack()
#	var stack_string = ""
#	for w in stack:
#		stack_string += str(w)+"; "
#
#	print("[GODOT] Window mapped event: "+str(window_id) + ", stack: "+stack_string)
#
#
#func _window_unmapped(window_id):
#	var stack = WindowManager.library.get_windows_stack()
#	var stack_string = ""
#	for w in stack:
#		stack_string += str(w)+"; "
#	print("[GODOT] Window unmapped event: "+str(window_id) + ", stack: "+stack_string)


#func _window_name_changed(window_id, name):
#	if window_id == WindowManager.library.get_active_window():
#		app.window_name_changed(name)


#func _active_window_changed(window_id):
#	print("[GODOT] Activating a new window: " + str(window_id))
#	app.active_window_changed(window_id)
#
#	# TODO: debug stuff, to remove
#	var stack = WindowManager.library.get_windows_stack()
#	var stack_string = ""
#	for w in stack:
#		stack_string += str(w)+"; "
#
#	print("[GODOT] Active window changed event: "+str(window_id) + ", stack: "+stack_string)


func _title_change_request(title):
	desktop.set_title(title)


func _window_mode_request(fullscreen):
	self.fullscreen = fullscreen
	if fullscreen:
		desktop.free_space()
		desktop.close()
	else:
		desktop.take_space()
		desktop.open()


func _display_mode_request(mode):
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
	if desktop != null:
		var res = desktop._event(name, arguments)
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
		Setting.create("system/desktop", "default/desktop"),
		Setting.create("system/launcher_app", "default/welcome_setup"),
		Setting.create("system/settings_app", "default/settings"),
		Setting.create("system/keyboard_app", "default/keyboard"),
		Setting.create("system/language", "en"),
		Setting.create("system/theme", "default/light_theme"),
		Setting.create("system/about", "default/about")
	]
