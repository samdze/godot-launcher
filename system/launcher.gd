# TODO: fix BeanShell not permitting to show the widgets the first time they are called.
#	May be an issue with Bean trying to raise itself when it detects another window on top.
#	Setting the launcher as an "always on top" window in the manager should fix it.
# TODO: Fix the Window Manager not capable of detecting 2048's game window name.
# TODO: Fix widget highlighter sometimes standing in the left when calling the widgets menu.

extends Control
class_name LauncherUI

enum Mode { OPAQUE, TRANSPARENT }

export(int, 30, 600) var standby_time = 300

var active_app_window_id = -1
var standby = false
var mode = Mode.OPAQUE setget _set_mode
var status_showing = false

var top_bar_showing = false
var bot_bar_showing = false

onready var window_manager : WindowManager = $WindowManager
onready var loading_overlay : LoadingOverlay = $Overlay/LoadingRect
onready var top_bar : TopBar = $TopContainer
onready var bottom_bar : BottomBar = $BottomContainer
onready var view : ViewHandler = $Main
onready var background : TextureRect = $Background
onready var standby_timer = $StandByTimer
onready var tween : Tween = $Tween

onready var first_view : PackedScene = load("res://views/launcher/launcher_view.tscn")



func _ready():
	window_manager.start()
	
	# Hide top and bottom bars at startup
	top_bar.rect_position = Vector2(top_bar.rect_position.x, - top_bar.rect_size.y)
	bottom_bar.rect_position = Vector2(bottom_bar.rect_position.x, OS.window_size.y)
	
	# Load config, dummy
	var backlight = clamp(1, 1, 9)
	
	# Apply config
	OS.execute("bash", ["-c", "echo " + str(backlight) + " > /proc/driver/backlight"])
	
	# Start the standby timer that turns off the backlight
	standby_timer.start(standby_time)
	
	# Listen to Top Bar signals, when you want to close or kill an app
	top_bar.connect("open_requested", self, "_status_open_requested")
	top_bar.connect("close_requested", self, "_status_close_requested")
	top_bar.connect("kill_app_requested", self, "_status_kill_app_requested", [], CONNECT_DEFERRED)
	
	# Listen to the View Handler signals, when views want to change the title or the bars visibility
	view.connect("title_change_requested", self, "_title_change_requested")
	view.connect("bars_visibility_change_requested", self, "_bars_visibility_change_requested")
	view.connect("mode_change_requested", self, "_mode_change_requested")
	
	view.add_view(first_view.instance())
	view.focus()


func _set_mode(value):
	mode = value
	match value:
		Mode.OPAQUE:
			print("Switching to OPAQUE mode.")
			var root = get_tree().root
			root.transparent_bg = false
			background.show()
		Mode.TRANSPARENT:
			print("Switching to TRANSPARENT mode.")
			var root = get_tree().root
			root.transparent_bg = true
			background.hide()
	update()


func _input(event):	
	if standby:
		standby = false
		OS.execute("bash", ["-c", "echo 1 > /proc/driver/backlight"])
	standby_timer.start(standby_time)
#	if event is InputEventKey:
#		if event.is_pressed():
#			$BottomContainer/InputEvents/HBoxContainer/Pressed/Value.text = OS.get_scancode_string(event.scancode) + " / " + OS.get_scancode_string(event.get_scancode_with_modifiers())
#		else:
#			$BottomContainer/InputEvents/HBoxContainer/Released/Value.text = OS.get_scancode_string(event.scancode) + " / " + OS.get_scancode_string(event.get_scancode_with_modifiers())
#	else:
#		$BottomContainer/InputEvents/HBoxContainer/Pressed/Value.text = event.as_text()


func _standby():
	OS.execute("bash", ["-c", "echo 0 > /proc/driver/backlight"])
	standby = true


func show_widgets():
	view.unfocus()
	top_bar.mode = TopBar.Mode.WIDGETS
	if not top_bar_showing:
		_show_top_bar()
	if not bot_bar_showing:
		_show_bot_bar()
	
	window_manager.give_focus(window_manager.get_window_id(), true)
	window_manager.raise_window(window_manager.get_window_id())
	tween.start()


