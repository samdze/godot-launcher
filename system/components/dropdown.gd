extends Button

signal item_selected(item)
signal item_focused(item)

var selected : BaseButton = null

#export(bool) var autoclose = true

onready var label : Label = $Controls/Label
onready var popup : PopupPanel = $PopupPanel
onready var items_container : VBoxContainer = $PopupPanel/ScrollContainer/ItemsContainer
onready var scroll_container : ScrollContainer = $PopupPanel/ScrollContainer


func _ready():
	connect("toggled", self, "_toggled")
	items_container.connect("gui_input", self, "_item_gui_input", [null])
	items_container.focus_neighbour_bottom = items_container.get_path()
	items_container.focus_neighbour_top = items_container.get_path()
	items_container.focus_neighbour_left = items_container.get_path()
	items_container.focus_neighbour_right = items_container.get_path()
	popup.set_as_toplevel(true)


func add_item(item : BaseButton):
	item.connect("pressed", self, "_item_pressed", [item])
	item.connect("gui_input", self, "_item_gui_input", [item])
	items_container.add_child(item)
	item.focus_neighbour_left = item.get_path()
	item.focus_neighbour_right = item.get_path()


func remove_item(item : BaseButton):
	if items_container.is_a_parent_of(item):
		item.disconnect("pressed", self, "_item_pressed")
		item.disconnect("gui_input", self, "_item_gui_input")
		item.focus_neighbour_left = NodePath()
		item.focus_neighbour_right = NodePath()
		items_container.remove_child(item)


func get_items() -> Array:
	return items_container.get_children()


func get_item_count():
	return items_container.get_child_count()


func clear_items():
	for i in items_container.get_children():
		remove_item(i)
		i.queue_free()


func set_selected(item : BaseButton):
	if items_container.is_a_parent_of(item):
		if selected != null:
			selected.pressed = false
		selected = item
		label.text = item.text if item != null else ""
		if popup.visible:
			item.pressed = true
			_item_grab_focus(item)
	elif popup.visible and item == null:
		if items_container.get_child_count() > 0:
			_item_grab_focus(items_container.get_child(0))
		else:
			_container_grab_focus()


func get_selected():
	return selected


func _toggled(button_pressed : bool):
	if button_pressed:
		Launcher.emit_event("prompts", [[BottomBar.ICON_NAV_V, tr("DEFAULT.PROMPT_NAVIGATION")], [BottomBar.ICON_BUTTON_A, tr("DEFAULT.PROMPT_SELECT"), BottomBar.ICON_BUTTON_B, tr("DEFAULT.PROMPT_BACK")]])
		_open_popup()
	else:
		_close_popup()


func _open_popup():
	# Calculate size and open popup
	items_container.notification(Container.NOTIFICATION_SORT_CHILDREN)
	popup.rect_size.x = self.rect_size.x + 2
	var height = items_container.rect_size.y
	var width = items_container.rect_size.x
	var container_rect = _get_nearest_scroll_or_app_global_rect()
	# TODO: include stylebox content margin instead of adding 2
	var popup_height = min(container_rect.size.y, height + scroll_container.margin_top - scroll_container.margin_bottom + 2)
	var popup_width = max(min(container_rect.size.x, width + scroll_container.margin_left - scroll_container.margin_right), self.rect_size.x + 2)
	var scroll_height = popup_height - scroll_container.margin_top + scroll_container.margin_bottom
	var scroll_width = popup_width - scroll_container.margin_left + scroll_container.margin_right
	scroll_container.rect_size.y = scroll_height
	scroll_container.rect_size.x = scroll_width
	
	popup.rect_size.y = popup_height
	popup.rect_size.x = popup_width
	popup.rect_global_position = Vector2(self.rect_global_position.x, self.rect_global_position.y)
	
	var v_off = -max(0, popup.get_global_rect().position.y + popup.get_global_rect().size.y - (container_rect.position.y + container_rect.size.y))
	if v_off == 0:
		v_off = -min(0, popup.get_global_rect().position.y - container_rect.position.y)
	var h_off = -max(0, popup.get_global_rect().position.x + popup.get_global_rect().size.x - (container_rect.position.x + container_rect.size.x))
	if h_off == 0:
		h_off = -min(0, popup.get_global_rect().position.x - container_rect.position.x)
	
	popup.rect_global_position = popup.rect_global_position + Vector2(h_off, v_off)
	popup.show()
	
	call_deferred("set_selected", selected)


func _close_popup():
	pressed = false
	popup.hide()


func _item_pressed(item):
	set_selected(item)
	emit_signal("item_selected", item)


func _item_gui_input(event : InputEvent, item):
	if event.is_action_pressed("ui_down") and item:
		var i = item.get_index() + 1 if item.get_index() < items_container.get_child_count() - 1 else 0
		_item_grab_focus(items_container.get_child(i))
		accept_event()
	if event.is_action_pressed("ui_up") and item:
		var i = item.get_index() - 1 if item.get_index() > 0 else items_container.get_child_count() - 1
		_item_grab_focus(items_container.get_child(i))
		accept_event()
	if event.is_action_pressed("ui_cancel"):
		# Close popup toggling the main button
		emit_signal("toggled", false)
		accept_event()


func _item_grab_focus(item):
	_ensure_visible(item)
	scroll_container.notification(Container.NOTIFICATION_SORT_CHILDREN)
	item.grab_focus()
	emit_signal("item_focused", item)


func _container_grab_focus():
	items_container.grab_focus()
	emit_signal("item_focused", null)


func _ensure_visible(control : Control):
	if is_a_parent_of(control):
		var global_rect = scroll_container.get_global_rect();
		var other_rect = control.get_global_rect();
		var stylebox : StyleBox = scroll_container.get_stylebox("bg")
		var right_margin = stylebox.content_margin_right;
		if scroll_container.get_v_scrollbar().visible:
			right_margin += scroll_container.get_v_scrollbar().get_size().x
		var left_margin = stylebox.content_margin_left;
		
		var bottom_margin = stylebox.content_margin_bottom
		if scroll_container.get_h_scrollbar().visible:
			bottom_margin += scroll_container.get_h_scrollbar().get_size().y
		var top_margin = stylebox.content_margin_top
		
		var diff = max(min(other_rect.position.y - top_margin, global_rect.position.y), other_rect.position.y + other_rect.size.y - global_rect.size.y + bottom_margin);
		scroll_container.scroll_vertical = scroll_container.scroll_vertical + (diff - global_rect.position.y)
		diff = max(min(other_rect.position.x - left_margin, global_rect.position.x), other_rect.position.x + other_rect.size.x - global_rect.size.x + right_margin);
		scroll_container.scroll_horizontal = scroll_container.scroll_horizontal + (diff - global_rect.position.x)


func _get_nearest_scroll_or_app_global_rect() -> Rect2:
	var node = get_parent()
	while node != null and not node is App and not node is ScrollContainer:
		node = node.get_parent()
	if node != null and node is Control:
		return node.get_global_rect()
	return Rect2(Vector2(0, 0), OS.window_size)
