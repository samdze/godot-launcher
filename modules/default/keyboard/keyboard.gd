extends App

signal text_entered(confirmed, text)

enum Layout { CHARACTERS, SYMBOLS }

export(NodePath) var first_characters_focused_key
export(NodePath) var first_symbols_focused_key

var title : String = "Keyboard"
var active_layout = Layout.CHARACTERS
var typed_text : String = ""
var cursor_position : int = 0

var last_focused_key : Control = null
var _text_font : Font = null

onready var scroll_container = $Layout/PanelContainer/MarginContainer/TextContainer
onready var text : Label = $Layout/PanelContainer/MarginContainer/TextContainer/LargeLabel
onready var highlighter : Control = $Layout/PanelContainer/MarginContainer/TextContainer/LargeLabel/Highlighter
onready var characters : Control = $Layout/KeysContainer/Characters
onready var symbols : Control = $Layout/KeysContainer/Symbols
onready var tween : Tween = $Tween


func _ready():
	_configure_layout(characters)
	_configure_layout(symbols)
	_switch_layout(active_layout, false)
	
	text.text = typed_text
	cursor_position = text.text.length()
	
	_text_font = text.get_font("font")
	
	_update_cursor_position()
	tween.interpolate_callback(highlighter, 0.35, "hide")
	tween.interpolate_callback(highlighter, 0.7, "show")
	tween.start()


func _configure_layout(layout):
	# Configure focus of keys on the edges
	# Top row
	for k in layout.get_node("Row1").get_children():
		k.focus_neighbour_top = k.get_path()
	# Bottom row
	for k in layout.get_node("Row4").get_children():
		k.focus_neighbour_bottom = k.get_path()
	# Left column
	for r in layout.get_children():
		r.get_child(0).focus_neighbour_left = r.get_child(0).get_path()
	# Right column
	for r in layout.get_children():
		r.get_child(r.get_child_count() - 1).focus_neighbour_right = r.get_child(r.get_child_count() - 1).get_path()
	# Configure button presses
	for r in layout.get_children():
		for k in r.get_children():
			k.connect("focus_entered", self, "_key_focused", [k])
			if k.name == "Right":
				k.connect("pressed", self, "_move_cursor", [true, 1])
			elif k.name == "Left":
				k.connect("pressed", self, "_move_cursor", [false, 1])
			else:
				k.connect("pressed", self, "_key_pressed", [k])


func _switch_layout(layout = null, update_prompts = false):
	active_layout = layout if layout != null else (Layout.SYMBOLS if active_layout == Layout.CHARACTERS else Layout.CHARACTERS)
	characters.hide()
	symbols.hide()
	match active_layout:
		Layout.CHARACTERS:
			characters.show()
			if update_prompts:
				Launcher.get_ui().bottom_bar.set_prompts([BottomBar.ICON_NAV, BottomBar.PROMPT_NAV],
					[BottomBar.ICON_BUTTON_START, BottomBar.PROMPT_DONE,
					BottomBar.ICON_BUTTON_X, BottomBar.PROMPT_CASE_SWITCH,
					BottomBar.ICON_BUTTON_Y, BottomBar.PROMPT_SYMBOLS_SWITCH,
					BottomBar.ICON_BUTTON_A, BottomBar.PROMPT_SELECT,
					BottomBar.ICON_BUTTON_B, BottomBar.PROMPT_BACKSPACE])
		Layout.SYMBOLS:
			symbols.show()
			if update_prompts:
				Launcher.get_ui().bottom_bar.set_prompts([BottomBar.ICON_NAV, BottomBar.PROMPT_NAV],
					[BottomBar.ICON_BUTTON_START, BottomBar.PROMPT_DONE,
					BottomBar.ICON_BUTTON_Y, BottomBar.PROMPT_CHAR_SWITCH,
					BottomBar.ICON_BUTTON_A, BottomBar.PROMPT_SELECT,
					BottomBar.ICON_BUTTON_B, BottomBar.PROMPT_BACKSPACE])


func _focus_first_key():
	match active_layout:
		Layout.CHARACTERS:
			get_node(first_characters_focused_key).grab_focus()
		Layout.SYMBOLS:
			get_node(first_symbols_focused_key).grab_focus()


func _append_string_at_cursor(text : String):
	self.text.text = self.text.text.insert(cursor_position, text)
	_move_cursor(true, text.length())


