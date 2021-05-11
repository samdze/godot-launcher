extends ScrollContainer


func _ready():
	get_v_scrollbar().connect("visibility_changed", self, "_update_stylebox")
	get_h_scrollbar().connect("visibility_changed", self, "_update_stylebox")


func _update_stylebox():
	if get_v_scrollbar().visible and get_h_scrollbar().visible:
		add_stylebox_override("bg", get_stylebox("scroll_hv"))
	elif get_v_scrollbar().visible:
		add_stylebox_override("bg", get_stylebox("scroll_v"))
	elif get_h_scrollbar().visible:
		add_stylebox_override("bg", get_stylebox("scroll_h"))
	else:
		add_stylebox_override("bg", get_stylebox("no_scroll"))


# Overriding the default function called to ensure visibility of a node.
func _ensure_focused_visible(control : Control):
	if follow_focus:
		ensure_visible(control)


func ensure_visible(control : Control):
	if is_a_parent_of(control):
		var global_rect = get_global_rect()
		var other_rect = control.get_global_rect()
		var stylebox : StyleBox = get_stylebox("bg")
		var right_margin = stylebox.content_margin_right
		if get_v_scrollbar().visible:
			right_margin += get_v_scrollbar().get_size().x
		var left_margin = stylebox.content_margin_left;
		
		var bottom_margin = stylebox.content_margin_bottom
		if get_h_scrollbar().visible:
			bottom_margin += get_h_scrollbar().get_size().y
		var top_margin = stylebox.content_margin_top
		
		var diff = max(min(other_rect.position.y - top_margin, global_rect.position.y), other_rect.position.y + other_rect.size.y - global_rect.size.y + bottom_margin);
		scroll_vertical = scroll_vertical + (diff - global_rect.position.y)
		diff = max(min(other_rect.position.x - left_margin, global_rect.position.x), other_rect.position.x + other_rect.size.x - global_rect.size.x + right_margin);
		scroll_horizontal = scroll_horizontal + (diff - global_rect.position.x)
