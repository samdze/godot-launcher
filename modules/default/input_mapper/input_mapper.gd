extends App

var previous_mapping = {}
var mapping_order = [
	"A", "B", "X", "Y", "→", "↑", "←", "↓", "MENU", "START", "OPTION"
]
var actions_order = [
	"ui_accept", "ui_cancel", "ui_button_x", "ui_button_y", "ui_right",
	"ui_up", "ui_left", "ui_down", "ui_menu", "ui_start", "alt_start"
]
var map_index = 0

onready var button_label = $VBoxContainer/HBoxContainer/PressLabel


func _ready():
	pass


func _focus():
	emit_signal("status_visibility_change_requested", false)
	emit_signal("title_change_requested", "Input Mapper")
	emit_signal("mode_change_requested", System.Mode.OPAQUE)
	
	previous_mapping.clear()
	for a in InputMap.get_actions():
		previous_mapping[a] = InputMap.get_action_list(a)
		InputMap.action_erase_events(a)
	
	map_index = 0
	_update_prompt()
	
	grab_focus()


func _unfocus():
	# Restoring the previous mapping if the new mapping is not completed.
	if map_index < mapping_order.size():
		for action in previous_mapping.keys():
			InputMap.action_erase_events(action)
			for e in previous_mapping[action]:
				InputMap.action_add_event(action, e)
	previous_mapping.clear()


func _update_prompt():
	if map_index <= mapping_order.size() - 1:
		button_label.text = mapping_order[map_index]
	else:
		button_label.text = "✓"


func _app_input(event : InputEvent):
	if map_index < mapping_order.size():
		if event.is_pressed():
			
			InputMap.action_add_event(actions_order[map_index], event)
			
			map_index += 1
			_update_prompt()
	else:
		if event.is_pressed():
			Launcher.get_ui().app.back_app()


# Called when the App is about to be destroyed and freed from memory.
# Do your cleanup here if needed.
func _destroy():
	pass


static func _get_component_name():
	return "Input Mapper"


# Override this function to expose user-editable settings to the Settings app
static func _get_settings():
	return [
		Setting.export([], TranslationServer.translate("DEFAULT.FOLDER_SYSTEM") + "/" + TranslationServer.translate("DEFAULT.INPUT_SETTINGS"), load("res://modules/default/input_mapper/settings/input_map_button.tscn"))
	]
