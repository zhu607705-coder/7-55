extends Node2D
## Generated image layers, independently registered in native scene space.
## Crops are runtime sampling only. Original RGBA files are never flattened.
const ROOT := "res://assets/objectized/chapter4/room201/"
const Evidence=preload("res://scripts/objects/room201_press_evidence.gd")
const ALPHA_CUTOFF := 4.0 / 255.0
var view:Control
var parts:Dictionary={}
var shader:Shader
var textures:Dictionary={}
var pick_images:Dictionary={}
var spring_coils:Array[Sprite2D]=[]
var shaft_segments:Array[Sprite2D]=[]
var built:=false
func _ready()->void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	shader=Shader.new()
	shader.code="""shader_type canvas_item;
uniform float alpha_cutoff = 0.0156862745;
uniform int clip_count = 0;
uniform vec2 clip_points[32];
varying vec4 item_tint;
void vertex(){item_tint = COLOR;}
void fragment(){
 vec4 sample_color = texture(TEXTURE, UV);
 if(sample_color.a < alpha_cutoff){discard;}
 if(clip_count > 2){
  vec2 p = UV * vec2(1536.0,1024.0);
  bool inside = false;
  int previous = clip_count - 1;
  for(int i=0; i<32; i++){
   if(i >= clip_count){break;}
   vec2 a = clip_points[i]; vec2 b = clip_points[previous];
   if((a.y > p.y) != (b.y > p.y)){
    if(p.x < (b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x){inside = !inside;}
   }
   previous = i;
  }
  if(!inside){discard;}
 }
 COLOR = sample_color * item_tint;
}"""
	_build();sync()
func _texture(file:String)->Texture2D:
	if not textures.has(file):textures[file]=load(ROOT+file)
	return textures[file]
func _sprite(id:String,file:String,region:Rect2,anchor:Vector2,z:int)->Sprite2D:
	var node:=Sprite2D.new();node.name=id;node.texture=_texture(file)
	node.centered=false;node.region_enabled=true;node.region_rect=region
	node.region_filter_clip_enabled=true;node.offset=region.position-anchor;node.z_index=z
	var material:=ShaderMaterial.new();material.shader=shader;material.set_shader_parameter("alpha_cutoff",ALPHA_CUTOFF);node.material=material
	add_child(node);parts[id]=node;return node
func _clip(id:String,points:PackedVector2Array)->void:
	var material:ShaderMaterial=parts[id].material
	material.set_shader_parameter("clip_count",points.size())
	var padded:PackedVector2Array=points.duplicate()
	padded.resize(32)
	material.set_shader_parameter("clip_points",padded)
