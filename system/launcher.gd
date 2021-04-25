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
var always_on_top_wanted : Array = []

var first_app : PackedScene
var settings_app_id
var keyboard_app_id

onready var window_manager : WindowManager = $WindowManager
onready var overlay_container : Control = $Overlay/Container
onready var loading_overlay : LoadingOverlay = $Overlay/Container/LoadingRect
onready var top_bar : TopBar = $Overlay/Container/TopContainer
onready var notifications_bar : Notifications = $Overlay/Container/TopContainer/NotificationsBar
onready var bottom_bar : BottomBar = $Overlay/Container/BottomContainer
onready var app : AppHandler = $App
onready var background : TextureRect = $Background
onready var standby_timer = $StandByTimer
onready var tween : Tween = $Tween


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	first_app = Modules.get_loaded_component_from_config("system", "launcher_app", "default/launcher").resource
	settings_app_id = Config.get_value_or_default("system", "settings_app", "default/settings")
	keyboard_app_id = Config.get_value_or_default("system", "keyboard_app", "default/keyboard")
	
	window_manager.connect("active_window_changed", self, "_active_window_changed")
	window_manager.connect("window_mapped", self, "_window_mapped")
	window_manager.connect("window_unmapped", self, "_window_unmapped")
	window_manager.connect("window_name_changed", self, "_window_name_changed")
	
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
	
	# Listen to Notifications
	notifications_bar.connect("notification_show_requested", self, "_notification_show_requested")
	notifications_bar.connect("notification_showing", self, "_notification_showing")
	notifications_bar.connect("notification_hide_requested", self, "_notification_hide_requested")
	notifications_bar.connect("notification_hidden", self, "_notification_hidden")
	
	# Listen to the App Handler signals, when Apps want to change the title or the bars visibility
	app.connect("title_change_requested", self, "_title_change_requested")
	app.connect("bars_visibility_change_requested", self, "_bars_visibility_change_requested")
	app.connect("mode_change_requested", self, "_mode_change_requested")
	
	app.add_app(first_app.instance())
	app.focus()


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
#	update()
#	overlay_container.update()
#	get_tree()


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


func want_always_on_top(object):
	var on_top = always_on_top_wanted.size() > 0
	if not always_on_top_wanted.has(object):
		always_on_top_wanted.append(object)
		if always_on_top_wanted.size() > 0 and not on_top:
			print("[GODOT] Setting always on top to TRUE")
			window_manager.set_always_on_top(window_manager.get_window_id(), true)


func unwant_always_on_top(object):
	var on_top = always_on_top_wanted.size() > 0
	if always_on_top_wanted.has(object):
		always_on_top_wanted.erase(object)
		if always_on_top_wanted.size() == 0 and on_top:
			print("[GODOT] Setting always on top to FALSE")
			window_manager.set_always_on_top(window_manager.get_window_id(), false)


func show_widgets():
	want_always_on_top(top_bar)
	app.unfocus()
	top_bar.mode = TopBar.Mode.WIDGETS
	if not top_bar_showing:
		_show_top_bar()
	if not bot_bar_showing:
		_show_bot_bar()
	
	window_manager.give_focus(window_manager.get_window_id(), true)
	window_manager.raise_window(window_manager.get_window_id())
	tween.start()


func hide_widgets():
	unwant_always_on_top(top_bar)
	app.focus()
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
	# TODO: could check if widgets can be opened, e.g. with a request to the current App
	if not loading_overlay.is_loading():
		show_widgets()


func _status_close_requested():
	hide_widgets()


func _status_kill_app_requested():
	# Can't close the launcher itself
	if active_app_window_id != window_manager.get_window_id():
#		window_manager.give_focus(window_manager.get_active_window())
		print("[GODOT] Trying to kill window " + str(active_app_window_id))
		window_manager.kill_window(active_app_window_id)


# Notifications handling
func _notification_show_requested(notification):
	notifications_bar.show_notification()


func _notification_showing(notification):
	want_always_on_top(notifications_bar)


func _notification_hide_requested(notification):
	notifications_bar.hide_notification()


func _notification_hidden(notification):
	unwant_always_on_top(notifications_bar)


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
		app.window_name_changed(name)


func _active_window_changed(window_id):
	active_app_window_id = window_id
	print("[GODOT] Activating a new window: " + str(window_id))
	app.active_window_changed(window_id)
#	yield(get_tree().create_timer(5.0), "timeout")
#	window_manager.raise_window(window_manager.get_window_id())
	
	# TODO: debug stuff, to remove
	var stack = window_manager.get_windows_stack()
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


static func _get_exported_settings():
	return [
		{ "section": "system", "key": "launcher_app", "label": "Launcher App", "control": preload("res://system/settings/editors/dropdown_launcher_app.tscn") },
		{ "section": "system", "key": "settings_app", "label": "Settings App", "control": preload("res://system/settings/editors/dropdown_settings_app.tscn") },
		{ "section": "system", "key": "keyboard_app", "label": "Keyboard App", "control": preload("res://system/settings/editors/dropdown_component_single.tscn") },
		{ "section": "system", "key": "language", "label": "Language", "control": preload("res://system/settings/editors/dropdown_component_single.tscn") },
		{ "section": "system", "key": "theme", "label": "Theme", "control": preload("res://system/settings/editors/dropdown_theme.tscn") },
		{ "section": "system", "key": "about", "label": "About", "control": load("res://system/settings/about/settings_button.tscn") }
	]
