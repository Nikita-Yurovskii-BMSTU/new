shader_type spatial;
render_mode blend_mix;

uniform sampler2D leaf_texture : source_color;
uniform float wind_speed = 1.0;
uniform float wind_strength = 0.05;

void vertex() {
    float height = VERTEX.y;
    VERTEX.x += sin(TIME * wind_speed + VERTEX.x) * wind_strength * height;
    VERTEX.z += cos(TIME * wind_speed * 0.8 + VERTEX.z) * wind_strength * height;
}

void fragment() {
    vec4 tex_color = texture(leaf_texture, UV);
    ALBEDO = tex_color.rgb;
    // ALPHA не трогаем — модель сама решает, где должны быть листья
    ROUGHNESS = 0.6;
	ALPHA = tex_color.a +0.0;

}