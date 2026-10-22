shader_type canvas_item;
uniform float alpha_cutoff = 0.04;
uniform float solid_threshold = 0.95;
uniform bool selected = false;
void fragment() {
    vec4 c = texture(TEXTURE, UV);
    if (c.a < alpha_cutoff) { discard; }
    if (c.a >= solid_threshold) { c.a = 1.0; }
    if (selected) { c.rgb = mix(c.rgb, vec3(0.92, 0.80, 0.43), 0.07); }
    COLOR = c;
}
