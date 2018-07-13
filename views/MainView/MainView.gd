extends Control

onready var paint_viewport = $View/MainFrame/LeftPanel/PaintViewport/ViewportContainer/Viewport
onready var cam = paint_viewport.get_node("main/spatial/camroot/cam")

func _ready():
	PainterState.brush.softness_slider = $View/MainFrame/RightPanel/Brush/Preview/softness_slider
	PainterState.brush.color_picker = $View/MainFrame/RightPanel/Brush/VBoxContainer/ColorPickerButton
	
	PainterState.paint_viewport.cursor_node = $View/MainFrame/LeftPanel/PaintViewport/ViewportUI/Cursor
	PainterState.paint_viewport.colorpicker_node = $View/MainFrame/LeftPanel/PaintViewport/ViewportUI/ColorPicker
	
	PainterState.viewports.albedo = paint_viewport.get_node("main/textures/paint/albedo")
	PainterState.viewports.roughness = paint_viewport.get_node("main/textures/paint/roughness")
	PainterState.viewports.metalness = paint_viewport.get_node("main/textures/paint/metalness")
	PainterState.viewports.emission = paint_viewport.get_node("main/textures/paint/emission")
	
	PainterState.utility_viewports.position = paint_viewport.get_node("main/textures/mesh/position")
	PainterState.utility_viewports.normal = paint_viewport.get_node("main/textures/mesh/normal")
	
	var albedo_rect = $View/MainFrame/LeftPanel/BottomPanel/HBoxContainer/albedo/rect
	var roughness_rect = $View/MainFrame/LeftPanel/BottomPanel/HBoxContainer/roughness/rect
	var metalness_rect = $View/MainFrame/LeftPanel/BottomPanel/HBoxContainer/metalness/rect
	var emission_rect = $View/MainFrame/LeftPanel/BottomPanel/HBoxContainer/emission/rect
	
	albedo_rect.texture = PainterState.viewports.albedo.get_texture()
	roughness_rect.texture = PainterState.viewports.roughness.get_texture()
	metalness_rect.texture = PainterState.viewports.metalness.get_texture()
	emission_rect.texture = PainterState.viewports.emission.get_texture()
		
	# little hack
	_on_active_texture_changed(0)
	
	PainterState.connect("active_texture_changed", self, "_on_active_texture_changed")
	
	# Setup the menu bar signals
	$View/MenuBar/FileMenu.get_popup().connect("index_pressed", self, "_on_filemenu_index_pressed")
	
	
func _on_filemenu_index_pressed(index):
	match index:
		0: new_image()
		1: open_image()
		2: save_image()
		3: save_image() # TODO save as...
		4: paint_viewport.get_node("main").change_mesh(preload("res://assets/models/Torus.mesh"))  # TODO show a FileDialog here
		5: get_tree().quit()

func new_image():
	var vps = [PainterState.viewports.albedo, PainterState.viewports.roughness, PainterState.viewports.metalness, PainterState.viewports.emission]
	for vp in vps:
		vp.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
		
func open_image():
	print("TODO load image")
	pass
	
func create_save_tree():
	
	# Create the data structure which will be serialized
	
	var save_root = Node.new()
	save_root.name = "save"
	
	# Save format version
	
	var save_version_root = Node.new()
	save_version_root.name = "version"
	
	var save_version = Node.new()
	save_version.name = "1"
	
	save_version_root.add_child(save_version)
	save_root.add_child(save_version_root)
	save_version.owner = save_root
	save_version_root.owner = save_root
	
	# Save texture slots in the form of sprites
	
	var save_slots = Node.new()
	save_slots.name = "slots"
	
	save_root.add_child(save_slots)
	save_slots.owner = save_root	
	
	var slots = paint_viewport.get_node("main/textures/paint").get_children()
	
	var skip = false #just for debugging...
	
	for slot in slots:
		
		if skip:
			break
			
		skip = true
		
		var save_slot = Sprite.new()
		save_slot.name = slot.name
		
		# Convert ViewportTexture to ImageTexture
		var vp_texture = slot.get_texture()
		var vp_img = vp_texture.get_data()
		var img_texture = ImageTexture.new()
		img_texture.create_from_image(vp_img)
		var img_texture_format = img_texture.get_format()  # format is 15 which is RGBAH (16-bit float RGBA)
		var img_compressed = vp_img.is_compressed() # NOT compressed
		save_slot.texture = img_texture
		
		# TODO it seems the format is wrong? It's saving the texture in compressed format for some reason.
		# TODO convert it to RGBA uncompressed 32-bit (16-bit might not be properly saved)
		# go save as tscn and debug it (but - it's 300mb!!!)
		# ALSO the "image" slot of the "ImageTexture" is null in the saved file. Why???
		# maybe relevant https://github.com/godotengine/godot/issues/8465
		
		save_slots.add_child(save_slot)
		save_slot.owner = save_root
		
	return save_root
	
func save_image():
	
	var save_extension = ".tscn"	
	
	# Get save path
	var dialog = FileDialog.new()
	dialog.add_filter("*%s;Texture Painter Save File" % save_extension)
	add_child(dialog)
	dialog.popup_centered_ratio(0.75)
	yield(dialog, "file_selected")
	
	# Create the data structure 
	var save_root = create_save_tree()
	
	
	
	# Save it to file
	var filename = dialog.current_path
	if !filename.ends_with(save_extension):
		filename += save_extension
	
	var pack = PackedScene.new()
	var result = pack.pack(save_root)
	if result == OK:
		result = ResourceSaver.save(filename, pack)#, ResourceSaver.FLAG_BUNDLE_RESOURCES) 
		if result == OK:
			print("Saved to %s!" % filename)
			return
	
	print("Save to %s failed" % filename)

	
func _on_ColorPickerButton_color_changed(color):
	PainterState.brush.color = color


func _on_active_texture_changed(idx):
	var previews = $View/MainFrame/LeftPanel/BottomPanel/HBoxContainer
	
	for i in range(4):
		var color = Color(1,0.3,0) if i == idx else Color(1.0, 1.0, 1.0)
		previews.get_children()[i].get_node("label").add_color_override("font_color", color)


func _on_softness_slider_value_changed(value):
	PainterState.brush.hardness = value
	
	$View/MainFrame/RightPanel/Brush/Preview/rect
	var gradient = $View/MainFrame/RightPanel/Brush/Preview/rect.material.get_shader_param("brush_gradient").gradient
	
	gradient.set_offset(0, value * (1 - 1e-3))


func _on_znear_slider_value_changed(value):
	$View/MainFrame/RightPanel/BottomPanel/VBoxContainer/znear_box/val.text = var2str(value)
	cam.near = value
	
	if cam.near > cam.far:
		$View/MainFrame/RightPanel/BottomPanel/VBoxContainer/zfar_box/zfar_slider.value = value + 1e-2

func _on_zfar_slider_value_changed(value):
	$View/MainFrame/RightPanel/BottomPanel/VBoxContainer/zfar_box/val.text = var2str(value)	
	cam.far = value
	
	if cam.far < cam.near:
		$View/MainFrame/RightPanel/BottomPanel/VBoxContainer/znear_box/znear_slider.value = value - 1e-2
