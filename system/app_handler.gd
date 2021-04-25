extends VBoxContainer
class_name AppHandler

signal app_changed(old_app, new_app)
signal bars_visibility_change_requested(show_top_bar, show_bottom_bar)
signal title_change_requested(title)
signal mode_change_requested(mode)

var apps_stack = []
var focused = false

onready var top_spacer = $TopSpacer
onready var bottom_spacer = $BottomSpacer
onready var container = $Container



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
	_clear_apps()
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


func _clear_apps():
	for v in apps_stack:
		v.queue_free()
	apps_stack.clear()


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
		current.disconnect("bars_visibility_change_requested", self, "_bars_visibility_change_requested")
		current.disconnect("mode_change_requested", self, "_mode_change_requested")
	
	for c in container.get_children():
		container.remove_child(c)
	
#	print("[GODOT] Removed previous App from the stack")
	
	if app != null:
		container.add_child(app)
		app.connect("title_change_requested", self, "_title_change_requested")
		app.connect("bars_visibility_change_requested", self, "_bars_visibility_change_requested")
		app.connect("mode_change_requested", self, "_mode_change_requested")
		if focused:
			app._focus()
	
#	print("[GODOT] Added new App in the stack")
	
	emit_signal("app_changed", current, app)


func _title_change_requested(title):
	emit_signal("title_change_requested", title)


func _bars_visibility_change_requested(show_top_bar, show_bottom_bar):
	top_spacer.visible = show_top_bar
	bottom_spacer.visible = show_bottom_bar
	emit_signal("bars_visibility_change_requested", show_top_bar, show_bottom_bar)


func _mode_change_requested(mode):
	emit_signal("mode_change_requested", mode)


func window_name_changed(name):
	if apps_stack.size() > 0:
		apps_stack.back()._window_name_changed(name)


func active_window_changed(window_id):
	if apps_stack.size() > 0:
		print("[GODOT] Giving the activating window to App " + apps_stack.back().name)
		apps_stack.back()._active_window_changed(window_id)
