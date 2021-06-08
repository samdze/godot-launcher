extends Node

var system_component = null
# Lists of components for each type+tag combination
var types_tags = {}				# Dictionary of { type/tag: Component[] }
# Lists of components dependant on each type+tag combination
var dependencies = {}			# Dictionary of { type/tag: Component[] }
# All the available components, indexed by id
var components = {}				# Dictionary of { id: Component }
var available_components = {}	# Dictionary of { id: Component }
var unavailable_components = {}	# Dictionary of { id: Component }


func _ready():
	reload()


func reload():
	Settings.reset()
	components.clear()
	system_component = null
	types_tags.clear()
	dependencies.clear()
	
	available_components.clear()
	unavailable_components.clear()
	
	# New modules system
	# 1. Collect all the components, catalogue them based on type and tags.
	_collect_modules()
	# 2. Resolve which components are unavailable or have dependencies that don't exist.
	var unavailable = _detect_unavailable_components()
	# 3. Disable components found in point 2, recursively. Any component disabled decreases the number of component
	#	available for its type and tags. When a value reaches zero, components depending on it will be disabled too.
	var disabled = _disable_components(unavailable)
	# 4. Detect if there are conflicting components, that is, components having the same tag and generate their settings.
	_select_tagged_components()
	# 5. Generate tags settings definitions, so that the user can later choose which one to use.
#	_generate_tags_settings_definitions()
	# 6. Generate standard settings defined by components.
	_generate_settings()
	
#	_load_modules()


func get_component(id : String) -> Component:
	if components.has(id):
		return components[id]
	return null


# Returns a component entry { id, module, name, script, scene, tags } or null
func get_available_component(id : String) -> Component:
	if available_components.has(id):
		return available_components[id]
	return null


# Returns a component entry { id, module, name, script, scene, tags } or null
func get_unavailable_component(id : String) -> Component:
	if unavailable_components.has(id):
		return unavailable_components[id]
	return null


func get_component_from_settings(section_key : String) -> Component:
	var id = Settings.get_value(section_key)
	if components.has(id):
		return get_component(id)
	Settings.reset_to_default(section_key)
	id = Settings.get_value(section_key)
	if components.has(id):
		return get_component(id)
	return null


# Returns an array of Components, by default the Launcher component is excluded
func get_components(types : int = Component.Type.ANY, tags : Array = []) -> Array:
	var components_list = []
	for v in components.values():
		var add_to_result = true
		if not v.type & types:
			continue
		for t in tags:
			if not v["tags"].has(t):
				add_to_result = false
				break
		if add_to_result:
			components_list.append(v)
	return components_list


func get_tagged_component(type : int, tag : String):
	return get_component_from_settings("tags/" + tag + "_" + Component.get_type_name(type))


# Returns an array of Components, by default the Launcher component is excluded
func get_available_components(types : int = Component.Type.ANY, tags : Array = []) -> Array:
	var components = []
	for v in available_components.values():
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


# Returns an array of Components, by default the Launcher component is excluded
func get_unavailable_components(types : int = Component.Type.ANY, tags : Array = []) -> Array:
	var components = []
	for v in unavailable_components.values():
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


func _collect_modules():
	# Load system module
	system_component = Component.new()
	system_component.id = "system"
	system_component.module = ""
	system_component.name = "Launcher"
	system_component.definition = preload("res://system/launcher.gd")
	system_component.resource = preload("res://system/launcher.tscn")
	system_component.type = Component.Type.SYSTEM
	system_component.tags = [Component.TAG_SYSTEM]
	
#	dependencies[str(Component.Type.SYSTEM) + "/" + Component.TAG_SYSTEM] = []
	components[system_component.id] = system_component
	
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
			
			_collect_module(file_name)
		
		file_name = dir.get_next()


