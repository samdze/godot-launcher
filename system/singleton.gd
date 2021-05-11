extends Node


func get_ui() -> System:
	return get_tree().current_scene as System


func emit_event(name, arguments = []):
	return get_tree().current_scene.emit_event(name, arguments)