func _build()->void:
	_sprite("StationaryWorkbench","stationary_workbench.png",Rect2(0,0,1536,1024),Vector2.ZERO,0)
	# Portrait preserves source pixel density by rearranging stationary crops.
	_sprite("PortraitBase","stationary_workbench.png",Rect2(225,170,660,701),Vector2(630,488),1)
	_sprite("PortraitRailEnd","stationary_workbench.png",Rect2(880,418,366,153),Vector2(880,488),2)
	_sprite("PortraitGantry","stationary_workbench.png",Rect2(891,52,205,613),Vector2(936,116),3)
	_clip("PortraitBase",PackedVector2Array([Vector2(570,177),Vector2(640,177),Vector2(654,193),Vector2(658,255),Vector2(850,255),Vector2(879,276),Vector2(883,826),Vector2(874,851),Vector2(364,859),Vector2(351,840),Vector2(354,560),Vector2(238,560),Vector2(226,550),Vector2(229,440),Vector2(242,423),Vector2(379,423),Vector2(383,279),Vector2(405,257),Vector2(554,257),Vector2(554,198)]))
	_clip("PortraitGantry",PackedVector2Array([Vector2(910,56),Vector2(955,56),Vector2(974,73),Vector2(974,288),Vector2(1073,390),Vector2(1074,422),Vector2(981,422),Vector2(982,665),Vector2(908,669),Vector2(895,653),Vector2(895,79)]))
	_clip("PortraitRailEnd",PackedVector2Array([Vector2(880,430),Vector2(909,420),Vector2(948,420),Vector2(969,442),Vector2(1198,428),Vector2(1210,422),Vector2(1246,422),Vector2(1246,570),Vector2(1194,570),Vector2(1194,526),Vector2(962,526),Vector2(962,564),Vector2(908,564),Vector2(908,526),Vector2(880,526)]))
	_sprite("Carriage","calibration_carriage.png",Rect2(447,336,323,287),Vector2(609,480),4)
	_sprite("TransparentClockSheet","transparent_clock_sheet.png",Rect2(510,376,239,205),Vector2(629,478),6)
	_sprite("PressureWheel","pressure_wheel.png",Rect2(865,225,486,497),Vector2(891,500),4)
	_sprite("HorizontalRailKnob","rail_knobs.png",Rect2(910,228,116,148),Vector2(979,300),5)
	_sprite("VerticalRailKnob","rail_knobs.png",Rect2(546,588,150,166),Vector2(621,690),5)
	# The up source is split into actual independent parts. The hinge does not
	# inherit generation drift from separately authored endpoint illustrations.
	_sprite("PressHousing","press_linkage_up.png",Rect2(668,19,221,215),Vector2(914,121),11)
	_sprite("PressLever","press_linkage_up.png",Rect2(889,34,592,267),Vector2(914,121),12)
	for i:int in 12:
		var shaft:=_sprite("RamShaft%02d"%i,"press_linkage_up.png",Rect2(745,81,43,54),Vector2(766.5,108),8)
		shaft_segments.append(shaft)
	for i:int in 4:
		var coil:=_sprite("SpringCoil%d"%i,"press_linkage_up.png",Rect2(714,239+i*20,121,22),Vector2(774.5,250+i*20),10)
		spring_coils.append(coil)
	_sprite("PressHead","press_linkage_up.png",Rect2(672,322,194,95),Vector2(769,371),10)
	var evidence:=Evidence.new();evidence.name="WearAndImprints";evidence.view=view;evidence.z_index=7;add_child(evidence)
	built=true
func _process(_delta:float)->void:sync()
func _pose(node:Sprite2D,point:Vector2,uniform_scale:float,angle:=0.0)->void:
	node.position=point;node.scale=Vector2.ONE*uniform_scale;node.rotation=angle
