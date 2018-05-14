
extends WorldEnvironment

var size = 4 # Note - this is actually scale inverted

signal active_texture_changed(idx)

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
	Rotate,
	Zoom,
	Pan,
	ColorPick,
}

class BrushSoftnessChangeState extends InputHandlerState:
	
	var initial_mouse_position = Vector2()
	var middle_position = Vector2()
	var initial_softness = 0
	var offset = 0
	
	var length_of_slider = 0
	
	func _init(parent):
		var vp = parent.get_viewport()
		
		length_of_slider = vp.size.y / 4
		
		initial_softness = PainterState.brush.softness_slider.value
		
		offset = initial_softness * length_of_slider
		
		initial_mouse_position = vp.get_mouse_position()
		
		middle_position = vp.get_mouse_position()
		middle_position.x -= offset
	
	func handle_input(parent, event):
		if !Input.is_action_pressed("paint_change_brush_softness"):
			Input.warp_mouse_position(initial_mouse_position)
			parent.state = parent.state_classes[parent.Paint].new()
		
		if event is InputEventMouseMotion:
			var difference = (event.global_position - middle_position).length() / length_of_slider
			PainterState.brush.softness_slider.value = difference
	
	func update(parent, delta):
		if !Input.is_action_pressed("paint_change_brush_softness"):
			Input.warp_mouse_position(initial_mouse_position)
			parent.state = parent.state_classes[parent.Paint].new()
		
		# Set cursor size/pos
		var vp = parent.get_viewport()
		var rect_size = Vector2(length_of_slider, length_of_slider) * 2
		parent.get_node("ui/cursor").rect_size = rect_size
		parent.get_node("ui/cursor").rect_position = middle_position - rect_size / 2


class BrushResizeState extends InputHandlerState:
	
	var initial_mouse_position = Vector2()
	var middle_position = Vector2()
	var initial_size = 0
	
	var offset = 50
	
	func _init(parent):
		var vp = parent.get_viewport()
		middle_position = vp.get_mouse_position()
		initial_mouse_position = vp.get_mouse_position()
		
		offset = vp.size.y / parent.size / 4
		
		middle_position.x -= offset
		initial_size = parent.size
	
	func handle_input(parent, event):
		if !Input.is_action_pressed("paint_resize_brush"):
			Input.warp_mouse_position(initial_mouse_position)
			parent.state = parent.state_classes[parent.Paint].new()
		
		if event is InputEventMouseMotion:
			var length = (event.global_position - middle_position).length() / offset
			
			if length != 0.0:
				parent.size = initial_size / length
			
	
	func update(parent, delta):
		if !Input.is_action_pressed("paint_resize_brush"):
			Input.warp_mouse_position(initial_mouse_position)
			parent.state = parent.state_classes[parent.Paint].new()
		
		# Set cursor size/pos
		var vp = parent.get_viewport()
		var rect_size = Vector2(vp.size.y / parent.size, vp.size.y / parent.size) / 2
		parent.get_node("ui/cursor").rect_size = rect_size
		parent.get_node("ui/cursor").rect_position = middle_position - rect_size / 2
		

class PaintState extends InputHandlerState:
	
	func handle_input(parent, ev):
		if ev is InputEventMouseButton:
			
			if Input.is_mouse_button_pressed(BUTTON_MIDDLE) and Input.is_key_pressed(KEY_SHIFT):
				parent.state = parent.state_classes[parent.Pan].new(parent)
				return
			
			if ev.button_index == BUTTON_MIDDLE:
				parent.state = parent.state_classes[parent.Rotate].new(parent)
				return
		
			if ev.button_index == BUTTON_WHEEL_UP or ev.button_index == BUTTON_WHEEL_DOWN:
				parent.state = parent.state_classes[parent.Zoom].new(parent)
				parent.state.handle_input(parent, ev) # we don't want to waste that.
				return
				
			if ev.pressed:
				parent.textures.should_paint = true
				parent.textures.should_paint_decal = ev.button_index == BUTTON_RIGHT
			else:
				parent.textures.should_paint = false
				
		
		if ev is InputEventKey and ev.pressed:
			
			var changed_texture = true
			
			match ev.scancode:
				KEY_1: parent.textures.current_slot = 0
				KEY_2: parent.textures.current_slot = 1
				KEY_3: parent.textures.current_slot = 2
				KEY_4: parent.textures.current_slot = 3
				_: changed_texture = false
			
			if changed_texture:
				parent.emit_signal("active_texture_changed", parent.textures.current_slot)
	
	func update(parent, delta):
		
		if Input.is_action_just_pressed("open_color_picker"):
			parent.state = parent.state_classes[parent.ColorPick].new(parent)
		
		if Input.is_action_pressed("paint_resize_brush"):
			parent.state = parent.state_classes[parent.BrushResize].new(parent)
		
		if Input.is_action_pressed("paint_change_brush_softness"):
			parent.state = parent.state_classes[parent.BrushSoftnessChange].new(parent)
		
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
		parent.textures.update_shaders(mouse_pos, parent.size, cam, PainterState.brush.color)

