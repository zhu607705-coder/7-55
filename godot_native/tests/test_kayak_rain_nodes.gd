extends SceneTree
## Deterministic render-object checks. The separate rain-rescue test exercises
## real wall-clock receipt, movie playback, skip, cancellation and settlement.
const Session=preload("res://scripts/media/c3_rain_rescue_session.gd")
const Model=preload("res://scripts/media/c3_rain_rescue_model.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("KAYAK RAIN NODES: "+label)
func at(view: Control,session: RefCounted,ms: int) -> void:
	session._started_ms=Time.get_ticks_msec()-ms
	view.pose=Model.pose_at(ms,false)
	view._update_native_actor()
func run() -> void:
	var state: Node=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	state.d.native.merge({"chapter":3,"scene":"qizhen_lake","page":"c3_lake","mode":"light","positions":{}},true)
	state.d.runtimeMode="rpg";state.d.rpgScene="qizhen_lake"
	state.d.qizhenLake.merge({"active":true,"phase":"boarding_tutorial","zone":"dock","vehicle":"on_foot","rainWarningSeen":true,"rainSafetyCleared":false,"rainRescueCompleted":false},true)
	var world: Control=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false)
	var session:=Session.new();session.configure(false,Model.APPROACH_POINT,state.d)
	var view: Control=load("res://scripts/media/c3_rain_rescue.gd").new();root.add_child(view);view.size=Vector2(960,540)
	view.setup({"session":session,"read_state":func():return state.d,"world":world});view.set_process(false)
	check(view.visual.scene_file_path=="res://scenes/objects/kayak_rig.tscn","rain uses the same native kayak packed scene")
	check(view.walker is Sprite2D and view.walker.name=="RescueWalker","approach/rescued player has an independent native sprite")
	check(view.splash.get_child_count()==8 and view.splash.get_children().all(func(n):return n is Line2D),"capsize rings are separate owned nodes")
	check(view.get_node("CaptionBackdrop").get_index()>view.splash.get_index() and view.caption.get_index()>view.get_node("CaptionBackdrop").get_index(),"caption backdrop and text occlude actor/effects")
	var before:=JSON.stringify(state.d)
	at(view,session,200)
	check(view.walker.visible and not view.visual.visible and not view.splash.visible,"approach displays walking actor only")
	check(is_equal_approx(view.walker.scale.x,view.walker.scale.y),"walking source frame is uniformly scaled")
	at(view,session,700)
	check(view.visual.visible and not view.walker.visible and not view.splash.visible,"launch owns the kayak actor")
	at(view,session,1420)
	check(view.visual.sampled_pose.left.phase=="exit","route gap does not restart the preceding left stroke")
	at(view,session,1550)
	check(view.visual.sampled_pose.left.phase=="recovery" and view.visual.sampled_pose.right.phase=="entry","second stroke overlaps the first side's independent recovery")
	for side: String in ["left","right"]:
		check(view.visual.hand_grip(side).global_position.distance_to(view.visual.paddle_grip(side).global_position)<.0002,"rain hand holds the matching paddle")
	at(view,session,4900)
	check(view.visual.visible and view.splash.visible and not view.walker.visible,"capsize owns both body and native splash nodes")
	check(view.visual.get_node("BodyRoll").rotation<0,"capsize rotates the native body pivot")
	check(view.splash.get_children().all(func(n):return is_equal_approx(n.width*n.scale.x,2)),"splash retains source two-pixel line width")
	at(view,session,5700)
	check(not view.visual.visible and not view.walker.visible and not view.splash.visible,"cinematic retires route actors")
	view.pose=Model.rescued_pose(700,false);view._update_native_actor()
	check(view.walker.visible and not view.visual.visible and not view.splash.visible,"rescued dock hold restores walker only")
	# Coexistence with the later native continuation: it owns the cinematic
	# surface while the route actors and outer backdrop retire.
	at(view,session,5700)
	view._begin_cinematic()
	check(is_instance_valid(view.native_renderer),"native cinematic still mounts the production renderer")
	view.native_renderer.present(Model.native_source_ms(0),false)
	view._layout_caption(state.d)
	check(not view.visual.visible and not view.walker.visible and not view.splash.visible,"native cinematic cannot duplicate route actors")
	check(not view.get_node("CaptionBackdrop").visible and not view.caption.visible,"desktop native cinematic keeps its own footer and caption")
	view._layout_caption({"native":{"host":{"world_display_scale":.37346938252449}}})
	check(view.caption.visible and view.native_renderer.external_caption and not view.get_node("CaptionBackdrop").visible,"compact native cinematic keeps exactly one caption over renderer footer")
	view.native_renderer.hide()
	view.pose=Model.rescued_pose(700,false);view._update_native_actor();view._layout_caption(state.d)
	check(view.walker.visible and view.get_node("CaptionBackdrop").visible and view.caption.visible,"dock hold restores sprite and outer footer")
	check(JSON.stringify(state.d)==before,"node sampling cannot author rescue/story state")
	var rig: Node2D=view.visual;var walker: Sprite2D=view.walker;var splash: Node2D=view.splash
	view.cancel();await process_frame
	check(not is_instance_valid(rig) and not is_instance_valid(walker) and not is_instance_valid(splash),"cancel frees all presentation-owned native objects")
	check(not world.presentation_actor_hidden,"cancel restores world actor ownership")
	world.free()
	print("KAYAK_RAIN_NODES: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
