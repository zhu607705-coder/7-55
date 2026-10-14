shader_type canvas_item;
render_mode unshaded;
uniform sampler2D original_source : filter_nearest, repeat_disable;
uniform sampler2D body_ownership : filter_nearest, repeat_disable;
uniform sampler2D east_hd : filter_linear_mipmap, repeat_disable;
uniform vec2 original_size = vec2(950.0,1656.0);
uniform bool east_neighbor_active = false;
uniform bool body_2_independent = false;
varying vec2 world_pixel;
void vertex() { world_pixel=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
    vec2 p=world_pixel-vec2(118.0,167.0);
    vec2 uv=p/vec2(256.0);
    // Full conservative original source envelopes, never old polygon-only alpha.
    int owner=int(round(textureLod(body_ownership,uv,0.0).r*255.0));
    if (owner>0 && !(owner==2 && body_2_independent)) { discard; }
    bool shared=east_neighbor_active && world_pixel.x>=350.0 && world_pixel.x<374.0;
    bool outer=p.x<2.0 || p.y<2.0 || p.y>=254.0 || (!shared && p.x>=254.0);
    if (outer) { discard; }
    vec3 detail=texture(TEXTURE,uv).rgb;
    if (shared) {
        vec3 east=texture(east_hd,(world_pixel-vec2(350.0,167.0))/vec2(24.0,256.0)).rgb;
        detail=mix(detail,east,smoothstep(350.0,374.0,world_pixel.x));
    }
    float distance_edge=min(p.x,min(p.y,256.0-p.y));
    if (!shared) { distance_edge=min(distance_edge,256.0-p.x); }
    // Vertical source-only shoulders are outside both y179..411 cores and agree
    // with unchanged north_large at the x374 endpoint. Active core stays pure HD.
    float coverage=smoothstep(2.0,12.0,distance_edge);
    if (coverage>=1.0) { COLOR=vec4(detail,1.0); }
    else { COLOR=vec4(mix(texture(original_source,world_pixel/original_size).rgb,detail,coverage),1.0); }
}
