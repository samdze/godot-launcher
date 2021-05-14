extends Node
class_name ModulateApplier

enum ModulateType { MODULATE, SELF_MODULATE }

var control_node : Control

export(NodePath) var apply_to
export(ModulateType) var modulate_type
export(String) var color_property


func _ready():
	control_node = get_node(apply_to)
	
	match modulate_type:
		ModulateType.MODULATE:
			control_node.modulate = control_node.get_color(color_property)
		ModulateType.SELF_MODULATE:
			control_node.self_modulate = control_node.get_color(color_property)
