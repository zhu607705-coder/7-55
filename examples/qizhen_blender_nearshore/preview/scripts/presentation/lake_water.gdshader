shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D shoreline_distance : filter_linear, repeat_disable;
uniform float water_clock = 0.0;
uniform vec2 boat_position = vec2(0.0);
uniform vec2 boat_direction = vec2(0.0, -1.0);
uniform float boat_speed = 0.0;
varying vec2 lake_world;
void vertex() {
 lake_world = UV;
 // Small vertex motion, separate from collision / navigation plane.
 VERTEX.y += 0.008 * sin(UV.x*1.7 + water_clock*.85) * sin(UV.y*1.1-water_clock*.65);
}
void fragment() {
 vec2 p=lake_world;
 vec2 shore_uv=(p-vec2(-22.5,-21.25))/vec2(50.,62.5);
 float edge=texture(shoreline_distance,shore_uv).r*7.5;
 float valid=step(0.,shore_uv.x)*step(0.,shore_uv.y)*step(shore_uv.x,1.)*step(shore_uv.y,1.);
 float shallow=(1.-smoothstep(.05,3.3,edge))*valid;
 float slow=sin(p.x*.21 + p.y*.12+water_clock*.13)*.5+.5;
 vec3 col=mix(vec3(.115,.265,.250),vec3(.140,.300,.275),slow);
 col=mix(col,vec3(.22,.345,.285),shallow*.58);
 float wav=sin(p.x*14.2+p.y*18.0+sin(p.x*2.5)*1.7+water_clock*.6);
 float lines=smoothstep(.94,.998,wav)*(.38+.62*sin(p.x*.9+p.y*.4)*sin(p.x*.9+p.y*.4));
 col+=vec3(.12,.17,.13)*lines*.22*max(0.0,sin(p.x*1.6+p.y*.6+water_clock*.2));
 float long_sheen=pow(max(0.0,sin(p.y*.67+sin(p.x*.13)*1.5-water_clock*.12)),24.0);
 
 vec2 d=p-boat_position;
 float behind=-dot(d,boat_direction);
 float across=abs(dot(d,vec2(-boat_direction.y,boat_direction.x)));
 float fade=clamp(boat_speed/190.0,0.,1.)*smoothstep(.35,1.0,behind)*(1.-smoothstep(1.,5.3,behind));
 float wake=exp(-pow((across-behind*.23)/.055,2.))*fade;
 float foam=exp(-pow((across-.24)/.07,2.))*exp(-abs(behind-.55)*2.)*fade;
 col=mix(col,vec3(.43,.57,.48),clamp(wake*.3+foam*.20,0.,.4));
 ALBEDO=col;
}
