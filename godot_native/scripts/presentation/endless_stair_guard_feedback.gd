extends Node
## B3 model-driven cues. No movement/catch rules live in this presentation layer.
const Foley=preload("res://scripts/audio/endless_stair_guard_foley.gd")
var view
var audio_enabled:=true
var last_tick:=-1
var last_serial:=-1
var last_guard_x:=0.0
var walk_frame_phase:=0.0
var foot_distance:=0.0
var foot_side:=0
var arm_amount:=0.0
var lift_angle:=0.0
var cues_played:Array[Dictionary]=[]
var step_events:Array[Dictionary]=[]
var scheduled_click_tick:=-1
var steps:Array[AudioStreamPlayer]=[]
var click:AudioStreamPlayer
var breath:AudioStreamPlayer
var arms:Array[MeshInstance3D]=[]
var sleeve_material:StandardMaterial3D
var skin_material:StandardMaterial3D
var hide_old_hand:MeshInstance3D
var inhale:AudioStreamWAV
var exhale:AudioStreamWAV
func setup(owner_view)->void:
	view=owner_view
	# Headless tests validate PCM and cue intent without queuing an unmixed audio driver.
	audio_enabled=DisplayServer.get_name()!="headless"
	for i in 2:
		var sound:=AudioStreamPlayer.new()
		sound.stream=Foley.make("step",i)
		sound.max_polyphony=3
		add_child(sound);steps.append(sound)
	click=AudioStreamPlayer.new();click.stream=Foley.make("click");add_child(click)
	breath=AudioStreamPlayer.new();add_child(breath)
	inhale=Foley.make("inhale");exhale=Foley.make("exhale")
	sleeve_material=StandardMaterial3D.new();sleeve_material.albedo_color=Color("24415a")
	sleeve_material.roughness=1
	skin_material=StandardMaterial3D.new();skin_material.albedo_color=Color("a38663")
	skin_material.roughness=1
	for i in 3:
		var piece:=MeshInstance3D.new();piece.name="GuardRaisedArm_%d"%i
		var mesh:=BoxMesh.new();mesh.size=Vector3.ONE;piece.mesh=mesh
		piece.material_override=skin_material if i==2 else sleeve_material
		piece.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		piece.layers=2;view.world.add_child(piece);arms.append(piece)
	hide_old_hand=MeshInstance3D.new()
	var mask:=BoxMesh.new();mask.size=Vector3.ONE;hide_old_hand.mesh=mask
	hide_old_hand.material_override=sleeve_material
	hide_old_hand.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hide_old_hand.layers=2;view.world.add_child(hide_old_hand)
	reset()
func reset()->void:
	last_tick=-1;last_serial=-1;last_guard_x=view.model.guard.x
	walk_frame_phase=0;foot_distance=0;foot_side=0;arm_amount=0;lift_angle=0
	scheduled_click_tick=-1;cues_played.clear();step_events.clear()
	for sound in steps:sound.stop()
	if click:click.stop()
	if breath:breath.stop()
	for piece in arms:piece.visible=false
	if hide_old_hand:hide_old_hand.visible=false
func advance()->void:
	if not view.active: return
	var m=view.model
	if last_tick==m.tick:return
	var moved:=absf(float(m.guard.x)-last_guard_x)
	last_guard_x=m.guard.x
	walk_frame_phase+=moved*3.5
	foot_distance+=moved
	var gap:=absf(float(m.player.x-m.guard.x))
	var gain:=clampf(-8.0-(gap-2.0)*1.15,-20,-8)
	if view.active and m.guard_grounded and foot_distance>=.98:
		foot_distance=fmod(foot_distance,.98)
		steps[foot_side].volume_db=gain
		steps[foot_side].pitch_scale=1.10 if m.pursuit_phase=="burst" else .96
		if audio_enabled:steps[foot_side].play()
		foot_side=1-foot_side
		step_events.append({"tick":m.tick,"phase":m.pursuit_phase,"speed":m.guard_pursuit_speed})
	if int(m.pursuit_event_serial)!=last_serial:
		last_serial=int(m.pursuit_event_serial)
		if m.pursuit_phase=="windup":
			click.volume_db=-7;click.pitch_scale=1.15 if m.pursuit_pattern=="fast" else .90
			if audio_enabled:click.play()
			breath.stream=inhale;breath.volume_db=-5;breath.pitch_scale=1.12 if m.pursuit_pattern=="fast" else .83
			if audio_enabled:breath.play()
			if m.pursuit_pattern=="slow":scheduled_click_tick=m.tick+18
		elif m.pursuit_phase=="recovery":
			breath.stream=exhale;breath.volume_db=-5;breath.pitch_scale=.92
			if audio_enabled:breath.play()
		cues_played.append({"tick":m.tick,"phase":m.pursuit_phase,"pattern":m.pursuit_pattern,"eventSerial":last_serial})
	if scheduled_click_tick>=0 and m.tick>=scheduled_click_tick:
		click.volume_db=-10;click.pitch_scale=.8
		if audio_enabled:click.play()
		scheduled_click_tick=-1
	last_tick=m.tick
