extends Node2D
## Visual-only, feet-anchored character atlas player. Does not own physics/input.
var sprite: Sprite2D
var profile: Dictionary = {}
var atlas: Texture2D
var atlases: Dictionary = {}
var available_walk_directions: Array[String] = []
var target_height := 10.0
var facing := "down"
var walking := false
var elapsed := 0.0
var frame_index := 0
var has_walk_animation := false
var ready_to_show := false
var distance_phase := 0.0
var registered_frames: Dictionary = {}

func configure(data: Dictionary, texture: Texture2D, display_height: float, extra_atlases: Dictionary = {}) -> bool:
	ready_to_show = false
	if is_instance_valid(sprite):sprite.visible=false
	if texture == null or display_height <= 0.0 or float(data.get("reference_body_height",0)) <= 0.0:
		return false
	var directions: Dictionary = data.get("directions",{})
	var candidate_atlases: Dictionary={"idle":texture}
	for key in extra_atlases:candidate_atlases[key]=extra_atlases[key]
	for direction in ["down","left","right","up"]:
		var states: Dictionary = directions.get(direction,{})
		if states.get("idle",[]).is_empty():return false
		for state in ["idle","walk"]:
			var state_frames:Array=states.get(state,[])
			var uses_phase:bool=not state_frames.is_empty() and state_frames[0].has("phase")
			var previous_phase:=-1.0
			for frame in states.get(state,[]):
				var frame_atlas: Texture2D=candidate_atlases.get(str(frame.get("atlas","idle")))
				if frame_atlas==null:return false
				var bounds:=Rect2(Vector2.ZERO,frame_atlas.get_size())
				var rect: Array = frame.get("region",[])
				var foot: Array = frame.get("foot",[])
				if rect.size()!=4 or foot.size()!=2:return false
				var region := Rect2(rect[0],rect[1],rect[2],rect[3])
				if region.size.x<=0 or region.size.y<=0 or not bounds.encloses(region):return false
				if foot[0]<0 or foot[0]>region.size.x or foot[1]<0 or foot[1]>region.size.y:return false
				if float(frame.get("duration",0.14))<=0:return false
				if float(data.get("atlas_reference_body_heights",{}).get(str(frame.get("atlas","idle")),data.reference_body_height))<=0:return false
				if frame.has("phase")!=uses_phase:return false
				if uses_phase:
					var phase_value:=float(frame.phase)
					if phase_value<0 or phase_value>=1 or phase_value<=previous_phase:return false
					previous_phase=phase_value
	profile=data.duplicate(true);atlas=texture;atlases=candidate_atlases;target_height=display_height
	registered_frames.clear()
	var heights:Dictionary=profile.get("atlas_reference_body_heights",{})
	for direction in ["down","left","right","up"]:
		registered_frames[direction]={}
		for state in ["idle","walk"]:
			var registered:Array=[]
			for frame in profile.directions[direction].get(state,[]):
				var atlas_id:=str(frame.get("atlas","idle"))
				var region:Array=frame.region
				var cutout:=AtlasTexture.new();cutout.atlas=atlases[atlas_id]
				cutout.region=Rect2(region[0],region[1],region[2],region[3]);cutout.filter_clip=true
				var visual_scale:=target_height/float(heights.get(atlas_id,profile.reference_body_height))
				registered.append({"texture":cutout,"scale":visual_scale,"offset":-Vector2(frame.foot[0],frame.foot[1])*visual_scale})
			registered_frames[direction][state]=registered
	if not is_instance_valid(sprite):
		sprite=Sprite2D.new();sprite.name="RegisteredStudentArtwork";sprite.centered=false
		sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;add_child(sprite)
	var shader:=Shader.new()
	shader.code="shader_type canvas_item; uniform float alpha_cutoff=0.04; uniform float solid_threshold=0.95; void fragment(){ vec4 c=texture(TEXTURE,UV); if(c.a<alpha_cutoff){discard;} if(c.a>solid_threshold){c.a=1.0;} COLOR=c; }"
	var material:=ShaderMaterial.new();material.shader=shader
	material.set_shader_parameter("alpha_cutoff",float(profile.get("alpha_cutoff",0.04)))
	material.set_shader_parameter("solid_threshold",float(profile.get("solid_alpha_threshold",0.95)))
	sprite.material=material
	has_walk_animation=true;available_walk_directions.clear()
	for direction in ["down","left","right","up"]:
		if directions[direction].get("walk",[]).size()<2:has_walk_animation=false
		else:available_walk_directions.append(direction)
	ready_to_show=true;sprite.visible=true
	reset_pose()
	return true

func set_motion(velocity: Vector2, delta: float) -> void:
	if not ready_to_show:return
	var moving := velocity.length_squared()>0.001
	var next_facing := facing
	if moving:
		if absf(velocity.x)>absf(velocity.y):next_facing="right" if velocity.x>0 else "left"
		else:next_facing="down" if velocity.y>0 else "up"
	if moving!=walking or next_facing!=facing:
		elapsed=0.0;frame_index=0
	walking=moving;facing=next_facing
	var frames: Array = _current_frames()
	if walking and frames.size()>1:
		elapsed+=maxf(0.0,delta)
		var total:=0.0
		for frame in frames:total+=float(frame.get("duration",0.14))
		elapsed=fmod(elapsed,total)
		var cursor:=0.0
		for i in range(frames.size()):
			cursor+=float(frames[i].get("duration",0.14))
			if elapsed<cursor:frame_index=i;break
	_apply_frame()

func advance_motion(displacement: Vector2, delta: float) -> void:
	# Use actual controller displacement after collision, never requested input.
	# Render rate and unique artwork-frame count are independent.
	var was_walking:=walking
	set_motion(displacement.normalized() if displacement.length_squared()>0.000000000001 else Vector2.ZERO,0.0)
	if not ready_to_show or not walking:return
	if not was_walking:distance_phase=0.0
	var frames:=_current_frames()
	if frames.size()<2:return
	var stride:=target_height*float(profile.get("cycle_stride_body_heights",0.0))
	if stride<=0.0:
		# A walking sheet without measured stride is not yet motion-ready.
		frame_index=0;_apply_frame();return
	distance_phase=fposmod(distance_phase+displacement.length()/stride,1.0)
	frame_index=mini(frames.size()-1,int(floor(distance_phase*frames.size())))
	if frames[0].has("phase"):
		frame_index=0
		for i in range(frames.size()):
			if distance_phase>=float(frames[i].phase):frame_index=i
	_apply_frame()

func _current_frames() -> Array:
	var states: Dictionary=profile.directions[facing]
	var frames: Array=states.get("walk",[]) if walking else []
	return states.idle if frames.is_empty() else frames

func _apply_frame() -> void:
	var frames:=_current_frames()
	frame_index=clampi(frame_index,0,frames.size()-1)
	var state:="walk" if walking and not registered_frames[facing].walk.is_empty() else "idle"
	var registered:Dictionary=registered_frames[facing][state][frame_index]
	# Immutable AtlasTexture objects are reused. No per-physics-tick texture allocation.
	sprite.texture=registered.texture;sprite.scale=Vector2.ONE*registered.scale
	sprite.position=registered.offset

func current_foot_global() -> Vector2:
	if not ready_to_show:return global_position
	var frame: Dictionary=_current_frames()[frame_index]
	return sprite.to_global(Vector2(frame.foot[0],frame.foot[1]))

func reset_pose() -> void:
	if not ready_to_show:return
	facing="down";walking=false;elapsed=0.0;frame_index=0;distance_phase=0.0
	_apply_frame()
