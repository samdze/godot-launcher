extends Node
class_name ThemeApplier

var theme_node : Control

export(NodePath) var apply_to


func _ready():
	theme_node = get_node(apply_to)
	theme_node.theme = Modules.get_loaded_component_from_config("system", "theme", "default/light_theme").resource
