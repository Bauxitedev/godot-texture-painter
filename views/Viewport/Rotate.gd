extends Node

onready var state_machine = $".."

onready var cam = $"../../spatial/camroot/cam"
onready var camroot = $"../../spatial/camroot"

func on_init():
	PainterState.paint_viewport.cursor_node.visible = false

func on_finalize():
	PainterState.paint_viewport.cursor_node.visible = true

func update(delta):
	pass

func handle_input(event):
	if !Input.is_mouse_button_pressed(BUTTON_MIDDLE):
		state_machine.switch_state("Paint")
		return
		
	if !(event is InputEventMouseMotion):
		return
	
	var relative = event.relative
	
	camroot.rotate(cam.global_transform.basis.x.normalized(), -relative.y / 250)
	camroot.rotate(Vector3(0, 1, 0), -relative.x / 250)