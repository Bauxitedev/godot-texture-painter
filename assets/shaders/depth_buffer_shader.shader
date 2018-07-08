shader_type spatial;
render_mode cull_disabled, depth_test_disable, depth_draw_never, unshaded;

void fragment()
{
	ALBEDO = pow(texture(DEPTH_TEXTURE, SCREEN_UV, 0).rrr, vec3(2.2));
	//Need to manually undo gamma correction for now by raising to power 2.2... see https://github.com/godotengine/godot/issues/18509
	//In godot 3.1 you can remove this and instead set "keep linear" on the depth_buffer viewport
}