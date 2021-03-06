extends Service

signal screen_brightness_changed(brightness)
signal power_mode_changed(mode)

enum Mode {
	ALWAYS_ON = 0,
	BALANCED = 1,
	POWER_SAVING = 2
}
const mode_names = [
	"always_on",
	"balanced",
	"power_saving"
]
const mode_settings = [
	{ "dim": 0, "off": 0, "shutdown": 0 },
	{ "dim": 60, "off": 300, "shutdown": 0 },
	{ "dim": 30, "off": 120, "shutdown": 600 },
]

var mode : int = Mode.BALANCED
var backlight : int = 5
var screen_on = true
var screen_dimmed = false

onready var dim_timer = $DimTimer
onready var off_timer = $OffTimer
onready var shutdown_timer = $ShutdownTimer


func _ready():
	# Setting every timer to 0 bacause we handle timers manually.
	OS.execute("bash", ["-c", "xset dpms 0 0 0"], true, [], false)
	OS.execute("bash", ["-c", "xset s off "], true, [], false)
	
	dim_timer.connect("timeout", self, "_dim_timeout")
	off_timer.connect("timeout", self, "_off_timeour")
	shutdown_timer.connect("timeout", self, "_shutdown_timeout")
	
	Settings.connect_setting("settings/power_mode", self, "_power_mode_changed")
	Settings.connect_setting("settings/brightness", self, "_brightness_changed")
	
	_brightness_changed()
	_power_mode_changed()


func _input(event):
	_reset_timers(mode)
	screen_on = true
	if screen_dimmed:
		screen_dimmed = false
		_update_backlight(backlight)


func _update_power_mode(mode : int):
	_reset_timers(mode)
	emit_signal("power_mode_changed", mode)
#	System.emit_event("power_mode_changed", [mode])


func _power_mode_changed():
	mode = clamp(int(Settings.get_value("settings/power_mode")), 0, Mode.size() - 1)
	_update_power_mode(mode)


func _update_backlight(value : int):
	OS.execute("bash", ["-c", "echo " + str(value) + " > /proc/driver/backlight"])
	emit_signal("screen_brightness_changed", value)
#	System.emit_event("brightness_changed", [value])


func _brightness_changed():
	backlight = clamp(int(Settings.get_value("settings/brightness")), 0, 9)
	_update_backlight(int(backlight))


func _dim_timeout():
	if not screen_dimmed:
		screen_dimmed = true
		_update_backlight(1)
	dim_timer.stop()


func _off_timeour():
	_update_backlight(0)
	if screen_on:
		screen_on = false
		OS.execute("bash", ["-c", "xset dpms force off"], true, [], false)
	off_timer.stop()


func _shutdown_timeout():
	_update_backlight(0)
	OS.execute("bash", ["-c", "shutdown now"], true, [], false)
	shutdown_timer.stop()


func _reset_timers(mode):
	if mode_settings[mode].dim > 0: dim_timer.start(mode_settings[mode].dim)
	else: dim_timer.stop()
	
	if mode_settings[mode].off > 0: off_timer.start(mode_settings[mode].off)
	else: off_timer.stop()
	
	if mode_settings[mode].shutdown > 0: shutdown_timer.start(mode_settings[mode].shutdown)
	else: shutdown_timer.stop()


func set_screen_brightness(value):
	if backlight != value:
		Settings.set_value("settings/brightness", int(clamp(value, 0, 9)))


func get_screen_brightness() -> int:
	return backlight


func set_power_mode(value : int):
	if mode != value:
		Settings.set_value("settings/power_mode", int(clamp(value, 0, Mode.size() - 1)))


func get_power_mode() -> int:
	return mode


#func _event(name, arguments):
#	match name:
#		"set_brightness":
#			set_screen_brightness(arguments[0])
#			return true
#		"get_brightness":
#			return get_screen_brightness()
#		"set_power_mode":
#			set_power_mode(arguments[0])
#			return true
#		"get_power_mode":
#			return get_power_mode()


static func get_localized_name(mode : int):
	return TranslationServer.translate("DEFAULT.POWER_MODE_" + mode_names[mode].to_upper())


static func _get_component_name():
	return "Power Manager"


static func _get_component_tags():
	return ["screen_brightness"]


static func _get_settings_definitions():
	return [
		Setting.create("settings/power_mode", 1),
		Setting.create("settings/brightness", 5),
	]


static func _get_settings_exports():
	return [
		Setting.export(["settings/power_mode"], TranslationServer.translate("DEFAULT.FOLDER_SYSTEM") + "/" + TranslationServer.translate("DEFAULT.POWER_MODE"), load("res://modules/default/power_manager/settings/dropdown_power_mode.tscn"))
	]
