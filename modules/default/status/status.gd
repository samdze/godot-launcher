extends Status

enum Mode { STATUS, WIDGETS }

var mode = Mode.STATUS setget _set_mode

onready var top_bar = $Status/TopContainer
onready var bot_bar = $Status/BottomContainer
onready var notifications_bar = $Status/TopContainer/NotificationsBar
onready var loading = $Status/LoadingRect
onready var root = $Status
onready var tween = $Tween


func _ready():
	top_bar.rect_position = Vector2(top_bar.rect_position.x, - top_bar.rect_size.y)
	bot_bar.rect_position = Vector2(bot_bar.rect_position.x, OS.window_size.y)
	
	top_bar.connect("close_requested", self, "_close_requested")
	top_bar.connect("home_requested", self, "_home_requested")
	top_bar.connect("controls_unfocused", self, "_controls_unfocused")
	
	notifications_bar.connect("notification_show_requested", self, "_notification_show_requested")
	notifications_bar.connect("notification_showing", self, "_notification_showing")
	notifications_bar.connect("notification_hide_requested", self, "_notification_hide_requested")
	notifications_bar.connect("notification_hidden", self, "_notification_hidden")
	
	loading.visible = false


func _input(event):
	match mode:
		Mode.STATUS:
			if event.is_action_pressed("alt_start") and not loading.is_loading():
				emit_signal("open_requested")


func _event(name, arguments):
	# The Status handles events differently, it passes them to Widgets too.
	var results = []
	match name:
		"notification":
			notifications_bar.append_notification(arguments[0], arguments[1])
			results.append(true)
#			return true
		"prompts":
			bot_bar.set_prompts(arguments[0], arguments[1])
			results.append(true)
#			return true
		"set_loading":
			loading.set_loading(arguments[0])
			results.append(true)
#			return true
		"is_loading":
			results.append(loading.is_loading())
	
	if top_bar != null:
		for w in top_bar.widgets_container.get_children():
			var res = w._event(name, arguments)
			if res != null:
				if res is Array:
					results += res
				else:
					results.append(res)
	
	return results


func set_title(title):
	top_bar.set_title(title)


func open():
	WindowManager.want_always_on_top(self)
	tween.remove_all()
	tween.interpolate_property(top_bar, "rect_position", top_bar.rect_position, Vector2(top_bar.rect_position.x, 0), 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.1)
	tween.interpolate_property(bot_bar, "rect_position", bot_bar.rect_position, Vector2(bot_bar.rect_position.x, OS.window_size.y - bot_bar.rect_size.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.1)
	tween.interpolate_callback(self, 0.3, "emit_signal", "opened")
	tween.start()


func close():
	if mode == Mode.WIDGETS:
		return
	tween.remove_all()
	tween.interpolate_property(top_bar, "rect_position", top_bar.rect_position, Vector2(top_bar.rect_position.x, - top_bar.rect_size.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_IN)
	tween.interpolate_property(bot_bar, "rect_position", bot_bar.rect_position, Vector2(bot_bar.rect_position.x, OS.window_size.y), 0.2, Tween.TRANS_QUAD, Tween.EASE_IN)
	tween.interpolate_callback(self, 0.2, "emit_signal", "_closed")
	tween.start()


func _closed():
	WindowManager.unwant_always_on_top(self)
	emit_signal("closed")


func enable():
	_set_mode(Mode.WIDGETS)


func disable():
	_set_mode(Mode.STATUS)


func _close_requested():
	var focused = root.get_focus_owner()
	if is_a_parent_of(focused):
		focused.release_focus()
	emit_signal("close_requested")


func _home_requested():
	emit_signal("home_requested")


func _controls_unfocused():
	_update_prompts()


func _notification_show_requested(notification):
	notifications_bar.show_notification()


func _notification_showing(notification):
	WindowManager.want_always_on_top(notifications_bar)


func _notification_hide_requested(notification):
	notifications_bar.hide_notification()


func _notification_hidden(notification):
	WindowManager.unwant_always_on_top(notifications_bar)


func _set_mode(value):
	mode = value
	match(value):
		Mode.STATUS:
			top_bar.disable()
		Mode.WIDGETS:
			top_bar.enable()
			_update_prompts()


func _update_prompts():
	bot_bar.set_prompts(
		[BottomBar.ICON_NAV_H, tr("DEFAULT.PROMPT_NAVIGATION"), 
			BottomBar.ICON_BUTTON_MENU, tr("DEFAULT.PROMPT_EXIT")],
		[BottomBar.ICON_BUTTON_A, tr("DEFAULT.PROMPT_SELECT"),
			BottomBar.ICON_BUTTON_B, tr("DEFAULT.PROMPT_BACK")])


# Override this function to give this App a name for the modules system
static func _get_component_name():
	return "Status"
