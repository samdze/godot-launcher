extends "../entry.gd"

var label : String = "" setget _set_label
var icon : Texture = null setget _set_icon

onready var label_node : Label = $Container/Label
onready var icon_node : TextureRect = $Container/TextureRect
onready var frame_node : TextureRect = $Container/CircleFrame
onready var icon_label : Label = $Container/IconLabel
onready var container : Control = $Container
onready var highlight : TextureRect = $Container/HighlightRing
onready var tween : Tween = $Tween


func _ready():
	._ready()
	_set_label(label)
	_set_icon(icon)


func set_highlighted(highlighted):
	tween.remove_all()
	if highlighted:
		highlight.visible = true
		tween.interpolate_property(highlight, "rect_rotation", 0, 30, 0.2)
	else:
		highlight.hide()
	tween.start()


func _set_label(value):
	if label_node:
		label_node.text = value
	label = value


func _set_icon(value):
	if icon_node:
		if value != null:
			icon_node.texture = value
			icon_node.visible = true
			icon_label.visible = false
			frame_node.visible = false
		else:
			icon_label.text = entry_script.get_label().left(2).strip_edges()
			icon_node.texture = null
			icon_node.visible = false
			icon_label.visible = true
			frame_node.visible = true
	icon = value


func init(script : LauncherEntry):
	.init(script)
	_set_label(entry_script.get_label())
	
	# Find the entry icon
#	var icons_path = ProjectSettings.globalize_path("res://icons/default")
	var icons_path = ProjectSettings.globalize_path(Modules.get_loaded_component_from_settings("system/icons").resource.resource_path.get_base_dir())
	var globalized_project_path = ProjectSettings.globalize_path("res://")
	# TODO: resolve the icon search folder automatically
	var apps_path = globalized_project_path.left(globalized_project_path.rfind("/", globalized_project_path.length() - 2))
	var entry_path = ProjectSettings.globalize_path(script.path).replace("\\", "/")
	
#	print("Icons path: " + icons_path)
#	print("Apps path: " + apps_path)
#	print("Entry path: " + entry_path)
	
	var search_icon_path = entry_path.replace(apps_path, "").get_basename() + ".png"
	var launcher_directory = "/" + ProjectSettings.globalize_path("res://").get_base_dir().get_file()
#	print("Launcher base directory: " + launcher_directory)
	if search_icon_path.find(launcher_directory) == 0:
		search_icon_path = search_icon_path.right(launcher_directory.length())
	var search_icon_ext_path = entry_path.replace(apps_path, "") + ".png"
	var icon_path_prefixed = icons_path + search_icon_path
	var icon_path_ext_prefixed = icons_path + search_icon_ext_path
	
	var prefixed_entry_name = icon_path_prefixed.get_file()
	var clean_entry_name = prefixed_entry_name.substr(prefixed_entry_name.find("_") + 1)
	var icon_path_clean = icon_path_prefixed.left(icon_path_prefixed.length() - prefixed_entry_name.length()) + clean_entry_name
	
	var prefixed_ext_entry_name = icon_path_ext_prefixed.get_file()
	var clean_ext_entry_name = prefixed_ext_entry_name.substr(prefixed_ext_entry_name.find("_") + 1)
	var icon_path_ext_clean = icon_path_ext_prefixed.left(icon_path_ext_prefixed.length() - prefixed_ext_entry_name.length()) + clean_ext_entry_name
	
#	print("Search icon path: " + search_icon_path)
#	print("Icon path prefixed: " + icon_path_prefixed)
#	print("Icon path clean: " + icon_path_clean)
	
	var icon = null
	if ResourceLoader.exists(icon_path_prefixed):
#		print("FOUND " + icon_path_prefixed)
		icon = ResourceLoader.load(icon_path_prefixed)
	elif ResourceLoader.exists(icon_path_clean):
#		print("FOUND " + icon_path_clean)
		icon = ResourceLoader.load(icon_path_clean)
	elif ResourceLoader.exists(icon_path_ext_prefixed):
#		print("FOUND " + icon_path_ext_prefixed)
		icon = ResourceLoader.load(icon_path_ext_prefixed)
	elif ResourceLoader.exists(icon_path_ext_clean):
#		print("FOUND " + icon_path_ext_clean)
		icon = ResourceLoader.load(icon_path_ext_clean)
	
	_set_icon(icon)