func _delete_string_at_cursor(lenght):
	self.text.text = self.text.text.left(max(0, cursor_position - lenght)) + self.text.text.substr(cursor_position, self.text.text.length() -  cursor_position)
	_move_cursor(false, lenght)


func _move_cursor(right, amount : int = 1):
	cursor_position = clamp(cursor_position + (1 if right else -1) * amount, 0, text.text.length())
	_update_cursor_position()


func _update_cursor_position():
	var text_caret_size = _text_font.get_string_size(text.text.substr(0, cursor_position))
	highlighter.rect_size.y = _text_font.get_height()
	highlighter.rect_global_position = text.rect_global_position + Vector2(text_caret_size.x, 0)
	highlighter.rect_size = highlighter.rect_size
	text.rect_min_size.x = highlighter.rect_position.x + highlighter.rect_size.x
	
	scroll_container.notification(Container.NOTIFICATION_SORT_CHILDREN)
	
	call_deferred("_ensure_cursor_visible")


func _ensure_cursor_visible():
	var global_rect = scroll_container.get_global_rect();
	var other_rect = highlighter.get_global_rect();
	other_rect.size = Vector2(other_rect.size.x, other_rect.size.y)
	var right_margin = 0;
	if scroll_container.get_v_scrollbar().visible:
		right_margin += scroll_container.get_v_scrollbar().get_size().x
	
	var bottom_margin = 0;
	if scroll_container.get_h_scrollbar().visible:
		bottom_margin += scroll_container.get_h_scrollbar().get_size().y

	var diff = max(min(other_rect.position.y, global_rect.position.y), other_rect.position.y + other_rect.size.y - global_rect.size.y + bottom_margin);
	scroll_container.scroll_vertical = scroll_container.scroll_vertical + (diff - global_rect.position.y)
	diff = max(min(other_rect.position.x, global_rect.position.x), other_rect.position.x + other_rect.size.x - global_rect.size.x + right_margin);
	scroll_container.scroll_horizontal = scroll_container.scroll_horizontal + (diff - global_rect.position.x)


func _focus():
	emit_signal("bars_visibility_change_requested", true, true)
	emit_signal("title_change_requested", title)
	emit_signal("mode_change_requested", LauncherUI.Mode.OPAQUE)
	Launcher.get_ui().bottom_bar.set_prompts([BottomBar.ICON_NAV, BottomBar.PROMPT_NAV],
		[BottomBar.ICON_BUTTON_START, BottomBar.PROMPT_DONE, BottomBar.ICON_BUTTON_X, BottomBar.PROMPT_CASE_SWITCH,
		BottomBar.ICON_BUTTON_Y, BottomBar.PROMPT_SYMBOLS_SWITCH,
		BottomBar.ICON_BUTTON_A, BottomBar.PROMPT_SELECT, BottomBar.ICON_BUTTON_B, BottomBar.PROMPT_BACKSPACE])
	
	_switch_layout(active_layout, true)
	if last_focused_key != null:
		last_focused_key.grab_focus()
	else:
		_focus_first_key()


# Called when the App is focuses and receives an input.
# Override this function instead of _input to receive global events.
func _app_input(event : InputEvent):
	if event.is_action_pressed("ui_start"):
		accept_event()
		emit_signal("text_entered", true, text.text)
		Launcher.get_ui().app.back_app()
	if event.is_action_pressed("ui_menu"):
		accept_event()
		emit_signal("text_entered", false, text.text)
		Launcher.get_ui().app.back_app()
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		_delete_string_at_cursor(1)
	if event.is_action_pressed("ui_button_x"):
		accept_event()
		var is_uppercase = characters.get_child(1).get_child(0).text == characters.get_child(1).get_child(0).text.to_upper()
		for r in characters.get_children():
			for k in r.get_children():
				k.text = k.text.to_lower() if is_uppercase else k.text.to_upper()
	if event.is_action_pressed("ui_button_y"):
		accept_event()
		_switch_layout(null, true)
		_focus_first_key()


func _key_pressed(button : Button):
	_append_string_at_cursor(button.text)


func _key_focused(button : Button):
	last_focused_key = button


static func _get_component_name():
	return "Keyboard"


static func _get_component_tags():
	return [Component.TAG_KEYBOARD]
