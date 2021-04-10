extends MarginContainer
class_name TopBar

signal open_requested()
signal close_requested()
signal kill_app_requested()

enum Mode { STATUS, WIDGETS }

var widgets_directory : String = "res://widgets"
var mode = Mode.STATUS setget _set_mode

onready var widgets_container = $TopPanel/HBoxContainer/Widgets
onready var title = $TopPanel/HBoxContainer/Label
onready var highligther = $TopPanel/Highlighter
onready var tween = $Tween


func _ready():
	# Load widgets
	var dir = Directory.new()
	var res = dir.open(widgets_directory)
	if res != OK:
		printerr("Directory ", widgets_directory, " not found.")
	else:
		dir.list_dir_begin(true, true)
		var file_name : String = dir.get_next()
		while file_name != "":
			var widget = null
			if dir.current_is_dir():
				# The widget is contained in a folder
				if ResourceLoader.exists(widgets_directory + "/" + file_name + "/" + file_name + ".tscn"):
					widget = ResourceLoader.load(widgets_directory + "/" + file_name + "/" + file_name + ".tscn").instance()
				elif ResourceLoader.exists(widgets_directory + "/" + file_name + "/" + file_name + ".gd"):
					widget = ResourceLoader.load(widgets_directory + "/" + file_name + "/" + file_name + ".gd").new()
				pass
			elif file_name.ends_with(".gd"):
				# The widget is a simple script file
				widget = ResourceLoader.load(widgets_directory + "/" + file_name).new()
			
			if widget != null:
				widgets_container.add_child(widget)
			file_name = dir.get_next()
	
	# Configure widgets
	for w in widgets_container.get_children():
		var index = w.get_index()
		if not w is Widget:
			continue
		
		w.connect("focus_entered", self, "_widget_focus_entered", [w])
		w.connect("pressed", self, "_widget_selected", [w])
		print("Configuring widget " + w.name)
		w.focus_neighbour_top = w.get_path()
		w.focus_neighbour_bottom = w.get_path()
		
		if index > 0:
			w.focus_neighbour_left = widgets_container.get_child(index - 1).get_path()
		else:
			w.focus_neighbour_left = widgets_container.get_child(widgets_container.get_child_count() - 1).get_path()
		if index < widgets_container.get_child_count() - 1:
			w.focus_neighbour_right = widgets_container.get_child(index + 1).get_path()
		else:
			w.focus_neighbour_right = widgets_container.get_child(0).get_path()
	
	highligther.hide()


func _input(event):
	match mode:
		Mode.STATUS:
			if event.is_action_pressed("alt_start"):
				emit_signal("open_requested")
		Mode.WIDGETS:
			if event.is_action_pressed("ui_menu"):
				emit_signal("kill_app_requested")
				emit_signal("close_requested")
			if event.is_action_pressed("ui_cancel"):
				emit_signal("close_requested")


func _widget_focus_entered(widget : Widget):
	print("Widget focused " + widget.name)
	tween.remove(highligther, "rect_global_position:x")
	tween.remove(highligther, "rect_size:x")
	tween.interpolate_property(highligther, "rect_global_position:x", highligther.rect_global_position.x, widget.rect_global_position.x, 0.1)
	tween.interpolate_property(highligther, "rect_size:x", highligther.rect_size.x, widget.rect_size.x, 0.1)
	tween.start()


func _widget_selected(widget):
	print("Widget selected " + widget.name)
	pass


func set_title(title):
	self.title.text = title


func _set_mode(value):
	mode = value
	match(value):
		Mode.STATUS:
			highligther.hide()
			highligther.rect_position = Vector2(0, highligther.rect_position.y)
		Mode.WIDGETS:
			highligther.show()
			if widgets_container.get_child_count() > 0:
				widgets_container.get_child(0).grab_focus()
			Launcher.get_ui().bottom_bar.set_prompts(
				[BottomBar.ICON_NAV_H, BottomBar.PROMPT_NAV, 
					BottomBar.ICON_BUTTON_MENU, BottomBar.PROMPT_EXIT],
				[BottomBar.ICON_BUTTON_B, BottomBar.PROMPT_BACK])
