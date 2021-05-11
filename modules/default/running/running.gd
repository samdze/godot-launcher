extends App

var app_window_id : int 
var running_app : PackedScene


func _ready():
	running_app = Modules.get_loaded_component_from_settings("system/running_app").resource


func _focus():
	emit_signal("status_visibility_change_requested", false)
	var window = WindowManager.library.get_active_window()
#	print("[GODOT] Setting app title of window " + str(window) +  "...")
	emit_signal("title_change_requested", WindowManager.library.get_window_title(window))
	print("[GODOT] App title set")
	emit_signal("mode_change_requested", System.Mode.TRANSPARENT)
	grab_focus()


func _app_input(event : InputEvent):
	
	pass


# Called when the App is about to be destroyed and freed from memory.
# Do your cleanup here if needed.
func _destroy():
	# TODO: kill the window this App is bound to.
	print("Running app closing: " + str(app_window_id))
	WindowManager.library.kill_window(app_window_id)


func _window_name_changed(name):
	emit_signal("title_change_requested", name)


func _active_window_changed(window_id):
	print("Running App: active window changed")
	if window_id != WindowManager.library.get_window_id() and window_id != app_window_id:
		var running_instance = running_app.instance()
		running_instance.app_window_id = window_id
		Launcher.get_ui().app.add_app(running_instance)
#		_focus()
	elif window_id == WindowManager.library.get_window_id():
		Launcher.get_ui().app.back_app()
#	else:
#		Launcher.get_ui().app.back_app()


static func _get_component_name():
	return "Running"


static func _get_component_tags():
	return [Component.TAG_RUNNING]
