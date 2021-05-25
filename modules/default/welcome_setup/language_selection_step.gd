extends Control

signal step_completed(succeeded)

var string_index = 0

onready var languages_container = $ScrollContainer/VBoxContainer


func enable():
	show()
	var locales = TranslationServer.get_loaded_locales() #System.get_languages().keys()
	var selected_entry = null
	selected_entry = TranslationServer.get_locale()
	
	for c in languages_container.get_children():
		languages_container.remove_child(c)
		c.queue_free()
	
	var selected = null
	for l in locales:
		var button : Button = Button.new()
		if selected_entry != null and selected_entry == l:
			selected = button
		button.clip_text = true
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		if System.get_languages().has(l):
			button.text = System.get_languages()[l]
		else:
			button.text = TranslationServer.get_locale_name(l)
		button.align = Button.ALIGN_LEFT
		button.toggle_mode = true
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		button.connect("pressed", self, "_language_button_pressed", [l])
		languages_container.add_child(button)
	if selected != null:
		selected.grab_focus()
	
	for c in languages_container.get_children():
		var index = c.get_index()
		c.focus_neighbour_left = c.get_path()
		c.focus_neighbour_right = c.get_path()
		if index > 0:
			c.focus_neighbour_top = languages_container.get_child(index - 1).get_path()
		else:
			c.focus_neighbour_top = languages_container.get_child(languages_container.get_child_count() - 1).get_path()
		if index < languages_container.get_child_count() - 1:
			c.focus_neighbour_bottom = languages_container.get_child(index + 1).get_path()
		else:
			c.focus_neighbour_bottom = languages_container.get_child(0).get_path()


func disable():
	hide()


func _language_button_pressed(locale):
	accept_event()
	Settings.set_value("system/language", locale)
	TranslationServer.set_locale(locale)
	
	emit_signal("step_completed", true)
