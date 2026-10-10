extends SceneTree
const Layer=preload("res://scripts/ui/library_world_layers.gd")
const Library=preload("res://scripts/chapters/library022.gd")
const PlayerMetrics=preload("res://scripts/player_metrics.gd")
var checks: int=0
var failures: int=0
var s: Dictionary
var layer: RefCounted
class Surface extends Control:
	var actor_texture: Texture2D=preload("res://assets/rpg/player/player_up_0.png")
	var layer: RefCounted
	var state: Dictionary
	var center:=Vector2(750,450)
	var magnify: float=1
	var actor:=Vector2(600,370)
	func _draw() -> void:
		var origin: Vector2=size/2-center*magnify
		draw_rect(Rect2(Vector2.ZERO,size),Color("0c1b24"))
		draw_texture_rect(layer.art,Rect2(origin,Vector2(1500,900)*magnify),false)
		var ctx: Dictionary={"origin":origin,"zoom":magnify,"player":actor,"scene_id":"library_interior"}
		layer.draw_back(self,ctx,state)
		# Source-sized actor drawn between background and foreground prop passes.
		var visual: Rect2=PlayerMetrics.visual_rect(actor)
		draw_texture_rect(actor_texture,Rect2(origin+visual.position*magnify,visual.size*magnify),false)
		layer.draw_front(self,ctx,state)
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func fresh() -> Dictionary:
	var state: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"chapter":2,"scene":"library_interior","page":"phone_home","mode":"light","settings":{"reduced_motion":false}}
	state.runtimeMode="rpg"; state.rpgScene="library_interior"; state.ui.libraryFinalsPhase="evidence_gathering"
	return state
func advance(ms: float) -> void:
	var left: float=ms
	while left>0:
		var part: float=minf(left,10); layer.tick(part/1000,s); left-=part
