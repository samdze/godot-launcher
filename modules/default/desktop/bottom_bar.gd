extends MarginContainer

const icon_mappings = {
	Desktop.Input.MOVE: "button_nav",
	Desktop.Input.A: "button_a",
	Desktop.Input.B: "button_b",
	Desktop.Input.X: "button_x",
	Desktop.Input.Y: "button_y",
	Desktop.Input.RIGHT: "button_right",
	Desktop.Input.UP: "button_up",
	Desktop.Input.LEFT: "button_left",
	Desktop.Input.DOWN: "button_down",
	Desktop.Input.START: "button_start",
	Desktop.Input.MENU: "button_menu",
	Desktop.Input.HOME: "button_home",
	Desktop.Input.MOVE_H: "button_nav_h",
	Desktop.Input.MOVE_V: "button_nav_v"
}

onready var left_container = $InputEvents/HBoxContainer/Left
onready var right_container = $InputEvents/HBoxContainer/Right


# Left_prompts and right_prompts are arrays of Desktop.Input.*s and strings.
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
		var texture = null
		if icon_mappings.has(left_prompts[i]):
			texture = get_icon(icon_mappings[left_prompts[i]], "Control")
		icon.texture = texture
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
		var texture = null
		if icon_mappings.has(right_prompts[i]):
			texture = get_icon(icon_mappings[right_prompts[i]], "Control")
		icon.texture = texture
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
