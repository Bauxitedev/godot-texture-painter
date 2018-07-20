extends "res://autoloads/textures/mesh/base.gd"

# Extracts position data for this triangle
func _get_triangle_data(datatool, p1i, p2i, p3i):
	
	var p1 = datatool.get_vertex(p1i)
	var p2 = datatool.get_vertex(p2i)
	var p3 = datatool.get_vertex(p3i)
	
	return [p1, p2, p3]