extends PanelContainer

onready var label = $EditorsContainer/LabelContainer/Label


func _ready():
	connect("focus_entered", self, "focus")
	connect("focus_exited", self, "unfocus")


func focus():
	add_stylebox_override("panel", get_stylebox("focus"))


func unfocus():
	add_stylebox_override("panel", null)
