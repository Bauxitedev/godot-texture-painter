shader_type canvas_item;

uniform sampler2D meshtex_pos;
uniform sampler2D meshtex_normal;

uniform sampler2D brush_tex; //Brush gradient
uniform sampler2D spot_tex; //Decal texture
uniform sampler2D depth_tex; //Stores the depth buffer, used for shadow mapping
uniform mat4 cam_mat;

uniform float fovy_degrees = 45;
uniform float z_near = 0.01;
uniform float z_far = 60.0;
uniform float aspect = 1.0; //Keep at 1 for now or brush gets stretched
uniform float aspect_shadow = 1.0; //W/H of the depth buffer

uniform vec2 mouse_pos;
uniform bool decal;
uniform float scale = 1.0;
uniform vec4 color = vec4(1.0,1.0,1.0,1.0);

// See https://github.com/godotengine/godot/blob/34c988cfa92f19c232b65990704816ba1c7d2622/core/math/camera_matrix.cpp
mat4 get_projection_matrix()
{
	float PI = 3.14159265359;
	
	float rads = fovy_degrees / 2.0 * PI / 180.0;

	float deltaZ = z_far - z_near;
	float sine = sin(rads);

	if (deltaZ == 0.0 || sine == 0.0 || aspect == 0.0)
		return mat4(0.0);
	
	float cotangent = cos(rads) / sine;

	mat4 matrix = mat4(1.0);
	matrix[0][0] = cotangent / aspect;
	matrix[1][1] = cotangent;
	matrix[2][2] = (z_far + z_near) / deltaZ;
	matrix[2][3] = 1.0; //try +1
	matrix[3][2] = 2.0 * z_near * z_far / deltaZ; 
	
	matrix[3][3] = 0.0;
	
	return matrix;
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment()
{
	//This is the 3d position of the triangle we're gonna paint on
	vec4 pos4 = texture(meshtex_pos, UV);
	if (pos4.a == 0.0)
		discard; //TODO better idea would be to multiply the end result with pos4.a to get anti aliased drawing across seams
		
	vec3 pos = pos4.rgb;
	
	// Normal of the vertex
	vec3 normal = texture(meshtex_normal, UV).xyz;
	
	vec4 obj_pos = inverse(cam_mat) * vec4(pos, 1.0);
	obj_pos.w = 1.0; 
	obj_pos = get_projection_matrix() * obj_pos; //From eye space to clip space
	obj_pos.xyz /= obj_pos.w; //From clip to normalized device coords

	vec2 depth_uv = obj_pos.xy;

	//Offset by mouse position and scale
	depth_uv += mouse_pos * vec2(1,-1) * 2.0 + vec2(-0.5,1.5);
	depth_uv = 2.0 * depth_uv - 1.0;
	depth_uv *= scale;
	depth_uv = 0.5 + 0.5 * depth_uv;
	
	vec2 depth_uv_shadow = 0.5 + 0.5 * (obj_pos.xy / vec2(aspect_shadow, 1.0));
	depth_uv_shadow = vec2(1.0-depth_uv_shadow.x, depth_uv_shadow.y); //x flipping needed for some reason???
	
	vec4 tex_albedo = textureLod(spot_tex, depth_uv, 0.0);
	
	//Attenuation due to normal alignment
	float normal_mutliplier = clamp(dot(normal, cam_mat[2].xyz), 0.0, 1.0); 
	
	bool outside_bounds = depth_uv.x < 0.0 || depth_uv.x > 1.0 || depth_uv.y < 0.0 || depth_uv.y > 1.0;
	bool outside_depth_bounds = obj_pos.z > 1.0 || obj_pos.z < -1.0;
	
	if (outside_bounds || outside_depth_bounds)
	{
		COLOR = vec4(0);
	}
	else
	{
		
		//shadow mapping to prevent painting on occluded surfaces
		vec3 l = cam_mat[2].xyz; //Light direction
		float cosTheta = clamp(dot(normalize(normal), normalize(l)), 0.0, 1.0);
		float bias = 0.005*tan(acos(cosTheta));
		bias = clamp(bias, 0.0, 0.01); 
		
		float transition_area = 0.01; //for smooth shadows
	
		//float c = 80.0; //180 is too much, but 80 is not good enough when painting from far away
		float shadow_mult = 0.0; //shadow multiplier
		int divisor = 4;
		for (int i = 0; i < divisor; i++) //sample x random positions on the shadow map
		{
			vec2 offset = vec2(rand(UV+float(i)*-0.7+vec2(0,TIME*0.1)), rand(UV+1.0+0.9*float(i)-TIME)) * 0.007;
			//TODO offset should abide by aspect_shadow
			float d = texture(depth_tex, depth_uv_shadow + offset, 0).r * 2.0 - 1.0; //convert depth to NDC		
			//shadow_mult += clamp(exp(-c*obj_pos.z)*exp(c*d), 0.0, 1.0); //(exponential-ish) is nicely smooth but TOO smooth (allows painting through surfaces)
			shadow_mult += smoothstep(obj_pos.z - bias - transition_area, obj_pos.z - bias + transition_area, d); //smooth shadows 
		}
		shadow_mult /= float(divisor);
		
		/*float d = texture(depth_tex, depth_uv_shadow, 0).r * 2.0 - 1.0;
		shadow_mult = smoothstep(obj_pos.z - bias, obj_pos.z, d);*/
		
		if (!decal) //Paint brush
		{
			//Gonna disable AA for now because of the outline bug
			if (length(depth_uv - 0.5) >= 0.5 - 1e-4)
				discard;
				
			float multiplier = 1.0;
			
			//Obey normals and shadows
			multiplier *= normal_mutliplier * shadow_mult;
			
			//Read the brush texture
			vec4 brush_value = texture(brush_tex, vec2(2.0 * length(depth_uv - vec2(0.5)), 0));
			
			COLOR = color * brush_value * vec4(vec3(1.0), multiplier);
		}
		else //Paint decal texture
			COLOR = vec4(vec3(1.0), normal_mutliplier * shadow_mult) * tex_albedo * color;
	}

}