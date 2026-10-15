extends SceneTree
## Real controller/world checks, with explicitly seeded prerequisite fixtures.
var state: Node
var shell: Control
var world: Control
var failures:=0
var checks:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("DORM OBJECT: "+label)
func frames(n:=3) -> void:
	for i in n:await process_frame
func fixture(checkpoint: String,dim:=Vector2i(1180,812)) -> void:
	if is_instance_valid(shell):await shell.shutdown();shell.free();await frames()
	check(state.begin_checkpoint(checkpoint),"source checkpoint loads "+checkpoint)
	root.size=dim
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell._show_world_mobile();shell._layout();await frames()
	world=shell.world;world.set_process(false);world.native_dorm.set_process(false);world.refresh_world();world._update_camera()
	world.native_dorm.sync(state.d,world.scene_id);world.native_dorm.configure_view(world.size/2-world.camera*world.zoom,world.zoom)
func target(id: String) -> Dictionary:
	for value: Dictionary in world.targets:
		if value.id==id:return value
	return {}
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	state=root.get_node("State")
	for dim: Vector2i in [Vector2i(1180,812),Vector2i(390,844)]:
		await fixture("c2-inventory",dim)
		check(world.native_dorm.snapshot().card_visible,"physical source campus card appears "+str(dim))
		check(world.native_dorm.source_space.get_child_count()==4,"independent native object nodes exist")
		check(world._distance(target("desk_03"))<=71,"original edge-proximity allows pickup before controls")
		var frozen: Vector2=world.player
		world.touch_axis=Vector2.RIGHT;world._process(.03);world.touch_axis=Vector2.ZERO
		check(world.player==frozen and not state.d.actOne.manualControlTested,"touch cannot bypass movement prerequisites")
		world._try_interact(target("desk_03"))
		check(state.d.items.campusCard and state.d.actOne.inventoryRecovered and state.d.actOne.phase=="system_return_required","original pickup commits immediately")
		check(shell.compact_inventory_open and shell.inventory_dock.visible,"source inventory restore opens the actual bag immediately")
		check(world.native_dorm.snapshot().card_tail,"accepted pickup starts read-only tail")
		check(not world.native_dorm.snapshot().card_visible,"physical card is removed immediately")
		var age: float=world.native_dorm.card_age
		state.act("c2_recover_card")
		check(world.native_dorm.card_age==age,"repeated pickup never restarts acquisition")
		world.native_dorm._process(.2)
		check(state.d.actOne.phase=="system_return_required","animation has no progression authority")
		world.native_dorm._process(.3)
		check(not world.native_dorm.fly_card.visible,"pickup tail ends at 460ms")
		state.act("c2_dorm_prop","cabinet_open");world.native_dorm.sync(state.d,world.scene_id);world.native_dorm._process(.3)
		check(world.native_dorm.cabinet_amount==1,"cabinet physically opens")
		state.act("c2_dorm_prop","cabinet_open");world.native_dorm._process(.3)
		check(world.native_dorm.cabinet_amount==0,"cabinet returns exactly closed")
		var before_position: Vector2=world.player
		world.player=Vector2(489,232);world._process(.001)
		check(world.nearby.get("id")=="window_cabinet","keyboard proximity prioritizes cabinet over always-near actor")
		world.player=before_position
		state.act("c2_dorm_prop","lamp_03_on");world.native_dorm._process(.3)
		check(world.native_dorm.lamp_amount==Vector2(0,1),"personal desk lamp is independent")
		var items_before:=JSON.stringify(state.d.items)
		state.act("c2_dorm_prop","invalid")
		check(JSON.stringify(state.d.items)==items_before,"optional furniture grants no items")
		world.player=Vector2(480,700);world._sync_player();world._update_camera();world.native_dorm.configure_view(world.size/2-world.camera*world.zoom,world.zoom)
		world._try_interact(target("exit_door"))
		check(state.d.native.scene=="dorm_hub" and world.native_dorm.snapshot().door_rejection,"locked door resists without travel")
		world.native_dorm._process(.19)
		check(not world.native_dorm.snapshot().door_rejection,"rejection returns exactly at 180ms")
		state.developer_mode=false
		check(state.save_game(),"ordinary accepted card/furniture save succeeds")
		state.d=state.initial();check(state.load_game(),"ordinary accepted card/furniture reload succeeds")
		world.refresh_world();world.native_dorm.sync(state.d,world.scene_id)
		check(state.d.items.campusCard and not world.native_dorm.snapshot().card_visible and not world.native_dorm.snapshot().card_tail,"reload cannot replay or duplicate card")
		check(state.d.native.dorm_props.lamp_03_on,"optional stable prop state survives reload")
		await fixture("c2-dorm-exit",dim)
		world.player=Vector2(480,700);world._sync_player();world._update_camera();world.native_dorm.configure_view(world.size/2-world.camera*world.zoom,world.zoom)
		world._process(.001)
		check(world.nearby.get("id")=="exit_door","keyboard proximity prioritizes earned door over actor")
		world._try_interact()
		check(state.d.native.scene=="campus_bootstrap" and state.d.actOne.phase=="complete","exit controller commits campus in input frame")
		check(world.native_dorm.snapshot().exit_tail,"successful old-door tail is visible over campus")
		check(world.native_dorm.exit_clip.clip_contents and world.native_dorm.exit_clip.size.y>0 and world.native_dorm.door_tail.get_parent()==world.native_dorm.exit_clip,"old-door copy is clipped away from world HUD and bag")
		check(state.d.rpgCheckpoint=="campus_spawn","original campus spawn remains authoritative")
		world.refresh_world();world._update_camera();world.native_dorm._process(.02)
		var current_hud: Dictionary=world.hud_metrics(world._hud_line())
		var bottom: Vector2=world.native_dorm._root_point(Vector2(0,world.size.y-current_hud.body_height-current_hud.body_gap))
		check(world.native_dorm.exit_clip.get_global_rect().end.y<=bottom.y+.01,"exit copy also stays above the taller campus arrival subtitle")
		var press:=InputEventKey.new();press.keycode=KEY_D;press.pressed=true;world.native_dorm.observe_input(press)
		check(not world.native_dorm.snapshot().exit_tail,"new movement input immediately dismisses read-only tail")
		state.developer_mode=false;check(state.save_game(),"ordinary exit save succeeds")
		state.d=state.initial();check(state.load_game(),"ordinary campus reload succeeds")
		world.refresh_world();world.native_dorm.sync(state.d,world.scene_id)
		check(state.d.native.scene=="campus_bootstrap" and not world.native_dorm.snapshot().exit_tail,"reload restores campus without exit replay")
	await fixture("c2-manual-movement")
	var prerequisites: Dictionary=state.d.duplicate(true)
	state.d.actOne.characterNamed=false;state.act("c2_use_gamepad")
	check(not state.d.actOne.controlsInstalled and state.d.items.gamepad,"unnamed actor rejects the gamepad")
	state.d=prerequisites.duplicate(true);state.d.actOne.exerciseStarted=false;state.act("c2_use_gamepad")
	check(not state.d.actOne.controlsInstalled and state.d.items.gamepad,"no exercise record rejects the gamepad")
	state.d=prerequisites;world.refresh_world();state.act("c2_use_gamepad")
	check(state.d.actOne.controlsInstalled and state.d.actOne.movementEnabled and not state.d.items.gamepad,"controller alone consumes gamepad and enables manual control")
	check(not state.d.actOne.manualControlTested,"connection does not fake first movement")
	# Source exercise pacing uses wall-clock time before connection. Restore the
	# declared checkpoint spawn so a single input cannot begin beside furniture.
	world.player=Vector2(480,720);world._sync_player()
	var keyboard_start: Vector2=world.player
	check(world.can_stand(keyboard_start) and world.can_stand(keyboard_start+Vector2(4.8,0)),"keyboard fixture and intended step are walkable")
	world.grab_focus()
	var movement:=InputEventKey.new();movement.keycode=KEY_D;movement.physical_keycode=KEY_D;movement.pressed=true
	Input.parse_input_event(movement);Input.flush_buffered_events();world._process(.03)
	var release: InputEventKey=movement.duplicate();release.pressed=false;Input.parse_input_event(release);Input.flush_buffered_events()
	check(world.player.x>keyboard_start.x and is_equal_approx(world.player.y,keyboard_start.y),"actual keyboard input moves right from the declared fixture")
	check(state.d.actOne.manualControlTested and state.d.actOne.phase=="reservation_briefing_required","actual keyboard displacement advances only first-movement fact")
	check(not state.d.actOne.canLeaveDorm,"manual movement still requires original reservation")
	state.act("c2_dorm_exit");check(state.d.native.scene=="dorm_hub","movement alone cannot bypass reservation")
	await fixture("c2-manual-movement",Vector2i(390,844));state.act("c2_use_gamepad")
	world.player=Vector2(480,720);world._sync_player()
	var touch_start: Vector2=world.player
	check(world.can_stand(touch_start) and world.can_stand(touch_start+Vector2(-4.8,0)),"touch fixture and intended step are walkable")
	world.touch_axis=Vector2.LEFT;world._process(.03);world.touch_axis=Vector2.ZERO
	check(world.player.x<touch_start.x and is_equal_approx(world.player.y,touch_start.y),"shared touch input moves left from the declared fixture")
	check(state.d.actOne.manualControlTested,"shared touch movement path earns first-step fact")
	await fixture("c2-inventory")
	state.d.native.settings.reduced_motion=true;world.native_dorm.sync(state.d,world.scene_id)
	world._try_interact(target("desk_03"));world.native_dorm._process(.2)
	check(world.native_dorm.fly_card.position==world.native_dorm.card_start,"reduced motion retains pickup source position")
	shell._show_phone_surface();world.native_dorm._process(.01)
	check(not world.native_dorm.fly_card.visible,"phone switch clears pending copy")
	await fixture("c2-inventory")
	world._try_interact(target("desk_03"))
	world.native_dorm.sync(state.d,"library_interior")
	check(not world.native_dorm.fly_card.visible and not world.native_dorm.snapshot().card_tail,"scene change immediately hides root-level card copy")
	await fixture("c2-dorm-exit")
	world.player=Vector2(480,700);world._sync_player();world._try_interact(target("exit_door"))
	check(world.native_dorm.door_tail.visible,"scene-cancel fixture begins with a live door tail")
	world.native_dorm.sync(state.d,"library_interior")
	check(not world.native_dorm.door_tail.visible and not world.native_dorm.snapshot().exit_tail,"different destination immediately hides root-level door copy")
	var minimal_settings: Dictionary=state.d.duplicate(true)
	minimal_settings.native.settings={}
	world.native_dorm.sync(minimal_settings,"duan_yongping_temporal_maze")
	check(not world.native_dorm.active and not world.native_dorm.reduced,"inactive adapter tolerates source fixtures without reduced-motion settings")
	check(state.d.native.settings.has("reduced_motion"),"fallback read does not mutate shared settings")
	await shell.shutdown();shell.free();await frames()
	print("DORM OBJECTS: %d checks / %d failures" % [checks,failures]);quit(1 if failures else 0)
