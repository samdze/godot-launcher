extends Node

const TAG_LAUNCHER = "launcher"
const TAG_RUNNING_APP = "running_app"
const TAG_SETTINGS = "settings"

var loaded_views = {}
var loaded_widgets = {}


func _ready():
	reload()


func reload():
	loaded_views.clear()
	loaded_widgets.clear()
	
	var dir = Directory.new()
	var res = dir.open("res://modules")
	if res != OK:
		printerr("Directory 'modules' not found! The launcher will not work.")
		return
	dir.list_dir_begin(true, true)
	var file_name : String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			
			_load_module(file_name)
		
		file_name = dir.get_next()


# Returns a View component entry { id, module, name, script, scene, tags } or null
func get_view(id):
	if loaded_views.has(id):
		return loaded_views[id]
	return null


# Returns a Widget component entry { id, module, name, script, scene, tags } or null
func get_widget(id):
	if loaded_widgets.has(id):
		return loaded_widgets[id]
	return null


# Returns an array of View component entries: [{ id, module, name, script, scene, tags }]
func get_loaded_views(tags = []) -> Array:
	var views = []
	for v in loaded_views.values():
		var add_to_result = true
		for t in tags:
			if not v["tags"].has(t):
				add_to_result = false
				break
		if add_to_result:
			views.append(v)
	return views


# Returns an array of Widgets component entries: { id, module, name, script, scene, tags }
func get_loaded_widgets(tags = []) -> Array:
	var widgets = []
	for v in loaded_widgets.values():
		var add_to_result = true
		for t in tags:
			if not v["tags"].has(t):
				add_to_result = false
				break
		if add_to_result:
			widgets.append(v)
	return widgets


func _load_module(module_name : String):
	print("Loading module " + module_name.to_upper())
	var dir = Directory.new()
	var res = dir.open("res://modules/" + module_name)
	if res != OK:
		printerr("Failed to load modules inside modules/" + module_name)
		return
	# Each folder should contain a component
	dir.list_dir_begin(true, true)
	var file_name : String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			var component_scene = null
			if ResourceLoader.exists("res://modules/" + module_name + "/" + file_name + "/" + file_name + ".tscn"):
				# The component has a PackedScene associated, save it for later.
				component_scene = ResourceLoader.load("res://modules/" + module_name + "/" + file_name + "/" + file_name + ".tscn")
			
			if ResourceLoader.exists("res://modules/" + module_name + "/" + file_name + "/" + file_name + ".gd"):
				# Script of the component found, check its type, name and load it.
				_load_component(module_name, ResourceLoader.load("res://modules/" + module_name + "/" + file_name + "/" + file_name + ".gd"), component_scene)
		
		file_name = dir.get_next()


func _load_component(module_name : String, script_class : GDScript, component_scene : PackedScene):
	var component_name = script_class._get_component_name()
	var component_tags = script_class._get_component_tags()
	var base_script = script_class.get_base_script()
	
	var entry = {}
	entry["id"] = module_name + "/" + script_class.resource_path.get_file().get_basename()
	entry["module"] = module_name
	entry["name"] = component_name
	entry["script"] = script_class
	entry["scene"] = component_scene
	entry["tags"] = component_tags
	
	print("Module " + module_name.to_upper() + " - Component \"" + component_name + "\" (" + entry["id"]  + ") found.")
	print("	Resource: " + script_class.resource_path)
	print("	Type: " + base_script.resource_path)
	print("	Tags: " + str(component_tags))
	
	if base_script == View:
		loaded_views[entry["id"]] = entry
	elif base_script == Widget:
		loaded_widgets[entry["id"]] = entry
