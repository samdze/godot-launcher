extends Control
class_name App

# Emit this signal when you want to change the top and bottom bars visibility
signal bars_visibility_change_requested(show_top_bar, show_bottom_bar)
# Emit this signal when you want to change the top bar title
signal title_change_requested(title)
# Emit this signal when you want to change the launcher mode to opaque or transparent
signal mode_change_requested(mode)


func _ready():
	
	pass


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		_destroy()


# Enables the propagation of signals emitted by "app" using signals of this App.
# Useful when you instance Apps inside another App instead of adding them to the App stack.
func enable_signals_proxy(app : App, signals : Array = ["bars_visibility_change_requested", "title_change_requested", "mode_change_requested"]):
	for s in signals:
		match s:
			"bars_visibility_change_requested":
				# 2 arguments signals
				if not app.is_connected(s, self, "_emit_proxied_signal_2"):
					app.connect(s, self, "_emit_proxied_signal_2", [s])
			"title_change_requested", "mode_change_requested":
				# 1 argument signals
				if not app.is_connected(s, self, "_emit_proxied_signal_1"):
					app.connect(s, self, "_emit_proxied_signal_1", [s])


# Disables previously enabled signals propagation for "app".
func disable_signals_proxy(app : App, signals : Array = ["bars_visibility_change_requested", "title_change_requested", "mode_change_requested"]):
	for s in signals:
		match s:
			"bars_visibility_change_requested":
				# 2 arguments signals
				if app.is_connected(s, self, "_emit_proxied_signal_2"):
					app.disconnect(s, self, "_emit_proxied_signal_2")
			"title_change_requested", "mode_change_requested":
				# 1 argument signals
				if app.is_connected(s, self, "_emit_proxied_signal_1"):
					app.disconnect(s, self, "_emit_proxied_signal_1")


# Returns whether signal propagation is enabled for "signal_name" of "app".
func is_signal_proxy_enabled(app : App, signal_name : String) -> bool:
	match signal_name:
		"bars_visibility_change_requested":
			return app.is_connected(signal_name, self, "_emit_proxied_signal_2")
		"title_change_requested", "mode_change_requested":
			return app.is_connected(signal_name, self, "_emit_proxied_signal_1")
	return false


func _emit_proxied_signal_1(arg1, signal_name):
	emit_signal(signal_name, arg1)


func _emit_proxied_signal_2(arg1, arg2, signal_name):
	emit_signal(signal_name, arg1, arg2)


# Called when the App gains focus, setup the App here.
# Signals like bars_visibility_change_requested and title_change_requested are best called here.
func _focus():
#	emit_signal("bars_visibility_change_requested", true, true)
#	emit_signal("title_change_requested", "My Custom App")
#	emit_signal("mode_change_requested", LauncherUI.Mode.OPAQUE)
	pass


# Called when the App loses focus
func _unfocus():
	
	pass


# Called when the App is focuses and receives an input.
# Override this function instead of _input to receive global events.
func _app_input(event : InputEvent):
	
	pass


# Called when the App is about to be destroyed and freed from memory.
# Do your cleanup here if needed.
func _destroy():
	
	pass


# Called when the active window changes name
func _window_name_changed(name : String):
	
	pass


# Called when another window becomes active
func _active_window_changed(window_id : int):
	
	pass


# Override this function to give this App a name for the modules system
static func _get_component_name():
	return "Default App"


# Override this function to give this App tags for the modules system
static func _get_component_tags():
	return []


# Override this function to expose user-editable settings to the Settings App
static func _get_exported_settings():
	return []


static func _get_component_type():
	return Component.Type.APP