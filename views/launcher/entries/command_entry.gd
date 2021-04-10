extends LauncherEntry

export(String, MULTILINE) var command

var thread : Thread
var running = false


func _ready():
	set_process(false)


func init_from_file(directory, file_name):
	command = "cd '" + directory + "'\n"+ \
		"exec ./" + file_name


func exec():
	thread = Thread.new()
	var result = thread.start(self, "_thread_func", command)
	if result == OK:
		running = true
		set_process(true)
	else:
		executed(FAILED)
	return result


func _process(delta):
	if not thread.is_active():
		_emit_executed(FAILED)


func is_running():
	return running


func _thread_func(cmd):
	print("[Start Command Entry thread]\n" + cmd + "\n[End Command Entry]")
	var output = []
	var result = OS.execute("bash", ["-c", cmd], true, output, true)
	prints("[Command Entry thread finished with exit code " + str(result) + "]")
	if output.size() > 0:
		print(str(output) + "\n")
	call_deferred("_emit_executed", OK if result == 0 else FAILED)


func _emit_executed(error):
	prints("Waiting for thread.")
	thread.wait_to_finish()
	running = false
	set_process(false)
	executed(error)
	prints("Thread terminated.")
