shader_type canvas_item;
render_mode unshaded;
uniform sampler2D region_rgb : filter_linear_mipmap, repeat_disable;
uniform vec4 source_rect;
varying vec2 world_pixel;
void vertex(){world_pixel=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
    float alpha=textureLod(TEXTURE,UV,0.0).r;
    if(alpha<0.04){discard;}
    COLOR=vec4(texture(region_rgb,(world_pixel-source_rect.xy)/source_rect.zw).rgb,alpha);
}
