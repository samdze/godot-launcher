extends MarginContainer
class_name BottomBar

const ICON_NAV = 0
const ICON_BUTTON_X = 1
const ICON_BUTTON_Y = 2
const ICON_BUTTON_A = 3
const ICON_BUTTON_B = 4
const ICON_BUTTON_MENU = 5
const ICON_BUTTON_SELECT = 6
const ICON_BUTTON_START = 7
const ICON_NAV_V = 8
const ICON_NAV_H = 9

onready var left_container = $InputEvents/HBoxContainer/Left
onready var right_container = $InputEvents/HBoxContainer/Right

export(Array, Texture) var icons


# Left_prompts and right_prompts are arrays of ICON_*s and strings.
# Each couple of values define the icon and the text of the prompt.
func set_prompts(left_prompts, right_prompts):
	for c in left_container.get_children():
		left_container.remove_child(c)
		c.queue_free()
	for c in right_container.get_children():
		right_container.remove_child(c)
		c.queue_free()
	
	var i = 0
	while i < left_prompts.size():
		var hbox = HBoxContainer.new()
		hbox.add_constant_override("separation", 2)
		var icon = TextureRect.new()
		icon.texture = icons[left_prompts[i]]
		icon.self_modulate = get_color("contrast", "Control")
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var text = preload("res://system/components/small_label.tscn").instance()
		text.valign = Label.VALIGN_CENTER
		text.text = left_prompts[i + 1]
		
		hbox.add_child(icon)
		hbox.add_child(text)
		hbox.name = left_prompts[i + 1]
		left_container.add_child(hbox)
		i += 2
	i = 0
	while i < right_prompts.size():
		var hbox = HBoxContainer.new()
		hbox.add_constant_override("separation", 2)
		var icon = TextureRect.new()
		icon.texture = icons[right_prompts[i]]
		icon.self_modulate = get_color("contrast", "Control")
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var text = preload("res://system/components/small_label.tscn").instance()
		text.valign = Label.VALIGN_CENTER
		text.text = right_prompts[i + 1]
		
		hbox.add_child(icon)
		hbox.add_child(text)
		hbox.name = right_prompts[i + 1]
		right_container.add_child(hbox)
		i += 2
