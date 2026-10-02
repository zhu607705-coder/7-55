extends SceneTree
const Bridge=preload("res://scripts/ui/world_viewport_container.gd")
const Item=preload("res://scripts/ui/inventory_item.gd")
class LockHost extends Control:
	var world_view: Control
	var modal: Control
	var active_game: Control
	var phone_document: Control
	var world_effect: Control
	var c3_narrative_host: Control
	var c3_scene_host: Control
	var library_story_host: Control
class NarrativeLock extends Control:
	func blocks_input() -> bool:return true
	func blocks_movement() -> bool:return true
var state: Node
var host: Control
var bridge: SubViewportContainer
var viewport: SubViewport
var world: Control
var checks: Array=[]
var feedback: Array=[]
func _initialize() -> void: run.call_deferred()
func frames(count: int=3) -> void:
	for i in count: await process_frame
func check(ok: bool,id: String,detail: Variant=null) -> void:
	checks.append({"id":id,"passed":ok,"detail":detail})
	if not ok: push_error(id+": "+str(detail))
func screen(point: Vector2) -> Vector2:
	var local: Vector2=(point-world.camera)*world.zoom+world.size/2
	return bridge.get_global_transform_with_canvas()*(local*bridge.size/Vector2(viewport.size))
func motion(at: Vector2,mask: int=0,relative: Vector2=Vector2.ZERO) -> void:
	var event:=InputEventMouseMotion.new();event.position=at;event.global_position=at;event.button_mask=mask;event.relative=relative;Input.parse_input_event(event)
	await process_frame
func mouse(at: Vector2,down: bool,button: int=MOUSE_BUTTON_LEFT) -> void:
	var event:=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=button;event.pressed=down;Input.parse_input_event(event)
	await process_frame
func click(point: Vector2) -> void:
	var at: Vector2=screen(point);await motion(at);await mouse(at,true);await mouse(at,false);await frames()
func drag(item_id: String,point: Vector2) -> void:
	var item:=Item.new();item.item_id=item_id;item.text=item_id;item.position=Vector2(30,40);item.size=Vector2(110,50);root.add_child(item);await frames()
	var start: Vector2=item.get_global_rect().get_center();var end: Vector2=screen(point)
	await motion(start);await mouse(start,true)
	for i in range(1,10): await motion(start.lerp(end,i/9.0),MOUSE_BUTTON_MASK_LEFT,(end-start)/9)
	check(root.gui_is_dragging(),"native-drag-starts-"+item_id)
	await mouse(end,false);await frames();item.queue_free();await frames()
func redraw() -> void:
	world.queue_redraw();await frames()
