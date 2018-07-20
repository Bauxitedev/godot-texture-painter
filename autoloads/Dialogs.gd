extends Node

# This is purely a container for Dialogs.
# It can be used to detect if there are any open dialogs at the moment.
func _ready():
	yield(get_tree(), "idle_frame")
	get_parent().move_child(self, get_parent().get_children().size()-1) # Little hack to ensure the Dialogs is the last singleton in the tree so it's drawn on top of everything else
		
func any_dialog_open():
	for c in get_children():
		if c.visible:
			return true
	return false
	
func create_file_dialog(mode, filters):
	
	var dialog = FileDialog.new()
	dialog.mode = mode
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	
	for filter in filters:
		dialog.add_filter(filter)
	
	add_child(dialog)
	dialog.popup_centered_ratio(0.75)
	dialog.connect("file_selected", self, "_file_selected", [dialog]) # TODO if a file is NOT selected, you'll leak memory here
	yield(dialog, "file_selected") # TODO this might break when the dialog is queue_freed before returning it
	
	return dialog
	
func _file_selected(filename, dialog):
	dialog.queue_free()