shader_type spatial;
render_mode blend_mix;

uniform sampler2D albedo_texture : source_color;
uniform float wind_speed = 0.8;
uniform float wind_strength = 0.02;  // Уменьшил до 0.02

void vertex() {
    float height = VERTEX.y;
    float max_height = 2.0;
    float bend = (height / max_height) * wind_strength * 0.001;
    float angle = sin(TIME * wind_speed) * bend;
    VERTEX.x += angle * height;
}

void fragment() {
    vec4 tex_color = texture(albedo_texture, UV);
    ALBEDO = tex_color.rgb;
}