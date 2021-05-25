extends Service

var volume : int = 50


func _ready():
	Settings.connect_setting("settings/audio_volume", self, "_audio_volume_changed")
	
	_audio_volume_changed()


#func _get_system_volume():
#	var percentage_regex = RegEx.new()
#	percentage_regex.compile("\\[(\\d+)%\\]")
#	var out = []
#	OS.execute("bash", ["-c", "amixer sget Master | grep 'Mono:'"], true, out, false)
#	if out.size() > 0:
#		var res = percentage_regex.search(out[0])
#		if res != null:
#			return int(res.get_string(1))
#	return 0


func _update_audio_volume(value : int):
	OS.execute("bash", ["-c", "amixer set Master " + str(value) + "%"], true)
	
	System.emit_event("audio_volume_changed", [value])


func _audio_volume_changed():
	volume = clamp(int(Settings.get_value("settings/audio_volume")), 0, 100)
	_update_audio_volume(volume)


func set_audio_volume(value : int):
	if volume != value:
		Settings.set_value("settings/audio_volume", int(clamp(value, 0, 100)))


func get_audio_volume() -> int:
	return volume


func _event(name, arguments):
	match name:
		"set_audio_volume":
			set_audio_volume(arguments[0])
			return true
		"get_audio_volume":
			return get_audio_volume()


static func _get_component_name():
	return "Alsa Audio"


static func _get_settings():
	return [
		Setting.create("settings/audio_volume", 50)
	]
