shader_type canvas_item;
uniform sampler2D retirement_mask : filter_nearest, repeat_disable;
uniform vec2 source_size = vec2(1448.0,1086.0);
uniform vec2 mask_origin = vec2(458.0,265.0);
uniform vec2 mask_size = vec2(132.0,214.0);
void fragment() {
    vec2 p=UV*source_size;
    vec2 m=(p-mask_origin)/mask_size;
    if(any(lessThan(m,vec2(0.0))) || any(greaterThanEqual(m,vec2(1.0))) || texture(retirement_mask,m).r<0.5) { discard; }
    COLOR=texture(TEXTURE,UV);
}
