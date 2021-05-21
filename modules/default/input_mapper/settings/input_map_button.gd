extends SettingEditor


# Override this function to configure the SettingEditor to handle the passed configuration entry
func _initialize_setting(section_key : Array, label : String):
	self.text = label


# Button exposes this function on its own
func _pressed():
	System.get_launcher().app.add_app(preload("../input_mapper.tscn").instance())
