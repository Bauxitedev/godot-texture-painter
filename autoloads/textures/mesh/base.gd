
extends Viewport

onready var draw = $draw 

export(Mesh) var mesh

# This scripts extracts the interpolated triangle's data in UV space

var tris = []

# Called whenever the mesh changes
func regenerate_mesh_texture():
	var datatool = MeshDataTool.new()
	datatool.create_from_surface(mesh, 0)
	
	tris = []
	
	for t in datatool.get_face_count():
		
		var p1i = datatool.get_face_vertex(t, 0)
		var p2i = datatool.get_face_vertex(t, 1)
		var p3i = datatool.get_face_vertex(t, 2)
		
		var triangle_data = _get_triangle_data(datatool, p1i, p2i, p3i)
		
		var uv1 = datatool.get_vertex_uv(p1i) * size
		var uv2 = datatool.get_vertex_uv(p2i) * size
		var uv3 = datatool.get_vertex_uv(p3i) * size
		
		tris.push_back([[uv1, uv2, uv3], triangle_data])
		
	# Trigger a single refresh of the viewport so the triangles get drawn
	# For some reason you need to wait 2 frames before it actually works
	render_target_update_mode = Viewport.UPDATE_ALWAYS
	$draw.update()	
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	render_target_update_mode = Viewport.UPDATE_DISABLED
	
func _ready():
	regenerate_mesh_texture()
	
# Override this method to return position/normal/tangent/vertex color/etc
func _get_triangle_data(datatool, p1i, p2i, p3i):
	pass