class RotateState extends InputHandlerState:
	func _init(parent):
		parent.get_node("ui/cursor").visible = false
	
	func handle_input(parent, event):
		
		if !Input.is_mouse_button_pressed(BUTTON_MIDDLE):
			parent.get_node("ui/cursor").visible = true
			parent.state = parent.state_classes[parent.Paint].new()
			return
		
		if !(event is InputEventMouseMotion):
			return
		
		var relative = event.relative
		
		var camroot = parent.get_node("spatial/camroot")
		var cam = parent.get_node("spatial/camroot/cam")
		
		camroot.rotate(cam.global_transform.basis.x.normalized(), -relative.y / 250)
		camroot.rotate(Vector3(0, 1, 0), -relative.x / 250)
	
	func update(parent, delta):
		pass

class ZoomState extends InputHandlerState:
	func _init(parent):
		parent.get_node("ui/cursor").visible = false
		pass
	
	func handle_input(parent, event):
		
		var direction
		
		if Input.is_mouse_button_pressed(BUTTON_WHEEL_UP):
			direction = -1.0
		elif Input.is_mouse_button_pressed(BUTTON_WHEEL_DOWN):
			direction = 1.0
		else:
			parent.get_node("ui/cursor").visible = true
			parent.state = parent.state_classes[parent.Paint].new()
			return

		var cam = parent.get_node("spatial/camroot/cam")
		
		var factor = 0.3
		
		cam.translate(Vector3(0, 0, 1) * factor * direction)
	
	func update(parent, event):
		pass

class PanState extends InputHandlerState:
	func _init(parent):
		parent.get_node("ui/cursor").visible = false
		pass
	
	func handle_input(parent, event):
		
		if !(Input.is_mouse_button_pressed(BUTTON_MIDDLE) and Input.is_key_pressed(KEY_SHIFT)):
			parent.get_node("ui/cursor").visible = true
			parent.state = parent.state_classes[parent.Paint].new()
			return
		
		if !(event is InputEventMouseMotion):
			return

		var relative = event.relative
		
		var camroot = parent.get_node("spatial/camroot")
		var cam = parent.get_node("spatial/camroot/cam")
		
		camroot.translate(Vector3(0, 0, 1) * -relative.x / 500)
		camroot.translate(Vector3(0, 1, 0) * relative.y / 500)
	
	func update(parent, event):
		pass

class ColorPickState extends InputHandlerState:
	
	var color_picker
	var initial_mouse_position
	
	func _init(parent):
		parent.get_node("ui/cursor").visible = false
		
		initial_mouse_position = parent.get_viewport().get_mouse_position()
		
		color_picker = parent.get_node("ui/ColorPicker")
		color_picker.rect_position = initial_mouse_position - color_picker.rect_size / 2
		color_picker.color = PainterState.brush.color
		color_picker.show()
		
		pass
	
	func handle_input(parent, event):
		pass
	
	func update(parent, event):
		
		if Input.is_action_just_pressed("open_color_picker"):
			color_picker.hide()
			parent.get_node("ui/cursor").visible = true
			parent.state = parent.state_classes[parent.Paint].new()
			Input.warp_mouse_position(initial_mouse_position)
			return
		
		PainterState.brush.color = color_picker.color
		PainterState.brush.color_picker.color = color_picker.color
		pass

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
	BrushSoftnessChange: BrushSoftnessChangeState,
	Rotate: RotateState,
	Zoom: ZoomState,
	Pan: PanState,
	ColorPick: ColorPickState,
}

func _process(delta):
	state.update(self, delta)

func _on_button_paint_gui_input(ev):
	state.handle_input(self, ev)

func _ready():
	
	change_mesh(preload("res://assets/models/Suzanne.mesh"))	
	
	# For debugging so you can see this works...
	# yield(get_tree().create_timer(2.0), "timeout")
	# change_mesh(preload("res://assets/models/Torus.mesh"))
	
	# yield(get_tree().create_timer(2.0), "timeout")
	# change_mesh(preload("res://assets/models/Suzanne.mesh"))

func _on_softness_slider_value_changed(value):
	
	var gradient = $ui/brush_preview/rect.material.get_shader_param("brush_gradient").gradient
	
	gradient.set_offset(0, value * (1 - 1e-3))

func change_mesh(mesh):
	
	print("changed mesh to ", mesh)	
	
	# This will make the program paint on a different mesh
	
	# TODO rename the "suz" node to "mesh" for consistency
	# Hack - setting a mesh resets the material, so keep it around and set it again
	var mat = $spatial/suz.get_surface_material(0)
	$spatial/suz.mesh = mesh
	$spatial/suz.set_surface_material(0, mat)
	
	# Regenerate all the mesh textures
	for vp in $textures/mesh.get_children():
		vp.mesh = mesh
		vp.regenerate_mesh_texture()