
extends Node2D

func _ready():
	update() # NOTE: actually needed to set viewport update mode to Once

	
func _draw():
	
	# This draws all triangles in UV space, using interpolated 3d data as colors
	
	var tris = get_parent().tris
	
	for t in tris:
	
		var uvs = t[0] # 3 uvs of the triangle
		var data = t[1] # 3 data vec3's of the triangle
		
		var colors = []
		for vec in data:
			colors.push_back(Color(vec.x, vec.y, vec.z))
			
		draw_polygon(uvs, colors, [], null, null, true)
		
		# TODO you might want to spread out a little
		# so you blend colors across seams
