extends SceneTree
const REGION=preload("res://campuses/buct_changping/scripts/registered_hd_region.gd")
const NORTH_PROFILE="res://campuses/buct_changping/data/west_north_hd_region.json"
const SOUTH_PROFILE="res://campuses/buct_changping/data/west_south_hd_region.json"
var checks:=0
var failures:Array[String]=[]
var output:=""
var records:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func settle()->void:await process_frame;await physics_frame;await process_frame
func run()->void:
	output=OS.get_environment("BUCT_WEST_QA_DIR")
	if output.is_empty():output=ProjectSettings.globalize_path("user://west-hd-test")
	DirAccess.make_dir_recursive_absolute(output)
	var scene:PackedScene=load("res://campuses/buct_changping/scenes/playable.tscn")
	var campus=scene.instantiate();campus.enable_west_hd_regions=false;root.add_child(campus);await settle()
	check(campus.initialized,"Frozen predecessor scene initializes")
	campus.visitor.set_physics_process(false)
	var before:=snapshot(campus)
	var library=campus.library_layer
	var library_texture=library.body_texture
	var lake=campus.lake_surface
	var lake_material=lake.get("material")
	check(campus.set_west_hd_resident(true),"Atomic two-region production residency hook installs")
	await settle()
	check(snapshot(campus)==before,"All physics/navigation/source authority unchanged by west display pair")
	if campus.west_hd_regions.size()!=2:campus.queue_free();await settle();finish();return
	var nw=campus.west_hd_regions[0];var sw=campus.west_hd_regions[1]
	check(nw.profile.id=="west_north" and sw.profile.id=="west_south","Deterministic NW/SW group ordering")
	var body=nw.bodies.teaching_2
	check(nw.get_diagnostics().independent_bodies==1 and sw.get_diagnostics().independent_bodies==0,"One whole teaching body belongs to NW only")
	check(nw.world_shadow_nodes.size()==2 and sw.world_shadow_nodes.is_empty(),"Two whole schematic source-polygon shadows draw once")
	check(nw.foliage_nodes.is_empty() and sw.foliage_nodes.size()==3,"Only three bounded same-HD crowns near existing approach")
	check(campus.library_layer==library and library.body_texture==library_texture,"Installed whole library RGBA is reused by exact identity")
	var old=campus.objects.get_node("teaching_2")
	check(old.get_children().filter(func(n):return n is StaticBody2D).size()==3,"All three original teaching ground feet remain")
	check(not old.get_node("SourcePixelSilhouette").visible,"Old teaching source silhouette is retired")
	for i in range(1,5):check(not old.get_node("teaching_2_SourceShadowOrAnnex_%d"%i).visible,"Old teaching source annex retired %d"%i)
	for name in ["CleanUnderlay_teaching_2","CleanUnderlay_library","StaticSourceGroundShadows/teaching_2_GroundShadow_1","StaticSourceGroundShadows/library_GroundShadow_1"]:
		check(not campus.world.get_node(name).visible,"Old ground display owner hidden: "+name)
	check(campus.objects.get_node("library").get_children().filter(func(n):return n is CanvasItem and not n is CollisionObject2D).is_empty(),"No independent old source-RGB library foreground remains")
	check(nw.get_index()>sw.get_index() and sw.get_index()>campus.wenli_hd_region.get_index(),"Corner NW owner renders after SW and legacy east")
	check(nw.get_index()>campus.north_hd_region.get_index() and nw.get_index()<campus.objects.get_index(),"NW seam owner remains below objects")
	check(campus.set_west_hd_resident(true) and campus.west_hd_regions[0]==nw,"Residency hook is idempotent")
	check(lake.get_hd_rgb_diagnostics().active,"HD lake RGB installs with zero extra texture allocation")
	check(not lake.remove_hd_rgb(nw) and lake.get_hd_rgb_diagnostics().active,"Foreign region cannot remove SW water display input")
	sw.hide();await settle();check(not lake.get_hd_rgb_diagnostics().active,"Hidden SW restores original lake material inputs")
	sw.show();check(campus.set_west_hd_resident(true) and lake.get_hd_rgb_diagnostics().active,"Explicit visible residency reattaches HD RGB after hidden state")
	for id in ["wenli_building","north_sports_hall","main_building","library"]:
		campus.show_landmark(id);var progress=campus.visited.duplicate();campus.show_landmark("teaching_2")
		check(body.selected and not library.selected and not campus.first_teaching_layer.selected and not campus.wenli_layer.selected and not campus.north_hd_region.bodies.north_sports_hall.selected,"Old card to teaching2 clears all prior highlights: "+id)
		check(campus.visited==progress,"Teaching neutral card never adds visit progress: "+id)
		campus.show_landmark(id);check(not body.selected,"Teaching2 to prior card clears new highlight: "+id)
	campus.visited.clear();campus.progress.text="已探访 0 / 3";campus.show_landmark("teaching_2");campus.close_info()
	check(not body.selected and campus.visited.is_empty() and campus.info_id.is_empty(),"Esc/close clears teaching highlight and neutral visit remains0/3")
	body.hide();await settle();check(not nw.world_shadow_nodes[0].node.visible and nw.world_shadow_nodes[1].node.visible,"Teaching visibility controls only its own shadow");body.show()
	library.hide();await settle();check(nw.world_shadow_nodes[0].node.visible and not nw.world_shadow_nodes[1].node.visible,"Library visibility controls only its own shadow");library.show();await settle()
	records.append({"allocation_nw":nw.get_diagnostics(),"allocation_sw":sw.get_diagnostics(),"water":lake.get_hd_rgb_diagnostics(),"authority_snapshot":before})
	var teaching_ref=weakref(body);body=null
	campus.set_west_hd_resident(false);nw=null;sw=null;await settle()
	check(teaching_ref.get_ref()==null,"Uninstall releases whole teaching body")
	check(old.get_node("SourcePixelSilhouette").visible and campus.world.get_node("CleanUnderlay_teaching_2").visible,"Uninstall restores exact old teaching owners")
	check(not campus.world.get_node("CleanUnderlay_library").visible,"Uninstall preserves independent library underlay retirement")
	check(snapshot(campus)==before,"Residency removal retains exact old logical geometry")
	check(not lake.get_hd_rgb_diagnostics().active,"Explicit group unload restores original water RGB")
	# Reverse profile order still produces the same canonical group.
	var reverse=REGION.install_group(campus,[SOUTH_PROFILE,NORTH_PROFILE],{"precommit_validator":Callable(campus,"_west_hd_precommit")})
	check(reverse.size()==2 and reverse[0].profile.id=="west_north","Reverse installation order canonicalizes ownership")
	if reverse.size()==2:reverse[0].uninstall()
	reverse.clear();await settle()
	# A late preparation error cannot hide old sources or leak detached body nodes.
	var bad:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SOUTH_PROFILE));bad.shared_edges[0].rgba_sha256="bad"
	var badpath=output.path_join("invalid-west-south.json");var file=FileAccess.open(badpath,FileAccess.WRITE);file.store_string(JSON.stringify(bad));file.close()
	check(REGION.install_group(campus,[NORTH_PROFILE,badpath]).is_empty(),"Late bad shared strip rejects complete group")
	check(old.get_node("SourcePixelSilhouette").visible and not campus.world.has_node("RegisteredHDRegion_west_north"),"Failed preparation leaves source visible with no partial group")
	check(campus.set_west_hd_resident(true),"Pair reinstalls after all lifecycle checks");await settle()
	var doomed=campus.west_hd_regions[1];campus.world.remove_child(doomed);await settle()
	check(not campus.west_hd_regions[0].get_diagnostics().active,"Direct SW detach retires NW and body atomically")
	check(not lake.get_hd_rgb_diagnostics().active,"Direct SW detach also restores original water inputs")
	doomed.queue_free();campus.west_hd_regions.clear();await settle()
	check(snapshot(campus)==before,"Direct detach never removes source logical geometry")
	campus.queue_free();await settle()
	var production=scene.instantiate();root.add_child(production);await settle()
	check(production.west_hd_regions.size()==2 and production.west_hd_regions[0].get_diagnostics().active and production.lake_surface.get_hd_rgb_diagnostics().active,"Unmodified default production scene enables west pair and HD water without fixture override")
	production.queue_free();await settle();finish()
