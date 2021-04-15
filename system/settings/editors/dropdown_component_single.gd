extends PanelContainer

signal value_changed(section, key, value)

enum Type { VIEW, WIDGET }

const OptionEntry = preload("dropdown_single_entry.tscn")

export(Type) var type
export(String) var tags

export(StyleBox) var focused_style
export(StyleBox) var default_style

var setting_section : String
var setting_key : String

var options = []
var current_id = ""

onready var select : BaseButton = $HBoxContainer/Value

onready var current : Label = $HBoxContainer/Value/Controls/Label
onready var popup : PopupPanel = $HBoxContainer/Value/PopupPanel
onready var items_container : VBoxContainer = $HBoxContainer/Value/PopupPanel/ScrollContainer/ItemsContainer
onready var scroll_container : ScrollContainer = $HBoxContainer/Value/PopupPanel/ScrollContainer


func _ready():
	var tags_array = tags.split(",")
	print("Tags array: " + str(tags_array))
	var selected_entry = null
	match type:
		Type.VIEW:
			options = Modules.get_loaded_views(tags_array)
			selected_entry = Modules.get_view(Config.get_or_default(setting_section, setting_key, ""))
		Type.WIDGET:
			options = Modules.get_loaded_widgets(tags_array)
			selected_entry = Modules.get_widget(Config.get_or_default(setting_section, setting_key, ""))
	print("Returned components: "+str(options))
	
	add_stylebox_override("panel", default_style)
	connect("focus_entered", self, "_focus_entered")
	connect("focus_exited", self, "_focus_exited")
	connect("gui_input", self, "_gui_input")
	
	popup.set_as_toplevel(true)
	
	select.focus_neighbour_top = select.get_path()
	select.focus_neighbour_bottom = select.get_path()
	select.focus_neighbour_left = select.get_path()
	select.focus_neighbour_right = select.get_path()
	select.connect("toggled", self, "_selection_focus_toggled")
	
	items_container.focus_neighbour_bottom = items_container.get_path()
	items_container.focus_neighbour_top = items_container.get_path()
	items_container.focus_neighbour_left = items_container.get_path()
	items_container.focus_neighbour_right = items_container.get_path()
	items_container.connect("gui_input", self, "_option_gui_input", [null])
	
	current_id = selected_entry["id"] if selected_entry != null else ""
	current.text = (selected_entry["module"].to_upper() + ": " + selected_entry["name"]) if selected_entry != null else ""


func _initialize_setting(section : String, key : String):
	setting_section = section
	setting_key = key


func _focus_entered():
	add_stylebox_override("panel", focused_style)


func _focus_exited():
	add_stylebox_override("panel", default_style)


func _gui_input(event : InputEvent):
	if event.is_action_pressed("ui_accept"):
		select.grab_focus()
		Input.parse_input_event(event)
#		accept_event()


func _selection_focus_toggled(pressed):
	if pressed:
		# Remove current options
		for c in items_container.get_children():
			items_container.remove_child(c)
			c.queue_free()
		for o in options:
			var button = OptionEntry.instance()
			button.data = o["id"]
			button.text = o["module"].to_upper() + ": " + o["name"]
			button.add_stylebox_override("hover", select.get_stylebox("hover"))
			button.add_stylebox_override("pressed", select.get_stylebox("hover"))
			button.add_stylebox_override("focus", select.get_stylebox("focus"))
			button.add_stylebox_override("disabled", select.get_stylebox("disabled"))
			button.add_stylebox_override("normal", select.get_stylebox("normal"))
			button.add_color_override("font_color", current.get_color("font_color"))
			button.add_color_override("font_color_hover", Color(1, 1, 1, 1))
			button.add_color_override("font_color_pressed", Color(1, 1, 1, 1))
			items_container.add_child(button)
		# Configure options
		var i = 0
		for c in items_container.get_children():
			c.connect("pressed", self, "_option_pressed", [c])
			c.connect("gui_input", self, "_option_gui_input", [c])
			c.focus_neighbour_left = c.get_path()
			c.focus_neighbour_right = c.get_path()
#			if i > 0:
#				c.focus_neighbour_top = items_container.get_child(i - 1).get_path()
#			else:
#				c.focus_neighbour_top = items_container.get_child(items_container.get_child_count() - 1).get_path()
#			if i < items_container.get_child_count() - 1:
#				c.focus_neighbour_bottom = items_container.get_child(i + 1).get_path()
#			else:
#				c.focus_neighbour_bottom = items_container.get_child(0).get_path()
			i += 1
		# TODO: move this logic to the dropdown UI component
		# Calculate size and open popup
		items_container.notification(NOTIFICATION_SORT_CHILDREN)
#		scroll_container.notification(NOTIFICATION_SORT_CHILDREN)
		popup.rect_size.x = select.rect_size.x + 2
		var height = items_container.rect_size.y
		var container_rect = _get_nearest_scroll_or_view_global_rect()
		var scroll_height = min(container_rect.size.y, height)
