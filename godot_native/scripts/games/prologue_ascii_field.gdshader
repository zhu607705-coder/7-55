shader_type canvas_item;
render_mode unshaded;
// The one marked field draw uses a dense advected ASCII atlas. Every other
// draw command (story text, buttons, windows) retains normal canvas rendering.
uniform sampler2D glyph_atlas : filter_nearest, repeat_disable;
uniform sampler2D fine_glyph_atlas : filter_nearest, repeat_disable;
uniform sampler2D hanzi_masks : filter_nearest, repeat_disable;
uniform float mask_count = 66.0;
uniform vec2 flow_cell = vec2(4.0,6.0);
uniform float assembly_duration = .28;
uniform float assembly_distance = 90.0;
uniform vec2 stroke_cell = vec2(3.0,4.0);
uniform float field_occupancy = .95;
uniform float word_cell_size = 4.0;
uniform float letter_gap = 5.0;
uniform float flow_clock = 0.0;
uniform bool reduced_motion = false;
uniform vec4 field_rect = vec4(0.0,0.0,430.0,820.0);
uniform vec4 word_data[32]; // two real bodies, six clue pieces, twenty-four ambient pieces
uniform vec4 word_symbols[32]; // first/second mask index, cos/sin rotation
uniform vec4 word_style[32]; // local time, uniform layout scale
uniform vec2 word_more[32]; // third/fourth mask index
varying vec4 draw_tag;

float hash_cell(vec2 cell) {
	return fract(sin(dot(cell,vec2(127.1,311.7)))*43758.5453);
}

float ascii_ink(vec2 p,vec2 cell_size,vec2 velocity,float seed,float occupancy,bool fine) {
	vec2 transported=p-flow_clock*velocity;
	vec2 cell=floor(transported/cell_size);
	float key=hash_cell(cell+vec2(seed,seed*1.7));
	if(key>occupancy) return 0.0;
	float symbol=fine ? 6.0+floor(fract(key*17.73)*4.0) : floor(fract(key*17.73)*12.0);
	vec2 within=fract(transported/cell_size);
	vec2 atlas_uv=vec2((symbol+within.x)/12.0,within.y);
	return fine ? texture(fine_glyph_atlas,atlas_uv).a : texture(glyph_atlas,atlas_uv).a;
}

float stroke_mask(vec2 local,int index) {
	float count=word_data[index].z;
	float side=20.0*word_cell_size;
	float width=count*side+max(0.0,count-1.0)*letter_gap;
	vec2 p=local+vec2(width*.5,side*.5);
	if(p.x<0.0 || p.y<0.0 || p.x>=width || p.y>=side) return 0.0;
	float letter=floor(p.x/(side+letter_gap));
	float x=mod(p.x,side+letter_gap);
	if(x>=side) return 0.0;
	float mask_index=letter<.5 ? word_symbols[index].x : letter<1.5 ? word_symbols[index].y : letter<2.5 ? word_more[index].x : word_more[index].y;
	vec2 cell=floor(vec2(x,p.y)/word_cell_size);
	return texture(hanzi_masks,vec2((cell.x+.5)/20.0,(mask_index*20.0+cell.y+.5)/(20.0*mask_count))).r;
}

vec4 terminal_field(vec2 p) {
	vec3 background=vec3(7.0,11.0,16.0)/255.0;
	vec3 accent=vec3(154.0,217.0,239.0)/255.0;
	float column=floor(p.x/flow_cell.x);
	float speed=reduced_motion ? 0.0 : 650.0+mod(column*7.0,9.0)*43.0;
	// Edge-fed streams cross smaller, stable patches of diagonal traffic.
	vec2 from_center=(p-vec2(215.0,410.0))/vec2(215.0,320.0);
	vec2 direction=abs(from_center.x)>abs(from_center.y) ? vec2(-sign(from_center.x),0.0) : vec2(0.0,-sign(from_center.y));
	vec2 velocity=direction*speed;
	float background_ink=ascii_ink(p,flow_cell,velocity,3.0,field_occupancy,false);
	float row_shade=.15+.1*hash_cell(floor((p-flow_clock*velocity)/flow_cell));
	vec3 color=mix(background,accent,background_ink*row_shade);
	vec2 patch=floor(p/vec2(72.0,108.0));
	float branch=hash_cell(patch+vec2(43.0,9.0));
	vec2 crossing=vec2(branch<.5 ? 1.0 : -1.0,.45+branch);
	vec2 drift=reduced_motion ? vec2(0.0) : crossing*(420.0+branch*230.0);
	float crossing_ink=ascii_ink(p+vec2(17.0,29.0),flow_cell,drift,11.0,.83,false);
	color=mix(color,accent,crossing_ink*(.055+.04*branch));
	bool in_physical_word=false;
	for(int i=0;i<32;i++) {
		if(word_data[i].z<.5 || word_data[i].w<=0.0) continue;
		vec2 delta=p-word_data[i].xy;
		float c=word_symbols[i].z;
		float s=word_symbols[i].w;
		vec2 local=vec2(delta.x*c+delta.y*s,-delta.x*s+delta.y*c)/max(.01,word_style[i].y);
		float half_width=(word_data[i].z*20.0*word_cell_size+max(0.0,word_data[i].z-1.0)*letter_gap)*.5;
		if(i<2 && abs(local.x)<half_width+3.0 && abs(local.y)<10.0*word_cell_size+3.0) in_physical_word=true;
		if(i>=2 && in_physical_word) continue;
		// Stable micro-glyphs travel from four sides into their own stroke cells.
		// Assembly finishes before the first possible physical target contact.
		float travel=reduced_motion ? 0.0 : assembly_distance*(1.0-smoothstep(0.0,assembly_duration,word_style[i].x));
		if(abs(local.x)>half_width+travel || abs(local.y)>10.0*word_cell_size+travel) continue;
		for(int side_index=0;side_index<4;side_index++) {
			vec2 incoming=side_index==0 ? vec2(0.0,-1.0) : side_index==1 ? vec2(1.0,0.0) : side_index==2 ? vec2(0.0,1.0) : vec2(-1.0,0.0);
			vec2 destination=local-incoming*travel;
			vec2 cell=floor(destination/stroke_cell);
			if(int(floor(hash_cell(cell+vec2(17.0,31.0))*4.0))!=side_index) continue;
			if(stroke_mask(destination,i)<.5) continue;
			float ink=ascii_ink(destination,stroke_cell,vec2(0.0),3.0,1.0,true);
			float strength=word_data[i].w*(.88+.12*hash_cell(cell));
			color=mix(color,vec3(219.0,237.0,244.0)/255.0,ink*strength);
		}

	}
	return vec4(color,1.0);
}

void vertex() { draw_tag=COLOR; }
void fragment() {
	if(draw_tag.r>.99 && draw_tag.g<.01 && draw_tag.b>.99) {
		COLOR=terminal_field(field_rect.xy+UV*field_rect.zw);
	}
}
