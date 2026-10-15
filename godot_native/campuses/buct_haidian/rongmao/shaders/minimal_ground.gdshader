shader_type canvas_item;
uniform sampler2D permitted_mask : filter_nearest, repeat_disable;
uniform vec2 raw_world_origin;
uniform vec2 raw_world_size;
uniform vec2 mask_origin=vec2(510.0,430.0);
uniform vec2 mask_size=vec2(54.0,58.0);
void fragment() {
    vec2 p=raw_world_origin+UV*raw_world_size;
    vec2 m=(p-mask_origin)/mask_size;
    if(any(lessThan(m,vec2(0.0))) || any(greaterThanEqual(m,vec2(1.0))) || texture(permitted_mask,m).r<0.5) { discard; }
    COLOR=texture(TEXTURE,UV);
}
