extends SceneTree
## Deterministic presentation fixture, not an earned controller progression.
const Fixture=preload("res://tests/canteen_native_fixture.gd")
const Game=preload("res://scripts/games/canteen_defense.gd")
const Layers=preload("res://scripts/ui/chapter3_world_layers.gd")
const Objects=preload("res://scripts/objects/canteen_object_scene.gd")
var checks:=0
var failures:=0
var cues:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	root.size=Vector2i(960,540)
	var state:Node=root.get_node("State")
	for reduced:bool in [false,true]:
		Fixture.install(state,"exit_blocking");state.d.native.settings.reduced_motion=reduced
		state.d.canteenHunt.queueGapOpened=true
		var saved:=JSON.stringify(state.d)
		var layers:=Layers.new();layers.sync(state.d,true)
		var furniture:=Objects.new();root.add_child(furniture);furniture.setup(null);furniture.sync(state.d,"canteen_interior");furniture.hide()
		var game:=Game.new();game.size=Vector2(960,540);root.add_child(game)
		game.configure_canteen_scene(furniture,layers,Vector2(790,260),Vector2(790,310),.85)
		cues.clear();game.presentation_requested.connect(func(id:String,_payload:Dictionary):cues.append({"id":id,"at":game._pickup_elapsed}))
		game.setup({"seed":"1","session_id":"pickup-fixture","source_pickup_prelude":true});game.set_process(false)
		check(game.canteen_scene==furniture and game.pickup_view.furniture==furniture,"same independent native furniture owns film and defense")
		check(game.pickup_view.actor_entries(0).size()==31,"all31 source light actors retained after phase changes")
		check(game.pickup_view.shadow_frame(300)==(0 if reduced else 1),"shadow retains source flicker while reduced motion holds frame0")
		check(game.pickup_view.actor_entries(8039).size()==31 and game.pickup_view.actor_entries(8040).is_empty(),"crowd removal happens exactly at8040ms")
		check(state.d.canteenHunt.phase=="exit_blocking" and game.pickup_view.snapshot.canteenHunt.phase=="pickup_search","snapshot cannot regress actual accepted phase")
		for spec:Array in [["shadow_auntie_push_5frame.png",Vector2(480,128)],["paper_chicken_shake_5frame.png",Vector2(320,80)],["paper_chicken_burst_8frame.png",Vector2(384,192)]]:
			var tex:Texture2D=game.pickup_view._texture("res://assets/rpg/canteen/pickup-cutscene/"+spec[0])
			check(tex!=null and tex.get_size()==spec[1],"original sheet dimensions "+spec[0])
		var capture_path:=OS.get_environment("CANTEEN_PICKUP_CAPTURE")
		for at:float in [0,650,850,1500,2630,3750,4030,4930,5620,5980,6410,6500,6980,7350,7950,8040,8538,8930,9580,10480,11379]:
			game._pickup_tick(at-game._pickup_elapsed);game.queue_redraw();await process_frame
			check(game.model.tick==0 and not game.running,"cinematic keeps gameplay clock frozen at"+str(at))
			check(JSON.stringify(state.d)==saved,"presentation does not write story at"+str(at))
			if not capture_path.is_empty() and not reduced:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(capture_path.path_join("pickup_%05d.png"%int(at)))
		game._pickup_elapsed=5980;game.refresh();game.toggle_pause()
		var pose:Dictionary=game.pickup_pose();game._process(.1)
		check(game.pickup_pose()==pose and game.model.tick==0,"pause freezes every cinematic pose and simulation")
		game.configure_activity_layout(Vector2(390,844),true)
		check(not game.overview.visible and game.board_view.visible and not game.dash_button.visible,"portrait has one cinematic viewport and no gameplay controls")
		check(game.pickup_pose()==pose,"rotation never changes story time or source pose")
		game.begin();check(not game.paused and game._pickup_active,"Resume keeps current film")
		game._pickup_elapsed=11379;game._pickup_tick(1)
		check(not game._pickup_active and game.running and game.model.tick==0,"handoff begins exactly11380ms before first defense tick")
		check(game.overview.visible and not game.retry_button.disabled,"ordinary portrait controls return at handoff")
		check(cues.filter(func(e:Dictionary)->bool:return e.id=="canteen_defense_started").size()==1,"one defense start cue")
		check(cues.filter(func(e:Dictionary)->bool:return e.id=="canteen_paper_burst_completed").size()==1,"one original burst completed cue")
		game._process(1.0/60);check(game.model.tick==1,"first authorized gameplay step follows film")
		game.queue_free();furniture.queue_free();await process_frame
		check(cues[-1].id=="native_activity_closed","leaving film releases all existing audio ownership")
	# Closing at a visible package frame cannot start a latent defense later.
	Fixture.install(state,"exit_blocking")
	var interrupted:=Game.new();root.add_child(interrupted)
	var cancelled:=[false];var interrupted_cues:Array=[]
	interrupted.cancelled.connect(func():cancelled[0]=true)
	interrupted.presentation_requested.connect(func(id:String,_payload:Dictionary):interrupted_cues.append(id))
	interrupted.setup({"seed":"1","session_id":"interrupt-fixture","source_pickup_prelude":true});interrupted.set_process(false)
	interrupted._pickup_tick(5000);interrupted.exit_button.pressed.emit()
	check(cancelled[0] and interrupted.model.tick==0,"Exit during package film emits cancellation without advancing game")
	interrupted.queue_free();await process_frame
	check(interrupted_cues[-1]=="native_activity_closed" and not interrupted_cues.has("canteen_defense_started"),"interrupted film releases cues with no delayed defense admission")
	print("CANTEEN_PICKUP_CINEMATIC ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
