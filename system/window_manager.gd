extends Node

var always_on_top_wanted : Array = []

onready var library : WindowManager = $NativeLibrary


func want_always_on_top(object):
	var on_top = always_on_top_wanted.size() > 0
	if not always_on_top_wanted.has(object):
		always_on_top_wanted.append(object)
		if always_on_top_wanted.size() > 0 and not on_top:
			library.set_always_on_top(library.get_window_id(), true)


func unwant_always_on_top(object):
	var on_top = always_on_top_wanted.size() > 0
	if always_on_top_wanted.has(object):
		always_on_top_wanted.erase(object)
		if always_on_top_wanted.size() == 0 and on_top:
			library.set_always_on_top(library.get_window_id(), false)
