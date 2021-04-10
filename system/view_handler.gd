extends VBoxContainer
class_name ViewHandler

signal view_changed(old_view, new_view)
signal bars_visibility_change_requested(show_top_bar, show_bottom_bar)
signal title_change_requested(title)
signal mode_change_requested(mode)

var views_stack = []
var focused = false

onready var top_spacer = $TopSpacer
onready var bottom_spacer = $BottomSpacer
onready var container = $Container



func _input(event):
	if focused:
		views_stack.back()._view_input(event)


func focus():
	if not focused:
		focused = true
		views_stack.back()._focus()


func unfocus():
	if focused:
		focused = false
		views_stack.back()._unfocus()


func set_view(view):
	_clear_views()
	views_stack.append(view)
	_update_view()


func add_view(view):
	views_stack.append(view)
	_update_view()


func back_view():
	# Don't remove the last view
	if views_stack.size() > 1:
		var view = views_stack.pop_back()
		container.remove_child(view)
		view.queue_free()
		_update_view()


func get_current_view():
	return views_stack.back() if views_stack.size() > 0 else null


func _clear_views():
	for v in views_stack:
		v.queue_free()
	views_stack.clear()


func _update_view():
	if views_stack.size() == 0 and container.get_child_count() == 0:
		return
	
	print("[GODOT] Checking views stack size and current view...")
	var current = container.get_child(0) if container.get_child_count() > 0 else null
	var view = views_stack.back() if views_stack.size() > 0 else null
	
	if view == current:
		return
	
	print("[GODOT] Removing previous view from the stack")
	
	if current != null:
		if focused:
			current._unfocus()
		current.disconnect("title_change_requested", self, "_title_change_requested")
		current.disconnect("bars_visibility_change_requested", self, "_bars_visibility_change_requested")
		current.disconnect("mode_change_requested", self, "_mode_change_requested")
	
	for c in container.get_children():
		container.remove_child(c)
	
	print("[GODOT] Removed previous view from the stack")
	
	if view != null:
		container.add_child(view)
		view.connect("title_change_requested", self, "_title_change_requested")
		view.connect("bars_visibility_change_requested", self, "_bars_visibility_change_requested")
		view.connect("mode_change_requested", self, "_mode_change_requested")
		if focused:
			view._focus()
	
	print("[GODOT] Added new view in the stack")
	
	emit_signal("view_changed", current, view)


func _title_change_requested(title):
	emit_signal("title_change_requested", title)


func _bars_visibility_change_requested(show_top_bar, show_bottom_bar):
	top_spacer.visible = show_top_bar
	bottom_spacer.visible = show_bottom_bar
	emit_signal("bars_visibility_change_requested", show_top_bar, show_bottom_bar)


func _mode_change_requested(mode):
	emit_signal("mode_change_requested", mode)


func window_name_changed(name):
	if views_stack.size() > 0:
		views_stack.back()._window_name_changed(name)


func active_window_changed(window_id):
	if views_stack.size() > 0:
		print("[GODOT] Giving the activating window to view " + views_stack.back().name)
		views_stack.back()._active_window_changed(window_id)
