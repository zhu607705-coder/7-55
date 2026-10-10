extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const Session=preload("res://scripts/presentation/c3_narrative_session.gd")
var checks: int=0
var errors: int=0
var state: Node
var main: Control
var host: Control
var world: Control
var boundary_count: int=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: errors+=1; push_error(label)
func _initialize() -> void: call_deferred("run")
func advance_to(ms: float) -> void:
	while host.current!=null and host.current.elapsed_ms<ms:
		var dt: float=minf(100,ms-host.current.elapsed_ms)
		world._process(dt/1000); host.tick(dt,true)
	world._process(0)
func find_entry(id: String) -> Dictionary:
	for e: Dictionary in world.chapter3_layers.entries(state.d):
		if e.id==id: return e
	return {}
func run() -> void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"promo test saves isolated")
	if errors: quit(1); return
	state=root.get_node("State"); state.developer_mode=false; state.d=state.initial()
	state.d.native.chapter=3; state.d.native.scene="canteen_interior"; state.d.native.page="c3_canteen"; state.d.rpgScene="canteen_interior"; state.d.runtimeMode="rpg"
	state.d.canteenHunt.active=true; state.d.canteenHunt.phase="tray_search"; state.d.canteenHunt.entryPaperEscaped=true
	state.d.items.dailySpecialSparklingWater=true
	root.size=Vector2i(1280,720)
	main=load("res://scenes/main.tscn").instantiate(); root.add_child(main)
	await process_frame; await process_frame
	host=main.c3_narrative_host; world=main.world; host.set_process(false); world.set_process(false)
	world.player=world._find_safe(Vector2(1232,285)); world._sync_player(); world._update_camera()
	state.action_completed.connect(func(action:String,_before:Dictionary,_next:Dictionary,_result:Dictionary)->void:
		if action=="c3_promo_visual_complete": boundary_count+=1)
	state.act("c3_target:canteen-promo-board"); host.tick(0,true); world._process(0)
	var session: RefCounted=host.current
	check(session!=null and session.sequence_id=="canteen_promo","actual source promo target issues full timeline")
	check(state.d.canteenHunt.promoDrinkPlaced and not state.d.items.dailySpecialSparklingWater and not state.d.canteenHunt.queueGapOpened,"placing consumes cup without opening queue")
	check(host.blocks_input() and not host.blocks_movement(),"source promo blocks interactions while allowing walking")
	state.act("c3_promo_visual_complete",{"complete":true})
	state.act("c3_promo_visual_complete",Session.new(state.d,session.spec))
	state.act("c3_promo_visual_complete",session)
	check(not state.d.canteenHunt.queueGapOpened,"forged,foreign,early visual receipts rejected")
	boundary_count=0
	advance_to(771)
	check(find_entry("promo_insert").is_empty() and not find_entry("promo_empty").is_empty(),"real layer waits for original772ms insert")
	advance_to(772)
	check(find_entry("promo_insert").frame==0 and find_entry("promo_insert").frameSize==Vector2(48,64),"actual layer crops original10fps insertion sheet")
	advance_to(1299)
	check(find_entry("promo_empty").is_empty() and not find_entry("promo_active").is_empty() and not find_entry("promo_bubbles").is_empty(),"source reveal switches active board and six-fps bubbles")
	advance_to(1852)
	check(is_equal_approx(world.zoom,2.1),"real camera reaches authored promo focus zoom")
	advance_to(2238)
	check(not find_entry("queue_turn").is_empty() and find_entry("queue_6").is_empty(),"front student changes to original turn asset")
	advance_to(2521)
	check(find_entry("queue_turn").is_empty() and not find_entry("queue_prompt_0").is_empty(),"wave begins with original prompt frame")
	check(world.chapter3_layers.adjusted_collisions([],state.d).size()==10,"all three moving queue foot colliders disabled during source wave")
	advance_to(3343)
	check(find_entry("queue_6").point.y==282 and find_entry("queue_8").point.y==322,"three source students settle exactly36px behind original anchors")
	check(world.chapter3_layers.adjusted_collisions([],state.d).size()==13,"moved queue collider positions restored after wave")
	advance_to(3998)
	check(not state.d.canteenHunt.queueGapOpened and state.d.canteenHunt.phase=="tray_search" and session.snapshot().rawText.is_empty(),"no premature gap,phase or dialogue at3998ms")
	advance_to(3999)
	check(state.d.canteenHunt.queueGapOpened and state.d.canteenHunt.phase=="menu_order" and session.visual_acknowledged,"authentic intermediate source callback opens queue at3999ms")
	check(session.snapshot().rawText=="玩家：他们怎么都退了？" and host.blocks_input(),"only then first original reply appears; interaction stays locked")
	check(boundary_count==1,"actual host sends one visual boundary callback")
	state.act("c3_story_complete",session)
	check(host.current==session and session.status=="playing","cannot skip remaining dialogue with visual receipt")
	advance_to(8999)
	check(host.current==null and session.status=="consumed","both2500ms source replies finish before releasing input")
	check(boundary_count==1 and not state.d.items.dailySpecialSparklingWater,"terminal acknowledgement cannot replay boundary or refund consumed cup")
	check(state.save_game(),"finished source state persists with guarded save")
	# Interrupted saved promo reconstructs the source220ms scene startup, then
	# original camera/queue motion; it never asks for a second already consumed cup.
	var controller:=Chapter.new(); var loaded: Dictionary=state.d.duplicate(true)
	loaded.canteenHunt.queueGapOpened=false; loaded.canteenHunt.phase="tray_search"
	var replay: RefCounted=controller.narrative_session(loaded)
	check(replay!=null and replay.spec.timelineStartMs==220 and replay.spec.delayMs==4219,"reload unfinished promo includes source220ms restart delay")
	check(not loaded.items.dailySpecialSparklingWater and not loaded.canteenHunt.queueGapOpened,"recovery does not duplicate items or advance facts")
	await main.shutdown(); main.queue_free(); await process_frame
	print("Chapter 3 promo integration: %d checks, %d failures" % [checks,errors]); quit(0 if errors==0 else 1)
