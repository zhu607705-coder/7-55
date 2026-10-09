extends SceneTree
## Controlled renderer/geometry fixture, not an earned chapter traversal.
const Fixture=preload("res://tests/canteen_native_fixture.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
const Prop=preload("res://scripts/objects/canteen_scene_object.gd")
var checks:=0
var failures:=0
var world:Control
var metrics:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func pose(point:Vector2)->void:
	world.player=point;world._sync_player();world.transition_alpha=0
	world.camera=point;world.zoom=2.2
	world.native_canteen.configure_view(world.size/2-world.camera*world.zoom,world.zoom,point)
func verify_partition(prop:Node2D)->void:
	var next:float=prop.source_region.position.y
	for part:Dictionary in prop.parts:
		check(part.region.position.y==next and part.region.size.y>0,"source rows are an exact non-overlapping partition: "+prop.object_id)
		check(part.sprite.modulate.a==1,"solid pixels never become a translucent duplicate: "+prop.object_id)
		next=part.region.end.y
	check(next==prop.source_region.end.y,"source partition preserves every original row: "+prop.object_id)
func precedes(a:Dictionary,b:Dictionary)->bool:
	if a.canvas_z!=b.canvas_z:return a.canvas_z<b.canvas_z
	return a.root_order<b.root_order
func actor_order(scene:Node2D,actor:Dictionary)->void:
	for prop:Node2D in scene.objects.values():
		for surface:Dictionary in prop.surfaces():
			if surface.depth==actor.depth:continue
			check(precedes(surface,actor)==(surface.depth<actor.depth),"exact foot-plane order: "+prop.object_id)
func verify_trays(scene:Node2D)->void:
	for target:Dictionary in world.targets:
		var id:String=str(target.id)
		if not id.begins_with("tray_"):continue
		var geometry:Dictionary=scene.target_geometry(id);var found:=false
		if not geometry.is_empty():
			for yy in range(1,6):
				for xx in range(1,6):
					var at:Vector2=geometry.transform*(geometry.rect.position+geometry.rect.size*Vector2(xx/6.0,yy/6.0))
					if world._pick_target(at).get("id","")==id:found=true
		check(found,"resting tray remains visible and selectable above its table "+id+" at "+str(target.position))
func capture(label:String)->void:
	var folder:=OS.get_environment("CANTEEN_OCCLUSION_CAPTURE_DIR")
	if folder.is_empty():return
	DirAccess.make_dir_recursive_absolute(folder);world.queue_redraw()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder.path_join(label+".png"))==OK,"capture "+label)
