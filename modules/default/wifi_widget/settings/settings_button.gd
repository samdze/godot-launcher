extends SettingEditor


# Override this function to configure the SettingEditor to handle the passed configuration entry
func _initialize_setting(section_key : Array, label : String):
	self.text = label


# Button exposes this function on its own
func _pressed():
	Launcher.get_ui().app.add_app(preload("wifi_settings_app.tscn").instance())
