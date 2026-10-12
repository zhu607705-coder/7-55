shader_type canvas_item;
uniform sampler2D depth_profile : filter_nearest, repeat_disable;
uniform float actor_foot_y = 10000.0;
uniform float body_height = 160.0;
uniform bool foreground_pass = false;
uniform float alpha_cutoff = 0.04;
uniform float solid_threshold = 0.95;
uniform bool selected = false;
void fragment() {
    vec4 c = texture(TEXTURE, UV);
    if (c.a < alpha_cutoff) { discard; }
    if (c.a >= solid_threshold) { c.a = 1.0; }
    vec2 depth_bytes = texture(depth_profile, vec2(UV.x, 0.5)).rg;
    float baseline = (depth_bytes.r * 65280.0 + depth_bytes.g * 255.0) / 65535.0 * body_height;
    bool is_front = actor_foot_y < baseline;
    if (foreground_pass != is_front) { discard; }
    if (selected) { c.rgb = mix(c.rgb, vec3(0.92, 0.80, 0.43), 0.07); }
    COLOR = c;
}
