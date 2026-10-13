shader_type canvas_item;
render_mode unshaded;
uniform sampler2D foot_depth : filter_nearest, repeat_disable;
uniform sampler2D surface_ids : filter_nearest, repeat_disable;
uniform vec2 raw_size = vec2(1.0,1.0);
uniform int surface_count = 2;
uniform float world_scale = 1.0;
uniform float world_origin_y = 0.0;
uniform float depth_lower = -100000.0;
uniform float depth_upper = 100000.0;
uniform float alpha_cutoff = 0.04;
uniform float solid_threshold = 0.97;
uniform bool selected = false;
uniform bool rgb_mipmaps_alpha0 = true;
void fragment() {
    vec4 c = texture(TEXTURE, UV);
    if (rgb_mipmaps_alpha0) { c.a = textureLod(TEXTURE, UV, 0.0).a; }
    if (c.a < alpha_cutoff) { discard; }
    ivec2 pixel = clamp(ivec2(floor(UV * raw_size)), ivec2(0), ivec2(raw_size) - ivec2(1));
    int face = int(round(texelFetch(surface_ids, pixel, 0).r * 255.0));
    if (face < 1 || face > surface_count) { discard; }
    float foot = texelFetch(foot_depth, ivec2(pixel.x,face - 1), 0).r * world_scale + world_origin_y;
    // One unique face and disjoint intervals: no doubled alpha at a split.
    if (foot <= depth_lower || foot > depth_upper) { discard; }
    if (c.a >= solid_threshold) { c.a = 1.0; }
    if (selected) { c.rgb = mix(c.rgb, vec3(0.92,0.80,0.43),0.07); }
    COLOR = c;
}
