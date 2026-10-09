extends SceneTree
const Fixture=preload("res://tests/canteen_native_fixture.gd")
const Prop=preload("res://scripts/objects/canteen_scene_object.gd")
var checks:=0
var failures:=0
var shell:Control
var state:Node
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func frames(n:int=3)->void:
	for i in range(n):await process_frame
func pose(at:Vector2)->void:
	shell.world.player=at;shell.world._sync_player();shell.world._update_camera();shell.world.transition_alpha=0
	shell.world.native_canteen.configure_view(shell.world.size/2-shell.world.camera*shell.world.zoom,shell.world.zoom,at)
func shot(label:String)->void:
	var folder:=OS.get_environment("CANTEEN_LAYER_CAPTURE_DIR")
	if folder.is_empty():return
	DirAccess.make_dir_recursive_absolute(folder)
	shell.world.queue_redraw();await frames();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder.path_join(label+".png"))==OK,"native capture "+label)
func run()->void:
	state=root.get_node("State");Fixture.install(state)
	state.d.canteenHunt.carriedTrayIds=["tray_blue_01"];state.d.native.positions={"canteen_interior:":{"x":1470.0,"y":576.0}}
	root.size=Vector2i(390,844);root.position=Vector2i(32,56)
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(8);shell._show_world_mobile();await frames(3)
	shell.world.set_process(false);shell.world.zoom=.65;pose(Vector2(1470,576))
	var scene:Node2D=shell.world.native_canteen
	var subtitle:Control=shell.c3_narrative_host.view;var effects:Control=shell.c3_narrative_host.effects;var paper:Control=shell.c3_scene_host.paper
	check(subtitle.z_index==70 and effects.z_index==55 and paper.z_index==70,"existing original story views are leased above native world")
	var bounded:=true
	for prop:Node2D in scene.objects.values():
		for part:Dictionary in prop.parts:bounded=bounded and part.sprite.z_index>=0 and part.sprite.z_index<=50
	check(bounded and scene.get_node("CanteenInterface").z_index==60,"world parts and HUD stay below existing modal100 and toast110")
	# Exact source-depth ties inside one coarse z bucket stay in native sibling order.
	for at:Vector2 in [Vector2(755,208),Vector2(755,213),Vector2(230,357),Vector2(230,366)]:
		pose(at)
		var ordered:=true;var actor:Sprite2D=scene.player_sprite;var depth:float=actor.get_meta("source_depth")
		for prop:Node2D in scene.objects.values():
			for part:Dictionary in prop.parts:
				if Prop.draw_layer(part.depth)==actor.z_index and part.depth!=depth:ordered=ordered and ((part.draw_root.get_index()<actor.get_index())==(part.depth<depth))
		check(ordered,"native actor/furniture sibling depth remains exact at "+str(at))
	pose(Vector2(1470,576));state.act("c3_target:auntie")
	shell.c3_narrative_host.tick(650,true);await frames(3);pose(Vector2(1470,576))
	check(state.d.canteenHunt.returnedTrayIds.has("tray_blue_01") and subtitle.visible,"unchanged return action produces the existing readable story view")
	await shot("canteen-return-subtitle")
	for i in range(80):shell.c3_narrative_host.tick(100,true)
	state.d.canteenHunt.phase="menu_order";state.d.canteenHunt.promoDrinkPlaced=true;state.d.canteenHunt.queueGapOpened=true
	shell.world.refresh_world();pose(Vector2(755,250));state.act("c3_target:ordering_kiosk");await frames(3)
	check(is_instance_valid(shell.modal) and shell.modal.z_index==100 and shell.modal.z_index>subtitle.z_index,"original ordering modal remains above the scene and narrative views")
	await shot("canteen-menu-over-world")
	shell._close_modal();state.d.native.scene="campus_bootstrap";shell.world.world_key="";shell.world.refresh_world()
	check(subtitle.z_index==0 and effects.z_index==0 and paper.z_index==0 and scene.story_layer_leases.is_empty(),"leaving canteen restores all captured original z values")
	subtitle.z_index=17;effects.z_index=3;paper.z_index=5
	state.d.native.scene="canteen_interior";shell.world.world_key="";shell.world.refresh_world();pose(Vector2(755,250))
	check(subtitle.z_index==70 and effects.z_index==55 and paper.z_index==70,"reentry reacquires the same views without copying text")
	state.d.native.scene="campus_bootstrap";shell.world.world_key="";shell.world.refresh_world()
	check(subtitle.z_index==17 and effects.z_index==3 and paper.z_index==5,"exit restores prior nonzero layers rather than assuming defaults")
	var report:=OS.get_environment("CANTEEN_LAYER_REPORT")
	if not report.is_empty():
		var file:=FileAccess.open(report,FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"fixture":true},"\t"));file.close()
	print("CANTEEN_NATIVE_LAYERS ",checks," checks; ",failures," failures")
	await shell.shutdown();shell.queue_free();await frames();quit(1 if failures else 0)
