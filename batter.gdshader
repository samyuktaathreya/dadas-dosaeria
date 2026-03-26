shader_type canvas_item;
uniform sampler2D dosa_texture_undercooked;
uniform sampler2D dosa_texture_cooked;
uniform sampler2D dosa_texture_slightly_overcooked;
uniform sampler2D dosa_texture_overcooked;
uniform float cooked_stage;
uniform vec2 pan_center; // 0..1 normalized screen position of this tawa's pan

void fragment(){
	vec4 brush = texture(TEXTURE, UV);

	// shift UVs so the dosa sprite centers on this tawa's pan
	vec2 dosa_uv = UV - pan_center + vec2(0.5, 0.5);

	vec4 dosa;
	if (cooked_stage > 0.5) {
		if (cooked_stage > 1.0) 
			dosa = texture(dosa_texture_cooked, dosa_uv);
		if (cooked_stage > 2.0)
			dosa = texture(dosa_texture_slightly_overcooked, dosa_uv);
		if (cooked_stage > 3.0) 
			dosa = texture(dosa_texture_overcooked, dosa_uv);
		if (cooked_stage <= 1.0)
			dosa = texture(dosa_texture_undercooked, dosa_uv);
		
		COLOR = vec4(dosa.rgb, brush.a);
	}
}