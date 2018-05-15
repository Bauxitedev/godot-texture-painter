extends Control

func _ready():
	PainterState.brush.softness_slider = $View/MainFrame/RightPanel/Brush/Preview/softness_slider
	PainterState.brush.color_picker = $View/MainFrame/RightPanel/Brush/VBoxContainer/ColorPickerButton
	
	PainterState.viewports.albedo = $View/MainFrame/LeftPanel/ViewportContainer/Viewport/main/textures/paint/albedo
	PainterState.viewports.roughness = $View/MainFrame/LeftPanel/ViewportContainer/Viewport/main/textures/paint/roughness
	PainterState.viewports.metalness = $View/MainFrame/LeftPanel/ViewportContainer/Viewport/main/textures/paint/metalness
	PainterState.viewports.emission = $View/MainFrame/LeftPanel/ViewportContainer/Viewport/main/textures/paint/emission
	
	var albedo_rect = $View/MainFrame/LeftPanel/BottomPanel/HBoxContainer/albedo/rect
	var roughness_rect = $View/MainFrame/LeftPanel/BottomPanel/HBoxContainer/roughness/rect
	var metalness_rect = $View/MainFrame/LeftPanel/BottomPanel/HBoxContainer/metalness/rect
	var emission_rect = $View/MainFrame/LeftPanel/BottomPanel/HBoxContainer/emission/rect
	
	albedo_rect.texture = PainterState.viewports.albedo.get_texture()
	roughness_rect.texture = PainterState.viewports.roughness.get_texture()
	metalness_rect.texture = PainterState.viewports.metalness.get_texture()
	emission_rect.texture = PainterState.viewports.emission.get_texture()
		
	# workaround for https://github.com/godotengine/godot/pull/18161
	$View/MainFrame/RightPanel/Brush/VBoxContainer/ColorPickerButton.get_popup().connect("modal_closed", self, "_on_ColorPickerButton_popup_closed")

	# little hack
	_on_active_texture_changed(0)
	
	PainterState.connect("active_texture_changed", self, "_on_active_texture_changed")
	
	# Setup the menu bar signals
	$View/MenuBar/FileMenu.connect("about_to_show", self, "_on_filemenu_about_to_show")
	$View/MenuBar/FileMenu.get_popup().connect("index_pressed", self, "_on_filemenu_index_pressed")
	$View/MenuBar/FileMenu.get_popup().connect("popup_hide", self, "_on_filemenu_hidden")

func _on_filemenu_about_to_show():
	# Hack to prevent the viewport stealing input
	$View/MainFrame/LeftPanel/ViewportContainer/Viewport.gui_disable_input = true

func _on_filemenu_hidden():
	# Hack to prevent the viewport stealing input	
	$View/MainFrame/LeftPanel/ViewportContainer/Viewport.gui_disable_input = false
	
	
func _on_filemenu_index_pressed(index):
	match index:
		# TODO show a FileDialog here
		0: $View/MainFrame/LeftPanel/ViewportContainer/Viewport/main.change_mesh(preload("res://assets/models/Torus.mesh"))
		1: get_tree().quit()
		

func _on_ColorPickerButton_popup_closed():
	# Hack to prevent the viewport stealing input	
	$View/MainFrame/LeftPanel/ViewportContainer/Viewport.gui_disable_input = false


func _on_ColorPickerButton_button_down():
	# Hack to prevent the viewport stealing input	
	$View/MainFrame/LeftPanel/ViewportContainer/Viewport.gui_disable_input = true


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
