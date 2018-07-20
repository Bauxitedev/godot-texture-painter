extends Node

var initial_mouse_position

onready var state_machine = $".."

var color_picker

func on_init():
	
	color_picker = PainterState.paint_viewport.colorpicker_node
	
	PainterState.paint_viewport.cursor_node.visible = false
	
	initial_mouse_position = get_tree().root.get_mouse_position()
	var middle_position = get_viewport().get_mouse_position()
	
	color_picker.rect_position = middle_position - color_picker.rect_size / 2
	color_picker.color = PainterState.brush.color
	color_picker.show()

func on_finalize():
	PainterState.paint_viewport.cursor_node.visible = true
	color_picker.hide()
	Input.warp_mouse_position(initial_mouse_position)
	

func update(delta):
	
	if Input.is_action_just_pressed("open_color_picker"):
		state_machine.switch_state("Paint")
	
	PainterState.brush.color = color_picker.color
	PainterState.brush.color_picker.color = color_picker.color

func handle_input(event):
	pass