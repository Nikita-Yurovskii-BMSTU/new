shader_type spatial;

uniform sampler2D albedo_texture : source_color;

void fragment() {
    vec4 tex_color = texture(albedo_texture, UV);
    
    // Повышаем контраст и резкость
    tex_color.rgb = pow(tex_color.rgb, vec3(0.8));
    tex_color.rgb = (tex_color.rgb - 0.5) * 1.2 + 0.5;
    
    ALBEDO = tex_color.rgb;
}