#		scroll_container.rect_size.y = scroll_height
		
		popup.rect_size.y = scroll_height
		popup.rect_global_position = Vector2(select.rect_global_position.x, select.rect_global_position.y)# + select.rect_size.y)
		
		var v_off = -max(0, popup.get_global_rect().position.y + popup.get_global_rect().size.y - (container_rect.position.y + container_rect.size.y))
		if v_off == 0:
			v_off = -min(0, popup.get_global_rect().position.y - container_rect.position.y)
		
		popup.rect_global_position = popup.rect_global_position + Vector2(-1, v_off)
		popup.popup()
#		popup.notification(NOTIFICATION_RESIZED)
#		scroll_container.notification(NOTIFICATION_SORT_CHILDREN)
		# Select the current option
		var current_found = false
		for c in items_container.get_children():
			if c.data == current_id:
				current_found = true
				c.pressed = true
				call_deferred("_option_grab_focus", c)
#				call_deferred("_option_grab_focus", c)
#				c.pressed = true
				break
		if not current_found:
			if items_container.get_child_count() > 0:
				call_deferred("_option_grab_focus", items_container.get_child(0))
			else:
				call_deferred("_items_container_grab_focus")
	else:
		# Close popup
		popup.hide()
		select.pressed = false
		call_deferred("grab_focus")


func _option_pressed(option):
	# Option selected, save/apply selection, close popup (toggling the main button) and five focus back to main control
	current_id = option.data
	current.text = option.text
	select.emit_signal("toggled", false)
	emit_signal("value_changed", setting_section, setting_key, option.data)


func _option_gui_input(event : InputEvent, option):
	if event.is_action_pressed("ui_down") and option:
		var i = option.get_index() + 1 if option.get_index() < items_container.get_child_count() - 1 else 0
		_option_grab_focus(items_container.get_child(i))
#		_ensure_visible(items_container.get_child(i))
#		items_container.get_child(i).grab_focus()
		accept_event()
	if event.is_action_pressed("ui_up") and option:
		var i = option.get_index() - 1 if option.get_index() > 0 else items_container.get_child_count() - 1
		_option_grab_focus(items_container.get_child(i))
#		_ensure_visible(items_container.get_child(i))
#		scroll_container.notification(NOTIFICATION_SORT_CHILDREN)
#		items_container.get_child(i).grab_focus()
		accept_event()
	if event.is_action_pressed("ui_cancel"):
		# Close popup (toggling the main button) and give focus back to main control
		select.emit_signal("toggled", false)
		accept_event()


func _items_container_grab_focus():
	items_container.grab_focus()
	_focus_entered()


func _option_grab_focus(option):
	_ensure_visible(option)
	scroll_container.notification(NOTIFICATION_SORT_CHILDREN)
	option.grab_focus()
	_focus_entered()


func _ensure_visible(control : Control):
	if is_a_parent_of(control):
		var global_rect = scroll_container.get_global_rect();
		var other_rect = control.get_global_rect();
		var right_margin = 0;
		if scroll_container.get_v_scrollbar().visible:
			right_margin += scroll_container.get_v_scrollbar().get_size().x
		
		var bottom_margin = 0;
		if scroll_container.get_h_scrollbar().visible:
			bottom_margin += scroll_container.get_h_scrollbar().get_size().y

		var diff = max(min(other_rect.position.y, global_rect.position.y), other_rect.position.y + other_rect.size.y - global_rect.size.y + bottom_margin);
		scroll_container.scroll_vertical = scroll_container.scroll_vertical + (diff - global_rect.position.y)
		diff = max(min(other_rect.position.x, global_rect.position.x), other_rect.position.x + other_rect.size.x - global_rect.size.x + right_margin);
		scroll_container.scroll_horizontal = scroll_container.scroll_horizontal + (diff - global_rect.position.x)


func _get_nearest_scroll_or_view_global_rect() -> Rect2:
	var node = get_parent()
	while node != null and not node is View and not node is ScrollContainer:
		node = node.get_parent()
	if node != null and node is Control:
		return node.get_global_rect()
	return Rect2(Vector2(0, 0), OS.window_size)


#func _ready():
#	add_stylebox_override("panel", default_style)
#	connect("focus_entered", self, "_focus_entered")
#	connect("focus_exited", self, "_focus_exited")
#	connect("gui_input", self, "_gui_input")
#
#	select.focus_neighbour_top = select.get_path()
#	select.focus_neighbour_bottom = select.get_path()
#	select.focus_neighbour_left = select.get_path()
#	select.focus_neighbour_right = select.get_path()
#	select.connect("toggled", self, "_selection_focus_toggled")
#
#
#func _focus_entered():
#	add_stylebox_override("panel", focused_style)
#
#
#func _focus_exited():
#	add_stylebox_override("panel", default_style)
#
#
#func _gui_input(event : InputEvent):
#	if event.is_action_pressed("ui_accept"):
#		select.grab_focus()
#		Input.parse_input_event(event)
##		accept_event()
#
#
#func _selection_focus_toggled(pressed):
#	if not pressed:
#		call_deferred("grab_focus")
