shader_type canvas_item;
// Preserve the web master; apply alpha cleanup and the locked base-art palette
// only at the native rendering boundary, before authored time/mode modulation.
uniform float alpha_cutoff : hint_range(0.0,1.0)=0.031372549;
uniform vec4 shared_palette[32];
uniform bool wood_material=false;
uniform bool green_material=false;
varying vec4 object_tint;
void vertex() {
	object_tint = COLOR;
}
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	if (source.a <= alpha_cutoff || source.a < 0.5) discard;
	vec3 nearest = shared_palette[0].rgb;
	float best = 1000.0;
	bool green_pixel = green_material && source.g>source.r*1.12 && source.g>source.b*1.05;
	for (int i=0; i<32; i++) {
		if (green_pixel && (i<20 || i>23)) continue;
		if (!green_pixel && (wood_material || green_material) && i!=0 && i!=1 && (i<8 || i>11)) continue;
		vec3 delta = source.rgb-shared_palette[i].rgb;
		float distance_squared = dot(delta,delta);
		if (distance_squared < best) {
			nearest = shared_palette[i].rgb;
			best = distance_squared;
		}
	}
	COLOR = vec4(nearest,1.0)*object_tint;
}
