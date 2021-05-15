extends Control

export(String) var control_type : String

export(Dictionary) var font_values : Dictionary
export(Dictionary) var constant_values : Dictionary
export(Dictionary) var color_values : Dictionary
export(Dictionary) var stylebox_values : Dictionary
export(Dictionary) var texture_values : Dictionary


func _ready():
	for k in font_values.keys():
		set(k, get_font(font_values[k], control_type))
	for k in constant_values.keys():
		set(k, get_constant(constant_values[k], control_type))
	for k in color_values.keys():
		set(k, get_color(color_values[k], control_type))
	for k in stylebox_values.keys():
		set(k, get_stylebox(stylebox_values[k], control_type))
	for k in texture_values.keys():
		set(k, get_icon(texture_values[k], control_type))
