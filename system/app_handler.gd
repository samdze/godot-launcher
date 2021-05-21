extends Control
class_name AppHandler

signal app_changed(old_app, new_app)
signal window_mode_request(fullscreen)
signal title_change_request(title)
signal display_mode_request(mode)
signal event(name, arguments)

export(NodePath) var app_container

var apps_stack = []
var focused = false

onready var container = get_node(app_container)


func _ready():
	WindowManager.library.connect("active_window_changed", self, "_active_window_changed")
	WindowManager.library.connect("window_mapped", self, "_window_mapped")
	WindowManager.library.connect("window_unmapped", self, "_window_unmapped")
	WindowManager.library.connect("window_name_changed", self, "_window_name_changed")


func _input(event):
	if focused:
		apps_stack.back()._app_input(event)


func focus():
	if not focused:
		focused = true
		apps_stack.back()._focus()


func unfocus():
	if focused:
		focused = false
		apps_stack.back()._unfocus()


func set_app(app):
	_clear_apps(false)
	apps_stack.append(app)
	_update_app()


func add_app(app):
	apps_stack.append(app)
	_update_app()


func back_app():
	# Don't remove the last App
	if apps_stack.size() > 1:
		var app = apps_stack.pop_back()
		container.remove_child(app)
		app.queue_free()
		_update_app()


func get_current_app():
	return apps_stack.back() if apps_stack.size() > 0 else null


func clear_apps(keep_first = true):
	_clear_apps(keep_first)
	_update_app()


func _clear_apps(keep_first = true):
	for v in apps_stack:
		if not keep_first or v != apps_stack.front():
			v.queue_free()
	var first = null
	if keep_first:
		first = apps_stack.front() if apps_stack.size() > 0 else null
	apps_stack.clear()
	if first != null:
		apps_stack.append(first)


func _update_app():
	if apps_stack.size() == 0 and container.get_child_count() == 0:
		return
	
#	print("[GODOT] Checking Apps stack size and current App...")
	var current = container.get_child(0) if container.get_child_count() > 0 else null
	var app = apps_stack.back() if apps_stack.size() > 0 else null
	
	if app == current:
		return
	
#	print("[GODOT] Removing previous App from the stack")
	
	if current != null:
		if focused:
			current._unfocus()
		current.disconnect("title_change_request", self, "_title_change_request")
		current.disconnect("window_mode_request", self, "_window_mode_request")
		current.disconnect("display_mode_request", self, "_display_mode_request")
	
	for c in container.get_children():
		container.remove_child(c)
	
#	print("[GODOT] Removed previous App from the stack")
	
	if app != null:
		container.add_child(app)
		app.connect("title_change_request", self, "_title_change_request")
		app.connect("window_mode_request", self, "_window_mode_request")
		app.connect("display_mode_request", self, "_display_mode_request")
		if focused:
			app._focus()
	
#	print("[GODOT] Added new App in the stack")
	
	emit_signal("app_changed", current, app)


func _event(name, arguments):
	# The App Handler passes events to the currently active App.
	var results = []
	var app = apps_stack.back() if apps_stack.size() > 0 else null
	if app != null:
		var res = app._event(name, arguments)
		if res != null:
			if res is Array:
				results += res
			else:
				results.append(res)
	
	return results


func _title_change_request(title):
	emit_signal("title_change_request", title)


func _window_mode_request(fullscreen):
	emit_signal("window_mode_request", fullscreen)


func _display_mode_request(mode):
	emit_signal("display_mode_request", mode)


func _window_name_changed(window_id, name):
	if window_id == WindowManager.library.get_active_window() and apps_stack.size() > 0:
		apps_stack.back()._window_name_changed(name)


func _window_mapped(window_id):
	pass


func _window_unmapped(window_id):
	pass


func _active_window_changed(window_id):
	if apps_stack.size() > 0:
		print("[GODOT] Giving the activating window to App " + apps_stack.back().name)
		apps_stack.back()._active_window_changed(window_id)
