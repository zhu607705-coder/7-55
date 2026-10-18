shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D shoreline_distance : filter_linear, repeat_disable;
uniform float water_clock = 0.0;
uniform vec2 boat_position = vec2(0.0);
uniform vec2 boat_direction = vec2(0.0, -1.0);
uniform float boat_speed = 0.0;

varying vec2 lake_world;

// Stable lattice hash for sparse arc placement and smooth low-frequency fields.
vec3 ripple_cell_hash(vec2 cell) {
    vec3 h = fract(vec3(cell.x, cell.y, cell.x) * vec3(0.1031, 0.1030, 0.0973));
    h += dot(h, h.yzx + 33.33);
    return fract((h.xxy + h.yxx) * h.zyx);
}

// Two smooth, low-frequency fields only. No high-frequency noise octaves.
float lake_noise(vec2 position) {
    vec2 cell = floor(position);
    vec2 f = fract(position);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = ripple_cell_hash(cell).x;
    float b = ripple_cell_hash(cell + vec2(1.0, 0.0)).x;
    float c = ripple_cell_hash(cell + vec2(0.0, 1.0)).x;
    float d = ripple_cell_hash(cell + vec2(1.0, 1.0)).x;
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
    lake_world = UV;
    // Keep the existing tiny visual displacement; gameplay uses its own plane.
    VERTEX.y += 0.008 * sin(UV.x * 1.7 + water_clock * 0.85)
        * sin(UV.y * 1.1 - water_clock * 0.65);
}