func _detect_unavailable_components() -> Array:
	var unavailable = []
	for id in components.keys():
		var c = components[id]
		if not c.definition._is_available():
			unavailable.append(c)
			continue
		var component_dependencies = c.definition._get_dependencies()
		for i in range(component_dependencies.size()):
			var dep = component_dependencies[i]
			if not types_tags.has(str(dep.type) + "/" + dep.tag):
				unavailable.append(c)
				i = component_dependencies.size()
				continue
	return unavailable


func _disable_components(to_disable : Array) -> Array:
	var disabled = {}
	
	while to_disable.size() > 0:
		var disabling = to_disable.pop_front()
		if not disabled.has(disabling):
			print("Disabling component " + str(disabling.id))
			# Mark this component as disabled and remove it from available components.
			disabled[disabling] = true
			components.erase(disabling.id)
			# Remove its tags from the lists of types_tags, if a list gets emptied,
			# add the dependant components to the to_disable array.787777
			var type = disabling.definition._get_component_type()
			for tag in disabling.definition._get_component_tags():
				var type_tag = str(type) + "/" + tag
				types_tags[type_tag].erase(disabling)
				if types_tags[type_tag].size() == 0:
					types_tags.erase(type_tag)
					if dependencies.has(type_tag):
						for c in dependencies[type_tag]:
							to_disable.append(c)
	# Returning all the disabled components
	return disabled.keys()


func _select_tagged_components():
	for type_tag in types_tags.keys():
		var components = types_tags[type_tag]
		var type_tag_array = type_tag.split("/")
		var setting_key = "tags/" +  type_tag_array[1] + "_" + Component.get_type_name(int(type_tag_array[0]))
		if components.size() == 1:
			# Only one component has this feature tag, use it.
			Settings.set_value(setting_key, components[0].id)
		else:
			# There are multiple candidates for this feature tag.
			# If a setting exists, use the component indicated there.
			var component_from_settings = get_component_from_settings(setting_key)
			if component_from_settings == null:
				# Otherwise, use the first available component.
				component_from_settings = components[0]
			Settings.set_value(setting_key, component_from_settings.id)


#func _generate_tags_settings_definitions():
#	var definitions = []
#	for key in Settings.get_section_keys("tags"):
#		definitions.append(Setting.create("tags/" + key, Settings.get_value("tags/" + key)))
#	if definitions.size() > 0:
#		Settings.add_settings_definitions(system_component, definitions)


func _generate_settings():
	for id in components.keys():
		var c = components[id]
		var definitions = c.definition._get_settings_definitions()
		if definitions.size() > 0:
			Settings.add_settings_definitions(c, definitions)
	for id in components.keys():
		var c = components[id]
		var exports = c.definition._get_settings_exports()
		if exports.size() > 0:
			Settings.add_settings_exports(c, exports)
	
#	var all_exports = {}
#	for id in components.keys():
#		var c = components[id]
#		var settings = c.definition._get_settings()
#		var definitions = []
#		var exports = []
#		for s in settings:
#			if s is Setting.Init:
#				definitions.append(s)
#			elif s is Setting.Export:
#				exports.append(s)
#		if definitions.size() > 0:
#			for d in definitions:
#				print("Adding " +str(d.section_key) +" to settings")
#			Settings.add_settings_definitions(c, definitions)
#		if exports.size() > 0:
#			all_exports[c] = exports
#	for c in all_exports.keys():
#		Settings.add_settings_exports(c, all_exports[c])


func _load_modules():
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
		
		components[system_component.id] = system_component
		available_components[system_component.id] = system_component
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


