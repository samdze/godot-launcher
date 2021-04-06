extends Control
class_name LauncherUI

enum Mode { LAUNCHER, STATUS }

export(int, 30, 600) var standby_time = 300

var active_app_window_id = -1
var standby = false
var mode = Mode.LAUNCHER setget _set_mode
var status_showing = false

var top_bar_showing = false
var bot_bar_showing = false

onready var window_manager : WindowManager = $WindowManager
onready var loading_overlay : LoadingOverlay = $Overlay/LoadingRect
onready var top_bar : TopBar = $TopContainer
onready var bottom_bar : BottomBar = $BottomContainer
onready var view : ViewHandler = $Main
onready var background : ColorRect = $Background
onready var standby_timer = $StandByTimer
onready var tween : Tween = $Tween

onready var first_view : PackedScene = load("res://system/view/launcher_view.tscn")



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
	top_bar.connect("close_requested", self, "_status_close_requested")
	top_bar.connect("kill_app_requested", self, "_status_kill_app_requested", [], CONNECT_DEFERRED)
	
	view.add_view(first_view.instance())


func _set_mode(value):
	mode = value
	match value:
		Mode.LAUNCHER:
			print("Switching to LAUNCHER mode.")
			var root = get_tree().root
			root.transparent_bg = false
			background.show()
			view.show()
			top_bar.mode = TopBar.Mode.DEFAULT
			if view.get_current_view() != null:
				_view_changed(view.get_current_view().show_top_bar, view.get_current_view().show_bottom_bar)
		Mode.STATUS:
			print("Switching to STATUS mode.")
			var root = get_tree().root
			root.transparent_bg = true
			view.hide()
			background.hide()
			_view_changed(false, false)
	update()


func _input(event):
	# TODO: to remove
	if event.is_action_pressed("ui_menu") and mode == Mode.LAUNCHER:
		get_tree().quit()
	
	if mode == Mode.STATUS and event.is_action_pressed("alt_start"):
		if not top_bar.mode == TopBar.Mode.STATUS:
			show_status(true, true)
	elif mode == Mode.LAUNCHER and event.is_action_pressed("alt_start"):
		# TODO: check if at least the bot or top bar is not showing and also unfocus the current view
		if not top_bar.mode == TopBar.Mode.STATUS:
			show_status(!top_bar_showing, !bot_bar_showing)
	
	if standby:
		standby = false
		OS.execute("bash", ["-c", "echo 1 > /proc/driver/backlight"])
	standby_timer.start(standby_time)
	if event is InputEventKey:
		if event.is_pressed():
			$BottomContainer/InputEvents/HBoxContainer/Pressed/Value.text = OS.get_scancode_string(event.scancode) + " / " + OS.get_scancode_string(event.get_scancode_with_modifiers())
		else:
			$BottomContainer/InputEvents/HBoxContainer/Released/Value.text = OS.get_scancode_string(event.scancode) + " / " + OS.get_scancode_string(event.get_scancode_with_modifiers())
	else:
		$BottomContainer/InputEvents/HBoxContainer/Pressed/Value.text = event.as_text()


func _standby():
	OS.execute("bash", ["-c", "echo 0 > /proc/driver/backlight"])
	standby = true


func show_status(show_top, show_bottom):
	top_bar.mode = TopBar.Mode.STATUS
	window_manager.give_focus(window_manager.get_window_id())
	if show_top or show_bottom:
		window_manager.raise_window(window_manager.get_window_id())
		status_showing = true
	if show_top:
		_show_top_bar()
	if show_bottom:
		_show_bot_bar()
	tween.start()


func hide_status():
	top_bar.mode = TopBar.Mode.DEFAULT
	if mode == Mode.STATUS:
		_hide_top_bar()
		_hide_bot_bar()
	else:
		if not top_bar_showing:
			_hide_top_bar()
		if not bot_bar_showing:
			_hide_bot_bar()
	tween.start()


func _show_top_bar():
	tween.remove(top_bar, "rect_position")
	tween.interpolate_property(top_bar, "rect_position", top_bar.rect_position, Vector2(top_bar.rect_position.x, 0), 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.2)


func _hide_top_bar():
	tween.remove(top_bar, "rect_position")
	tween.interpolate_property(top_bar, "rect_position", Vector2(top_bar.rect_position.x, 0), Vector2(top_bar.rect_position.x, -top_bar.rect_size.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_IN)


func _show_bot_bar():
	tween.remove(bottom_bar, "rect_position")
	tween.interpolate_property(bottom_bar, "rect_position", bottom_bar.rect_position, Vector2(bottom_bar.rect_position.x, OS.window_size.y - bottom_bar.rect_size.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.2)


func _hide_bot_bar():
	tween.remove(bottom_bar, "rect_position")
	tween.interpolate_property(bottom_bar, "rect_position", Vector2(bottom_bar.rect_position.x, OS.window_size.y - bottom_bar.rect_size.y), Vector2(bottom_bar.rect_position.x, OS.window_size.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_IN)


func _status_close_requested():
	window_manager.give_focus(window_manager.get_active_window())
	hide_status()


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


func _active_window_changed(window_id):
	active_app_window_id = window_id
	if window_id == window_manager.get_window_id():
		_set_mode(Mode.LAUNCHER)
	else:
		_set_mode(Mode.STATUS)
	view.active_window_changed(window_id)
	
	var stack = window_manager.get_windows_stack()
	var stack_string = ""
	for w in stack:
		stack_string += str(w)+"; "
	
	print("[GODOT] Active window changed event: "+str(window_id) + ", stack: "+stack_string)


func _status_hidden():
	window_manager.lower_window(window_manager.get_window_id())
	status_showing = false


func _view_changed(show_top_bar, show_bottom_bar):
	top_bar_showing = show_top_bar
	bot_bar_showing = show_bottom_bar
	tween.remove(top_bar, "rect_position")
	tween.remove(bottom_bar, "rect_position")
	if show_top_bar:
		tween.interpolate_property(top_bar, "rect_position", top_bar.rect_position, Vector2(top_bar.rect_position.x, 0), 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT)
	else:
		tween.interpolate_property(top_bar, "rect_position", top_bar.rect_position, Vector2(top_bar.rect_position.x, - top_bar.rect_size.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_IN)
	if show_bottom_bar:
		tween.interpolate_property(bottom_bar, "rect_position", bottom_bar.rect_position, Vector2(bottom_bar.rect_position.x, OS.window_size.y - bottom_bar.rect_size.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT)
	else:
		tween.interpolate_property(bottom_bar, "rect_position", bottom_bar.rect_position, Vector2(bottom_bar.rect_position.x, OS.window_size.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_IN)
	tween.start()
