shader_type canvas_item;
render_mode unshaded;
uniform sampler2D original_source : filter_nearest, repeat_disable;
uniform sampler2D body_ownership : filter_nearest, repeat_disable;
uniform sampler2D west_hd : filter_linear_mipmap, repeat_disable;
uniform sampler2D east_hd : filter_linear_mipmap, repeat_disable;
uniform vec2 original_size = vec2(950.0, 1656.0);
uniform vec4 source_rect = vec4(350.0,167.0,384.0,256.0);
uniform vec4 west_sample_rect = vec4(398.0,399.0,256.0,24.4);
uniform vec4 east_sample_rect = vec4(630.0,399.0,104.0,24.4);
uniform bool west_neighbor_active = false;
uniform bool east_neighbor_active = false;
uniform bool body_1_independent = false;
uniform bool body_2_independent = false;
uniform bool external_top_owner_active = false;
uniform vec4 external_top_owner_rect = vec4(0.0);
varying vec2 world_pixel;
bool inside_rect(vec2 p, vec4 rect) {
    return all(greaterThanEqual(p,rect.xy)) && all(lessThan(p,rect.xy+rect.zw));
}
void vertex() { world_pixel=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
    if (external_top_owner_active && inside_rect(world_pixel,external_top_owner_rect)) { discard; }
    vec2 p=world_pixel-source_rect.xy;
    vec2 uv=p/source_rect.zw;
    int owner=int(round(textureLod(body_ownership,uv,0.0).r*255.0));
    bool independent=(owner==1 && body_1_independent)||(owner==2 && body_2_independent);
    // Unaccepted bodies retain their exact original visual/underlay/physics.
    if (owner>0 && !independent) { discard; }
    float retirement=independent ? 1.0 : 0.0;
    bool west=west_neighbor_active && inside_rect(world_pixel,vec4(398.0,399.0,256.0,24.0));
    bool east=east_neighbor_active && inside_rect(world_pixel,vec4(630.0,399.0,104.0,24.0));
    bool shared=west||east;
    bool right_handoff=east && p.x>=source_rect.z-12.0;
    bool outer=p.x<2.0 || p.y<2.0 || (!right_handoff && p.x>=source_rect.z-2.0) || (!shared && p.y>=source_rect.w-2.0);
    if (outer && retirement<1.0) { discard; }
    vec3 own_detail=texture(TEXTURE,uv).rgb;
    vec3 detail=own_detail;
    float lower_horizontal_coverage=1.0;
    if (shared) {
        vec3 lower=own_detail;
        if (west) {
            lower=texture(west_hd,(world_pixel-west_sample_rect.xy)/west_sample_rect.zw).rgb;
            lower_horizontal_coverage=smoothstep(400.0,410.0,world_pixel.x);
            if (!east_neighbor_active) { lower_horizontal_coverage=min(lower_horizontal_coverage,smoothstep(2.0,12.0,654.0-world_pixel.x)); }
        }
        if (east) {
            vec3 east_detail=texture(east_hd,(world_pixel-east_sample_rect.xy)/east_sample_rect.zw).rgb;
            if (west) {
                // Reconstruct the accepted west/east composite once, then one
                // vertical mix. The triple overlap is never alpha-stacked.
                lower=mix(lower,east_detail,smoothstep(630.0,654.0,world_pixel.x));
                lower_horizontal_coverage=1.0;
            } else {
                lower=east_detail;
                lower_horizontal_coverage=smoothstep(632.0,642.0,world_pixel.x);
            }
        }
        detail=mix(own_detail,lower,smoothstep(399.0,423.0,world_pixel.y));
        // This right shoulder lies wholly outside the new core (x>=722).
        // Its limit agrees with the unchanged lower region outside x734.
        if (right_handoff) { detail=mix(detail,lower,smoothstep(722.0,734.0,world_pixel.x)); }
    }
    float distance_edge=min(p.x,p.y);
    if (!right_handoff) { distance_edge=min(distance_edge,source_rect.z-p.x); }
    if (!shared) { distance_edge=min(distance_edge,source_rect.w-p.y); }
    float coverage=max(smoothstep(2.0,12.0,distance_edge),retirement);
    if (shared) {
        // Source-only shoulder starts at the EXCLUSIVE core endpoint y411.
        // Thus the complete y399..411 core band remains pure new/lower HD.
        float shoulder=smoothstep(411.0,423.0,world_pixel.y);
        coverage=min(coverage,1.0-shoulder*(1.0-lower_horizontal_coverage));
        if (right_handoff) {
            float old_lower_coverage=min(lower_horizontal_coverage,smoothstep(401.0,411.0,world_pixel.y));
            coverage=min(coverage,1.0-smoothstep(722.0,734.0,world_pixel.x)*(1.0-old_lower_coverage));
        }
        coverage=max(coverage,retirement);
    }
    if (coverage>=1.0) { COLOR=vec4(detail,1.0); }
    else { COLOR=vec4(mix(texture(original_source,world_pixel/original_size).rgb,detail,coverage),1.0); }
}
