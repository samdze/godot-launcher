extends Control
class_name View

# Emit this signal when you want to change the top and bottom bars visibility
signal bars_visibility_change_requested(show_top_bar, show_bottom_bar)
# Emit this signal when you want to change the top bar title
signal title_change_requested(title)
# Emit this signal when you want to change the launcher mode to opaque or transparent
signal mode_change_requested(mode)


func _ready():
	
	pass


# Called when the view gains focus, setup the view here.
# Signals like bars_visibility_change_requested and title_change_requested are best called here.
func _focus():
#	emit_signal("bars_visibility_change_requested", true, true)
#	emit_signal("title_change_requested", "My Custom View")
#	emit_signal("mode_change_requested", LauncherUI.Mode.OPAQUE)
	pass


# Called when the view loses focus
func _unfocus():
	
	pass


# Called when the view is focuses and receives an input.
# Override this function instead of _input to receive global events.
func _view_input(event):
	
	pass


# Called when the active window changes name
func _window_name_changed(name):
	
	pass


# Called when another window becomes active
func _active_window_changed(window_id):
	
	pass
