shader_type canvas_item;
uniform sampler2D dosa_texture;
uniform vec2 pan_center;
uniform float cook_level;

void fragment(){
    vec4 brush = texture(TEXTURE, UV);
    
    vec2 dosa_uv = UV - pan_center + vec2(0.5, 0.5);
    vec4 dosa = texture(dosa_texture, dosa_uv);
    
    vec4 batter_color = vec4(1.0, 1.0, 1.0, brush.a);  // white
    vec4 cooked_color = vec4(dosa.rgb, brush.a);
    
    COLOR = mix(batter_color, cooked_color, cook_level);
}