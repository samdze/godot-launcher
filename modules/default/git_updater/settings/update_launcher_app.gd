extends App

enum Operation { CHECK, UPDATE }
enum State { IDLE, UPDATE_AVAILABLE, CONFIRM_UPDATE }
enum Check { ERROR, COMMIT_UPDATE_AVAILABLE, UPDATE_AVAILABLE, UP_TO_DATE }

var processing = false
var thread : Thread = null
var semaphore : Semaphore = null

var should_exit = false
var operation = null
var state = State.IDLE
var last_update_release_date = null

onready var http = $HTTPRequest
onready var message : Label = $MarginContainer/ScrollContainer/Container/Message
onready var system_version : Button = $MarginContainer/ScrollContainer/Container/CurrentVersion
onready var confirm_panel = $MarginContainer/UpdateConfirm


func _ready():
	semaphore = Semaphore.new()
	thread = Thread.new()
	thread.start(self, "_thread_function", null)
	system_version.text = tr("DEFAULT.LAUNCHER_VERSION").format([Launcher.get_version()])
	state = State.IDLE
	
	var output = []
#	OS.execute('cmd', ['/C', "git log -1 --format='%at' | xargs -I{} date -d @{} +%Y/%m/%d_%H:%M:%S"], true, output, true)
#	OS.execute('cmd', ['/C', "git log -1 --format='%at'"], true, output, true)
	OS.execute("bash", ["-c", "git log -1 --format='%at' | xargs -I{} date -d @{} +%Y/%m/%d_%H:%M:%S"], true, output, false)
	if output.size() > 0 and output[0].length() > 0:
		print(output)
		var pair = output[0].split("_")
		var ymd = pair[0].split("/")
		var hms = pair[1].split(":")
		
		last_update_release_date = {
			"year": str(ymd[0]),
			"month": str(ymd[1]),
			"day": str(ymd[2]),
			"hour": str(hms[0]),
			"minute": str(hms[1]),
			"second": str(hms[2])
		}
	
	if last_update_release_date != null:
		message.text = tr("DEFAULT.CURRENT_UPDATE_RELEASE_DATE").format({
			"year": last_update_release_date.year,
			"month": last_update_release_date.month,
			"day": last_update_release_date.day,
			"hour": last_update_release_date.hour,
			"minute": last_update_release_date.minute,
			"second": last_update_release_date.second,
		})
	else:
		message.text = ""


# Called when the App gains focus, setup the App here.
# Signals like bars_visibility_change_requested and title_change_requested are best called here.
func _focus():
	emit_signal("status_visibility_change_requested", true)
	emit_signal("title_change_requested", tr("DEFAULT.UPDATE_LAUNCHER"))
	emit_signal("mode_change_requested", System.Mode.OPAQUE)
	_update_prompts()


func _set_state(value):
	state = value
	match state:
		State.IDLE:
			confirm_panel.hide()
		State.UPDATE_AVAILABLE:
			confirm_panel.hide()
		State.CONFIRM_UPDATE:
			confirm_panel.show()
	_update_prompts()


func _update_prompts():
	match state:
		State.IDLE:
			Launcher.emit_event("prompts", [
				[],
				[BottomBar.ICON_BUTTON_Y, tr("DEFAULT.PROMPT_CHECK_UPDATES"), BottomBar.ICON_BUTTON_B, tr("DEFAULT.PROMPT_BACK")]
			])
		State.UPDATE_AVAILABLE:
			Launcher.emit_event("prompts", [
				[],
				[BottomBar.ICON_BUTTON_Y, tr("DEFAULT.PROMPT_UPDATE"), BottomBar.ICON_BUTTON_B, tr("DEFAULT.PROMPT_BACK")]
			])
		State.CONFIRM_UPDATE:
			Launcher.emit_event("prompts", [
				[],
				[BottomBar.ICON_BUTTON_A, tr("DEFAULT.PROMPT_CONFIRM"), BottomBar.ICON_BUTTON_B, tr("DEFAULT.PROMPT_BACK")]
			])


# Called when the App loses focus
func _unfocus():
	
	pass


