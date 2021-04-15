extends LauncherEntry

var settings_view : PackedScene


func _ready():
	settings_view = Modules.get_view(Config.get_or_default("system", "settings_view", null))["scene"]
	_set_label("Settings")


func exec():
	Launcher.get_ui().view.add_view(settings_view.instance())
	executed(OK)
	return OK
