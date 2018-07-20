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
	yield(dialog, "file_selected") 
	
	return dialog
	
func _file_selected(filename, dialog):
	dialog.queue_free()
	
func create_confirmation_dialog(text):
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = text
	
	add_child(dialog)
	dialog.popup_centered(Vector2(400,200))
	dialog.connect("confirmed", self, "_confirmed", [dialog]) # TODO if a file is NOT selected, you'll leak memory here
	yield(dialog, "confirmed") 
	
	return dialog
	
func _confirmed(dialog):
	dialog.queue_free()
	
func create_accept_dialog(text, buttons):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	for b in buttons:
		dialog.add_button(b.capitalize(), true, b)
	add_child(dialog)
	dialog.popup_centered(Vector2(400,100))
	dialog.get_ok().queue_free() # Delete the OK button
	
	dialog.connect("custom_action", self, "_custom_action", [dialog]) # TODO if a file is NOT selected, you'll leak memory here
	var result = yield(dialog, "custom_action")
	return [dialog, result]
	
func _custom_action(action, dialog):
	dialog.queue_free()