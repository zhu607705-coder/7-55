shader_type canvas_item;
render_mode unshaded;
uniform sampler2D source_ownership : filter_nearest, repeat_disable;
uniform vec4 source_rect = vec4(657.0,735.0,109.0,110.0);
uniform vec2 image_origin;
uniform vec2 raw_size;
uniform float world_scale;
uniform float inferred_shade = 0.75;
void fragment() {
    vec2 world = image_origin + UV * raw_size * world_scale;
    vec2 mask_uv = (world - source_rect.xy) / source_rect.zw;
    if (any(lessThan(mask_uv, vec2(0.0))) || any(greaterThanEqual(mask_uv, vec2(1.0)))) { discard; }
    if (texture(source_ownership, mask_uv).r < 0.5) { discard; }
    COLOR = vec4(texture(TEXTURE, UV).rgb * inferred_shade, 1.0);
}
