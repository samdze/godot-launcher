extends App

enum Operation { CHECK, UPDATE }

var processing = false
var thread : Thread = null
var semaphore : Semaphore = null

var should_exit = false
var operation = null


func _ready():
	semaphore = Semaphore.new()
	thread = Thread.new()
	thread.start(self, "_thread_function", null)


# Called when the App gains focus, setup the App here.
# Signals like bars_visibility_change_requested and title_change_requested are best called here.
func _focus():
	emit_signal("status_visibility_change_requested", true)
	emit_signal("title_change_requested", tr("DEFAULT.UPDATE_LAUNCHER"))
	emit_signal("mode_change_requested", System.Mode.OPAQUE)
	Launcher.emit_event("prompts", [
		[],
		[BottomBar.ICON_BUTTON_A, tr("DEFAULT.PROMPT_SELECT"), BottomBar.ICON_BUTTON_Y, tr("DEFAULT.CHECK_UPDATES"), BottomBar.ICON_BUTTON_B, tr("DEFAULT.PROMPT_BACK")]
	])


# Called when the App loses focus
func _unfocus():
	
	pass


# Called when the App is focuses and receives an input.
# Override this function instead of _input to receive global events.
func _app_input(event : InputEvent):
	if event.is_action_pressed("ui_cancel") and not processing:
		accept_event()
		Launcher.get_ui().app.back_app()
	if event.is_action_pressed("ui_button_y") and not processing:
		accept_event()
		_check_updates()


func _check_updates():
	processing = true
	Launcher.emit_event("set_loading", [true])
	operation = Operation.CHECK
	semaphore.post()


func _update_launcher():
	processing = true
	Launcher.emit_event("set_loading", [true])
	operation = Operation.UPDATE
	semaphore.post()


func _check_completed(result):
	processing = false
	Launcher.emit_event("set_loading", [false])
	
	pass


func _update_completed(result):
	processing = false
	Launcher.emit_event("set_loading", [false])
	
	pass


func _thread_function(data):
	var output = []
	
	while not should_exit:
		semaphore.wait()
		if should_exit:
			return
		
		if operation == Operation.CHECK:
			# Check if an update is available
			
			call_deferred("_check_completed", null)
		elif operation == Operation.UPDATE:
			# Update the launcher
			
			call_deferred("_update_completed", null)


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		should_exit = true
		semaphore.post()
		thread.wait_to_finish()
