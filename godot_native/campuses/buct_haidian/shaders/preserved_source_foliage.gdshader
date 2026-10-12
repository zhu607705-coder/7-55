shader_type canvas_item;
uniform sampler2D foliage_mask : filter_nearest, repeat_disable;
uniform vec2 mask_origin = vec2(400.0,144.0);
uniform vec2 mask_size = vec2(480.0,368.0);
void fragment() {
    vec2 m = (UV/TEXTURE_PIXEL_SIZE-mask_origin)/mask_size;
    if (m.x < 0.0 || m.y < 0.0 || m.x >= 1.0 || m.y >= 1.0 || texture(foliage_mask,m).r < 0.5) { discard; }
    COLOR = texture(TEXTURE,UV);
}
