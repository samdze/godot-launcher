extends Node

var loaded_components = {} # Dictionary of { id: Component }


func _ready():
	reload()


func reload():
	Settings.reset()
	loaded_components.clear()
	
	# Load system module
	var system_exports = Launcher._get_settings()
	if system_exports != null and system_exports.size() > 0:
		var system_component = Component.new()
		system_component.id = "system"
		system_component.module = ""
		system_component.name = "Launcher"
		system_component.resource = preload("res://system/launcher.tscn")
		system_component.type = Component.Type.SYSTEM
		system_component.tags = [Component.TAG_SYSTEM]
		
		loaded_components[system_component.id] = system_component
		_load_settings(system_component, system_exports)
	
	# Load other modules
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
#	Settings.update()


# Returns a component entry { id, module, name, script, scene, tags } or null
func get_loaded_component(id : String) -> Component:
	if loaded_components.has(id):
		return loaded_components[id]
	return null


func get_loaded_component_from_settings(section_key : String) -> Component:
	var id = Settings.get_value(section_key)
	if loaded_components.has(id):
		return get_loaded_component(id)
	Settings.reset_to_default(section_key)
	id = Settings.get_value(section_key)
	if loaded_components.has(id):
		return get_loaded_component(id)
	return null


# Returns an array of Components, by default the Launcher component is excluded
func get_loaded_components(types : int = Component.Type.ANY, tags : Array = []) -> Array:
	var components = []
	for v in loaded_components.values():
		var add_to_result = true
		if not v.type & types:
			continue
		for t in tags:
			if not v["tags"].has(t):
				add_to_result = false
				break
		if add_to_result:
			components.append(v)
	return components


func _load_module(module_name : String):
	print("Loading module " + module_name.to_upper())
	var has_localizations = false
	var has_english_translation = false
	var dir = Directory.new()
	var res = dir.open("res://modules/" + module_name)
	if res != OK:
		printerr("Failed to load components inside modules/" + module_name)
		return
	# Each folder should contain a component
	dir.list_dir_begin(true, true)
	var components_to_load = []
	var file_name : String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			components_to_load.append(file_name)
		elif file_name.get_extension() == "translation":
			# This is a translation resource, load it before anything else in this module.
			has_localizations = true
			var translation : Translation = ResourceLoader.load("res://modules/" + module_name + "/" + file_name)
			if translation.locale == "en":
				has_english_translation = true
			TranslationServer.add_translation(translation)
			print("Module " + module_name.to_upper() + " - Translation \"" + file_name + "\" found.")
		
		file_name = dir.get_next()
	
	for c_name in components_to_load:
		var component_resource = null
		# Componnets must have .tscn or .tres extension
		if ResourceLoader.exists("res://modules/" + module_name + "/" + c_name + "/" + c_name + ".tscn"):
			component_resource = ResourceLoader.load("res://modules/" + module_name + "/" + c_name + "/" + c_name + ".tscn")
		elif ResourceLoader.exists("res://modules/" + module_name + "/" + c_name + "/" + c_name + ".tres"):
			component_resource = ResourceLoader.load("res://modules/" + module_name + "/" + c_name + "/" + c_name + ".tres")
		if component_resource != null:
			# Valid Component found, load it
			_load_component(module_name, component_resource)
	
	if has_localizations and not has_english_translation:
		printerr("Module " + module_name.to_upper() + " doesn't have an english translation!")


func _load_component(module_name : String, component_resource : Resource):
	var component_class = component_resource
	if component_resource.resource_path.get_extension() == "tscn":
		# This is a PackedScene, special processing is needed
		component_class = _find_packed_scene_script(component_resource)
	
	var component_name = component_class._get_component_name()
	var component_tags = component_class._get_component_tags()
	var component_settings = component_class._get_settings()
	var component_type = component_class._get_component_type()
	
	var entry : Component = Component.new()
	entry.id = module_name + "/" + component_resource.resource_path.get_file().get_basename()
	entry.module = module_name
	entry.name = component_name
	entry.resource = component_resource
	entry.tags = component_tags
	entry.type = component_type
	
	print("Module " + module_name.to_upper() + " - Component \"" + component_name + "\" (" + entry["id"]  + ") found.")
	print("	Resource: " + component_resource.resource_path)
	print("	Type: " + str(component_type))
	print("	Tags: " + str(component_tags))
	
	if component_settings != null and component_settings.size() > 0:
		_load_settings(entry, component_settings)
	
	loaded_components[entry.id] = entry


func _load_settings(entry, settings):
	var definitions = []
	var exports = []
	for s in settings:
		if s is Setting.Init:
			definitions.append(s)
		elif s is Setting.Export:
			exports.append(s)
	Settings.add_settings_definitions(entry, definitions)
	Settings.add_settings_exports(entry, exports)


func _find_packed_scene_script(scene : PackedScene) -> GDScript:
	var state : SceneState = scene.get_state()
	for i in range(state.get_node_property_count(0)):
#		print(str(i) + " property " + state.get_node_property_name(0, i) +": "+ str(state.get_node_property_value(0, i)))
		if state.get_node_property_name(0, i) == "script":
			var script_resource : GDScript = state.get_node_property_value(0, i)
#			print("	Found script resource: " + script_resource.get_instance_base_type())
			return script_resource
	return null
