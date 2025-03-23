shader_type canvas_item;

uniform sampler2D mask;
uniform vec2 target = vec2 (0.5f);

void fragment(){
	COLOR = texture(TEXTURE, UV);
	float x = SCREEN_PIXEL_SIZE.x / distance(vec2(target.x,UV.y),UV);
	float y = SCREEN_PIXEL_SIZE.y / distance (vec2(UV.x,target.y),UV);
	COLOR.a = texture(mask,vec2(x,y)).r;
}
