
extends WorldEnvironment

var size = 4 # Note - this is actually scale inverted

onready var textures = $textures

class InputHandlerState:
	func handle_input(parent, event):
		pass
	
	func update(parent, delta):
		pass

enum States {
	Paint,
	BrushResize,
	BrushSoftnessChange,
}

class BrushSoftnessChangeState extends InputHandlerState:
	
	var middle_position = Vector2()
	var initial_softness = 0
	var new_softness
	var offset = 0
	
	var length_of_slider = 0
	
	func _init(parent):
		var vp = parent.get_viewport()
		
		length_of_slider = vp.size.y / 4
		
		initial_softness = parent.get_node("ui/brush_preview/softness_slider").value
		
		offset = initial_softness * length_of_slider
		
		middle_position = vp.get_mouse_position()
		middle_position.x -= offset
	
	func handle_input(parent, event):
		if !Input.is_action_pressed("paint_change_brush_softness"):
			parent.state = parent.state_classes[parent.Paint].new()
		
		if event is InputEventMouseMotion:
			var difference = (event.global_position - middle_position).length() / length_of_slider
			parent.get_node("ui/brush_preview/softness_slider").value = difference
	
	func update(parent, delta):
		if !Input.is_action_pressed("paint_change_brush_softness"):
			parent.state = parent.state_classes[parent.Paint].new()
		
		# Set cursor size/pos
		var vp = parent.get_viewport()
		var rect_size = Vector2(length_of_slider, length_of_slider) * 2
		parent.get_node("ui/cursor").rect_size = rect_size
		parent.get_node("ui/cursor").rect_position = middle_position - rect_size / 2


class BrushResizeState extends InputHandlerState:
	
	var middle_position = Vector2()
	var initial_size = 0
	
	var offset = 50
	
	func _init(parent):
		var vp = parent.get_viewport()
		middle_position = vp.get_mouse_position()
		
		offset = vp.size.y / parent.size / 4
		
		middle_position.x -= offset
		initial_size = parent.size
	
	func handle_input(parent, event):
		if !Input.is_action_pressed("paint_resize_brush"):
			parent.state = parent.state_classes[parent.Paint].new()
		
		if event is InputEventMouseMotion:
			var length = (event.global_position - middle_position).length() / offset
			
			if length != 0.0:
				parent.size = initial_size / length
			
	
	func update(parent, delta):
		if !Input.is_action_pressed("paint_resize_brush"):
			parent.state = parent.state_classes[parent.Paint].new()
		
		# Set cursor size/pos
		var vp = parent.get_viewport()
		var rect_size = Vector2(vp.size.y / parent.size, vp.size.y / parent.size) / 2
		parent.get_node("ui/cursor").rect_size = rect_size
		parent.get_node("ui/cursor").rect_position = middle_position - rect_size / 2
		

class PaintState extends InputHandlerState:
	
	func handle_input(parent, ev):
		if ev is InputEventMouseButton:
		
			if ev.button_index == BUTTON_WHEEL_UP:
				parent.size /= 1.1
				return
			if ev.button_index == BUTTON_WHEEL_DOWN:
				parent.size *= 1.1
				return
				
			if ev.pressed:
				parent.textures.should_paint = true
				parent.textures.should_paint_decal = ev.button_index == BUTTON_RIGHT
			else:
				parent.textures.should_paint = false
				
		
		if ev is InputEventKey and ev.pressed:
			
			match ev.scancode:
				KEY_1: parent.textures.current_slot = 0
				KEY_2: parent.textures.current_slot = 1
				KEY_3: parent.textures.current_slot = 2
				KEY_4: parent.textures.current_slot = 3
				
		
		if Input.is_action_pressed("paint_resize_brush"):
			parent.state = parent.state_classes[parent.BrushResize].new(parent)
		
		if Input.is_action_pressed("paint_change_brush_softness"):
			parent.state = parent.state_classes[parent.BrushSoftnessChange].new(parent)
	
	func update(parent, delta):
			# Cam controls
		var cam = parent.get_node("spatial/camroot/cam")
		parent.rotate_cam(cam, delta)
		
		# Get mouse pos in ndc space
		var vp = parent.get_viewport()
		var mouse_pos = vp.get_mouse_position() / vp.size
		
		# Aspect ratio correction
		mouse_pos.x -= 0.5
		mouse_pos.x *= vp.size.x / float(vp.size.y)
		mouse_pos.x += 0.5
		
		# Hack to prevent painting being stuck
		if !Input.is_mouse_button_pressed(BUTTON_LEFT) && !Input.is_mouse_button_pressed(BUTTON_RIGHT):
			parent.textures.should_paint = false 
		
		# Set cursor size/pos
		var rect_size = Vector2(vp.size.y / parent.size, vp.size.y / parent.size) / 2
		parent.get_node("ui/cursor").rect_size = rect_size
		parent.get_node("ui/cursor").rect_position = parent.get_viewport().get_mouse_position() - rect_size / 2
		
		# Update paint shaders
		parent.textures.update_shaders(mouse_pos, parent.size, cam, parent.get_node("ui/margin/picker").color)

func rotate_cam(cam, delta):
	var rotspeed = 2
	if Input.is_action_pressed("ui_up"):
		$spatial/camroot.rotate(cam.global_transform.basis.x.normalized(), -delta * rotspeed)
	if Input.is_action_pressed("ui_down"):
		$spatial/camroot.rotate(cam.global_transform.basis.x.normalized(), delta * rotspeed)
	if Input.is_action_pressed("ui_left"):
		$spatial/camroot.rotate(Vector3(0,1,0), -delta * rotspeed)
	if Input.is_action_pressed("ui_right"):
		$spatial/camroot.rotate(Vector3(0,1,0), delta * rotspeed)


var state = PaintState.new()

var state_classes = {
	Paint: PaintState,
	BrushResize: BrushResizeState,
	BrushSoftnessChange: BrushSoftnessChangeState
}

func _process(delta):
	state.update(self, delta)



func _on_button_paint_gui_input(ev):
	state.handle_input(self, ev)
	



func _on_softness_slider_value_changed(value):
	
	var gradient = $ui/brush_preview/rect.material.get_shader_param("brush_gradient").gradient
	
	gradient.set_offset(0, value * (1 - 1e-3))
