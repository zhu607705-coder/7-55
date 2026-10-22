shader_type canvas_item;
render_mode unshaded;
uniform sampler2D foot_depth : filter_nearest, repeat_disable;
uniform vec2 body_origin;
uniform vec2 shadow_origin;
uniform vec2 shadow_raw_size = vec2(1115.0,1411.0);
uniform float world_scale = 0.1757847534;
uniform float raw_body_width = 1115.0;
uniform float raw_left = 358.0;
uniform float raw_right = 1055.0;
uniform float allowed_inside = 0.35;
uniform float allowed_outside = 1.75;
uniform float opacity = 0.55;
void fragment() {
    vec4 c = texture(TEXTURE,UV);
    if(c.a < 0.03) { discard; }
    vec2 p = (shadow_origin + UV*shadow_raw_size*world_scale - body_origin)/world_scale;
    if(p.x<raw_left || p.x>raw_right) { discard; }
    int x = clamp(int(floor(p.x)),0,int(raw_body_width)-1);
    int l = max(int(raw_left),x-6);
    int r = min(int(raw_right),x+6);
    float foot = texelFetch(foot_depth,ivec2(x,0),0).r;
    float gradient = (texelFetch(foot_depth,ivec2(r,0),0).r-texelFetch(foot_depth,ivec2(l,0),0).r)/float(max(1,r-l));
    float signed_distance = (p.y-foot)*world_scale/sqrt(1.0+gradient*gradient);
    if(signed_distance < -allowed_inside || signed_distance > allowed_outside) { discard; }
    COLOR = vec4(c.rgb,c.a*opacity);
}
