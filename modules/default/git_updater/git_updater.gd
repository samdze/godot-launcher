extends Service


static func _get_component_name():
	return "Git Updater"


static func _get_settings():
	return [
		Setting.export([], TranslationServer.translate("DEFAULT.UPDATE"), load("res://modules/default/git_updater/settings/update_launcher_button.tscn"))
	]
