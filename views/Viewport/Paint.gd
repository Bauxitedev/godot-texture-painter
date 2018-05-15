extends Node

onready var state_machine = $".."

onready var cam = $"../../spatial/camroot/cam"
onready var camroot = $"../../spatial/camroot"

func on_init():
	pass

func on_finalize():
	pass

func update(delta):
	
	# switch textures
	
	var new_active_texture = -1
	
	if Input.is_key_pressed(KEY_1): new_active_texture = 0
	if Input.is_key_pressed(KEY_2): new_active_texture = 1
	if Input.is_key_pressed(KEY_3): new_active_texture = 2
	if Input.is_key_pressed(KEY_4): new_active_texture = 3
		
	if new_active_texture != -1:
		PainterState.set_active_texture(new_active_texture)
	
	if Input.is_action_just_pressed("open_color_picker"):
		state_machine.switch_state("ColorPick")
		return
	
	if Input.is_action_pressed("paint_change_brush_softness"):
		state_machine.switch_state("BrushSoftnessChange")
		return
	
	if Input.is_action_pressed("paint_resize_brush"):
		state_machine.switch_state("BrushResize")
		return
	
	rotate_cam(delta)
	
	# Get mouse pos in ndc space
	var vp = get_viewport()
	var mouse_pos = vp.get_mouse_position() / vp.size
	
	# Aspect ratio correction
	mouse_pos.x -= 0.5
	mouse_pos.x *= vp.size.x / float(vp.size.y)
	mouse_pos.x += 0.5
	
	# Hack to prevent painting being stuck
	if !Input.is_mouse_button_pressed(BUTTON_LEFT) && !Input.is_mouse_button_pressed(BUTTON_RIGHT):
		PainterState.textures_node.should_paint = false 
	
	# Set cursor size/pos
	var rect_size = Vector2(vp.size.y / PainterState.brush.size, vp.size.y / PainterState.brush.size) / 2
	PainterState.paint_viewport.cursor_node.rect_size = rect_size
	PainterState.paint_viewport.cursor_node.rect_position = get_viewport().get_mouse_position() - rect_size / 2
	
	# Update paint shaders
	PainterState.textures_node.update_shaders(mouse_pos, PainterState.brush.size, cam, PainterState.brush.color)

func handle_input(event):
	if event is InputEventMouseButton:
			
		if Input.is_mouse_button_pressed(BUTTON_MIDDLE) and Input.is_key_pressed(KEY_SHIFT):
			state_machine.switch_state("Pan")
			return
		
		if event.button_index == BUTTON_MIDDLE:
			state_machine.switch_state("Rotate")
			return
	
		if event.button_index == BUTTON_WHEEL_UP or event.button_index == BUTTON_WHEEL_DOWN:
			state_machine.switch_state("Zoom")
			return
			
		if event.pressed:
			PainterState.textures_node.should_paint = true
			PainterState.textures_node.should_paint_decal = event.button_index == BUTTON_RIGHT
		else:
			PainterState.textures_node.should_paint = false


func rotate_cam(delta):
	var rotspeed = 2
	if Input.is_action_pressed("ui_up"):
		camroot.rotate(cam.global_transform.basis.x.normalized(), -delta * rotspeed)
	if Input.is_action_pressed("ui_down"):
		camroot.rotate(cam.global_transform.basis.x.normalized(), delta * rotspeed)
	if Input.is_action_pressed("ui_left"):
		camroot.rotate(Vector3(0,1,0), -delta * rotspeed)
	if Input.is_action_pressed("ui_right"):
		camroot.rotate(Vector3(0,1,0), delta * rotspeed)