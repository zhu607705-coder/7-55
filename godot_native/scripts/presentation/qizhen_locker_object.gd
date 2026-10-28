extends RefCounted
## The dock cupboard is a source-pixel object, not a second inventory owner.
## The existing key-to-cord transaction is committed before its doors move.
const Picker=preload("res://scripts/world_object_picker.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
const SpatialRules=preload("res://scripts/space/spatial_rules.gd")
const PLATE="res://assets/rpg/interiors/qizhen_lake_dock.png"
const FACE=Rect2(277,744,72,61)
const HALF_WIDTH=36
const SLIDE=30
const DURATION=1.64
const TARGET="qizhen_use_item_1"

class LockerActor extends Node2D:
	var slide_px:float=0
	var latch_px:float=0
	var cord_lift:float=0
	var cord_alpha:float=0
	var motion:AnimationPlayer
	func _ready()->void:
		name="QizhenLockerObject"
		motion=AnimationPlayer.new();motion.name="DoorMotion"
		motion.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		add_child(motion)
		var clip:=Animation.new();clip.length=DURATION
		_add_track(clip,"slide_px",[0.0,.24,.4,.88,1.12,DURATION],[0.,0.,4.,27.,30.,30.])
		_add_track(clip,"latch_px",[0.0,.06,.12,.18,.24,DURATION],[0.,1.,-1.,1.,0.,0.])
		_add_track(clip,"cord_lift",[0.0,1.08,1.2,1.48,DURATION],[0.,0.,-3.,-12.,-12.])
		_add_track(clip,"cord_alpha",[0.0,.24,.52,1.2,1.48,DURATION],[0.,0.,1.,1.,0.,0.])
		var library:=AnimationLibrary.new();library.add_animation("unlock",clip)
		motion.add_animation_library("",library)
	func _add_track(clip:Animation,property:String,times:Array,values:Array)->void:
		var index:=clip.add_track(Animation.TYPE_VALUE)
		clip.track_set_path(index,NodePath(".:"+property))
		for i:int in times.size():clip.track_insert_key(index,float(times[i]),float(values[i]))

var actor:LockerActor
var plate:Texture2D
var owner:Dictionary={}
var active:=false
var initialized:=false
var unlocked:=false
var reduced:=false
var elapsed:=0.0
var playing:=false
var play_count:=0

func _notification(what:int)->void:
	if what==NOTIFICATION_PREDELETE and is_instance_valid(actor):actor.free()

func attach(host:Node)->void:
	if is_instance_valid(actor):return
	actor=LockerActor.new();host.add_child(actor)
	_set_pose()

func _set_pose()->void:
	if not is_instance_valid(actor) or actor.motion==null:return
	actor.motion.play("unlock")
	actor.motion.seek(elapsed if playing else DURATION if unlocked else 0.0,true)
	if not playing:actor.motion.pause()

func sync(state:Dictionary,scene_changed:bool=false)->void:
	var current:bool=str(state.get("native",{}).get("scene",""))=="qizhen_lake" and str(state.get("qizhenLake",{}).get("zone",""))=="dock"
	if not current:
		active=false;initialized=false;playing=false;elapsed=0
		if is_instance_valid(actor) and actor.motion!=null:actor.motion.pause()
		return
	active=true
	var opened:bool=bool(state.get("qizhenLake",{}).get("lockerOpened",false))
	reduced=bool(state.get("native",{}).get("settings",{}).get("reduced_motion",false))
	if not initialized or scene_changed or not is_same(owner,state):
		owner=state;initialized=true;unlocked=opened;playing=false;elapsed=DURATION if opened else 0.0
		_set_pose();return
	if opened!=unlocked:
		unlocked=opened
		playing=opened and not reduced
		elapsed=0.0 if playing or not opened else DURATION
		if playing:play_count+=1
		_set_pose()
	if reduced and playing:
		playing=false;elapsed=DURATION;_set_pose()

func tick(delta:float,state:Dictionary)->void:
	sync(state)
	if not active or not playing or not is_finite(delta) or delta<=0:return
	elapsed=minf(DURATION,elapsed+minf(delta,.1))
	if is_instance_valid(actor):actor.motion.seek(elapsed,true)
	if elapsed>=DURATION:
		playing=false
		if is_instance_valid(actor):actor.motion.pause()

func _slide()->int:
	return clampi(roundi(actor.slide_px),0,SLIDE) if is_instance_valid(actor) else SLIDE if unlocked and not playing else 0

func snapshot()->Dictionary:
	var slide:int=_slide()
	return {"active":active,"playing":playing,"unlocked":unlocked,"phase":"unlatching" if playing and elapsed<.24 else "opening" if playing and elapsed<1.12 else "cord_lift" if playing else "open" if unlocked else "closed","elapsed":elapsed,"playCount":play_count,"sourceFace":FACE,"slidePixels":slide,"leftLeaf":Rect2(FACE.position,Vector2(HALF_WIDTH-slide,FACE.size.y)),"rightLeaf":Rect2(FACE.position+Vector2(HALF_WIDTH+slide,0),Vector2(HALF_WIDTH-slide,FACE.size.y)),"uniformScale":true,"animationPlayer":is_instance_valid(actor) and actor.motion!=null}

func draw(canvas:CanvasItem,context:Dictionary,state:Dictionary,front:bool)->void:
	sync(state)
	if not active:return
	var ground:float=context.get("player_ground_y",SpatialRules.foot_y(Vector2(context.get("player",Vector2.ZERO))))
	var in_front:bool=SpatialRules.depth_in_front(FACE.end.y,ground)
	if in_front!=front:return
	attach(canvas)
	if plate==null and ResourceLoader.exists(PLATE):plate=load(PLATE)
	if plate==null:return
	var origin:Vector2=context.get("origin",Vector2.ZERO);var zoom:float=float(context.get("zoom",1))
	canvas.draw_set_transform(origin,0,Vector2.ONE*zoom)
	var slide:int=_slide()
	# Replace exactly the original two leaves; stationary frame and masonry
	# stay in the plate. Every moving fragment retains one-to-one source pixels.
	canvas.draw_rect(FACE,Color("344452"))
	canvas.draw_rect(FACE.grow(-3),Color("2D443E"))
	for y:int in [760,780,800]:
		canvas.draw_rect(Rect2(279,y,68,2),Color("766E63"))
		canvas.draw_rect(Rect2(279,y+2,68,2),Color("202B35"))
	for x:int in [286,338]:canvas.draw_rect(Rect2(x,750,2,48),Color("526B7A"))
	if is_instance_valid(actor) and actor.cord_alpha>0:
		var at:=Vector2(313,789+roundi(actor.cord_lift))
		var rope:=PackedVector2Array()
		for i:int in range(25):rope.append(at+Vector2(roundi(cos(i*TAU/24)*8),roundi(sin(i*TAU/24)*5)))
		canvas.draw_polyline(rope,Color("D8C7A0",actor.cord_alpha),2)
		canvas.draw_line(at+Vector2(6,2),at+Vector2(11,7),Color("A39B87",actor.cord_alpha),1)
	var latch:int=roundi(actor.latch_px) if is_instance_valid(actor) else 0
	var source_y:int=maxi(-latch,0);var dest_y:int=maxi(latch,0)
	var leaf_height:float=FACE.size.y-absi(latch)
	var left_source:=Rect2(FACE.position+Vector2(slide,source_y),Vector2(HALF_WIDTH-slide,leaf_height))
	var right_source:=Rect2(FACE.position+Vector2(HALF_WIDTH,source_y),Vector2(HALF_WIDTH-slide,leaf_height))
	canvas.draw_texture_rect_region(plate,Rect2(FACE.position+Vector2(0,dest_y),left_source.size),left_source)
	canvas.draw_texture_rect_region(plate,Rect2(FACE.position+Vector2(HALF_WIDTH+slide,dest_y),right_source.size),right_source)
	# Match the existing plate wash in both observation modes.
	canvas.draw_rect(FACE,Color(.03,.15,.26,float(context.get("mode_mix",0))*.3))
	Picker.record(canvas,[TARGET],FACE)
	canvas.draw_set_transform(Vector2.ZERO)
