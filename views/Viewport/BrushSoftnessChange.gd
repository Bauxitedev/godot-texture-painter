extends Node

var initial_mouse_position = Vector2()
var middle_position = Vector2()
var initial_softness = 0
var offset = 0
var length_of_slider = 0

onready var state_machine = $".."
onready var vp = get_viewport()

func on_init():

	length_of_slider = vp.size.y / 4
	
	initial_softness = PainterState.brush.softness_slider.value
	
	offset = initial_softness * length_of_slider
	
	initial_mouse_position = get_tree().root.get_mouse_position()
	
	Input.warp_mouse_position(initial_mouse_position + Vector2(offset, 0) * initial_softness)
	
	middle_position = vp.get_mouse_position()

func on_finalize():
	Input.warp_mouse_position(initial_mouse_position)

func update(delta):
	if !Input.is_action_pressed("paint_change_brush_softness"):
		state_machine.switch_state("Paint")
		return
	
	# Set cursor size/pos
	var rect_size = Vector2(length_of_slider, length_of_slider) * 2
	PainterState.paint_viewport.cursor_node.rect_size = rect_size
	PainterState.paint_viewport.cursor_node.rect_position = middle_position - rect_size / 2

func handle_input(event):
	if !Input.is_action_pressed("paint_change_brush_softness"):
		state_machine.switch_state("Paint")
		return
	
	if event is InputEventMouseMotion:
		var difference = (event.global_position - middle_position).length() / length_of_slider
		PainterState.brush.softness_slider.value = difference