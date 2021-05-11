extends SettingEditor


# Override this function to configure the SettingEditor to handle the passed configuration entry
func _initialize_setting(section_key : Array, label : String):
	self.text = label


# Button exposes this function on its own
func _pressed():
	OS.execute("bash", ["-c", "sed -i s/godot-launcher/launcher/g ~/.bashrc"], true)
	var result = OS.execute("bash", ["-c", "sudo reboot"], true)
