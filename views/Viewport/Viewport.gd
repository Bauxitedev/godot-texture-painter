extends WorldEnvironment

onready var state_machine = $InputStates


func _process(delta):
	
	if Input.is_key_pressed(KEY_F12):
		PainterState.store_textures_on_disk("res://export/")
	
	state_machine.update(delta)
	
	# update the camera slave to match the actual camera
	
	var camera_slave = $textures/depth_buffer/cam_slave
	var camera = $spatial/camroot/cam
	
	camera_slave.global_transform = camera.global_transform
	camera_slave.fov = camera.fov
	camera_slave.near = camera.near
	camera_slave.far = camera.far
	
	# set depth_quad distance to camera to average of znear and zfar
	# this prevents the depth quad disappearing due to falling outside the depth buffer range
	camera_slave.get_node("depth_quad").translation.z = (camera.near + camera.far) / -2.0
	
	# this forces a viewport redraw
	# TODO new viewport is slow since it's drawing the object at 2048x2048 and then again at main res.
	# only update the viewport when camera transform/fov/near/far changes
	$textures/depth_buffer.render_target_update_mode = Viewport.UPDATE_ONCE
	

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
	
	var mat = $spatial/mesh.get_surface_material(0)
	$spatial/mesh.mesh = mesh

	# Set all the viewports to Filter + Aniso so we get smooth jaggies
	# (This needs to be done here, since it seems not to work when set in the editor)
	var flags = Texture.FLAG_FILTER | Texture.FLAG_ANISOTROPIC_FILTER
	# Don't enable REPEAT here or the seams will probably get worse
	
	mat.albedo_texture.flags = flags
	mat.roughness_texture.flags = flags	
	mat.metallic_texture.flags = flags		
	mat.emission_texture.flags = flags
	
	$spatial/mesh.set_surface_material(0, mat)
	

	
	# Regenerate all the mesh textures
	for vp in $textures/mesh.get_children():
		vp.mesh = mesh
		vp.regenerate_mesh_texture()