func _collect_module(module_name : String):
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
			var component_class = component_resource
			if component_resource.resource_path.get_extension() == "tscn":
				# This is a PackedScene, special processing is needed
				component_class = _find_packed_scene_script(component_resource)
			
			# Valid Component found, load it
			_collect_component(module_name, component_resource, component_class)
	
	if has_localizations and not has_english_translation:
		printerr("Module " + module_name.to_upper() + " doesn't have an english translation!")


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
			var component_class = component_resource
			if component_resource.resource_path.get_extension() == "tscn":
				# This is a PackedScene, special processing is needed
				component_class = _find_packed_scene_script(component_resource)
			
			# Valid Component found, load it
			_load_component(module_name, component_resource, component_class)
	
	if has_localizations and not has_english_translation:
		printerr("Module " + module_name.to_upper() + " doesn't have an english translation!")


func _collect_component(module_name : String, component_resource : Resource, component_class : Resource):
	var component_name = component_class._get_component_name()
	var component_tags = component_class._get_component_tags()
	var component_dependencies = component_class._get_dependencies()
	var component_type = component_class._get_component_type()
	
	var entry : Component = Component.new()
	entry.id = module_name + "/" + component_resource.resource_path.get_file().get_basename()
	entry.module = module_name
	entry.name = component_name
	entry.resource = component_resource
	entry.definition = component_class
	entry.tags = component_tags
	entry.type = component_type
	
	var info = "Module " + module_name.to_upper() + " - Component \"" + component_name + "\" (" + entry["id"]  + ") found.\n" + \
		"	Resource: " + component_resource.resource_path + "\n	Type: " + str(component_type) + "\n	Tags: " + str(component_tags)
	print(info)
	
	for dep in component_dependencies:
		if not dependencies.has(str(dep.type) + "/" + dep.tag):
			dependencies[str(dep.type) + "/" + dep.tag] = [entry]
		else:
			dependencies[str(dep.type) + "/" + dep.tag].append(entry)
	for tag in component_tags:
		if not types_tags.has(str(component_type) + "/" + tag):
			types_tags[str(component_type) + "/" + tag] = [entry]
		else:
			types_tags[str(component_type) + "/" + tag].append(entry)
	
	components[entry.id] = entry


func _load_component(module_name : String, component_resource : Resource, component_class : Resource):
	var component_name = component_class._get_component_name()
	var component_tags = component_class._get_component_tags()
	var component_settings = component_class._get_settings()
	var component_type = component_class._get_component_type()
	
	var entry : Component = Component.new()
	entry.id = module_name + "/" + component_resource.resource_path.get_file().get_basename()
	entry.module = module_name
	entry.name = component_name
	entry.resource = component_resource
	entry.definition = component_class
	entry.tags = component_tags
	entry.type = component_type
	
	if component_class._is_available():
		var info = "Module " + module_name.to_upper() + " - Component \"" + component_name + "\" (" + entry["id"]  + ") found.\n" + \
			"	Resource: " + component_resource.resource_path + "\n	Type: " + str(component_type) + "\n	Tags: " + str(component_tags)
		print(info)
		
		if component_settings != null and component_settings.size() > 0:
			_load_settings(entry, component_settings)
	
		available_components[entry.id] = entry
	else:
		var info = "Module " + module_name.to_upper() + " - Component \"" + component_name + "\" (" + entry["id"]  + ") is not available!\n" + \
			"	Resource: " + component_resource.resource_path + "\n	Type: " + str(component_type) + "\n	Tags: " + str(component_tags)
		printerr(info)
		
		unavailable_components[entry.id] = entry
	components[entry.id] = entry


func _load_settings(entry, settings):
	var definitions = []
	var exports = []
	for s in settings:
		if s is Setting.Init:
			definitions.append(s)
		elif s is Setting.Export:
			exports.append(s)
	Settings.add_settings_definitions(entry, definitions)
	# Settings exports may have to be loaded all at once at the end.
	Settings.add_settings_exports(entry, exports)


func _find_packed_scene_script(scene : PackedScene) -> GDScript:
	var state : SceneState = scene.get_state()
	for i in range(state.get_node_property_count(0)):
		if state.get_node_property_name(0, i) == "script":
			var script_resource : GDScript = state.get_node_property_value(0, i)
			return script_resource
	return null
