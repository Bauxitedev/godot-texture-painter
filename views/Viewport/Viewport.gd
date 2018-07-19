extends WorldEnvironment

onready var state_machine = $InputStates
onready var parent_viewport = get_parent()
onready var camera =  $spatial/camroot/cam

func _process(delta):
	
	if Input.is_key_pressed(KEY_F12): 
		PainterState.store_textures_on_disk("res://export/")
	
	if !Dialogs.any_dialog_open():
		state_machine.update(delta)
	


func _on_ViewportUI_gui_input(ev):
	if !Dialogs.any_dialog_open():
		state_machine.handle_input(ev)

func _ready():
	
	PainterState.main = self
	
	state_machine.switch_state("Paint")
	
	# setup the mesh's spatial textures (TODO maybe do this in the Textures node instead?)
	var mat = $spatial/mesh.get_surface_material(0)
	mat.albedo_texture = Textures.get_node("paint/albedo").get_texture()
	mat.roughness_texture = Textures.get_node("paint/roughness").get_texture()
	mat.metallic_texture = Textures.get_node("paint/metalness").get_texture()
	mat.emission_texture = Textures.get_node("paint/emission").get_texture()
	$debug_todo_remove_this.texture =  Textures.get_node("depth_buffer").get_texture()
	
	# setup the paint shader's viewport textures
	var paint_shader = preload("res://assets/shaders/paint_shader.tres") 
	paint_shader.set_shader_param("meshtex_pos", Textures.get_node("mesh/position").get_texture())
	paint_shader.set_shader_param("meshtex_normal",  Textures.get_node("mesh/normal").get_texture())
	paint_shader.set_shader_param("depth_tex", Textures.get_node("depth_buffer").get_texture())
	
	# finally setup mesh
	change_mesh(preload("res://assets/models/Suzanne.mesh"))


func _on_softness_slider_value_changed(value):
	
	var gradient = $ui/brush_preview/rect.material.get_shader_param("brush_gradient").gradient
	
	gradient.set_offset(0, value * (1 - 1e-3))

func change_mesh(mesh): # This will make the program paint on a different mesh
	
	var mat = $spatial/mesh.get_surface_material(0)
	$spatial/mesh.mesh = mesh

	# Set all the viewports to Filter + Aniso so we get smooth jaggies (This needs to be done here, since it seems not to work when set in the editor)
	var flags = Texture.FLAG_FILTER | Texture.FLAG_ANISOTROPIC_FILTER
	mat.albedo_texture.flags = flags 
	mat.roughness_texture.flags = flags	 
	mat.metallic_texture.flags = flags
	mat.emission_texture.flags = flags
	
	$spatial/mesh.set_surface_material(0, mat)
	
	# Regenerate all the mesh textures
	for vp in Textures.get_node("mesh").get_children():
		vp.mesh = mesh
		vp.regenerate_mesh_texture()

