shader_type spatial;

uniform sampler2D trunk_texture : source_color;
uniform float darken_start = 1.5;
uniform float darken_end = 3.0;

void fragment() {
    vec4 tex_color = texture(trunk_texture, UV);
    
    // Затемнение вместо прозрачности
    float dark = 1.0;
    if (VERTEX.y > darken_start) {
        dark = 1.0 - (VERTEX.y - darken_start) / (darken_end - darken_start);
        dark = clamp(dark, 0.1, 1.0);
    }
    
    ALBEDO = tex_color.rgb * dark;
    ROUGHNESS = 0.7;
}