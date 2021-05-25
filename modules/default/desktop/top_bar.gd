extends MarginContainer

signal controls_unfocused()
signal close_request()
signal home_request()

onready var widgets_container = $TopPanel/HBoxContainer/Widgets
onready var title_container = $TopPanel/HBoxContainer/LabelContainer
onready var title = $TopPanel/HBoxContainer/LabelContainer/Label
onready var widget_controls = $TopPanel/WidgetControls
onready var highligther = $TopPanel/Highlighter
onready var tween = $Tween


func _ready():
	# Create loaded widgets
	var widgets = Modules.get_loaded_components(Component.Type.WIDGET)
	for w in widgets:
		var widget = null
		widget = w.resource.instance()
		
		if widget != null:
			widgets_container.add_child(widget)
	
	connect("close_request", self, "_close_request")
	
	# Configure widgets and title
	title.connect("focus_entered", self, "_item_focus_entered", [title])
	title.connect("gui_input", self, "_title_gui_input")
	title.connect("gui_input", self, "_gui_input")
	title.focus_neighbour_bottom = title.get_path()
	title.focus_neighbour_top = title.get_path()
	if widgets_container.get_child_count() > 0:
		title.focus_neighbour_right = widgets_container.get_child(0).get_path()
		title.focus_neighbour_left = widgets_container.get_child(widgets_container.get_child_count() - 1).get_path()
	
	for w in widgets_container.get_children():
		var index = w.get_index()
		if not w is Widget:
			continue
		
		w.connect("focus_entered", self, "_item_focus_entered", [w])
		w.connect("pressed", self, "_widget_selected", [w])
		w.connect("unfocus_controls_request", self, "_unfocus_controls_request", [w])
		w.connect("gui_input", self, "_gui_input")
		
		w.focus_neighbour_top = w.get_path()
		w.focus_neighbour_bottom = w.get_path()
		
		if index > 0:
			w.focus_neighbour_left = widgets_container.get_child(index - 1).get_path()
		else:
			w.focus_neighbour_left = title.get_path()
		if index < widgets_container.get_child_count() - 1:
			w.focus_neighbour_right = widgets_container.get_child(index + 1).get_path()
		else:
			w.focus_neighbour_right = title.get_path()
	
	widget_controls.hide()
	highligther.hide()


func _gui_input(event : InputEvent):
#	match mode:
#		Mode.WIDGETS:
	if event.is_action_pressed("ui_menu"):
		emit_signal("home_request")
		emit_signal("close_request")
	if event.is_action_pressed("ui_cancel"):
		emit_signal("close_request")


func _close_request():
	var focused = get_focus_owner()
	if is_a_parent_of(focused):
		focused.release_focus()


func _item_focus_entered(item : Control):
	print("Widget focused " + item.name)
	tween.remove(highligther, "rect_global_position:x")
	tween.remove(highligther, "rect_size:x")
	tween.interpolate_property(highligther, "rect_global_position:x", highligther.rect_global_position.x, item.rect_global_position.x, 0.1)
	if item is Widget:
		tween.interpolate_property(highligther, "rect_size:x", highligther.rect_size.x, item.rect_size.x, 0.1)
	elif item == title:
		tween.interpolate_property(highligther, "rect_size:x", highligther.rect_size.x, min(item.rect_size.x, title_container.rect_size.x), 0.1)
	tween.start()
	if item is Widget:
		var controls = item._get_widget_controls()
		if controls != null:
			for c in widget_controls.get_children():
				widget_controls.remove_child(c)
			widget_controls.rect_size = widget_controls.rect_min_size
			widget_controls.show()
			widget_controls.add_child(controls)
			
			widget_controls.rect_size = controls.rect_size
			
			widget_controls.rect_global_position.x = item.rect_global_position.x + item.rect_size.x - widget_controls.rect_size.x
		else:
			widget_controls.hide()
	else:
		widget_controls.hide()


func _widget_selected(widget : Widget):
	print("Widget selected " + widget.name)
	widget._widget_selected()


func _unfocus_controls_request(widget : Widget):
	widget.grab_focus()
	emit_signal("controls_unfocused")
#	_update_prompts()


func _title_gui_input(event : InputEvent):
	if event.is_action_pressed("ui_accept"):
		emit_signal("close_request")


func set_title(title):
	self.title.text = title
	self.title.notification(NOTIFICATION_DRAW)
	# Reset the title width
	self.title.rect_size = Vector2(0, self.title.rect_size.y)


func disable():
	highligther.hide()
	widget_controls.hide()
	highligther.rect_position = Vector2(0, highligther.rect_position.y)


func enable():
	highligther.show()
	title.grab_focus()
