extends Reference
class_name Component

const TAG_SYSTEM = "system"				# Launcher tag, for internal use only
const TAG_LAUNCHER = "launcher"			# Used to indicate the first App, generally the launcher
const TAG_RUNNING = "running"			# Apps that handle programs running in the foreground
const TAG_SETTINGS = "settings"			# Apps that can be used as settings apps
const TAG_KEYBOARD = "keyboard"			# Apps that can be used as keyboard apps

# Types of Component. ANY includes all types except SYSTEM. ALL includes SYSTEM too.
enum Type { 
	ALL = 9223372036854775807,
	ANY = 9223372036854775806, 
	SYSTEM = 1,
	APP = 2,
	WIDGET = 4,
	THEME = 8,
	SERVICE = 16,
	ICONS = 32,
	DESKTOP = 64
}

var id : String				# Unique id of the component
var name : String			# Developer assigned name of the component
var module : String			# The name of the module that contains the component (the folder name)
var resource : Resource 	# Theme resource, scene, etc.
var definition : Resource	# The object representing the component class
var tags : Array 			# Array of strings
var type : int				# Type of the component: APP, WIDGET, THEME, etc.


static func get_type_name(type) -> String:
	match type:
		Type.SYSTEM:
			return "system"
		Type.APP:
			return "app"
		Type.WIDGET:
			return "widget"
		Type.THEME:
			return "theme"
		Type.SERVICE:
			return "service"
		Type.ICONS:
			return "icons"
		Type.DESKTOP:
			return "desktop"
	return ""


static func depend(type : int, tag : String) -> Dependency:
	var dependency = Dependency.new()
	dependency.type = type
	dependency.tag = tag
	return dependency


class Dependency extends Reference:
	var type : int
	var tag : String
