extends Node
## Disposable display binding. The controller-owned session survives this node.
const Opening=preload("res://scripts/ui/native_opening_presentation.gd")
var session: RefCounted
var surface: Control
var art_scale:=1.0
var kind: String=""
var message: Control
var burst: Control
var laugh: Control
var digits: Array=[]
var skip: Button
var dots: Array=[]
var group: CanvasGroup
var material: ShaderMaterial
const CRASH_SHADER="""shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float inversion=0.0;
uniform float hue=0.0;
uniform float contrast=1.0;
void fragment(){
 vec4 c=textureLod(screen_texture,SCREEN_UV,0.0);
 if(c.a>0.0001){c.rgb/=c.a;}
 c.rgb=mix(c.rgb,vec3(1.0)-c.rgb,inversion);
 float cs=cos(hue), sn=sin(hue);
 mat3 h=mat3(vec3(.213+.787*cs-.213*sn,.213-.213*cs+.143*sn,.213-.213*cs-.787*sn),vec3(.715-.715*cs-.715*sn,.715+.285*cs+.140*sn,.715-.715*cs+.715*sn),vec3(.072-.072*cs+.928*sn,.072-.072*cs-.283*sn,.072+.928*cs+.072*sn));
 c.rgb=h*c.rgb;
 c.rgb=clamp((c.rgb-vec3(.5))*contrast+vec3(.5),vec3(0.0),vec3(1.0));
 COLOR*=c;
}
"""

static func bind_friend(root: Control,clock: RefCounted,code: Control,attack: Control,laugh_text: Control,code_digits: Array,skip_button: Button,scale: float) -> Node:
	var binding: Node=load("res://scripts/ui/phone_entry_visual.gd").new()
	binding.name="FriendEntryVisual"; binding.kind="friend"; binding.session=clock; binding.surface=root; binding.art_scale=scale
	binding.message=code; binding.burst=attack; binding.laugh=laugh_text; binding.digits=code_digits; binding.skip=skip_button
	root.add_child(binding)
	return binding

static func bind_crash(root: Control,clock: RefCounted,scale: float,loading_dots: Array=[]) -> Node:
	var binding: Node=load("res://scripts/ui/phone_entry_visual.gd").new()
	binding.dots=loading_dots
	binding.name="TiyiEntryVisual"; binding.kind="crash"; binding.session=clock; binding.surface=root; binding.art_scale=scale
	binding._build_crash()
	root.add_child(binding)
	return binding

static func bind_loading(root: Control,clock: RefCounted,scale: float,loading_dots: Array) -> Node:
	var binding: Node=load("res://scripts/ui/phone_entry_visual.gd").new()
	binding.name="ZjudingEntryVisual"; binding.kind="loading"; binding.session=clock; binding.surface=root; binding.art_scale=scale; binding.dots=loading_dots
	root.add_child(binding)
	return binding

static func dot_offset(milliseconds: float,index: int) -> float:
	var elapsed:=milliseconds-index*150
	if elapsed<0: return 0
	var progress:=fposmod(elapsed,900)/450
	var stepped:=floorf(fposmod(progress,1)*3)/3
	return -10*stepped if progress<1 else -10*(1-stepped)

func _build_crash() -> void:
	var children:=surface.get_children()
	group=CanvasGroup.new(); group.name="TiyiWholeAppCrash"; surface.add_child(group)
	var themed:=Control.new(); themed.name="TiyiAppContents"; themed.size=surface.size; themed.mouse_filter=Control.MOUSE_FILTER_IGNORE
	group.add_child(themed)
	for child: Node in children: child.reparent(themed,false)
	material=ShaderMaterial.new(); var shader:=Shader.new(); shader.code=CRASH_SHADER; material.shader=shader; group.material=material

func _ready() -> void:
	if kind=="crash":
		# CanvasGroup is Node2D. Keep an explicit themed Control wrapper so all
		# app controls, including the loading text and exit button, share Fusion.
		var theme_owner: Control=surface
		while theme_owner!=null and theme_owner.theme==null: theme_owner=theme_owner.get_parent_control()
		if theme_owner!=null: group.get_node("TiyiAppContents").theme=theme_owner.theme
	_process(0)

static func crash_sample(milliseconds: float) -> Dictionary:
	var progress:=clampf(milliseconds/600.0,0,1)
	var times: Array=[0.0,.3,.55,.8,1.0]
	var values: Array=[Vector4(0,0,1,1),Vector4(-8,4,1,1),Vector4(10,0,.92,1),Vector4(0,0,.4,.6),Vector4(0,0,.02,0)]
	var index:=0
	while index<3 and progress>=float(times[index+1]): index+=1
	var blend:=1.0 if progress>=1 else floorf((progress-float(times[index]))/(float(times[index+1])-float(times[index]))*6)/6
	var value: Vector4=values[index].lerp(values[index+1],blend)
	var filter:=Vector3(0,0,1)
	if index==0: filter=Vector3(.9*blend,90*blend,1)
	elif index==1: filter=Vector3(.9,90,1) if blend<.5 else Vector3(0,0,3)
	elif index==2: filter=Vector3(0,0,3) if blend<.5 else Vector3(1,0,1)
	else: filter=Vector3(1-blend,0,1)
	return {"x":value.x,"skew":value.y,"scale_y":value.z,"alpha":value.w,"filter":filter}

func _process(_delta: float) -> void:
	for i in range(dots.size()): dots[i].position.y=float(dots[i].get_meta("rest_y"))+dot_offset(session.elapsed_ms,i)/art_scale
	if kind=="friend":
		var elapsed: float=session.friend_elapsed_ms
		message.visible=session.friend_phase>=1; burst.visible=session.friend_phase>=2; laugh.visible=session.friend_phase>=3
		skip.mouse_filter=Control.MOUSE_FILTER_STOP if session.friend_phase==2 and elapsed>=4000 else Control.MOUSE_FILTER_IGNORE
		# Original local .wx-chat.is-smashed: seven120ms stepped shakes only.
		surface.position=Opening.shake_at((elapsed-2000)/1000)/art_scale if elapsed>=2000 and elapsed<2840 else Vector2.ZERO
		if session.friend_phase>=3:
			var progress:=clampf(floorf((elapsed-session.laugh_at_ms)/1000*8)/8,0,1)
			var vectors: Array=[Vector2(-180,-320),Vector2(160,-260),Vector2(-220,300),Vector2(230,260)]
			var rotations: Array=[-260,200,300,-220]
			for i in range(4):
				digits[i].position=Vector2(81+i*34,37)+vectors[i]*progress; digits[i].rotation=deg_to_rad(rotations[i])*progress; digits[i].modulate.a=1-progress
	elif kind=="crash" and is_instance_valid(group):
		var sample:=crash_sample(session.elapsed_ms-3000) if session.phase in ["crashing","exiting"] else crash_sample(0)
		var center:=surface.size/2
		var x_axis:=Vector2(1,0); var y_axis:=Vector2(tan(deg_to_rad(sample.skew))*sample.scale_y,sample.scale_y)
		group.transform=Transform2D(x_axis,y_axis,center+Vector2(sample.x/art_scale,0)-x_axis*center.x-y_axis*center.y)
		group.self_modulate.a=sample.alpha
		material.set_shader_parameter("inversion",sample.filter.x); material.set_shader_parameter("hue",deg_to_rad(sample.filter.y)); material.set_shader_parameter("contrast",sample.filter.z)