func frame()->int:
	# Freeze only in the near-still preparation portion; feet otherwise follow travel.
	if view.model.pursuit_phase=="windup" and view.model.guard_pursuit_speed<1.0:return 0
	return int(floor(walk_frame_phase))%8
func hand_pose(base_hand:Vector3,facing:String,delta:float)->Vector3:
	var m=view.model
	var amount:=0.0
	var phase_progress:float=m.pursuit_phase_progress()
	if m.pursuit_phase=="windup":
		var rise_time:=.28 if m.pursuit_pattern=="fast" else .58
		amount=smoothstep(0,1,minf(1,float(m.pursuit_phase_ticks)/60/rise_time))
	elif m.pursuit_phase=="burst":amount=1-smoothstep(0,1,minf(1,float(m.pursuit_phase_ticks)/15))
	# The model's progress drives pose, never an independently scheduled attack.
	arm_amount=amount
	lift_angle=amount*(.34 if m.pursuit_pattern=="fast" else .22)
	var hand_pixel:=Vector2(75,59)
	var shoulder_pixel:=Vector2(56,61)
	var elbow_pixel:=Vector2(70,74)
	if facing=="up":
		hand_pixel=Vector2(72,55);shoulder_pixel=Vector2(63,61);elbow_pixel=Vector2(75,70)
	elif facing=="down":
		hand_pixel=Vector2(75,57);shoulder_pixel=Vector2(63,61);elbow_pixel=Vector2(77,72)
	var hand:Vector3=base_hand.lerp(view._sprite_socket(view.pursuer,hand_pixel),amount)
	var shoulder:Vector3=view._sprite_socket(view.pursuer,shoulder_pixel)
	var elbow:Vector3=shoulder.lerp(base_hand,.55).lerp(view._sprite_socket(view.pursuer,elbow_pixel),amount)
	var visible:bool=amount>.04 and view.active
	for arm in arms:arm.visible=visible
	hide_old_hand.visible=visible
	if visible:
		var z:Vector3=view.camera.global_basis.z*.035
		_segment(arms[0],shoulder+z,elbow+z,.115)
		_segment(arms[1],elbow+z,hand+z,.092)
		_segment(arms[2],hand+z,hand+z+view.camera.global_basis.y*.065,.070)
		hide_old_hand.transform=Transform3D(view.camera.global_basis.scaled(Vector3(.10,.12,.018)),base_hand+z*.5)
	return hand
func _segment(piece:MeshInstance3D,a:Vector3,b:Vector3,width:float)->void:
	var up:Vector3=(b-a).normalized()
	var normal:Vector3=view.camera.global_basis.z
	var side:=up.cross(normal).normalized()
	piece.transform=Transform3D(Basis(side*width,up*a.distance_to(b),normal*.022),(a+b)*.5)
func torch_pose(base_pose:Dictionary)->Dictionary:
	var result:=base_pose.duplicate()
	var direction:Vector3=(Vector3(base_pose.target)-Vector3(base_pose.position)).normalized()
	var across:Vector3=direction.cross(Vector3.UP).normalized()
	if across.length_squared()>.001:direction=direction.rotated(across,lift_angle)
	result.target=Vector3(base_pose.position)+direction*view.torch.spot_range
	return result
func pause_audio()->void:
	for sound in steps:sound.stop()
	click.stop();breath.stop()

func _exit_tree()->void:
	pause_audio()
	for sound in steps:sound.stream=null
	click.stream=null;breath.stream=null
	inhale=null;exhale=null;view=null
