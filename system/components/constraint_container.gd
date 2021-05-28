extends Container
class_name ConstraintContainer

enum HAlignment { LEFT, CENTER, RIGHT }
enum VAlignment { TOP, CENTER, BOTTOM }

export(bool) var constraint_width : bool = false
export(bool) var constraint_height : bool = false
# When the size reaches the max value, align children to an edge or center them.
export(HAlignment) var h_alignment = HAlignment.CENTER
export(VAlignment) var v_alignment = VAlignment.CENTER
# Set max_width or max_height to 0 to use the default value defined in the Theme.
export(int, 0, 8192) var max_width = 0
export(int, 0, 8192) var max_height = 0


func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		var max_size = rect_size
		if constraint_width:
			max_size.x = get_constant("max_width", "ConstraintContainer") if max_width == 0 else max_width
		if constraint_height:
			max_size.y = get_constant("max_height", "ConstraintContainer") if max_height == 0 else max_height
		var final_size = Vector2(min(max_size.x, rect_size.x) if max_size.x > 0 else rect_size.x,
			min(max_size.y, rect_size.y) if max_size.y > 0 else rect_size.y)
		var final_position = (rect_size - final_size) / 2
		for c in get_children():
			fit_child_in_rect(c, Rect2(final_position, final_size))
