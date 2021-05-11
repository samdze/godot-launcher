extends Control
class_name AppHandler

signal app_changed(old_app, new_app)
signal status_visibility_change_requested(show)
signal title_change_requested(title)
signal mode_change_requested(mode)
signal event(name, arguments)

export(NodePath) var widgets_spacer
export(NodePath) var prompts_spacer
export(NodePath) var app_container

var apps_stack = []
var focused = false

onready var top_spacer = get_node(widgets_spacer)
onready var bottom_spacer = get_node(prompts_spacer)
onready var container = get_node(app_container)


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
		current.disconnect("title_change_requested", self, "_title_change_requested")
		current.disconnect("status_visibility_change_requested", self, "_status_visibility_change_requested")
		current.disconnect("mode_change_requested", self, "_mode_change_requested")
	
	for c in container.get_children():
		container.remove_child(c)
	
#	print("[GODOT] Removed previous App from the stack")
	
	if app != null:
		container.add_child(app)
		app.connect("title_change_requested", self, "_title_change_requested")
		app.connect("status_visibility_change_requested", self, "_status_visibility_change_requested")
		app.connect("mode_change_requested", self, "_mode_change_requested")
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


func _title_change_requested(title):
	emit_signal("title_change_requested", title)


func _status_visibility_change_requested(show):
	top_spacer.visible = show
	bottom_spacer.visible = show
	emit_signal("status_visibility_change_requested", show)


func _mode_change_requested(mode):
	emit_signal("mode_change_requested", mode)


func window_name_changed(name):
	if apps_stack.size() > 0:
		apps_stack.back()._window_name_changed(name)


func active_window_changed(window_id):
	if apps_stack.size() > 0:
		print("[GODOT] Giving the activating window to App " + apps_stack.back().name)
		apps_stack.back()._active_window_changed(window_id)
