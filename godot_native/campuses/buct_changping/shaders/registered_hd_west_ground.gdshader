shader_type canvas_item;
render_mode unshaded;

uniform sampler2D original_source : filter_nearest, repeat_disable;
uniform sampler2D body_ownership : filter_nearest, repeat_disable;
uniform sampler2D water_complement : filter_nearest, repeat_disable;
uniform sampler2D east_hd : filter_linear_mipmap, repeat_disable;
uniform sampler2D south_hd : filter_linear_mipmap, repeat_disable;
uniform sampler2D southeast_hd : filter_linear_mipmap, repeat_disable;
uniform vec2 original_size = vec2(950.0, 1656.0);
uniform vec4 source_rect;
uniform vec4 east_sample_rect;
uniform vec4 south_sample_rect;
uniform vec4 southeast_sample_rect;
uniform vec4 south_rect;
uniform vec4 north_rect;
uniform vec4 corner_rect;
uniform bool east_neighbor_active = false;
uniform bool south_neighbor_active = false;
uniform bool north_owner_active = false;
uniform bool southeast_neighbor_active = false;
uniform bool water_complement_active = false;
uniform bool external_top_owner_active = false;
uniform vec4 external_top_owner_rect;
varying vec2 world_pixel;

bool inside_rect(vec2 point, vec4 rect) {
    return all(greaterThanEqual(point, rect.xy)) && all(lessThan(point, rect.xy + rect.zw));
}

void vertex() {
    world_pixel = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    if (external_top_owner_active && inside_rect(world_pixel, external_top_owner_rect)) { discard; }
    vec2 p = world_pixel - source_rect.xy;
    vec2 uv = p / source_rect.zw;
    // NW is the sole horizontal/corner owner. SW never alpha-composites there.
    if (north_owner_active && inside_rect(world_pixel, north_rect)) { discard; }
    // Exactly the original binary water alpha yields to the existing lake node.
    // RGB is sampled at continuous 5x coordinates; no pixel-cell alpha geometry.
    if (water_complement_active && textureLod(water_complement, uv, 0.0).r > 0.5) { discard; }

    bool south_shared = south_neighbor_active && inside_rect(world_pixel, south_rect);
    bool corner = south_shared && inside_rect(world_pixel, corner_rect);
    // Missing neighbors retain their own source fallback. Do not borrow a strip
    // merely because another neighbor is active on the other side of the corner.
    bool east_shared = (east_neighbor_active || (corner && southeast_neighbor_active)) && p.x >= source_rect.z - 24.0;

    // Retirement is evaluated BEFORE the ordinary two-source-pixel discard.
    // This preserves the teaching shadow's real x398 edge in the wider collar.
    float retirement = textureLod(body_ownership, uv, 0.0).r;
    bool outer_collar = p.x < 2.0 || p.y < 2.0;
    outer_collar = outer_collar || (!east_shared && p.x >= source_rect.z - 2.0);
    outer_collar = outer_collar || (!south_shared && p.y >= source_rect.w - 2.0);
    if (outer_collar && retirement < 1.0) { discard; }

    vec3 own_detail = texture(TEXTURE, uv).rgb;
    vec3 detail = own_detail;
    float u = smoothstep(source_rect.x + source_rect.z - 24.0, source_rect.x + source_rect.z, world_pixel.x);
    float v = smoothstep(south_rect.y, south_rect.y + max(south_rect.w, 1.0), world_pixel.y);
    if (corner) {
        vec3 sw = texture(south_hd, (world_pixel - south_sample_rect.xy) / south_sample_rect.zw).rgb;
        vec3 ne = own_detail;
        vec3 se = sw;
        if (east_neighbor_active) { ne = texture(east_hd, (world_pixel - east_sample_rect.xy) / east_sample_rect.zw).rgb; }
        if (southeast_neighbor_active) { se = texture(southeast_hd, (world_pixel - southeast_sample_rect.xy) / southeast_sample_rect.zw).rgb; }
        // Fixed NW owner; four TRUE unfeathered inputs, one separable RGB sum.
        detail = (1.0-u)*(1.0-v)*own_detail + u*(1.0-v)*ne + (1.0-u)*v*sw + u*v*se;
    } else if (south_shared) {
        detail = mix(own_detail, texture(south_hd, (world_pixel - south_sample_rect.xy) / south_sample_rect.zw).rgb, v);
    } else if (east_shared) {
        detail = mix(own_detail, texture(east_hd, (world_pixel - east_sample_rect.xy) / east_sample_rect.zw).rgb, u);
    }

    float distance_edge = min(p.x, p.y);
    if (!east_shared) { distance_edge = min(distance_edge, source_rect.z - p.x); }
    if (!south_shared) { distance_edge = min(distance_edge, source_rect.w - p.y); }
    float coverage = max(smoothstep(2.0, 12.0, distance_edge), retirement);
    if (corner && (!east_neighbor_active || !southeast_neighbor_active)) {
        float east_fallback = smoothstep(2.0, 12.0, source_rect.z - p.x);
        float north_coverage = east_neighbor_active ? 1.0 : east_fallback;
        float south_coverage = southeast_neighbor_active ? 1.0 : east_fallback;
        coverage = max(retirement, min(coverage, mix(north_coverage, south_coverage, v)));
    }
    // At coverage 1 there is no source fetch or mix(source, detail, 1) rounding.
    if (coverage >= 1.0) {
        COLOR = vec4(detail, 1.0);
    } else {
        vec3 source = texture(original_source, world_pixel / original_size).rgb;
        COLOR = vec4(mix(source, detail, coverage), 1.0);
    }
}