func run()->void:
	var state:Node=root.get_node("State");Fixture.install(state)
	world=load("res://scripts/world.gd").new();root.size=Vector2i(1280,800);world.size=root.size;root.add_child(world);await process_frame;world.set_process(false)
	var scene:Node2D=world.native_canteen
	var original:Dictionary=state.d.duplicate(true)
	# First-row empty table: rear, front and both side aisles are real standable
	# positions. Tests cross the ground-depth plane alongside, never through it.
	for point:Vector2 in [Vector2(675,273),Vector2(675,390),Vector2(616,325),Vector2(743,325),Vector2(616,360),Vector2(616,370)]:
		pose(point)
		check(world.can_stand(point),"fixture pose is physically clear "+str(point))
		verify_partition(scene.objects.dining_1_4_table);verify_partition(scene.objects.dining_1_4_bench_left)
		actor_order(scene,{"depth":scene.player_sprite.get_meta("source_depth"),"canvas_z":scene.player_sprite.z_index,"root_order":scene.player_sprite.get_index()})
	pose(Vector2(616,325));await capture("wide-table-side")
	pose(Vector2(675,273));await capture("wide-table-behind")
	pose(Vector2(675,390));await capture("wide-table-front")
	# Exercise every authored spawn slot, not just the twelve current trays.
	var saved_slots:Array=state.d.native.c3_tray_slots.duplicate(true)
	var slots:Array=world.worlds.canteen_interior.constants.CANTEEN_TRAY_SLOTS
	for offset in range(0,slots.size(),12):
		var batch:Array=[]
		for i in range(12):batch.append(slots[(offset+i)%slots.size()])
		state.d.native.c3_tray_slots=batch;world.refresh_world();pose(Vector2(616,325))
		verify_trays(scene)
	state.d.native.c3_tray_slots=saved_slots;world.refresh_world();pose(Vector2(616,325))
	# A player and two distinct seated NPC planes can overlap one tabletop. The
	# pure partition must be deterministic when actor enumeration changes.
	var table:Node2D=scene.objects.dining_1_2_table
	var actors:Array=[{"depth":360.0,"rect":table.geometry().rect},{"depth":377.0,"rect":table.geometry().rect},{"depth":389.0,"rect":table.geometry().rect}]
	var forward:Array=table.depth_slices(actors);actors.reverse()
	check(forward==table.depth_slices(actors),"three simultaneous actor planes have stable slices")
	check(forward.size()==5,"three actor boundaries need only four top pieces plus the front")
	pose(Vector2(445,343))
	for surface:Dictionary in scene.entity_surfaces:
		if scene._is_grounded_actor(str(surface.node.name)):
			check(float(surface.depth)==float(surface.node.get_meta("source_depth")),"NPC depth remains its authored bottom anchor")
			actor_order(scene,{"depth":surface.depth,"canvas_z":surface.node.z_index,"root_order":surface.node.get_index()})
	await capture("wide-seated-npc")
	for id:String in ["west_mat","southeast_mat"]:
		check(scene.objects[id].parts[0].depth==0 and scene.objects[id].parts[0].sprite.z_index==0,"door mat remains on the floor "+id)
	for id:String in ["dish_return","tray_station","drink_shelf","side_cabinet","mixer_counter","south_counter"]:
		var prop:Node2D=scene.objects[id]
		check(prop.parts.size()==1 and prop.parts[0].depth==prop.sort_depth,"upright cabinet sorts at its physical floor contact "+id)
	for id:String in ["return_stack","shelf_sign","south_menu"]:
		var prop:Node2D=scene.objects[id];var support:Node2D=scene.objects[prop.definition.supported_by]
		check(prop.sort_depth>support.sort_depth,"supported object stays above its own counter "+id)
	pose(Vector2(1422,270));await capture("wide-cabinet-behind")
	pose(Vector2(1422,355));await capture("wide-cabinet-front")
	pose(Vector2(1349,865));await capture("wide-door-mat")
	root.size=Vector2i(390,844);world.size=root.size;pose(Vector2(616,325));await capture("portrait-table-side")
	var static_updates:Dictionary={}
	for prop:Node2D in scene.objects.values():static_updates[prop.object_id]=prop.slice_updates
	var warm_nodes:int=get_node_count()
	for i in range(20):pose(Vector2(616,325))
	for prop:Node2D in scene.objects.values():check(prop.slice_updates==static_updates[prop.object_id],"stationary actors do not rebuild slices "+prop.object_id)
	check(get_node_count()==warm_nodes,"stationary view never allocates painter nodes")
	var distant_updates:int=scene.objects.dining_3_7_table.slice_updates
	pose(Vector2(616,330))
	check(scene.objects.dining_3_7_table.slice_updates==distant_updates,"movement only updates overlapping furniture")
	var total_parts:=0;var pool_parts:=0
	for prop:Node2D in scene.objects.values():total_parts+=prop.parts.size();pool_parts+=prop.part_pool.size()
	var started:int=Time.get_ticks_usec()
	for i in range(120):pose(Vector2(616,300+float(i%80)))
	var duration:int=Time.get_ticks_usec()-started
	var warmed_pool:=0
	for prop:Node2D in scene.objects.values():warmed_pool+=prop.part_pool.size()
	for i in range(80):pose(Vector2(616,300+float(i)))
	var repeated_pool:=0
	for prop:Node2D in scene.objects.values():repeated_pool+=prop.part_pool.size()
	check(repeated_pool==warmed_pool,"repeating a walk reuses every existing surface node")
	metrics.append({"configure_view_120_us":duration,"parts":total_parts,"pooled_parts":pool_parts,"nodes":get_node_count(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
	check(pool_parts<340,"adaptive slices remain bounded; no fixed per-pixel node grid")
	check(state.d.canteenHunt==original.canteenHunt and state.d.items==original.items,"render sorting cannot change story or inventory")
	# A prop's painter siblings must be cleaned up even if only that prop is
	# removed, not just when the complete World scene goes away.
	var holder:=Node2D.new();root.add_child(holder)
	var disposable:=Prop.new();holder.add_child(disposable)
	disposable.configure(table.definition,table.asset,table.texture);disposable.attach_surfaces(holder)
	var painter_refs:Array=[]
	for part:Dictionary in disposable.parts:painter_refs.append(weakref(part.draw_root))
	disposable.queue_free();await process_frame;await process_frame
	for ref:WeakRef in painter_refs:check(ref.get_ref()==null,"removing one prop retires its painter siblings")
	holder.queue_free();await process_frame
	var report:=OS.get_environment("CANTEEN_OCCLUSION_REPORT")
	if not report.is_empty():
		var file:=FileAccess.open(report,FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"fixture":true,"metrics":metrics},"\t"));file.close()
	print("CANTEEN_FOOT_OCCLUSION ",checks," checks; ",failures," failures ",metrics)
	world.queue_free();await process_frame;quit(1 if failures else 0)
