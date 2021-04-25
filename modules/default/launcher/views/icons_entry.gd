extends "../entry.gd"

var label : String = "" setget _set_label
var icon : Texture = null setget _set_icon

onready var label_node : Label = $Container/Label
onready var container : Control = $Container
onready var highlight : TextureRect = $Container/HighlightRing
onready var tween : Tween = $Tween


func _ready():
	._ready()
	_set_label(label)
	_set_icon(icon)


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


func _set_icon(icon):
	
	pass


func init(script : LauncherEntry):
	.init(script)
	_set_label(entry_script.get_label())
	_set_icon(entry_script.get_icon())
