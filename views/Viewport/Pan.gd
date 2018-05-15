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
	if !(Input.is_mouse_button_pressed(BUTTON_MIDDLE) and Input.is_key_pressed(KEY_SHIFT)):
		state_machine.switch_state("Paint")
		return
	
	if !(event is InputEventMouseMotion):
		return

	var relative = event.relative
	
	camroot.translate(Vector3(0, 0, 1) * -relative.x / 500)
	camroot.translate(Vector3(0, 1, 0) * relative.y / 500)