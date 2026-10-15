shader_type canvas_item;
render_mode unshaded;
// Original PNGs are immutable. CSS brightness/contrast/saturation and screen
// compositing are applied here, after the native projected starfield.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D dark_tex : source_color, repeat_disable, filter_linear;
uniform sampler2D outline_tex : source_color, repeat_disable, filter_linear;
uniform sampler2D glow_tex : source_color, repeat_disable, filter_linear;
uniform sampler2D core_tex : source_color, repeat_disable, filter_linear;
uniform sampler2D leds_tex : source_color, repeat_disable, filter_linear;
uniform vec4 art_rect = vec4(0.0,0.0,1.0,1.0);
uniform vec2 viewport_pixels = vec2(960.0,540.0);
uniform int stage_id = 0; // questions, playback, final
uniform vec4 levels = vec4(0.0); // LEDs, core, glow, scene reveal
vec4 sample_layer(sampler2D tex,vec2 uv) {
	if(any(lessThan(uv,vec2(0.0))) || any(greaterThan(uv,vec2(1.0)))) return vec4(0.0);
	return texture(tex,uv);
}
vec3 filtered(vec3 rgb,float brightness,float contrast,float saturation) {
	vec3 c=(rgb*brightness-vec3(0.5))*contrast+vec3(0.5);
	return clamp(mix(vec3(dot(c,vec3(0.2126,0.7152,0.0722))),c,saturation),vec3(0.0),vec3(1.0));
}
vec3 over(vec3 dst,vec4 src,float opacity) {return mix(dst,src.rgb,src.a*opacity);}
vec3 screen_over(vec3 dst,vec4 src,float opacity) {return mix(dst,vec3(1.0)-(vec3(1.0)-dst)*(vec3(1.0)-src.rgb),src.a*opacity);}
vec4 soft_glow(vec2 uv,float radius) {
	// Bounded Gaussian kernel in CSS/display pixels; no rewritten lamp artwork.
	vec4 result=vec4(0.0);float weight=0.0;
	for(int y=-2;y<=2;y++) {
		for(int x=-2;x<=2;x++) {
			float w=exp(-float(x*x+y*y)*0.5);
			result+=sample_layer(glow_tex,uv+vec2(float(x),float(y))*radius/(art_rect.zw*viewport_pixels))*w;weight+=w;
		}
	}
	return result/weight;
}
void fragment() {
	vec3 bg=stage_id==1 ? texture(screen_texture,SCREEN_UV).rgb : vec3(0.0);
	vec2 uv=(UV-art_rect.xy)/art_rect.zw;
	vec4 dark=sample_layer(dark_tex,uv);
	if(stage_id==0) {
		dark.rgb=filtered(dark.rgb,0.16,1.18,1.0);bg=over(bg,dark,0.48);
	} else {
		bool final_frame=stage_id==2;
		dark.rgb=filtered(dark.rgb,final_frame ? 0.62 : 0.56,final_frame ? 1.06 : 1.1,final_frame ? 1.0 : 0.78);bg=over(bg,dark,1.0);
		vec4 outline=sample_layer(outline_tex,uv);outline.rgb=filtered(outline.rgb,final_frame ? 1.08 : 0.72,final_frame ? 1.08 : 1.18,final_frame ? 1.0 : 0.72);bg=screen_over(bg,outline,final_frame ? 0.9 : 0.44);
		vec2 glow_uv=final_frame ? (uv-vec2(0.5,0.295))/1.13+vec2(0.5,0.295) : uv;
		vec4 glow=soft_glow(glow_uv,final_frame ? 7.0 : 6.0);glow.rgb=filtered(glow.rgb,final_frame ? 1.2 : 0.9,1.0,1.0);bg=screen_over(bg,glow,final_frame ? 0.88 : levels.z);
		vec4 core=sample_layer(core_tex,uv);core.rgb=filtered(core.rgb,final_frame ? 1.15 : 0.96,1.0,1.0);bg=screen_over(bg,core,final_frame ? 1.0 : levels.y);
		vec4 leds=sample_layer(leds_tex,uv);leds.rgb=filtered(leds.rgb,final_frame ? 1.15 : 0.94,1.0,1.0);bg=screen_over(bg,leds,final_frame ? 1.0 : levels.x);
		float flare_scale=final_frame ? 1.28 : 0.72+levels.z;
		float flare_r=length((UV-(art_rect.xy+art_rect.zw*vec2(0.5,0.295)))*viewport_pixels)/(art_rect.z*viewport_pixels.x*0.11*flare_scale);
		float flare_a=(1.0-smoothstep(0.0,0.68,flare_r))*(final_frame ? 0.58 : levels.z)*0.52;
		bg=screen_over(bg,vec4(1.0,0.94,0.75,flare_a),1.0);
	}
	float radial=length((UV-vec2(0.5,stage_id==0 ? 0.32 : 0.38))/vec2(0.71,0.88));
	float vignette=radial<0.58 ? smoothstep(0.2,0.58,radial)*0.24 : mix(0.24,0.92,smoothstep(0.58,1.0,radial));
	if(stage_id==0)vignette=mix(0.14,0.94,smoothstep(0.0,0.78,radial));
	else if(stage_id==2)vignette=radial<0.56 ? smoothstep(0.18,0.56,radial)*0.30 : mix(0.30,0.94,smoothstep(0.56,1.0,radial));
	bg*=1.0-vignette;
	if(stage_id==1)bg*=levels.w;
	COLOR=vec4(bg,1.0);
}
