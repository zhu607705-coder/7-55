shader_type canvas_item;
render_mode unshaded;
// Coefficients are covered by test_theater_lens; keep in sync with CPU picking.
void fragment() {
	vec2 p=UV*2.0-1.0;
	vec2 q=vec2(p.x+0.08*sin(6.28318530718*p.x)-0.16*sin(3.14159265359*p.x)+0.06*sin(3.14159265359*p.y)*p.x*p.x,
		p.y+0.16*sin(3.14159265359*p.x)*(0.45+0.55*p.y*p.y)+0.08*sin(6.28318530718*p.x)*p.y);
	vec2 uv=q*0.5+0.5;
	vec4 tex=texture(TEXTURE,uv);
	if(uv.x<0.0 || uv.x>1.0 || uv.y<0.0 || uv.y>1.0) tex=vec4(0.027,0.029,0.055,1.0);
	COLOR=tex;
}
