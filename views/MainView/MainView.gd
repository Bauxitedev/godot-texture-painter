extends Control

onready var paint_viewport = $View/MainFrame/LeftPanel/PaintViewport/ViewportContainer/Viewport
onready var cam = paint_viewport.get_node("main/spatial/camroot/cam")

func _ready():
	PainterState.brush.softness_slider = $View/MainFrame/RightPanel/Brush/Preview/softness_slider
	PainterState.brush.color_picker = $View/MainFrame/RightPanel/Brush/VBoxContainer/ColorPickerButton
	
	PainterState.paint_viewport.cursor_node = $View/MainFrame/LeftPanel/PaintViewport/ViewportUI/Cursor
	PainterState.paint_viewport.colorpicker_node = $View/MainFrame/LeftPanel/PaintViewport/ViewportUI/ColorPicker
	
	# Put the paint viewports in PainterState.viewports
	var paint_vps = paint_viewport.get_node("main/textures/paint").get_children()
	for paint_vp in paint_vps:
		var vp_name = paint_vp.name
		PainterState.viewports[vp_name] = paint_vp
		var texture_rect = get_node("View/MainFrame/LeftPanel/BottomPanel/HBoxContainer/%s/rect" % vp_name)
		texture_rect.texture = paint_vp.get_texture()

	# Put the utility viewports in PainterState.utility_viewports
	var utility_vps = paint_viewport.get_node("main/textures/mesh").get_children()
	for utility_vp in utility_vps:
		PainterState.utility_viewports[utility_vp.name] = utility_vp
	
	# little hack
	_on_active_texture_changed(0)
	
	PainterState.connect("active_texture_changed", self, "_on_active_texture_changed")
	
	# Setup the menu bar signals
	$View/MenuBar/FileMenu.get_popup().connect("index_pressed", self, "_on_filemenu_index_pressed")
	
	
func _on_filemenu_index_pressed(index):
	match index:
		0: ImageOps.new_image()
		1: ImageOps.open_image()
		2: ImageOps.save_image()
		3: ImageOps.save_image() # TODO save as...
		4: load_mesh()
		5: ImageOps.import_image()
		6: ImageOps.export_image()
		7: get_tree().quit()

func load_mesh():
	paint_viewport.get_node("main").change_mesh(preload("res://assets/models/Torus.mesh"))  # TODO show a FileDialog here
	new_image()
	
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
