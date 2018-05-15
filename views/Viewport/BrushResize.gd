extends Node

var initial_mouse_position = Vector2()
var middle_position = Vector2()
var initial_size = 0
var offset = 0

onready var state_machine = $".."

onready var cursor = $"../../ui/cursor"

func on_init():
	middle_position = get_viewport().get_mouse_position()
	initial_mouse_position = get_tree().root.get_mouse_position()
	
	offset = get_viewport().size.y / PainterState.brush.size / 4
	
	Input.warp_mouse_position(initial_mouse_position + Vector2(offset, 0))
	
	initial_size = PainterState.brush.size

func on_finalize():
	Input.warp_mouse_position(initial_mouse_position)

func update(delta):
	if !Input.is_action_pressed("paint_resize_brush"):
		state_machine.switch_state("Paint")
		return
	
	# Set cursor size/pos
	var vp = get_viewport()
	var rect_size = Vector2(vp.size.y / PainterState.brush.size, vp.size.y / PainterState.brush.size) / 2
	cursor.rect_size = rect_size
	cursor.rect_position = middle_position - rect_size / 2

func handle_input(event):
	if !Input.is_action_pressed("paint_resize_brush"):
		state_machine.switch_state("Paint")
		return
	
	if event is InputEventMouseMotion:
		var length = (event.global_position - middle_position).length() / offset
		
		if length != 0.0:
			PainterState.brush.size = initial_size / length