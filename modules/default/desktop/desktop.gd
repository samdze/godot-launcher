extends Desktop

enum Mode { DESKTOP, WIDGETS }

export(Array, NodePath) var status_spacers_paths

var mode = Mode.DESKTOP setget _set_mode
var status_spacers = []

onready var app_handler : AppHandler = $App
onready var top_bar = $Overlay/Status/TopContainer
onready var bot_bar = $Overlay/Status/BottomContainer
onready var notifications_bar = $Overlay/Status/TopContainer/NotificationsBar
onready var loading = $Overlay/Status/LoadingRect
onready var root = $Overlay/Status
onready var tween = $Tween


func _ready():
	for s in status_spacers_paths:
		status_spacers.append(get_node(s))
	
	top_bar.rect_position = Vector2(top_bar.rect_position.x, - top_bar.rect_size.y)
	bot_bar.rect_position = Vector2(bot_bar.rect_position.x, OS.window_size.y)
	
	top_bar.connect("close_request", self, "_close_request")
	top_bar.connect("home_request", self, "_home_request")
	top_bar.connect("controls_unfocused", self, "_controls_unfocused")
	
	notifications_bar.connect("notification_show_request", self, "_notification_show_request")
	notifications_bar.connect("notification_showing", self, "_notification_showing")
	notifications_bar.connect("notification_hide_request", self, "_notification_hide_request")
	notifications_bar.connect("notification_hidden", self, "_notification_hidden")
	
	loading.visible = false


func _input(event):
	match mode:
		Mode.DESKTOP:
			if event.is_action_pressed("ui_home") and not loading.is_loading():
				get_tree().set_input_as_handled()
				emit_signal("open_request")


func _event(name, arguments):
	# The Desktop handles events differently, it passes them to Widgets too.
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


func get_app_handler() -> AppHandler:
	return app_handler


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
	tween.interpolate_callback(self, 0.2, "emit_signal", "closed")
	tween.start()


func take_space():
	for s in status_spacers:
		s.show()


func free_space():
	for s in status_spacers:
		s.hide()


func _closed():
	WindowManager.unwant_always_on_top(self)
	emit_signal("closed")


func enable():
	_set_mode(Mode.WIDGETS)


func disable():
	_set_mode(Mode.DESKTOP)


func _close_request():
	var focused = root.get_focus_owner()
	if is_a_parent_of(focused):
		focused.release_focus()
	emit_signal("close_request")


func _home_request():
	emit_signal("home_request")


func _controls_unfocused():
	_update_prompts()


func _notification_show_request(notification):
	notifications_bar.show_notification()


func _notification_showing(notification):
	WindowManager.want_always_on_top(notifications_bar)


func _notification_hide_request(notification):
	notifications_bar.hide_notification()


func _notification_hidden(notification):
	WindowManager.unwant_always_on_top(notifications_bar)


func _set_mode(value):
	mode = value
	match(value):
		Mode.DESKTOP:
			top_bar.disable()
		Mode.WIDGETS:
			top_bar.enable()
			_update_prompts()


func _update_prompts():
	bot_bar.set_prompts(
		[Desktop.Input.MOVE_H, tr("DEFAULT.PROMPT_NAVIGATION"), 
			Desktop.Input.MENU, tr("DEFAULT.PROMPT_EXIT")],
		[Desktop.Input.A, tr("DEFAULT.PROMPT_SELECT"),
			Desktop.Input.B, tr("DEFAULT.PROMPT_BACK")])


# Override this function to give this App a name for the modules system
static func _get_component_name():
	return "GameShell Desktop"
