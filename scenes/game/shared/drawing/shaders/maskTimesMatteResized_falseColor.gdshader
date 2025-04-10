shader_type canvas_item;

uniform sampler2D mask;

void fragment(){
	COLOR = texture(TEXTURE, UV);
	if (COLOR.rgb != vec3(0.0, 0.0, 0.0)){
		COLOR.rgb = vec3(1.0,0.0,0.0); // DESCRIPTION: Set all pixels red
	}

	if (texture(mask, UV).rgb == vec3(1.0, 1.0, 1.0)){
		if (COLOR.rgb != vec3(0.0, 0.0, 0.0)){
			COLOR.rgb = vec3(0.0,1.0,0.0); // DESCRIPTION: Set revealed pixels to green
		}
	}
}