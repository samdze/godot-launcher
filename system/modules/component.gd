extends Reference
class_name Component

const TAG_SYSTEM = "System"				# System tag, for internal use only
const TAG_LAUNCHER = "launcher"
const TAG_RUNNING = "running"
const TAG_SETTINGS = "settings"
const TAG_KEYBOARD = "keyboard"

# Types of Component. ANY includes all types except SYSTEM. ALL includes all types
enum Type { ALL = 9223372036854775807, ANY = 9223372036854775806, SYSTEM = 1, APP = 2, WIDGET = 4, THEME = 8, SERVICE = 16 }

var id : String				# Unique id of the component
var name : String			# Developer assigned name of the component
var module : String			# The name of the module that contains the component (the folder name)
var resource : Resource 	# Theme resource, scene, etc.
var tags : Array 			# Array of strings
var type : int				# Type of the component: APP, WIDGET, THEME, etc.
