
extends WorldEnvironment

var size = 4 # Note - this is actually scale inverted

onready var textures = $textures

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
		

func _process(delta):
	
	# Cam controls
	var cam = $spatial/camroot/cam		
	rotate_cam(cam, delta)
	
	# Get mouse pos in ndc space
	var vp = get_viewport()
	var mouse_pos = vp.get_mouse_position() / vp.size
	
	# Aspect ratio correction
	mouse_pos.x -= 0.5
	mouse_pos.x *= vp.size.x / float(vp.size.y)
	mouse_pos.x += 0.5
	
	# Hack to prevent painting being stuck
	if !Input.is_mouse_button_pressed(BUTTON_LEFT) && !Input.is_mouse_button_pressed(BUTTON_RIGHT):
		textures.should_paint = false 
	
	# Set cursor size/pos
	var rect_size = Vector2(vp.size.y / size, vp.size.y / size) / 2
	$ui/cursor.rect_size = rect_size
	$ui/cursor.rect_position = get_viewport().get_mouse_position() - rect_size / 2
	
	# Update paint shaders
	textures.update_shaders(mouse_pos, size, cam, $ui/margin/picker.color)


func _on_button_paint_gui_input(ev):
	
	if ev is InputEventMouseButton:
		
		if ev.button_index == BUTTON_WHEEL_UP:
			size /= 1.1
			return
		if ev.button_index == BUTTON_WHEEL_DOWN:
			size *= 1.1
			return
			
		if ev.pressed:
			textures.should_paint = true
			textures.should_paint_decal = ev.button_index == BUTTON_RIGHT
		else:
			textures.should_paint = false
			
	
	if ev is InputEventKey and ev.pressed:
		
		match ev.scancode:
			KEY_1: textures.current_slot = 0
			KEY_2: textures.current_slot = 1
			KEY_3: textures.current_slot = 2
			KEY_4: textures.current_slot = 3


func _on_softness_slider_value_changed(value):
	
	var gradient = $ui/brush_preview/rect.material.get_shader_param("brush_gradient").gradient
	
	gradient.set_offset(0, value * (1 - 1e-3))
