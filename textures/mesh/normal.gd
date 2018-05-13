extends "res://textures/mesh/base.gd"

# Extracts normal data for this triangle
func _get_triangle_data(datatool, p1i, p2i, p3i):
	
	var p1 = datatool.get_vertex_normal(p1i)
	var p2 = datatool.get_vertex_normal(p2i)
	var p3 = datatool.get_vertex_normal(p3i)
	
	return [p1, p2, p3]