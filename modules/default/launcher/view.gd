extends Control

signal entry_focused(entry)
signal entry_selected(entry)
signal executed(error, entry)
signal move_requested(to_directory)


# Override this function to provide a way to remove all the entries.
func clear_entries():
	
	pass


# Override this function to provide a way to add new entries to this view.
func append_entries(entries : Array):
	
	pass


# Override this function to provide a way to focus a previously added entry by index.
func select_entry(index):
	
	pass
