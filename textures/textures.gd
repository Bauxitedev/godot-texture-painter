extends Node

var should_paint = false
var should_paint_decal = false


enum Slot {
	ALBEDO,
	ROUGHNESS,
	METALNESS,
	EMISSION
}

# Which slot we are currently painting on
var current_slot = ALBEDO


func update_shaders(mouse_pos, size, cam, color):
	
	var parent_viewport = PainterState.main.get_parent()
	
	
	var cam_matrix = cam.global_transform
	
	for paint_sprite in get_tree().get_nodes_in_group("paint_sprite"):
		
		var mat = paint_sprite.material	
		
		var paint_sprite_name = paint_sprite.get_parent().name 
		var slot_matches = Slot[paint_sprite_name.to_upper()] == current_slot
		paint_sprite.visible = should_paint && slot_matches
		
		# var label = get_node("/root/main/ui/hbox/" + paint_sprite_name + "/label")
		# label.add_color_override("font_color", Color(1,0.3,0) if slot_matches else Color(1,1,1))
		
		if !paint_sprite.visible:
			continue

		mat.set_shader_param("scale", size)	
		mat.set_shader_param("cam_mat", cam_matrix)
		mat.set_shader_param("z_near", cam.near)
		mat.set_shader_param("z_far", cam.far)
		mat.set_shader_param("fovy_degrees", cam.fov)
		mat.set_shader_param("mouse_pos", mouse_pos)
		mat.set_shader_param("aspect", 1.0) # Don't change this or your brush gets skewed!
		mat.set_shader_param("aspect_shadow", float(parent_viewport.size.x) / parent_viewport.size.y)
		mat.set_shader_param("decal", should_paint_decal)
		mat.set_shader_param("color", color)
	