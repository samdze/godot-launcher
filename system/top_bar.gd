extends MarginContainer
class_name TopBar

signal close_requested()
signal kill_app_requested()

enum Mode { DEFAULT, STATUS }

var widgets_directory : String = "res://widgets"
var mode = Mode.DEFAULT setget _set_mode

onready var widgets_container = $TopPanel/HBoxContainer
onready var title = $TopPanel/HBoxContainer/Label



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


func _input(event):
	if mode == Mode.STATUS:
		if event.is_action_pressed("ui_menu"):
			emit_signal("kill_app_requested")
		if event.is_action_pressed("ui_cancel"):
			emit_signal("close_requested")


func _set_mode(value):
	mode = value
	match(value):
		Mode.DEFAULT:
			pass
		Mode.STATUS:
			Launcher.get_ui().bottom_bar.set_prompts(
				[#BottomBar.ICON_NAV, BottomBar.PROMPT_NAV, 
					BottomBar.ICON_BUTTON_MENU, BottomBar.PROMPT_EXIT],
				[BottomBar.ICON_BUTTON_B, BottomBar.PROMPT_BACK])
