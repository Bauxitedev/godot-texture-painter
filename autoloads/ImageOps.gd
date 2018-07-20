extends Node

var save_extension = ".tpain" # Blame it on the a a a a a alcohol

func new_image():
	var vps = PainterState.viewports.values()
	for vp in vps:
		vp.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
		
func open_image():
	
	# Show dialog
	var dialog = yield(Dialogs.create_file_dialog(FileDialog.MODE_OPEN_FILE, ["*%s;Texture Painter Save File" % save_extension]), "completed")
	
	new_image()  # Not technically needed but just to be sure
	var textures = {}
	
	# Read the ImageTextures and put them in a dictionary
	var slots = SaveManager.Load(ProjectSettings.globalize_path(dialog.current_path))
	for slot_name in slots:
		var tex = SaveManager.GetTexture(slot_name)
		textures[slot_name] = tex
	SaveManager.ClearTextures()
	
	# Then put them into the viewports
	put_textures_into_viewports(textures)
		
func put_textures_into_viewports(textures):
	
	var sprites = []
	
	# Add sprites to the viewports
	for tex_name in textures:
		
		var spr = Sprite.new() 
		var img = textures[tex_name].image
		var vp = PainterState.viewports[tex_name]
		
		spr.texture = ImageTexture.new()
		spr.texture.create_from_image(img) # needed for some god forsaken reason??? doubles RAM usage!
		spr.name = tex_name
		spr.centered = false
		sprites.push_back(spr)
		
		vp.size = Vector2(img.get_width(), img.get_height())
		vp.add_child(spr)
		vp.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME

	# Wait a bit so the viewport has time to draw the sprites and clear the viewport
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
		
	# Remove the sprites
	for spr in sprites:
		spr.queue_free()
		

func save_image():
	
	# Show dialog
	var dialog = yield(Dialogs.create_file_dialog(FileDialog.MODE_SAVE_FILE, "*%s;Texture Painter Save File" % save_extension), "completed")
	
	# Save it to file
	var filename = dialog.current_path
	if !filename.ends_with(save_extension):
		filename += save_extension
	
	# Convert ViewportTextures to ImageTextures and save 'em
	SaveManager.ClearTextures()	
	var vps = PainterState.viewports.values()
	for vp in vps:
		var vp_texture = vp.get_texture()
		var vp_img = vp_texture.get_data()
		var img_texture = ImageTexture.new()
		img_texture.create_from_image(vp_img)
		SaveManager.SetTexture(vp.name, img_texture) # hack since we cannot pass a dictionary from GDscript to C#
	SaveManager.Save(ProjectSettings.globalize_path(filename))

func import_image():
	
	# Get load path
	var dialog = yield(Dialogs.create_file_dialog(FileDialog.MODE_OPEN_FILE, ["*.png;PNG image", "*.jpg;JPG image"]), "completed")
	var path = dialog.current_path
	
	# Ask what slot we want to import to
	var slot_dialog = AcceptDialog.new()
	slot_dialog.dialog_text = "On what slot do you want to import the texture?"
	for slot in PainterState.viewports:
		slot_dialog.add_button(slot.capitalize(), true, slot)
	Dialogs.add_child(slot_dialog)
	slot_dialog.popup_centered(Vector2(400,100))
	slot_dialog.get_ok().queue_free() # Delete the OK button
	
	# Wait for user to pick a slot
	var result = yield(slot_dialog, "custom_action")
	slot_dialog.queue_free()
	
	# Import the image
	var img = Image.new()
	img.load(path)
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	
	# Finally put the texture into that slot
	put_textures_into_viewports({ result: tex })
	
	
func export_image():
	
	# Get save path
	var dialog = yield(Dialogs.create_file_dialog(FileDialog.MODE_SAVE_FILE, []), "completed")
	
	# Gather save filenames
	var files_to_save = {}
	for vp in PainterState.viewports.values():
		files_to_save["%s_%s.png" % [dialog.current_path, vp.name]] = vp
	
	# Show confirmation dialog
	var conf_dialog = ConfirmationDialog.new()
	
	var dialog_text = "This will save the following files:\n"
	for f in files_to_save:
		dialog_text += "\n · %s" % ProjectSettings.globalize_path(f)
	dialog_text += "\n\nContinue?"
	conf_dialog.dialog_text = dialog_text
	
	Dialogs.add_child(conf_dialog)
	conf_dialog.popup_centered(Vector2(400,200))
	yield(conf_dialog, "confirmed")
	conf_dialog.queue_free()
	
	# Finally save to PNG (TODO allow bitdepth control and other formats)
	# BTW parallellization here brings export time from 2.2sec to 0.7sec
	var time_start = OS.get_ticks_msec() / 1000.0
	var threads = []
	for f in files_to_save:
		var t = Thread.new()
		t.start(self, "thread_save_png", [files_to_save[f].get_texture().get_data(), f])
		threads.push_back(t)
	for t in threads:
		t.wait_to_finish()
	var time_end = OS.get_ticks_msec() / 1000.0
	print("Exporting took %s sec" % (time_end - time_start))
		
func thread_save_png(userdata):
	userdata[0].save_png(userdata[1])
