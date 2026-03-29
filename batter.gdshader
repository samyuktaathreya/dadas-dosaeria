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

	// Use smoothstep to feather the edge of the drawn brush stroke.
    // The values (0.05 to 0.8) control the harshness of the fade. 
    // Tweak these numbers to make the edge softer or harder!
	float soft_brush_mask = smoothstep(0.05, 0.8, brush.a);

	if (cooked_stage > 0.5) {
		vec4 dosa = vec4(0.0);
		
        // Switched to if/else-if for cleaner fallback logic
		if (cooked_stage > 3.0) {
			dosa = texture(dosa_texture_overcooked, dosa_uv);
		} else if (cooked_stage > 2.0) {
			dosa = texture(dosa_texture_slightly_overcooked, dosa_uv);
		} else if (cooked_stage > 1.0) {
			dosa = texture(dosa_texture_cooked, dosa_uv);
		} else {
			dosa = texture(dosa_texture_undercooked, dosa_uv);
		}
		
		// Multiply dosa's alpha by our softened mask to respect both bounds
		COLOR = vec4(dosa.rgb, dosa.a * soft_brush_mask);
	} else {
        // Make sure the raw, uncooked batter also gets the soft edge!
        COLOR = vec4(brush.rgb, brush.a * soft_brush_mask);
    }
}