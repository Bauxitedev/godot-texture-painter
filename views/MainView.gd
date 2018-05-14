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


func _on_ColorPickerButton_popup_closed():
	$View/MainFrame/LeftPanel/ViewportContainer/Viewport.gui_disable_input = false


func _on_ColorPickerButton_button_down():
	$View/MainFrame/LeftPanel/ViewportContainer/Viewport.gui_disable_input = true


func _on_ColorPickerButton_color_changed(color):
	PainterState.brush.color = color


func _on_main_active_texture_changed(idx):
	var previews = $View/MainFrame/LeftPanel/BottomPanel/HBoxContainer
	
	for i in range(4):
		var color = Color(1,0.3,0) if i == idx else Color(1.0, 1.0, 1.0)
		previews.get_children()[i].get_node("label").add_color_override("font_color", color)


func _on_softness_slider_value_changed(value):
	PainterState.brush.hardness = value
	
	$View/MainFrame/RightPanel/Brush/Preview/rect
	var gradient = $View/MainFrame/RightPanel/Brush/Preview/rect.material.get_shader_param("brush_gradient").gradient
	
	gradient.set_offset(0, value * (1 - 1e-3))
