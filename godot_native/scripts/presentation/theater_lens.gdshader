shader_type canvas_item;
render_mode unshaded;
// Coefficients are covered by test_theater_lens; keep in sync with CPU picking.
void fragment() {
	vec2 p=UV*2.0-1.0;
	vec2 q=vec2(p.x*(1.0+0.075*p.y*p.y)+0.026*p.y*p.y+0.014*p.x*p.x,
		p.y+0.16*p.x*p.x*(0.34+p.y)+0.033*p.x*p.x*p.x);
	vec2 uv=q*0.5+0.5;
	vec4 tex=texture(TEXTURE,uv);
	if(uv.x<0.0 || uv.x>1.0 || uv.y<0.0 || uv.y>1.0) tex=vec4(0.027,0.029,0.055,1.0);
	COLOR=tex;
}
