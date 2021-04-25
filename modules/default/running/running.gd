extends App

var app_window_id : int 


func _ready():
	pass


func _focus():
	emit_signal("bars_visibility_change_requested", false, false)
	var window = Launcher.get_ui().window_manager.get_active_window()
#	print("[GODOT] Setting app title of window " + str(window) +  "...")
	emit_signal("title_change_requested", Launcher.get_ui().window_manager.get_window_title(window))
#	print("[GODOT] App title set")
	emit_signal("mode_change_requested", LauncherUI.Mode.TRANSPARENT)
	grab_focus()


func _app_input(event : InputEvent):
	
	pass


# Called when the App is about to be destroyed and freed from memory.
# Do your cleanup here if needed.
func _destroy():
	# TODO: kill the window this App is bound to.
	pass


func _window_name_changed(name):
	emit_signal("title_change_requested", name)


func _active_window_changed(window_id):
	if window_id != Launcher.get_ui().window_manager.get_window_id():
		_focus()
	else:
		Launcher.get_ui().app.back_app()


static func _get_component_name():
	return "Running"


static func _get_component_tags():
	return [Component.TAG_RUNNING]
