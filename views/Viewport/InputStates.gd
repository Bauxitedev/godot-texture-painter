extends Node

var state = null

var state_key = ""
var next_state_key = ""

func update(delta):
	if state:
		state.update(delta)
	
	_maybe_perform_transition()

func handle_input(event):
	if state:
		state.handle_input(event)
	
	_maybe_perform_transition()

func switch_state(new_state):
	next_state_key = new_state

func _maybe_perform_transition():
	if next_state_key != "":
		if state:
			state.on_finalize()
		
		state_key = next_state_key
		next_state_key = ""
		
		state = get_node(state_key)
		if state:
			state.on_init()