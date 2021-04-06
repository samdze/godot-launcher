extends VBoxContainer
class_name ViewHandler

signal view_changed(show_top_bar, show_bottom_bar)

var views_stack = []

onready var top_spacer = $TopSpacer
onready var bottom_spacer = $BottomSpacer
onready var container = $Container



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
	
	var current = container.get_child(0) if container.get_child_count() > 0 else null
	var view = views_stack.back() if views_stack.size() > 0 else null
	
	if view == current:
		return
	
	for c in container.get_children():
		container.remove_child(c)
	
	top_spacer.visible = view.show_top_bar
	bottom_spacer.visible = view.show_bottom_bar
	
	if current != null:
		current._unfocus()
	
	if view != null:
		container.add_child(view)
		view._focus()
	
	emit_signal("view_changed", view.show_top_bar if view != null else true, view.show_bottom_bar if view != null else true)


func active_window_changed(window_id):
	if views_stack.size() > 0:
		views_stack.back()._active_window_changed(window_id)
		if window_id == Launcher.get_ui().window_manager.get_window_id():
			views_stack.back()._focus()