# Called when the App is focuses and receives an input.
# Override this function instead of _input to receive global events.
func _app_input(event : InputEvent):
	if processing: return
	match state:
		State.IDLE:
			if event.is_action_pressed("ui_cancel"):
				accept_event()
				Launcher.get_ui().app.back_app()
			if event.is_action_pressed("ui_button_y"):
				accept_event()
				_check_updates()
		State.UPDATE_AVAILABLE:
			if event.is_action_pressed("ui_cancel"):
				accept_event()
				Launcher.get_ui().app.back_app()
			if event.is_action_pressed("ui_button_y"):
				accept_event()
				_set_state(State.CONFIRM_UPDATE)
		State.CONFIRM_UPDATE:
			if event.is_action_pressed("ui_accept"):
				accept_event()
				_update_system()
			if event.is_action_pressed("ui_cancel"):
				accept_event()
				_set_state(State.UPDATE_AVAILABLE)


func _check_updates():
	processing = true
	Launcher.emit_event("set_loading", [true])
	operation = Operation.CHECK
	semaphore.post()


func _update_system():
	processing = true
	Launcher.emit_event("set_loading", [true])
	operation = Operation.UPDATE
	semaphore.post()


func _check_completed(check_result, data):
	processing = false
	Launcher.emit_event("set_loading", [false])
	
	match check_result:
		Check.ERROR:
			message.text = tr("DEFAULT.UPDATE_CHECK_ERROR")
			_set_state(State.IDLE)
		Check.COMMIT_UPDATE_AVAILABLE:
			message.text = tr("DEFAULT.UPDATE_AVAILABLE").format([data.version])
			_set_state(State.UPDATE_AVAILABLE)
		Check.UPDATE_AVAILABLE:
			message.text = tr("DEFAULT.UPDATE_AVAILABLE").format([data.version])
			_set_state(State.UPDATE_AVAILABLE)
		Check.UP_TO_DATE:
			message.text = tr("DEFAULT.LAUNCHER_UP_TO_DATE")
			_set_state(State.IDLE)


func _update_completed(result):
	if result == OK:
		get_tree().quit()
	else:
		processing = false
		Launcher.emit_event("set_loading", [false])
		message.text = tr("DEFAULT.UPDATE_ERROR")
		_set_state(State.IDLE)


func _request_completed(result, response_code, headers, body, semaphore, res):
	if result == OK:
		var response = parse_json(body.get_string_from_utf8())
		if response.version != Launcher.get_version():
			res.append(Check.UPDATE_AVAILABLE)
		else:
			res.append(Check.UP_TO_DATE)
		res.append(response.version)
	else:
		res.append(Check.ERROR)
		res.append("")
	semaphore.post()


func _thread_function(data):
	var output = []
	
	while not should_exit:
		semaphore.wait()
		if should_exit:
			return
		
		if operation == Operation.CHECK:
			var req_semaphore = Semaphore.new()
			# Check if an update is available
			var result = []
			http.connect("request_completed", self, "_request_completed", [req_semaphore, result])
			http.request("https://raw.githubusercontent.com/samdze/godot-launcher/main/version.json")
			req_semaphore.wait()
			http.disconnect("request_completed", self, "_request_completed")
			
			print("Result of first check is " + str(result))
			if result[0] == Check.UP_TO_DATE:
				# Check latest commit instead of version
				var exit_code = OS.execute("bash", ["-c", "git remote update"], true, output, true)
				print("Exit code " + str(exit_code) + " for 'git remote update' with result: " + str(output))
				if exit_code != 0:
					result[0] = Check.ERROR
				else:
					OS.execute("bash", ["-c", "git show --no-notes --format=format:'%H' origin/main | head -n 1"], true, output, true)
					print("Remote: " + str(output))
					var remote_commit = output[0]
					OS.execute("bash", ["-c", "git show --no-notes --format=format:'%H' main | head -n 1"], true, output, true)
					print("Local: " + str(output))
					var local_commit = output[0]
					
					if remote_commit != local_commit:
						result[0] = Check.COMMIT_UPDATE_AVAILABLE
						result[1] = result[1] + "+"
			
			call_deferred("_check_completed", result[0], { "version": result[1] })
		elif operation == Operation.UPDATE:
			# Update the launcher
			var result = FAILED
			var exit_code = OS.execute("bash", ["-c", "git fetch --all"], true, output, true)
			print("Fetch (" + str(exit_code) + "): " + str(output))
			if exit_code == 0:
				exit_code = OS.execute("bash", ["-c", "git reset --hard origin/main"], true, output, true)
				print("Reset (" + str(exit_code) + "): " + str(output))
				if exit_code == 0:
					result = OK
			
			call_deferred("_update_completed", result)


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		should_exit = true
		semaphore.post()
		print("Waiting thread to finish...")
		thread.wait_to_finish()
