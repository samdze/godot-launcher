extends LauncherEntry


func get_label():
	match TranslationServer.get_locale():
		"it":
			return "Esci"
	return "Quit"


func exec():
	Launcher.emit_event("set_loading", [false])
	Launcher.emit_event("prompts", [[BottomBar.ICON_NAV_V, tr("DEFAULT.PROMPT_NAVIGATION")], [BottomBar.ICON_BUTTON_A, tr("DEFAULT.PROMPT_SELECT"), BottomBar.ICON_BUTTON_B, tr("DEFAULT.PROMPT_BACK")]])
	var popup = PopupPanel.new()
	popup.connect("popup_hide", self, "_popup_hidden")
	var vbox = VBoxContainer.new()
	
	var options = []
	
	var quit = Button.new()
	quit.connect("pressed", self, "_quit")
	quit.text = "Quit"
	quit.clip_text = true
	quit.align = Button.ALIGN_CENTER
	
	var shutdown = Button.new()
	shutdown.connect("pressed", self, "_shutdown")
	shutdown.text = "Shutdown"
	shutdown.clip_text = true
	shutdown.align = Button.ALIGN_CENTER
	
	var reboot = Button.new()
	reboot.connect("pressed", self, "_reboot")
	reboot.text = "Reboot"
	reboot.clip_text = true
	reboot.align = Button.ALIGN_CENTER
	
	
	vbox.add_child(quit)
	vbox.add_child(shutdown)
	vbox.add_child(reboot)
	
	popup.add_child(vbox)
	
	Launcher.get_ui().add_child(popup)
	popup.popup_centered(Vector2(160, 64))
	
	quit.focus_neighbour_bottom = shutdown.get_path()
	quit.focus_neighbour_top = reboot.get_path()
	quit.focus_neighbour_left = quit.get_path()
	quit.focus_neighbour_right = quit.get_path()
	
	shutdown.focus_neighbour_top = quit.get_path()
	shutdown.focus_neighbour_bottom = reboot.get_path()
	shutdown.focus_neighbour_left = shutdown.get_path()
	shutdown.focus_neighbour_right = shutdown.get_path()
	
	reboot.focus_neighbour_top = shutdown.get_path()
	reboot.focus_neighbour_bottom = quit.get_path()
	reboot.focus_neighbour_left = reboot.get_path()
	reboot.focus_neighbour_right = reboot.get_path()
	
	quit.grab_focus()
	
#	Engine.get_main_loop().quit()
#	executed(OK)
	return OK


func _popup_hidden():
	executed(OK)


func _quit():
	Engine.get_main_loop().quit()
	executed(OK)


func _shutdown():
	OS.execute("bash", ["-c", "sudo shutdown now"])
	Engine.get_main_loop().quit()
	executed(OK)


func _reboot():
	OS.execute("bash", ["-c", "sudo reboot"])
	Engine.get_main_loop().quit()
	executed(OK)
