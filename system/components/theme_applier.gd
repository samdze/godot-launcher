extends Node
class_name ThemeApplier

var theme_node : Control

export(NodePath) var apply_to


func _ready():
	theme_node = get_node(apply_to)
	theme_node.theme = Modules.get_component_from_settings("system/theme").resource
