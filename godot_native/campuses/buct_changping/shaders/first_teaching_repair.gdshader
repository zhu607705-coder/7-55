shader_type canvas_item;
render_mode unshaded;
uniform sampler2D permission_mask : filter_nearest, repeat_disable;
uniform vec4 permission_world_rect;
uniform vec2 image_world_origin;
uniform vec2 raw_image_size;
uniform float image_world_scale;
void fragment() {
    vec2 point = image_world_origin + UV * raw_image_size * image_world_scale;
    vec2 mask_uv = (point - permission_world_rect.xy) / permission_world_rect.zw;
    if (mask_uv.x < 0.0 || mask_uv.y < 0.0 || mask_uv.x >= 1.0 || mask_uv.y >= 1.0) {discard;}
    if (texture(permission_mask,mask_uv).r < 0.5) {discard;}
    COLOR = vec4(texture(TEXTURE,UV).rgb,1.0);
}