func _initialize() -> void: call_deferred("run")
func run() -> void:
	s=fresh(); layer=Layer.new(); layer.sync(s)
	var source: Dictionary=layer.source
	check(int(source.shelf.bounds.left)==502 and int(source.shelf.bounds.top)==110 and int(source.shelf.bounds.width)==123 and int(source.shelf.bounds.height)==123,"literal source cabinet rectangle")
	check(source.backpack.parts.size()==41,"original source-evaluated 41 backpack shapes")
	check(source.shelf.outline.size()==25,"all source cabinet silhouette vertices")
	check(source.shelf.totalMs==2105 and layer.shelf_total_ms()==2895,"source 13-frame plus paper timeline total2895ms")
	check(layer.bag_shake_ms()==1260 and layer.bag_total_ms()==4360,"source backpack shake/delay/transfer timing")
	for row: Dictionary in source.steppedSamples: check(layer._stepped(float(row.value))==float(row.result),"actual Phaser Stepped easing "+str(row.value))
	var initial: String=JSON.stringify(s)
	layer.tick(0.05,s); check(initial==JSON.stringify(s),"renderer never writes story state")
	var static_boxes: Array=[{"id":"north_display_shelf","left":502,"top":108,"right":625,"bottom":234},{"id":"other","left":10,"top":10,"right":20,"bottom":20}]
	check(layer.adjusted_collisions(static_boxes,s)==static_boxes,"idle collision unchanged")
	var lib: RefCounted=Library.new(); s.items.callNumber755=true; s.ui.libraryFinalsPuzzle.callNumberCollected=true
	lib.dispatch(s,"lib_shelf"); layer.sync(s)
	check(s.ui.libraryFinalsPuzzle.archivedRuleCollected and layer.blocks_movement(),"controller acquisition starts source shelf motion without moving its fact")
	var at: float=0
	for i in range(source.shelf.frames.size()):
		var row: Dictionary=source.shelf.frames[i]
		advance(float(row.durationMs)-1)
		check(layer.shelf_frame==maxi(0,i-1),"frame does not move early "+str(i))
		advance(1); at+=float(row.durationMs)
		check(layer.shelf_offset==int(row.offsetPx) and layer.shelf_frame==i,"source delayed frame exact "+str(i))
		var solid: Dictionary=layer.collision_rect()
		check(solid.left==502+mini(0,int(row.offsetPx)) and solid.right==625+maxi(0,int(row.offsetPx)),"collision covers rail and cabinet in frame "+str(i))
		check(layer.adjusted_collisions(static_boxes,s)[1]==static_boxes[1] and static_boxes[0].right==625,"other/source collisions remain immutable "+str(i))
	check(layer.shelf_phase=="sliding","last move holds before paper reveal")
	advance(109); check(layer.shelf_phase=="sliding","source110ms paper wait retained")
	advance(1); check(layer.shelf_phase=="paper" and layer.paper_pose().visible,"paper reveal begins at2215ms")
	advance(240+220+219); check(layer.blocks_movement(),"movement locked through paper transfer")
	advance(1); check(not layer.blocks_movement() and layer.shelf_phase=="complete" and not layer.paper_pose().visible,"shelf releases movement only at2895ms")
	check(layer.collision_rect().left==502 and layer.collision_rect().right==641,"completed shelf collision union retains rail anchor")
	check(layer.take_cues()==[{"id":"library_archived_rule_reveal_completed","payload":{"itemId":"archivedLeaveRule","revealSerial":layer.reveal_serial}}],"one source reveal completion cue with its runtime identity, no controller mutation")
	# State import / reentry must restore final prop pose without an animation replay.
	s=s.duplicate(true); layer.sync(s)
	check(layer.shelf_offset==16 and not layer.blocks_movement(),"save reload snaps acquired shelf to final position")
	s.native.scene="campus_bootstrap"; layer.sync(s); s.native.scene="library_interior"; layer.sync(s)
	check(layer.shelf_offset==16 and not layer.blocks_movement(),"scene reentry restores shelf pose")
	# Reduced mode preserves final pose and collision with source380ms timeline.
	s=fresh(); s.native.settings.reduced_motion=true; layer.sync(s); s.ui.libraryFinalsPuzzle.archivedRuleCollected=true; layer.sync(s)
	advance(139); check(layer.shelf_offset==0,"reduced shelf starts after140ms")
	advance(1); check(layer.shelf_offset==16 and layer.shelf_phase=="paper","reduced shelf preserves paper phase")
	advance(239); check(layer.blocks_movement(),"reduced paper still finishing")
	advance(1); check(not layer.blocks_movement() and layer.shelf_total_ms()==380,"reduced source timeline completes380ms")
	# Backpack removes baked pixels immediately and performs exact vector overlay.
	s=fresh(); layer.sync(s); s.ui.libraryFinalsPuzzle.backpackEvicted=true; layer.sync(s)
	check(layer.backpack_eviction_active() and not layer.blocks_movement() and layer.debug_snapshot().backpackClearPatch,"eviction clears baked bag; source free movement stays allowed")
	advance(35); check(is_equal_approx(layer.backpack_pose().position.x,1258.5),"linear half-shake position")
	advance(35); check(layer.backpack_pose().position.x==1262,"shake reaches+7px")
	advance(70); check(layer.backpack_pose().position.x==1255,"shake yoyos home")
	advance(1120); check(layer.backpack_pose().position==Vector2(1255,407),"nine source shake cycles finish1260ms")
	advance(1900); check(layer.backpack_pose().position==Vector2(1255,407) and layer.backpack_pose().alpha==1,"source1900ms transfer delay")
	advance(1); check(layer.backpack_pose().position==Vector2(334,634) and layer.backpack_pose().alpha==0,"source default Stepped transfers immediately after delay")
	advance(1198); check(layer.backpack_eviction_active(),"eviction completion still waits full1200ms tween")
	advance(1); check(not layer.backpack_eviction_active() and not layer.backpack_pose().visible,"eviction overlay retires4360ms")
	var broadcasts: Array=layer.take_cues()
	check(broadcasts.size()==4 and broadcasts[1].payload.text=="玩家：什么时候？" and broadcasts[2].payload.text=="书包：三分钟。","source world broadcast cues retain all four original lines")
	s=s.duplicate(true); layer.sync(s)
	check(layer.debug_snapshot().backpackClearPatch and not layer.backpack_pose().visible,"evicted save retains clear patch without duplicate bag")
	# Depth parity; source player's sorting key is y+120.
	check(layer._in_pass(330,{"player":Vector2(563,200)},true) and not layer._in_pass(330,{"player":Vector2(563,220)},true),"shelf occlusion crosses exact source player depth210")
	# Exact staff sprite, idle rhythm and reduced-motion pose.
	s=fresh(); layer.sync(s)
	check(layer.staff_art.get_size()==Vector2(192,128),"original two-frame staff sheet is loaded")
	check(layer.staff_pose().position==Vector2(334,632) and is_equal_approx(layer.staff_pose().scale,0.72),"staff source position/origin scale")
	advance(1670); check(layer.staff_pose().frame==1,"staff uses authored1.8fps frame sequence")
	advance(1200); check(layer.staff_pose().frame==0,"staff returns to frame0 before repeat delay")
	advance(1000); check(layer.staff_pose().frame==0,"staff holds during900ms repeat delay")
	s.ui.libraryFinalsPuzzle.lostFoundStage="scanning"; layer.sync(s); advance(120)
	check(layer.staff_pose().frame==1 and layer.staff_pose().position.y==635,"source receipt checking leans staff by3px")
	s.ui.libraryFinalsPuzzle.lostFoundStage="stamped"; s.ui.libraryFinalsPuzzle.nonPersonProofStamped=true; layer.sync(s); advance(120)
	check(layer.staff_pose().frame==1 and layer.staff_pose().position.y==636,"source stamp impact leans staff by4px")
	advance(690); check(layer.stamp_ms==-1 and layer.staff_pose().frame==0,"source810ms stamp returns to idle")
	s=fresh(); s.native.settings.reduced_motion=true; layer.sync(s); advance(2000)
	check(layer.staff_pose().frame==0 and layer.staff_pose().position==Vector2(334,632),"reduced motion staff remains still")
	await test_native_world_integration()
	if OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name()!="headless": await capture_gallery()
	print("Library world layers: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
func capture_gallery() -> void:
	var directory: String="res://.screenshots/library-world"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	root.size=Vector2i(960,540)
	var view:=Surface.new(); view.size=Vector2(960,540); view.layer=layer; root.add_child(view)
	for mode: String in ["shelf_idle","shelf_shake","shelf_shifted","shelf_paper","shelf_complete","shelf_actor_front","backpack_occupied","backpack_shaking","backpack_removed","front_desk_idle","front_desk_checking","front_desk_stamping"]:
		s=fresh(); view.state=s; layer.sync(s); view.center=Vector2(570,190); view.magnify=2.0; view.actor=Vector2(600,260)
		if mode.begins_with("shelf") and mode!="shelf_idle":
			s.ui.libraryFinalsPuzzle.archivedRuleCollected=true; layer.sync(s)
			advance(255 if mode=="shelf_shake" else 2105 if mode=="shelf_shifted" else 2300 if mode=="shelf_paper" else 3000)
		if mode=="shelf_actor_front": view.actor=Vector2(583,220)
		if mode.begins_with("backpack"):
			view.center=Vector2(1255,407); view.magnify=3.0; view.actor=Vector2(1320,500)
			if mode!="backpack_occupied": s.ui.libraryFinalsPuzzle.backpackEvicted=true; layer.sync(s); advance(350 if mode=="backpack_shaking" else 4360)
		if mode.begins_with("front_desk"):
			view.center=Vector2(334,587); view.magnify=2.4; view.actor=Vector2(440,680)
			if mode=="front_desk_checking": s.ui.libraryFinalsPuzzle.lostFoundStage="scanning"; layer.sync(s); advance(360)
			if mode=="front_desk_stamping": s.ui.libraryFinalsPuzzle.nonPersonProofStamped=true; s.ui.libraryFinalsPuzzle.lostFoundStage="stamped"; layer.sync(s); advance(120)
		view.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
		var path: String=directory+"/"+mode+".png"; root.get_texture().get_image().save_png(path); print("CAPTURE ",ProjectSettings.globalize_path(path))
	view.queue_free(); await process_frame

func test_native_world_integration() -> void:
	root.size=Vector2i(1440,900)
	var state: Node=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	state.d.native.chapter=2; state.d.native.scene="library_interior"; state.d.native.page="phone_home"; state.d.native.mode="light"
	state.d.rpgScene="library_interior"; state.d.runtimeMode="rpg"; state.d.ui.libraryFinalsPhase="evidence_gathering"
	state.d.items.callNumber755=true; state.d.ui.libraryFinalsPuzzle.callNumberCollected=true
	state.d.actOne.movementEnabled=true; state.d.actOne.controlsInstalled=true
	var shell: Control=load("res://scenes/main.tscn").instantiate(); root.add_child(shell)
	await process_frame; await process_frame
	var world: Control=shell.world; world.set_process(false)
	check(world.library_layers!=null and world.library_layers.shelf_offset==0,"live world initializes exact library layer")
	# Isolate the source cabinet footprint to demonstrate actual foot collision.
	var original: Array=world.collisions.duplicate(true)
	world.collisions=[{"id":"north_display_shelf","left":502,"top":108,"right":625,"bottom":234}]
	var right_of_initial:=Vector2(635,170)-PlayerMetrics.FOOT_CENTER_OFFSET
	check(world.can_stand(right_of_initial),"live collision initially permits point outside initial cabinet")
	state.act("lib_shelf"); await process_frame; await process_frame
	check(shell.world_frame.visible and not shell.phone.visible,"shelf keeps its source animation visible before opening the earned rule")
	check(world.library_layers.blocks_movement() and world._scene_presentation_blocks(),"successful controller shelf action locks native movement")
	world.touch_axis=Vector2.RIGHT; var prior: Vector2=world.player
	for i in range(200): world._process(0.01)
	check(world.player==prior and world.library_layers.shelf_offset==14,"world ticks animation while actual movement remains blocked")
	for i in range(100): world._process(0.01)
	check(world.library_layers.shelf_offset==16 and not world.library_layers.blocks_movement(),"live layer completes source motion")
	check(shell.phone.visible and not shell.world_frame.visible,"source reveal completion opens the existing reader")
	check(not world.can_stand(right_of_initial),"live collision uses expanded source rail/cabinet union")
	shell.phone_world_return.pressed.emit(); await process_frame; await process_frame
	check(shell.world_frame.visible and not world.library_layers.blocks_movement(),"reader return retains final cabinet without replay")
	world.touch_axis=Vector2.ZERO; world.collisions=original
	state.d.ui.libraryFinalsPhase="pass_ready"; state.d.ui.libraryFinalsPuzzle.evictionPassGenerated=true; state.d.ui.libraryFinalsPuzzle.passBriefingSeen=true; state.d.items.seatReleasePass=true
	state.act("lib_apply_pass"); await process_frame; await process_frame
	check(world.library_layers.backpack_eviction_active() and world.library_layers.debug_snapshot().backpackClearPatch,"live PASS starts baked-pixel replacement and dynamic backpack")
	for i in range(440): world._process(0.01)
	check(not world.library_layers.backpack_eviction_active() and world.library_layers.debug_snapshot().backpackClearPatch,"live completed eviction retains empty table")
	if is_instance_valid(shell.audio_director): await shell.audio_director.shutdown()
	if is_instance_valid(shell.media_host): await shell.media_host.shutdown()
	shell.queue_free(); await process_frame
