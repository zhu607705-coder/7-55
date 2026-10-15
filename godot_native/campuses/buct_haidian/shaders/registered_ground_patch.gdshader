shader_type canvas_item;
uniform sampler2D repair_mask : filter_nearest, repeat_disable;
uniform vec2 mask_origin = vec2(400.0,144.0);
uniform vec2 mask_size = vec2(480.0,368.0);
uniform vec2 world_origin;
uniform vec2 world_size;
uniform vec2 clip_origin=vec2(-1000000.0);
uniform vec2 clip_size=vec2(2000000.0);
// Optional overlap-only seam blend between real generated ground textures.
// Left, top, right, bottom distances in world/source pixels; default is no blend.
uniform vec4 overlap_feather=vec4(0.0);
uniform float accepted_max_x = 100000.0;
void fragment() {
    vec2 p = world_origin + UV * world_size;
    vec2 m = (p-mask_origin)/mask_size;
    if (p.x<clip_origin.x || p.y<clip_origin.y || p.x>=clip_origin.x+clip_size.x || p.y>=clip_origin.y+clip_size.y) { discard; }
    if (p.x >= accepted_max_x || m.x < 0.0 || m.y < 0.0 || m.x >= 1.0 || m.y >= 1.0 || texture(repair_mask,m).r < 0.5) { discard; }
    float alpha_weight=1.0;
    if(overlap_feather.x>0.0) { alpha_weight*=smoothstep(0.0,overlap_feather.x,p.x-clip_origin.x); }
    if(overlap_feather.y>0.0) { alpha_weight*=smoothstep(0.0,overlap_feather.y,p.y-clip_origin.y); }
    if(overlap_feather.z>0.0) { alpha_weight*=smoothstep(0.0,overlap_feather.z,clip_origin.x+clip_size.x-p.x); }
    if(overlap_feather.w>0.0) { alpha_weight*=smoothstep(0.0,overlap_feather.w,clip_origin.y+clip_size.y-p.y); }
    vec4 source=texture(TEXTURE,UV);
    COLOR=vec4(source.rgb,source.a*alpha_weight);
}
