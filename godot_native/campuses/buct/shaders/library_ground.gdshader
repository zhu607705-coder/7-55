shader_type canvas_item;
uniform sampler2D repair_coverage : filter_linear, repeat_disable;
void fragment() {
    vec4 c = texture(TEXTURE, UV);
    float coverage = texture(repair_coverage, UV).r;
    COLOR = vec4(c.rgb, c.a * coverage);
}
