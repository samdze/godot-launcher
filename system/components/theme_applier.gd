extends Control

export(Dictionary) var font_values : Dictionary
export(Dictionary) var constant_values : Dictionary
export(Dictionary) var color_values : Dictionary
export(Dictionary) var stylebox_values : Dictionary
export(Dictionary) var texture_values : Dictionary



func _ready():
	for k in font_values.keys():
		add_font_override(k, get_font(font_values[k]))
	for k in constant_values.keys():
		add_constant_override(k, get_constant(constant_values[k]))
	for k in color_values.keys():
		add_color_override(k, get_color(color_values[k]))
	for k in stylebox_values.keys():
		add_stylebox_override(k, get_stylebox(stylebox_values[k]))
	for k in texture_values.keys():
		add_icon_override(k, get_icon(texture_values[k]))
