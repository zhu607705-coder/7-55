shader_type canvas_item;
render_mode unshaded;
uniform sampler2D original_source : filter_nearest, repeat_disable;
uniform sampler2D body_ownership : filter_linear, repeat_disable;
uniform sampler2D shared_hd_strip : filter_linear_mipmap, repeat_disable;
uniform vec2 original_size = vec2(950.0,1656.0);
uniform vec4 source_rect = vec4(630.0,399.0,240.0,240.0);
uniform vec4 shared_rect = vec4(630.0,615.0,240.0,24.0);
uniform bool shared_neighbor_active = false;
uniform bool external_top_owner_active = false;
uniform vec4 external_top_owner_rect;
varying vec2 world_pixel;
void vertex() { world_pixel = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
    if (external_top_owner_active && all(greaterThanEqual(world_pixel, external_top_owner_rect.xy)) && all(lessThan(world_pixel, external_top_owner_rect.xy + external_top_owner_rect.zw))) { discard; }
    vec2 p = world_pixel - source_rect.xy;
    bool shared = shared_neighbor_active && world_pixel.y >= shared_rect.y;
    if (p.x < 2.0 || p.x >= source_rect.z-2.0 || p.y < 2.0 || (!shared && p.y >= source_rect.w-2.0)) { discard; }
    vec2 uv = p/source_rect.zw;
    vec3 detail = texture(TEXTURE,uv).rgb;
    // The strip is unfeathered registered original HD, never the legacy rim RGB.
    if (shared) {
        vec2 suv = (world_pixel-shared_rect.xy)/(vec2(textureSize(shared_hd_strip,0))*0.2);
        float t = smoothstep(0.0,1.0,(world_pixel.y-shared_rect.y)/shared_rect.w);
        detail = mix(detail,texture(shared_hd_strip,suv).rgb,t);
    }
    float distance_edge = min(min(p.x,source_rect.z-p.x),p.y);
    if (!shared) { distance_edge = min(distance_edge,source_rect.w-p.y); }
    float coverage = smoothstep(2.0,12.0,distance_edge);
    // Old body pixels have explicit ground ownership even near an outer rim.
    coverage = max(coverage,texture(body_ownership,uv).r);
    vec3 source = texture(original_source,world_pixel/original_size).rgb;
    // Exactly one opaque owner. The outer transition is a source-space RGB mix,
    // not two independently translucent quads leaving low-res residue in a seam.
    // Avoid mix(a,b,1) cancellation rounding: full HD ownership has no source dependency.
    COLOR = vec4(coverage >= 1.0 ? detail : mix(source,detail,coverage),1.0);
}
