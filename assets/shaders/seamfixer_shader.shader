shader_type canvas_item;

uniform sampler2D paint_tex; // The viewport with paint in it
uniform sampler2D meshtex_pos; // The 3d position data 

void fragment()
{
	float epsilon = 1e-5;
	
	//Only need to fix seams on pixels outside any UV islands
	if (texture(meshtex_pos, UV).a >= epsilon)
		discard;
		
	int neighborhood = 5; //Look in neighborhood of -5....5 pixels for colors to fill in the seams	
	// TODO allow configuring this (but don't go too high or it'll lag)	
	
	vec3 new_color = vec3(0.0); //New color of this pixel
	int found_counter = 0; //How many samples we found we can use
	
	for (int x = -neighborhood; x <= neighborhood; x++)
	{
		for (int y = -neighborhood; y <= neighborhood; y++)
		{
			ivec2 point = ivec2(round(UV / SCREEN_PIXEL_SIZE)) + ivec2(x, y);
			vec4 pos_col = texelFetch(meshtex_pos, point, 0);
			vec4 paint_col = texelFetch(paint_tex, point, 0);
			
			if (pos_col.a < epsilon || paint_col.a < epsilon)
				continue;
				
			new_color += paint_col.rgb;
			found_counter++;
			
		}
	}
	
	//If no neighbors found, skip this pixel
	if (found_counter == 0)
		discard;
		
	//Else use the average of the colors found
	new_color /= float(found_counter);
	COLOR = vec4(new_color, 1.0);
		
		
}