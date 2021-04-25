extends Resource
class_name Setting

export(Array) var setting_pairs = []
export(String) var label = ""
export(PackedScene) var control
export(GDScript) var init_script
export(String) var init_func_name = ""

# TODO: refactor Setting system
static func create(control : PackedScene):
	
	return load("res://system/settings/setting.gd").new("", "", "", control, null, "")


func _init(section, key, label, control, init_script, init_func_name):
	self.section = section
	self.key = key
	self.control = control
	self.init_script = init_script
	self.init_func_name = init_func_name


func instance() -> Control:
	var instanced = control.instance()
	if init_script != null and init_script.has_method(init_func_name):
		init_script.call(init_func_name, instanced)
	return instanced
