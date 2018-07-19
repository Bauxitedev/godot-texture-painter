extends WorldEnvironment

onready var state_machine = $InputStates
onready var parent_viewport = get_parent()
onready var depth_buffer = Textures.get_node("depth_buffer")


func _process(delta):
	
	if Input.is_key_pressed(KEY_F12): 
		PainterState.store_textures_on_disk("res://export/")
	
	if !Dialogs.any_dialog_open():
		state_machine.update(delta)
	
	update_depth_buffer()
	
func update_depth_buffer(): # TODO move this into the Textures scene
	# update depth buffer size to match parent viewport
	depth_buffer.size = parent_viewport.size
	
	# update the camera slave to match the actual camera
	var camera_slave = Textures.get_node("depth_buffer/cam_slave")
	var camera = $spatial/camroot/cam
	camera_slave.global_transform = camera.global_transform
	camera_slave.fov = camera.fov
	camera_slave.near = camera.near
	camera_slave.far = camera.far
	
	# set depth_quad distance to camera to average of znear and zfar
	# this prevents the depth quad disappearing due to falling outside the depth buffer range
	camera_slave.get_node("depth_quad").translation.z = (camera.near + camera.far) / -2.0
	
	# this forces a viewport redraw
	# TODO new viewport is slow since it's drawing the object TWICE, once in main buffer and once in depth buffer.
	# only update the viewport when camera transform/fov/near/far changes
	# depth_buffer.render_target_update_mode = Viewport.UPDATE_ONCE
	# Update - new bug appeared! when viewport is thin and you change znear, the viewport doesn't clear itself anymore
	# UPDATE2 - even after uncommenting this, the viewport still occasionally ends up in no-clear mode

func _on_ViewportUI_gui_input(ev):
	if !Dialogs.any_dialog_open():
		state_machine.handle_input(ev)

func _ready():
	
	PainterState.main = self
	PainterState.textures_node = Textures # TODO get rid of textures_node, no longer needed
	
	state_machine.switch_state("Paint")
	
	# setup the mesh's spatial textures (TODO maybe do this in the Textures node instead?)
	var mat = $spatial/mesh.get_surface_material(0)
	mat.albedo_texture = Textures.get_node("paint/albedo").get_texture()
	mat.roughness_texture = Textures.get_node("paint/roughness").get_texture()
	mat.metallic_texture = Textures.get_node("paint/metalness").get_texture()
	mat.emission_texture = Textures.get_node("paint/emission").get_texture()
	$debug_todo_remove_this.texture =  Textures.get_node("depth_buffer").get_texture()
	
	# setup the paint shader's viewport textures
	var paint_shader = Textures.get_node("paint/albedo/paint_sprite").material
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

