shader_type canvas_item;

uniform sampler2D mask;

void fragment(){
	COLOR = texture(TEXTURE, UV);
	if (COLOR.a != 0.0){
		COLOR.a = texture(mask, UV).a;
	}
}