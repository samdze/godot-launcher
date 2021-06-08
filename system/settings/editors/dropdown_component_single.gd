extends SettingEditor

export(Component.Type) var type
export(String) var tags
export(bool) var reload_needed = false

var setting_section : String
var setting_key : String
var setting_label : String

var options = []

onready var entry = $SettingEntry
onready var dropdown : BaseButton = $SettingEntry/EditorsContainer/Dropdown


func _ready():
	var tags_array = tags.split(",")
#	print("Tags array: " + str(tags_array))
#	print("Tags array size: " + str(tags_array.size()))
	if tags_array.size() == 1 and tags_array[0].empty():
		tags_array = []
	var selected_entry = null
	options = Modules.get_components(type, tags_array)
	selected_entry = Modules.get_component_from_settings(setting_section + "/" + setting_key)
	
#	print("Returned components: "+str(options))
	
	connect("focus_entered", self, "_focus_entered")
	connect("focus_exited", self, "_focus_exited")
	connect("gui_input", self, "_gui_input")
	
	dropdown.focus_neighbour_top = dropdown.get_path()
	dropdown.focus_neighbour_bottom = dropdown.get_path()
	dropdown.focus_neighbour_left = dropdown.get_path()
	dropdown.focus_neighbour_right = dropdown.get_path()
	dropdown.connect("toggled", self, "_selection_focus_toggled")
	dropdown.connect("item_selected", self, "_item_selected")
	
	_generate_items(options, selected_entry)
	entry.label.text = setting_label


func _generate_items(options, selected_option = null) -> Control:
	var selected = null
	dropdown.clear_items()
	for o in options:
		var button : Button = Button.new()
		if selected_option != null and selected_option == o:
			selected = button
		button.set_meta("data", o)
		button.clip_text = true
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.text = o["module"].to_upper() + ": " + o["name"]
		button.align = Button.ALIGN_LEFT
		button.toggle_mode = true
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		dropdown.add_item(button)
	if selected != null:
		dropdown.set_selected(selected)
	return selected


func _initialize_setting(sections_keys : Array, label : String):
	var first_pair = sections_keys[0].split("/")
	setting_section = first_pair[0]
	setting_key = first_pair[1]
	setting_label = label


func _focus_entered():
	entry.focus()


func _focus_exited():
	entry.unfocus()


func _gui_input(event : InputEvent):
	if event.is_action_pressed("ui_accept"):
		dropdown.grab_focus()
		Input.parse_input_event(event)


func _selection_focus_toggled(pressed):
	if pressed:
		_focus_entered()
	else:
		call_deferred("grab_focus")


func _item_selected(item):
	# Option selected, save/apply selection
	dropdown.emit_signal("toggled", false)
	emit_signal("value_changed", setting_section + "/" + setting_key, item.get_meta("data").id, reload_needed)
