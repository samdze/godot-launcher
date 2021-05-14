extends PanelContainer

onready var label = $EditorsContainer/LabelContainer/Label


func _ready():
	label.add_color_override("font_color", get_color("font_color", "Button"))
	connect("focus_entered", self, "focus")
	connect("focus_exited", self, "unfocus")


func focus():
	add_stylebox_override("panel", get_stylebox("focus"))
	label.add_color_override("font_color", get_color("font_color_hover", "Button"))


func unfocus():
	add_stylebox_override("panel", null)
	label.add_color_override("font_color", get_color("font_color", "Button"))
