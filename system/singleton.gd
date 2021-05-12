extends Node

var version : String


func _ready():
	var version_file = File.new()
	if version_file.open(ProjectSettings.globalize_path("res://version.json"), File.READ) == OK:
		version = parse_json(version_file.get_as_text()).version
		print("System version: " + version)


func get_version() -> String:
	return version


func get_ui() -> System:
	return get_tree().current_scene as System


func emit_event(name, arguments = []):
	return get_tree().current_scene.emit_event(name, arguments)