func hide_widgets():
	view.focus()
	top_bar.mode = TopBar.Mode.STATUS
	if not top_bar_showing:
		_hide_top_bar()
	if not bot_bar_showing:
		_hide_bot_bar()
	
	window_manager.give_focus(window_manager.get_active_window(), false)
	tween.start()


func _show_top_bar():
	tween.remove(top_bar, "rect_position")
	tween.interpolate_property(top_bar, "rect_position", top_bar.rect_position, Vector2(top_bar.rect_position.x, 0), 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.1)
#	tween.interpolate_property(top_bar, "rect_position", top_bar.rect_position, Vector2(top_bar.rect_position.x, 0), 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.2)


func _hide_top_bar():
	tween.remove(top_bar, "rect_position")
	tween.interpolate_property(top_bar, "rect_position", top_bar.rect_position, Vector2(top_bar.rect_position.x, - top_bar.rect_size.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_IN)
#	tween.interpolate_property(top_bar, "rect_position", Vector2(top_bar.rect_position.x, 0), Vector2(top_bar.rect_position.x, -top_bar.rect_size.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_IN)


func _show_bot_bar():
	tween.remove(bottom_bar, "rect_position")
	tween.interpolate_property(bottom_bar, "rect_position", bottom_bar.rect_position, Vector2(bottom_bar.rect_position.x, OS.window_size.y - bottom_bar.rect_size.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.1)
#	tween.interpolate_property(bottom_bar, "rect_position", bottom_bar.rect_position, Vector2(bottom_bar.rect_position.x, OS.window_size.y - bottom_bar.rect_size.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.2)


func _hide_bot_bar():
	tween.remove(bottom_bar, "rect_position")
	tween.interpolate_property(bottom_bar, "rect_position", bottom_bar.rect_position, Vector2(bottom_bar.rect_position.x, OS.window_size.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_IN)
#	tween.interpolate_property(bottom_bar, "rect_position", Vector2(bottom_bar.rect_position.x, OS.window_size.y - bottom_bar.rect_size.y), Vector2(bottom_bar.rect_position.x, OS.window_size.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_IN)


func _status_open_requested():
	# TODO: could check if widgets can be opened, e.g. with a request to the current view
	show_widgets()


func _status_close_requested():
	hide_widgets()


func _status_kill_app_requested():
	# Can't close the launcher itself
	if active_app_window_id != window_manager.get_window_id():
#		window_manager.give_focus(window_manager.get_active_window())
		print("[GODOT] Trying to kill window " + str(active_app_window_id))
		window_manager.kill_window(active_app_window_id)


func _window_mapped(window_id):
	var stack = window_manager.get_windows_stack()
	var stack_string = ""
	for w in stack:
		stack_string += str(w)+"; "
	
	print("[GODOT] Window mapped event: "+str(window_id) + ", stack: "+stack_string)


func _window_unmapped(window_id):
	var stack = window_manager.get_windows_stack()
	var stack_string = ""
	for w in stack:
		stack_string += str(w)+"; "
	print("[GODOT] Window unmapped event: "+str(window_id) + ", stack: "+stack_string)


func _window_name_changed(window_id, name):
	if window_id == window_manager.get_active_window():
		view.window_name_changed(name)


func _active_window_changed(window_id):
	active_app_window_id = window_id
	print("[GODOT] Activating a new window: " + str(window_id))
	view.active_window_changed(window_id)
	
	# TODO: debug stuff, to remove
	var stack = Array()# = window_manager.get_windows_stack()
	var stack_string = ""
	for w in stack:
		stack_string += str(w)+"; "
	
	print("[GODOT] Active window changed event: "+str(window_id) + ", stack: "+stack_string)


func _title_change_requested(title):
	top_bar.set_title(title)


func _bars_visibility_change_requested(show_top_bar, show_bottom_bar):
	if top_bar.mode == TopBar.Mode.STATUS:
		if show_top_bar != top_bar_showing:
			if show_top_bar:
				_show_top_bar()
			else:
				_hide_top_bar()
		if show_bottom_bar != bot_bar_showing:
			if show_bottom_bar:
				_show_bot_bar()
			else:
				_hide_bot_bar()
		tween.start()
	top_bar_showing = show_top_bar
	bot_bar_showing = show_bottom_bar


func _mode_change_requested(mode):
	if mode != self.mode:
		_set_mode(mode)