func sync()->void:
	if not built or view==null:return
	position=view.origin;scale=Vector2.ONE*view.fit
	var compact:bool=view.narrow
	parts.StationaryWorkbench.visible=not compact
	for id:String in ["PortraitBase","PortraitRailEnd","PortraitGantry"]:parts[id].visible=compact
	if compact:
		_pose(parts.PortraitBase,view.center,.90)
		_pose(parts.PortraitRailEnd,Vector2(575,view.center.y),.40)
		_pose(parts.PortraitGantry,view.lever_pivot,.90)
	var a:Vector3=view._visual_calibration()
	var carriage_scale:float=view.carriage_art_scale()
	_pose(parts.Carriage,view.carriage_center(),carriage_scale)
	var sheet:Vector2=view.carriage_center()
	if not view.checkpoint.inserted:
		sheet=view.loose_center
		if view.gesture=="plate":sheet+=(view.drag_current-view.drag_start)/maxf(.01,view.fit)
	elif view.motion=="insert":sheet=view.loose_center.lerp(sheet,smoothstep(0,.48,view.motion_time))
	if view.motion=="press" and view.motion_time>.51 and not view.reduced:
		var release:float=sin(clampf((view.motion_time-.51)/.58,0,1)*PI)
		sheet+=Vector2(4*sin((view.motion_time-.51)*48) if view.press_outcome=="bounce" else 0,-28*release)
	_pose(parts.TransparentClockSheet,sheet,view.sheet_art_scale())
	parts.TransparentClockSheet.visible=view.checkpoint.inserted or view.plate_available
	var wheel_angle:float=a.z*.045
	if view.gesture=="crank":wheel_angle+=wrapf(((view.drag_current-view.origin)/maxf(.01,view.fit)-view.wheel).angle()-view.crank_angle,-PI,PI)*.22
	var wheel_scale:float=.62 if compact else .80
	_pose(parts.PressureWheel,view.wheel-Vector2(217,-27)*wheel_scale,wheel_scale,wheel_angle)
	var handles:Array=view.rail_handles()
	_pose(parts.HorizontalRailKnob,handles[0].point,.92 if compact else .85)
	parts.HorizontalRailKnob.flip_h=not compact
	_pose(parts.VerticalRailKnob,handles[1].point,.92 if compact else .85)
	var housing_scale:float=.90 if compact else 1.0
	_pose(parts.PressHousing,view.lever_pivot,housing_scale)
	_pose(parts.PressLever,view.lever_pivot,view.lever_art_scale(),view._press_depth()*.79)
	var depth:float=view._press_depth()
	var head:Vector2=view.ram_center()
	var head_scale:float=1.50 if compact else 1.20
	var spring_scale:float=1.25 if compact else 1.05
	_pose(parts.PressHead,head,head_scale)
	var spacing:float=lerpf(20.0,7.0,depth)*(1-a.z*.025)*spring_scale
	for i:int in spring_coils.size():
		_pose(spring_coils[i],head-Vector2(0,(63+(3-i)*spacing/spring_scale)*spring_scale),spring_scale)
	var spring_top:Vector2=head-Vector2(0,63*spring_scale+spacing*3)
	var shaft_top:Vector2=view.lever_pivot+Vector2(-142,99)*housing_scale
	var direction:Vector2=spring_top-shaft_top
	for i:int in shaft_segments.size():
		var visible_segments:int=clampi(ceili(direction.length()/32)+1,2,shaft_segments.size())
		var fraction:float=float(i)/float(visible_segments-1)
		var at:Vector2=shaft_top.lerp(spring_top,fraction)
		_pose(shaft_segments[i],at,housing_scale,direction.angle()-PI/2)
		shaft_segments[i].visible=direction.length()>12 and i<visible_segments
	queue_redraw()
func pressure_wheel_contains(point_in_view:Vector2,padding_pixels:=4.0)->bool:
	if not built or view==null:return false
	# Match this frame's actual rendered pose, including accepted pressure steps.
	sync()
	var node:Sprite2D=parts.PressureWheel
	if not node.visible or node.texture==null:return false
	var pose:Transform2D=transform*node.transform
	var pixel_scale:float=minf(pose.x.length(),pose.y.length())
	if pixel_scale<=.000001:return false
	var texel:Vector2=pose.affine_inverse()*point_in_view-node.offset+node.region_rect.position
	# At most four screen pixels by default, and never more than32 source pixels.
	# The region is the measured alpha>=4 part, not the full1536px canvas.
	var padding:float=minf(clampf(padding_pixels,0,6)/pixel_scale,32)
	if not node.region_rect.grow(padding).has_point(texel):return false
	if not pick_images.has("PressureWheel"):pick_images.PressureWheel=node.texture.get_image()
	var pixels:Image=pick_images.PressureWheel
	if pixels==null:return false
	var bounds:Rect2i=Rect2i(node.region_rect).intersection(Rect2i(Vector2i.ZERO,pixels.get_size()))
	var sample:Vector2i=Vector2i(floori(texel.x),floori(texel.y))
	if bounds.has_point(sample) and pixels.get_pixelv(sample).a>=ALPHA_CUTOFF:return true
	var radius:int=ceili(padding)
	for y:int in range(maxi(bounds.position.y,sample.y-radius),mini(bounds.end.y,sample.y+radius+1)):
		for x:int in range(maxi(bounds.position.x,sample.x-radius),mini(bounds.end.x,sample.x+radius+1)):
			if texel.distance_squared_to(Vector2(x+.5,y+.5))<=padding*padding and pixels.get_pixel(x,y).a>=ALPHA_CUTOFF:return true
	return false
func _draw()->void:
	if view==null:return
	# Extend only the clear wood band; no movable part is baked into it.
	if view.narrow:
		var wood:Texture2D=_texture("stationary_workbench.png")
		for y:int in range(0,1320,72):draw_texture_rect_region(wood,Rect2(0,y,750,72),Rect2(350,885,750,72))
