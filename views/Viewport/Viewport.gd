extends WorldEnvironment

onready var state_machine = $InputStates


func _process(delta):
	state_machine.update(delta)

func _on_button_paint_gui_input(ev):
	state_machine.handle_input(ev)

func _ready():
	
	PainterState.textures_node = $textures
	
	state_machine.switch_state("Paint")
	
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