extends Control
class_name LauncherEntry

signal executed(error)

export(String) var label : String = "" setget _set_label

onready var container : Control = $Container
onready var label_node : Label = $Container/Label
onready var highlight : TextureRect = $Container/HighlightRing
onready var tween : Tween = $Tween


# Substitute label with a string of choice in a subclass to give this entry a custom name.
func _ready():
	_set_label(label)


# Extend this class and override this method to define what happens when this entry is selected.
# Call "executed(error)" at the end of the method or when you're done if it's an asynchronous task.
# In "executed(error)", error should be OK or FAILED.
# Return OK if the execution is successful.
# Return FAILED otherwise.
func exec():
	
	executed(OK)
	return OK


func set_highlighted(highlighted):
	tween.remove_all()
	if highlighted:
		highlight.visible = true
		tween.interpolate_property(highlight, "rect_rotation", 0, 30, 0.2)
	else:
		highlight.hide()
	tween.start()


func _set_label(value):
	if label_node:
		label_node.text = value
	label = value


func executed(error):
	emit_signal("executed", error)