func snapshot(map:Node2D)->Dictionary:
	var physics:Array=[];collect(map,map,physics)
	return {"physics":REGION._sha(var_to_bytes(physics)),"physics_records":physics.size(),"walk_polys":REGION._sha(var_to_bytes(map.walk_polys)),"blockers":REGION._sha(var_to_bytes(map.blockers)),"source_data":REGION._sha(var_to_bytes(map.data)),"route_file":FileAccess.get_sha256("res://campuses/buct_changping/data/playable_route.json"),"layers_file":FileAccess.get_sha256("res://campuses/buct_changping/data/layers.json")}
func collect(map:Node,node:Node,result:Array)->void:
	if node is CollisionObject2D:result.append([str(map.get_path_to(node)),node.get_class(),node.collision_layer,node.collision_mask,node.global_transform])
	if node is CollisionPolygon2D:result.append([str(map.get_path_to(node)),node.polygon,node.global_transform,node.disabled])
	if node is CollisionShape2D:
		var shape:Variant=null
		if node.shape is CircleShape2D:shape=node.shape.radius
		elif node.shape is RectangleShape2D:shape=node.shape.size
		result.append([str(map.get_path_to(node)),shape,node.global_transform,node.disabled])
	for child in node.get_children():collect(map,child,result)
func finish()->void:
	var file=FileAccess.open(output.path_join("west-region-headless-result.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"records":records,"scope":"Headless lifecycle/ownership/navigation only; no visual acceptance"},"  "));file.close()
	print("BUCT_WEST_REGION checks=%d failures=%d"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