func reset_scene(scene: String) -> void:
	state.d=state.initial();state.d.native.scene=scene;state.d.native.mode="light";state.d.native.chapter=4
	state.d.native.positions={};state.d.rpgCheckpoint="";world.world_key="";world.refresh_world();world.set_process(false)
	world.player=Vector2(650,700);world.camera=Vector2(836,470);world.zoom=.7;world.interactions.clear();feedback.clear()
	world.transition_alpha=0;world.presentation_actor_hidden=false
	await redraw()
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial();state.feedback.connect(func(text):feedback.append(text))
	root.size=Vector2i(1440,900)
	host=Control.new();host.position=Vector2(200,170);host.scale=Vector2(.85,.85);root.add_child(host)
	bridge=Bridge.new();bridge.size=Vector2(1100,618.75);bridge.stretch=true;host.add_child(bridge)
	viewport=SubViewport.new();viewport.size=Vector2i(960,540);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;bridge.add_child(viewport)
	world=load("res://tests/world_object_probe.gd").new();world.size=Vector2(960,540);viewport.add_child(world);bridge.world_surface=world;world.set_process(false);await frames(5)
	await reset_scene("campus_bootstrap")
	# Two opaque rendered objects overlap. Their y values deliberately put them
	# on opposite sides of the actor, opposing source-list order.
	var pixels:=Image.create(64,64,false,Image.FORMAT_RGBA8);pixels.fill(Color.WHITE)
	world.target_textures["res://tests/pick_fixture.png"]=ImageTexture.create_from_image(pixels)
	world.player=Vector2(836,460);world.camera=Vector2(836,470);world.zoom=1
	world.targets=[{"id":"front","position":[836,480],"art":"res://tests/pick_fixture.png","art_size":[100,100],"item":"campusCard","radius":200,"action":"noop"},{"id":"rear","position":[836,450],"art":"res://tests/pick_fixture.png","art_size":[100,100],"item":"fishingRod","radius":200,"action":"noop"}]
	state.d.items.campusCard=true;state.d.items.fishingRod=true
	await redraw();await click(Vector2(836,470))
	check(world.interactions==["front"],"click-selects-painted-front-not-first-radius",world.interactions)
	world.interactions.clear();var before: Dictionary=state.d.items.duplicate(true)
	await drag("fishingRod",Vector2(836,470))
	check(world.interactions.is_empty() and state.d.items==before,"wrong-item-never-redirects-to-compatible-hidden-target",world.interactions)
	await drag("campusCard",Vector2(836,470));check(world.interactions==["front"],"correct-item-same-object-as-click",world.interactions)
	# The exact half-open art edge has no old 32/36px center-radius disagreement.
	world.interactions.clear();await click(Vector2(885.9,510));check(world.interactions==["front"],"art-edge-click-49px-from-center",world.interactions)
	world.interactions.clear();await drag("campusCard",Vector2(885.9,510));check(world.interactions==["front"],"art-edge-drop-matches-click",world.interactions)
	world.interactions.clear();await click(Vector2(886.1,510));check(world.interactions.is_empty(),"art-outside-edge-is-not-target")
	# Actual wheel and right-drag input update the same camera/zoom transform.
	var original_zoom: float=world.zoom;await mouse(screen(Vector2(836,470)),true,MOUSE_BUTTON_WHEEL_UP);await mouse(screen(Vector2(836,470)),false,MOUSE_BUTTON_WHEEL_UP)
	check(world.zoom>original_zoom,"actual-wheel-zooms")
	await motion(screen(Vector2(836,470)),MOUSE_BUTTON_MASK_RIGHT,Vector2(31,-18));world._update_camera();await redraw()
	check(world.pan_offset.length()>1,"actual-right-drag-pans")
	world.interactions.clear();await click(Vector2(836,470));await drag("campusCard",Vector2(836,470))
	check(world.interactions==["front","front"],"zoom-pan-click-drop-retain-object",world.interactions)
	# A non-drop foreground object cannot dispatch an ordinary read action or
	# become transparent to a compatible inventory target behind it.
	world.targets[0].erase("item");world.interactions.clear();feedback.clear();await redraw()
	await drag("fishingRod",Vector2(836,470))
	check(world.interactions.is_empty(),"non-drop-front-object-blocks-hidden-compatible-drop",world.interactions)
	check(not feedback.is_empty() and str(feedback.back()).contains("没有落在"),"non-drop-object-produces-neutral-miss",feedback)
	await click(Vector2(836,470));check(world.interactions==["front"],"ordinary-click-on-non-drop-object-preserved",world.interactions)
	world.targets[0].item="campusCard";world.interactions.clear();feedback.clear();await redraw();await drag("fishingRod",Vector2(836,470))
	check(not feedback.is_empty() and str(feedback.back()).contains("不适合"),"eligible-object-wrong-item-produces-invalid-item",feedback)
	# Presentation/modal guards receive genuine pointer/drop input too.
	var lock_host:=LockHost.new();root.add_child(lock_host);world.host_node=lock_host
	lock_host.modal=Control.new();lock_host.add_child(lock_host.modal)
	world.interactions.clear();await click(Vector2(836,470));await drag("campusCard",Vector2(836,470))
	check(world.interactions.is_empty(),"modal-lock-prevents-click-and-inventory-drop")
	lock_host.modal.queue_free();await frames();lock_host.modal=null
	lock_host.c3_narrative_host=NarrativeLock.new();lock_host.add_child(lock_host.c3_narrative_host)
	await click(Vector2(836,470));await drag("campusCard",Vector2(836,470))
	check(world.interactions.is_empty(),"narrative-lock-prevents-click-and-inventory-drop")
	world.host_node=null;lock_host.queue_free();await frames()
	# Geometry only resolves the object. Existing interaction guards still decide
	# proximity and mode, without consuming either wrong or correct inventory.
	world.run_controller=true;world.player=Vector2(200,460);world.targets[0].radius=1;feedback.clear();await redraw()
	await drag("campusCard",Vector2(836,470))
	check(not feedback.is_empty() and str(feedback.back()).contains("太远"),"actual-drop-still-checks-proximity",feedback)
	world.targets[0].radius=1000;world.targets[0].mode="dark";feedback.clear();await redraw();await drag("campusCard",Vector2(836,470))
	check(not feedback.is_empty() and str(feedback.back()).contains("需要深色观察"),"actual-drop-still-checks-mode",feedback)
	check(state.d.items.campusCard and state.d.items.fishingRod,"rejected-drops-preserve-owned-items")
	world.run_controller=false;world.targets[0].erase("mode");world.player=Vector2(836,460);world.interactions.clear()
	# Transparent pixels in front reveal the actually visible underlying object.
	pixels.fill(Color.TRANSPARENT);pixels.fill_rect(Rect2i(0,0,16,64),Color.WHITE)
	world.target_textures["res://tests/transparent_fixture.png"]=ImageTexture.create_from_image(pixels)
	world.targets[0].art="res://tests/transparent_fixture.png";await redraw()
	world.interactions.clear();await click(Vector2(836,470));check(world.interactions==["rear"],"transparent-sprite-pixels-do-not-steal-pick",world.interactions)
	await reset_scene("dorm_hub")
	state.d.actOne.dormHubUnlocked=true;state.d.actOne.phase="inventory_required";world.targets=state.get_targets("dorm_hub");world.camera=Vector2(580,425);world.zoom=1.1;world.player=Vector2(570,460)
	await redraw();await click(Vector2(611,492));check(world.interactions==["desk_03"],"dorm-source-bounds-half-scale-and-offset",world.interactions)
	world.interactions.clear();await drag("campusCard",Vector2(611,492));check(world.interactions.is_empty(),"dorm-non-drop-desk-rejects-inventory",world.interactions)
	await reset_scene("library_interior")
	state.d.native.chapter=2;state.d.actOne.phase="complete";state.d.actOne.libraryEntered=true;state.d.ui.libraryFinalsPuzzle.itemReportGenerated=true
	# Source target construction below isolates service geometry from unrelated
	# story sessions; production controller gates are tested separately.
	var module=load("res://scripts/chapters/library022.gd").new()
	world.targets=[module._target("front_desk","staff",[334,594],[174,519,320,150],64,"lib_front_desk"),module._target("identity_machine","service",[334,594],[174,519,320,150],64,"lib_scan","itemRecognitionReport")]
	world.library_layers.sync(state.d,true);world.player=Vector2(400,700);world.camera=Vector2(334,590);world.zoom=1;await redraw()
	await click(Vector2(334,549));check(world.interactions==["front_desk"],"library-staff-head-owned-by-visible-staff",world.interactions)
	world.interactions.clear();await click(Vector2(300,608));check(world.interactions==["identity_machine"],"library-service-owned-by-stamp-zone",world.interactions)
	world.interactions.clear();await drag("campusCard",Vector2(300,608));check(world.interactions.is_empty(),"library-wrong-item-cannot-fall-through-to-staff")
	state.d.ui.libraryFinalsPuzzle.backpackInspected=true;state.d.ui.libraryFinalsPuzzle.occupancyNoteCollected=false
	world.targets=[module._target("backpack_pass","bag",[1255,407],[1237,375,36,64],100,"lib_apply_pass","seatReleasePass"),module._target("occupancy_note","note",[1282,422],[1261,406,42,32],80,"lib_note")]
	world.library_layers.sync(state.d,true);world.player=Vector2(1280,520);world.camera=Vector2(1282,422);world.interactions.clear();await redraw()
	await click(Vector2(1265,415));check(world.interactions==["occupancy_note"],"library-note-painted-over-backpack-is-picked",world.interactions)
	state.d.items.seatReleasePass=true;world.interactions.clear();await drag("seatReleasePass",Vector2(1265,415))
	check(world.interactions.is_empty(),"library-note-blocks-compatible-backpack-behind-it")
	await reset_scene("theater_interior")
	state.d.native.chapter=3;state.d.theaterHunt.active=true;state.d.theaterHunt.phase="program_search";state.d.theaterHunt.admitted=true
	world.targets=state.get_targets("theater_interior");world.chapter3_layers.sync(state.d,true);world.player=Vector2(568,455);world.camera=Vector2(568,405);world.zoom=1
	await redraw();await click(Vector2(568,405));check(world.interactions==["theater_program_opening"],"c3-layer-owned-program-picks-current-art",world.interactions)
	await reset_scene("qizhen_lake")
	state.d.native.chapter=3;state.d.qizhenLake.active=true;state.d.qizhenLake.zone="open_water";state.d.qizhenLake.vehicle="kayak";state.d.qizhenLake.phase="tool_chain"
	world.targets=state.get_targets("qizhen_lake");world.player=Vector2(1040,720);world.camera=Vector2(1040,620);world.zoom=1;await redraw()
	# Pick an opaque pixel shared by the current authored water surfaces.
	var lake_point:=Vector2.INF
	for y in range(580,661):
		for x in range(960,1121):
			if world._pick_target(Vector2(x,y)).get("id","")=="qizhen_fishing_item_1":lake_point=Vector2(x,y);break
		if lake_point.is_finite():break
	check(lake_point.is_finite(),"lake-light-visible-operation-surface-exists")
	if lake_point.is_finite():
		await click(lake_point);await drag("fishingRod",lake_point)
		check(world.interactions==["qizhen_fishing_item_1","qizhen_fishing_item_1"],"coincident-lake-light-click-drop-match",world.interactions)
	state.d.native.mode="dark";world.targets=state.get_targets("qizhen_lake");await redraw();world.interactions.clear()
	var dark_point:=Vector2.INF
	for y in range(580,661):
		for x in range(960,1121):
			if world._pick_target(Vector2(x,y)).get("id","")=="qizhen_reflection_item_1":dark_point=Vector2(x,y);break
		if dark_point.is_finite():break
	check(dark_point.is_finite(),"lake-dark-visible-reflection-surface-exists")
	if dark_point.is_finite():await click(dark_point);check(world.interactions==["qizhen_reflection_item_1"],"coincident-lake-dark-click-observes",world.interactions)
	await reset_scene("duan_yongping_temporal_maze")
	state.d.chapter4.prologueSeen=true;state.d.chapter4.phase="morning_checkin";state.d.chapter4.floor="A1";state.d.chapter4.timeState="0755_morning";state.d.chapter4.mode="light"
	world.targets=state.get_targets(world.scene_id);world.player=Vector2(836,790);world.camera=Vector2(836,740);world.zoom=1;await redraw()
	var reader: Dictionary={}
	for target: Dictionary in world.targets:
		if target.id=="a1_campus_card_reader":reader=target
	check(not reader.is_empty(),"c4-current-reader-target-exists")
	if not reader.is_empty():
		await click(Vector2(reader.position[0],reader.position[1]));check(world.interactions==["a1_campus_card_reader"],"c4-authored-reader-picks-visible-installation",world.interactions)
	# Authored multi-item lake workbench keeps its original acceptance list.
	var source: Dictionary=load("res://scripts/chapters/c3_base.gd").new().from_source({"id":"bench","label":"bench","x":836,"y":740,"width":80,"height":60,"acceptedItems":["nylonCord","fishingRod"]},"noop")
	world.targets=[source];world.interactions.clear();await redraw();await drag("fishingRod",Vector2(836,740))
	check(world.interactions==["bench"],"source-multi-item-drop-route-preserved",world.interactions)
	world.interactions.clear();await drag("campusCard",Vector2(836,740));check(world.interactions.is_empty(),"multi-item-list-rejects-wrong-item")
	world.capture_mode=true;world.interactions.clear();await click(world.player);await drag("campusCard",world.player);check(world.interactions.is_empty(),"capture-lock-prevents-click-and-drop")
	world.capture_mode=false
	host.queue_free();await frames()
	var failed: Array=checks.filter(func(row):return not row.passed)
	var file:=FileAccess.open("user://world-object-picking.json",FileAccess.WRITE);file.store_string(JSON.stringify({"kind":"real-input-subviewport","checks":checks},"\t"));file.close()
	print("WORLD_OBJECT_PICKING: %d checks; %d failures"%[checks.size(),failed.size()]);quit(1 if not failed.is_empty() else 0)