void fragment() {
    vec2 p = lake_world;
    vec2 shore_uv = (p - vec2(-22.5, -21.25)) / vec2(50.0, 62.5);
    float edge = texture(shoreline_distance, shore_uv).r * 7.5;
    float valid = step(0.0, shore_uv.x) * step(0.0, shore_uv.y)
        * step(shore_uv.x, 1.0) * step(shore_uv.y, 1.0);
    // Distance is an art mask, not measured water depth. Fade at the map border.
    vec2 border = min(shore_uv, vec2(1.0) - shore_uv) * vec2(50.0, 62.5);
    float shore_coverage = valid * smoothstep(0.0, 0.5, min(border.x, border.y));
    float shallow = (1.0 - smoothstep(0.12, 4.6, edge)) * shore_coverage;
    float waterline = (1.0 - smoothstep(0.04, 0.65, edge)) * shore_coverage;

    // Broad, slow color motion. No diagonal repeating wave crests are drawn.
    float drift = sin(dot(p, vec2(0.27, 0.16)) - water_clock * 0.10);
    float cross_drift = sin(dot(p, vec2(-0.12, 0.31)) + water_clock * 0.075);
    float phase_a = dot(p, vec2(0.65, 1.12)) - water_clock * 0.13 + drift * 0.30;
    float phase_b = dot(p, vec2(-0.55, 0.78)) - water_clock * 0.10 + cross_drift * 0.30;
    float wave_a = sin(phase_a);
    float wave_b = sin(phase_b);

    // Modest domain warp avoids straight color contours and periodic ripples.
    vec2 warped = p + vec2(drift, cross_drift) * 0.65;
    float body_noise = lake_noise(warped * 0.30 + vec2(2.7, 5.1)
        + vec2(0.007, -0.009) * water_clock);
    float band_noise = lake_noise(warped * vec2(0.19, 0.72) + vec2(-3.8, 8.2)
        + vec2(-0.008, 0.012) * water_clock);
    float reflection_band = smoothstep(0.40, 0.73, band_noise)
        * smoothstep(0.25, 0.64, body_noise);

    // A warped, generously jittered layout: sparse arcs form occasional packets.
    float ripple_patch = smoothstep(0.55, 0.76, body_noise * 0.60 + band_noise * 0.40);
    vec2 ripple_p = p + vec2(drift * 0.60, cross_drift * 0.85)
        + vec2(body_noise - 0.5, band_noise - 0.5) * vec2(0.55, 0.90)
        - vec2(0.012, 0.024) * water_clock;
    vec2 cell_size = vec2(2.30, 1.15);
    vec2 cell = floor(ripple_p / cell_size);
    vec3 variation = ripple_cell_hash(cell);
    vec2 local = (fract(ripple_p / cell_size) - 0.5) * cell_size;
    local -= (variation.xy - 0.5) * vec2(0.90, 0.62);
    float half_length = 0.20 + variation.z * 0.43;
    float along = local.x / half_length;
    float arc_curve = (0.025 + variation.y * 0.045) * along * along;
    // Derivatives use continuous coordinates, never discontinuous cell edges.
    vec2 ripple_pixel = fwidth(ripple_p);
    float arc_aa = max(ripple_pixel.y + ripple_pixel.x
        * (0.05 + variation.y * 0.09) * abs(along) / half_length, 0.004);
    float arc_line = 1.0 - smoothstep(0.008, 0.008 + arc_aa, abs(local.y + arc_curve));
    float arc_ends = 1.0 - smoothstep(0.45, 1.0, abs(along));
    float cell_presence = smoothstep(0.28, 0.52, variation.z);
    // Only a minority have a shorter companion crest; spacing varies by cell.
    float second_offset = 0.11 + variation.x * 0.12;
    float second_line = 1.0 - smoothstep(0.007, 0.007 + arc_aa,
        abs(local.y + arc_curve - second_offset));
    float second_ends = 1.0 - smoothstep(0.30, 0.72, abs(along + 0.12));
    float paired = smoothstep(0.70, 0.95, variation.y);
    float fine_crest = (arc_line * arc_ends + second_line * second_ends * paired * 0.50)
        * cell_presence * ripple_patch;

    float body_tone = clamp(0.12 + body_noise * 0.72 + drift * 0.10 + cross_drift * 0.06, 0.0, 1.0);
    vec3 deep_color = mix(vec3(0.092, 0.238, 0.230), vec3(0.160, 0.310, 0.284), body_tone);
    // Quiet mineral/silt variation is most visible in the first few shore units.
    float bed_variation = body_noise * 0.65 + band_noise * 0.35;
    vec3 shallow_color = mix(vec3(0.222, 0.342, 0.282),
        vec3(0.286, 0.391, 0.309), bed_variation);
    vec3 col = mix(deep_color, shallow_color, shallow * 0.76);
    col = mix(col, vec3(0.163, 0.267, 0.220), waterline * 0.20);

    // Soft reflection approximation for the fixed orthographic presentation.
    // Camera-up factor is uniform; avoid per-pixel normal/matrix/reflection work.
    float grazing = 1.0 - clamp(abs(INV_VIEW_MATRIX[2].y), 0.0, 1.0);
    float fresnel = grazing * grazing;
    fresnel = fresnel * fresnel * grazing;
    float sky_patch = smoothstep(-0.65, 0.85,
        drift * 0.60 + cross_drift * 0.40 + wave_a * 0.04);
    vec3 reflected_color = mix(vec3(0.267, 0.371, 0.350),
        vec3(0.405, 0.499, 0.458), sky_patch);
    // Broken darker bank-color patches soften the transition near land.
    float bank_patch = smoothstep(0.32, 0.70, body_noise) * (0.35 + band_noise * 0.65);
    reflected_color = mix(reflected_color, vec3(0.155, 0.257, 0.211),
        shallow * bank_patch * 0.55);
    col = mix(col, reflected_color, 0.12 + fresnel * 0.38);
    // Broad connected sheen bands, broken up by the second smooth field.
    col = mix(col, vec3(0.280, 0.398, 0.363), reflection_band * 0.19);
    float green_reflection = (1.0 - smoothstep(0.35, 4.2, edge))
        * shore_coverage * bank_patch;
    col = mix(col, vec3(0.125, 0.255, 0.188), green_reflection * 0.18);

    // Artistic blue dock reflection only, in the same local world coordinates.
    // Game rectangle (5984,2712,224,84), origin (6000,2850), scale 40.
    // The original dock depth still occludes this opaque water underneath it.
    vec2 dock_reflection_p = p + vec2(wave_a * 0.07, wave_b * 0.045);
    vec2 dock_outside = max(abs(dock_reflection_p - vec2(1.95, -2.25))
        - vec2(2.80, 1.05), vec2(0.0));
    float dock_reflection = (1.0 - smoothstep(0.05, 0.85, length(dock_outside)))
        * (0.28 + 0.72 * smoothstep(0.28, 0.72, band_noise));
    col = mix(col, vec3(0.125, 0.332, 0.371), dock_reflection * 0.38);
    col += vec3(0.022, 0.028, 0.024) * fine_crest * (1.0 - waterline * 0.65);

    // Preserve the speed-linked boat wake and its existing envelope.
    vec2 d = p - boat_position;
    float behind = -dot(d, boat_direction);
    float across = abs(dot(d, vec2(-boat_direction.y, boat_direction.x)));
    float fade = clamp(boat_speed / 190.0, 0.0, 1.0)
        * smoothstep(0.35, 1.0, behind) * (1.0 - smoothstep(1.0, 5.3, behind));
    float wake_width = max(0.055, fwidth(across - behind * 0.23) * 0.75);
    float wake_offset = (across - behind * 0.23) / wake_width;
    float foam_offset = (across - 0.24) / 0.07;
    float wake = exp(-wake_offset * wake_offset) * fade;
    float foam = exp(-foam_offset * foam_offset) * exp(-abs(behind - 0.55) * 2.0) * fade;
    col = mix(col, vec3(0.43, 0.57, 0.48), clamp(wake * 0.30 + foam * 0.20, 0.0, 0.4));
    ALBEDO = col;
}
