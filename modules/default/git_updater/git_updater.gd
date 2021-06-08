extends Service


static func _get_component_name():
	return "Git Updater"


# Override this function to check whether this Component can be used on the device
static func _is_available():
	return OS.execute("bash", ["-c", "git --version"], true) == 0


static func _get_settings_exports():
	return [
		Setting.export([], TranslationServer.translate("DEFAULT.UPDATE_LAUNCHER"), load("res://modules/default/git_updater/settings/update_launcher_button.tscn"))
	]
