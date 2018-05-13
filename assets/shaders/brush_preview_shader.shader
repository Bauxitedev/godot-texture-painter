shader_type canvas_item;

uniform sampler2D brush_gradient;

void fragment()
{
	
	vec2 uv = vec2(distance(UV, vec2(0.5, 0.5)) * 2.0,0);
	
	if (uv.x > 1.0 - 1e-7)
		discard;
	COLOR = texture(brush_gradient, uv) * 1.0;
}