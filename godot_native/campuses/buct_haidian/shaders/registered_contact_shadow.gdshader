shader_type canvas_item;
uniform sampler2D contact_clip : filter_linear, repeat_disable;
uniform float shadow_opacity = 0.5;
void fragment() {
    vec4 c = texture(TEXTURE,UV);
    COLOR = vec4(c.rgb,c.a*texture(contact_clip,UV).r*shadow_opacity);
}
