extends Control

signal step_completed(succeeded)


func enable():
	show()
	grab_focus()


func disable():
	hide()


func _gui_input(event):
	if event.is_pressed() and not event.is_echo():
		print("Received and input in Setup Completed")
		accept_event()
		emit_signal("step_completed", true)
