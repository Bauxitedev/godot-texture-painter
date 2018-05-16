extends WorldEnvironment

onready var state_machine = $InputStates


func _process(delta):
	state_machine.update(delta)

func _on_ViewportUI_gui_input(ev):
	state_machine.handle_input(ev)

func _ready():
	
	PainterState.textures_node = $textures
	
	state_machine.switch_state("Paint")
	
	change_mesh(preload("res://assets/models/Suzanne.mesh"))



func _on_softness_slider_value_changed(value):
	
	var gradient = $ui/brush_preview/rect.material.get_shader_param("brush_gradient").gradient
	
	gradient.set_offset(0, value * (1 - 1e-3))

func change_mesh(mesh):
	
	print("changed mesh to ", mesh)	
	
	# This will make the program paint on a different mesh
	
	# TODO rename the "suz" node to "mesh" for consistency
	var mat = $spatial/suz.get_surface_material(0)
	$spatial/suz.mesh = mesh

	# Set all the viewports to Filter + Aniso so we get smooth jaggies
	# (This needs to be done here, since it seems not to work when set in the editor)
	var flags = Texture.FLAG_FILTER | Texture.FLAG_ANISOTROPIC_FILTER
	# Don't enable REPEAT here or the seams will probably get worse
	
	mat.albedo_texture.flags = flags
	mat.roughness_texture.flags = flags	
	mat.metallic_texture.flags = flags		
	mat.emission_texture.flags = flags
	
	$spatial/suz.set_surface_material(0, mat)
	

	
	# Regenerate all the mesh textures
	for vp in $textures/mesh.get_children():
		vp.mesh = mesh
		vp.regenerate_mesh_texture()

