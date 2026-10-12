shader_type canvas_item;
render_mode unshaded;
uniform sampler2D foot_depth : filter_nearest, repeat_disable;
uniform float raw_width = 1115.0;
uniform float world_scale = 1.0;
uniform float world_origin_y = 0.0;
uniform float depth_lower = -100000.0;
uniform float depth_upper = 100000.0;
uniform float alpha_cutoff = 0.05;
uniform float solid_threshold = 0.95;
uniform bool selected = false;
uniform bool rgb_mipmaps_alpha0 = true;
void fragment() {
    vec4 c = texture(TEXTURE, UV);
    if (rgb_mipmaps_alpha0) { c.a = textureLod(TEXTURE, UV, 0.0).a; }
    if (c.a < alpha_cutoff) { discard; }
    int column = clamp(int(floor(UV.x * raw_width)), 0, int(raw_width) - 1);
    float foot = texelFetch(foot_depth, ivec2(column, 0), 0).r * world_scale + world_origin_y;
    // Mutually exclusive (lower, upper] ranges; equal actor feet stay in the back pass.
    if (foot <= depth_lower || foot > depth_upper) { discard; }
    if (c.a >= solid_threshold) { c.a = 1.0; }
    if (selected) { c.rgb = mix(c.rgb, vec3(0.92, 0.80, 0.43), 0.07); }
    COLOR = c;
}
