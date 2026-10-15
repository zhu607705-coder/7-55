extends SceneTree
## Real accepted predecessor scene + real candidate assets, headless ownership only.
## Requires BUCT_V4_QA_DIR as an absolute external output directory. No user:// writes.
## This file was authored but not executed by its worker. It is not GPU acceptance.
const REGION=preload("res://campuses/buct_changping/scripts/registered_hd_region.gd")
const V4=preload("res://campuses/buct_changping/scripts/registered_hd_north_large.gd")
const CANDIDATE="res://campuses/buct_changping/data/north_large_hd_region.json"
const EAST_PROFILE="res://campuses/buct_changping/data/north_hd_region.json"
class BudgetBlocker extends Node2D:
	var layer_bytes:=0
	func get_diagnostics() -> Dictionary:
		return {"active":true,"new_gpu_texture_bytes":layer_bytes}
var checks:=0
var failures: Array[String]=[]
var records: Array=[]
var output:=""
var fixture_serial:=0
var _external_output_ready:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func settle() -> void:
	await process_frame;await physics_frame;await process_frame
func fixture(data: Dictionary,label: String) -> String:
	fixture_serial+=1
	var file_path=output.path_join("fixture-%02d-%s.json"%[fixture_serial,label])
	var file=FileAccess.open(file_path,FileAccess.WRITE)
	if file==null:check(false,"External fixture is writable: "+label);return ""
	file.store_string(JSON.stringify(data));file.close();return file_path
func owner_visuals(map: Node2D) -> Array:
	var result: Array=[]
	for id in V4.BODY_OWNER_IDS:
		var node: Node=map.objects.get_node_or_null(id)
		if node==null:result.append([id,null]);continue
		result.append([id,node.get_instance_id(),node.position])
		for child in node.get_children():
			if child is CanvasItem:result.append([id,str(child.name),child.get_instance_id(),child.visible,child.position])
		var underlay: Node=map.world.get_node_or_null("CleanUnderlay_"+str(id))
		if underlay is CanvasItem:result.append(["underlay",id,underlay.get_instance_id(),underlay.visible])
	return result
func guard(lower: Node2D) -> bool:
	return lower!=null and is_instance_valid(lower) and is_instance_valid(lower.ground_sprite) and lower.ground_sprite.material is ShaderMaterial and lower.ground_sprite.material.get_shader_parameter("external_top_owner_active")==true
func display_identity(map: Node2D) -> Dictionary:
	var world_ids: Array=[];var object_ids: Array=[]
	for child in map.world.get_children():world_ids.append([str(child.name),child.get_instance_id()])
	for child in map.objects.get_children():object_ids.append([str(child.name),child.get_instance_id()])
	return {"source_id":map.SOURCE.get_instance_id(),"world_ids":world_ids,"object_ids":object_ids,"original_body_visuals":owner_visuals(map),"west_guard":guard(map.west_hd_regions[0]) if map.west_hd_regions.size()==2 else false,"east_guard":guard(map.north_hd_region)}
func collect(map: Node,node: Node,result: Array) -> void:
	if node is CollisionObject2D:result.append([str(map.get_path_to(node)),node.get_class(),node.collision_layer,node.collision_mask,node.global_transform])
	if node is CollisionPolygon2D:result.append([str(map.get_path_to(node)),node.polygon,node.global_transform,node.disabled])
	if node is CollisionShape2D:
		var shape: Variant=null
		if node.shape is CircleShape2D:shape=node.shape.radius
		elif node.shape is RectangleShape2D:shape=node.shape.size
		result.append([str(map.get_path_to(node)),shape,node.global_transform,node.disabled])
	for child in node.get_children():collect(map,child,result)
func authority(map: Node2D) -> Dictionary:
	var physics: Array=[];collect(map,map,physics)
	return {"physics":REGION._sha(var_to_bytes(physics)),"physics_records":physics.size(),"walk_polys":REGION._sha(var_to_bytes(map.walk_polys)),"blockers":REGION._sha(var_to_bytes(map.blockers)),"source_data":REGION._sha(var_to_bytes(map.data)),"source_png":FileAccess.get_sha256(V4.SOURCE_ASSET),"route_file":FileAccess.get_sha256("res://campuses/buct_changping/data/playable_route.json"),"layers_file":FileAccess.get_sha256("res://campuses/buct_changping/data/layers.json"),"player_script":map.visitor.get_script().resource_path,"player_position":map.visitor.position,"player_scale":map.visitor.scale}
func reject_unchanged(map: Node2D,data: Dictionary,label: String,options: Dictionary={}) -> void:
	var before=display_identity(map);var physics=authority(map)
	var path=fixture(data,label)
	if path.is_empty():return
	var result=V4.install_region(map,path,options)
	check(result==null,"Rejected candidate: "+label)
	if result!=null:result.uninstall()
	check(display_identity(map)==before,"Rejected candidate changes zero existing display identities: "+label)
	check(authority(map)==physics,"Rejected candidate changes zero physics/route/player authority: "+label)
func run() -> void:
	output=OS.get_environment("BUCT_V4_QA_DIR")
	if output.is_empty() or not output.is_absolute_path() or output.begins_with("user://") or output.begins_with("res://"):
		check(false,"BUCT_V4_QA_DIR must be an explicit absolute external directory; no user-data fallback")
		finish();return
	if DirAccess.make_dir_recursive_absolute(output)!=OK:check(false,"External QA directory creation failed");finish();return
	_external_output_ready=true
	var scene: PackedScene=load("res://campuses/buct_changping/scenes/playable.tscn")
	var map=scene.instantiate();root.add_child(map);await settle()
	check(map.initialized,"Actual production scene with default northern owner initializes")
	if not map.initialized:map.queue_free();await settle();finish();return
	map.visitor.set_physics_process(false)
	var data: Variant=REGION._read_json(CANDIDATE)
	check(data is Dictionary and V4._valid_v4_profile(data),"Actual candidate profile has exact bounded v4 contract")
	if not data is Dictionary:map.queue_free();await settle();finish();return
	check(data.independent_buildings.is_empty(),"Candidate has zero new independent RGBA buildings")
	check(map.west_hd_regions.size()==2 and is_instance_valid(map.north_hd_region),"Four accepted predecessor regions are actually resident")
	if map.west_hd_regions.size()!=2 or not is_instance_valid(map.north_hd_region):map.queue_free();await settle();finish();return
	# First prove the production default; then isolate the original failure fixtures.
	var default_upper: Node2D=map.north_large_hd_region
	check(map.enable_north_large_hd_region and is_instance_valid(default_upper) and default_upper==map.world.get_node_or_null("RegisteredHDRegion_north_large"),"Fresh production entry installs the separate default northern member")
	if not is_instance_valid(default_upper):map.queue_free();await settle();finish();return
	var default_regions:=0;var default_bytes:=0
	for child in map.world.get_children():
		if child.has_method("get_diagnostics"):
			var diag: Dictionary=child.get_diagnostics()
			if diag.get("active",false) and diag.has("new_gpu_texture_bytes"):
				default_regions+=1;default_bytes+=int(diag.new_gpu_texture_bytes)
	check(default_regions==6 and default_bytes==52283306,"Default entry owns exactly six HD layers and 52,283,306 logical layer bytes")
	check(default_upper.bodies.is_empty() and default_upper.restore_items.is_empty() and guard(map.west_hd_regions[0]) and guard(map.north_hd_region),"Default north has zero new RGBA bodies and both authenticated lower guards")
	var default_authority=authority(map);var default_original_visuals=owner_visuals(map)
	check(map.set_north_large_hd_resident(true) and map.north_large_hd_region==default_upper,"Default residency re-request is idempotent")
	var default_ref=weakref(default_upper)
	check(map.set_north_large_hd_resident(false) and map.north_large_hd_region==null and not guard(map.west_hd_regions[0]) and not guard(map.north_hd_region),"Northern residency hook synchronously unloads its member and both guards")
	default_upper=null;await settle()
	check(default_ref.get_ref()==null and authority(map)==default_authority and owner_visuals(map)==default_original_visuals,"Default unload frees the owner without changing original geometry or fallback visuals")
	check(map.set_north_large_hd_resident(true) and is_instance_valid(map.north_large_hd_region),"Northern residency hook reinstalls the real default profile")
	check(guard(map.west_hd_regions[0]) and guard(map.north_hd_region) and authority(map)==default_authority,"Reinstalled default rebinds only visual guards and preserves geometry")
	map.enable_north_large_hd_region=false
	check(map.set_north_large_hd_resident(false),"Disable default northern display for the existing failure/lifecycle fixtures")
	await settle()
	check(not map.world.has_node("RegisteredHDRegion_north_large"),"Predecessor failure fixture explicitly has no northern v4 owner")
	var before=authority(map);var original_visuals=owner_visuals(map)
	var original_source=map.SOURCE;var original_library=map.library_layer;var original_wenli=map.wenli_layer
	var baseline=display_identity(map)
	var bad: Dictionary=data.duplicate(true);bad.quality_approved=false
	reject_unchanged(map,bad,"unapproved")
	reject_unchanged(map,data,"missing-ground",{"ground_asset":"res://campuses/buct_changping/assets/__missing_v4_candidate__.png"})
	bad=data.duplicate(true);bad.ground_rgba_sha256="wrong"
	reject_unchanged(map,bad,"wrong-ground-rgba")
	bad=data.duplicate(true);bad.source_body_ownership.sha256="wrong"
	reject_unchanged(map,bad,"wrong-owner-mask-sha")
	bad=data.duplicate(true);bad.shared_lower_edges[1].rgba_sha256="wrong"
	reject_unchanged(map,bad,"late-east-strip-sha")
	bad=data.duplicate(true);bad.shared_lower_edges[0].neighbor_node="RegisteredHDRegion_unrelated"
	reject_unchanged(map,bad,"wrong-neighbor-id")
	bad=data.duplicate(true);bad.shared_lower_edges[0].rect=[350,399,384,24]
	reject_unchanged(map,bad,"broad-coincident-band")
	bad=data.duplicate(true);bad.runtime_size=[1920,1280];bad.texels_per_source_pixel=5
	reject_unchanged(map,bad,"unrequested-five-texel-upscale")
	var mask_path=output.path_join("fixture-invalid-owner-index.r8.bin")
	var invalid_mask=FileAccess.get_file_as_bytes(data.source_body_ownership.asset)
	check(invalid_mask.size()==384*256,"Actual owner-index mask has source-sized byte count")
	if invalid_mask.size()==384*256:
		invalid_mask[0]=3
		var file=FileAccess.open(mask_path,FileAccess.WRITE);file.store_buffer(invalid_mask);file.close()
		bad=data.duplicate(true);bad.source_body_ownership.asset=mask_path;bad.source_body_ownership.sha256=FileAccess.get_sha256(mask_path)
		reject_unchanged(map,bad,"invalid-owner-index-with-correct-hash")
	# An incomplete source scene may not claim to preserve missing fallback bodies.
	var fallback_owner=map.objects.get_node(V4.BODY_OWNER_IDS[0])
	var fallback_index: int=fallback_owner.get_index()
	map.objects.remove_child(fallback_owner)
	reject_unchanged(map,data,"missing-original-fallback-owner")
	map.objects.add_child(fallback_owner);map.objects.move_child(fallback_owner,fallback_index)
	check(authority(map)==before,"Fallback-owner fixture restores original collision/source authority")
	# An existing valid object reserving a lower slot rejects before any commit.
	var west=map.west_hd_regions[0];var east=map.north_hd_region
	var reservation:=Node2D.new();west._external_top_owner=reservation
	reject_unchanged(map,data,"precommit-lower-binding-conflict")
	west.clear_external_top_owner();reservation.free()
	# Instrument count and byte admission without creating actual textures/physics.
	var blockers: Array[Node2D]=[]
	for i in range(2):
		var blocker=BudgetBlocker.new();blocker.name="V4TestCountBlocker%d"%i;map.world.add_child(blocker);blockers.append(blocker)
	reject_unchanged(map,data,"seventh-region-count")
	for blocker in blockers:map.world.remove_child(blocker);blocker.free()
	blockers.clear()
	var bytes_blocker=BudgetBlocker.new();bytes_blocker.layer_bytes=12000000;map.world.add_child(bytes_blocker)
	reject_unchanged(map,data,"resident-layer-byte-overflow")
	map.world.remove_child(bytes_blocker);bytes_blocker.free()
	check(display_identity(map)==baseline,"All failure fixtures restore exact predecessor display identities")
	var upper=V4.install_region(map,CANDIDATE)
	check(upper!=null,"Actual native imported candidate installs through v4 factory")
	if upper==null:map.queue_free();await settle();finish();return
	check(upper.bodies.is_empty() and upper.restore_items.is_empty(),"Zero independent RGBA means zero legacy building retirements")
	var diagnostics: Dictionary=upper.get_diagnostics()
	check(diagnostics.new_gpu_texture_bytes==9689195 and diagnostics.independent_body_gpu_bytes==0,"Candidate owns exactly 9,689,195 logical layer bytes and zero new body bytes")
	check(diagnostics.runtime_grid_texels_per_source_pixel==4,"Four-texel runtime lattice remains explicit")
	check(abs(float(diagnostics.native_original_detail_density)-float(data.provenance.effective_native_detail_density))<0.000000000001,"Effective native detail density is read from actual registration provenance")
	check(upper._last_lower_state==[true,true] and guard(west) and guard(east),"Both authenticated lower bands yield to one v4 owner")
	check(upper.get_index()>west.get_index() and upper.get_index()>east.get_index() and upper.get_index()<map.objects.get_index(),"Actual owner DAG stays below all independent objects")
	check(authority(map)==before and owner_visuals(map)==original_visuals,"Actual install changes no original player/physics/route or two fallback buildings")
	check(map.SOURCE==original_source and map.library_layer==original_library and map.wenli_layer==original_wenli,"Original source/library/Wenli object identities survive")
	check(V4.install_region(map,CANDIDATE)==upper,"Identical real candidate install is idempotent")
	var altered=data.duplicate(true);altered.ground_rgba_sha256="different"
	check(V4.install_region(map,fixture(altered,"active-profile-mismatch"))==null and upper._committed,"Active owner rejects a different profile without replacement")
	# Memory-only lower perturbations are restored in this same call stack.
	var original_roi: Array=west.profile.roi_xywh.duplicate()
	west.profile.roi_xywh=[350,167,384,256];upper._process(0.0)
	check(upper._last_lower_state==[false,true] and not guard(west) and guard(east),"Wrong coincident west ROI disables only west and clears its guard")
	west.profile.roi_xywh=original_roi;upper._process(0.0)
	var east_ground_sha: String=east.profile.ground_rgba_sha256
	east.profile.ground_rgba_sha256="wrong";upper._process(0.0)
	check(upper._last_lower_state==[true,false] and not guard(east),"Wrong accepted lower-ground identity cannot activate an east sampler")
	east.profile.ground_rgba_sha256=east_ground_sha;upper._process(0.0)
	west.hide();upper._process(0.0)
	check(upper._last_lower_state==[false,true] and not guard(west),"Hidden west restores only local source fallback")
	west.show();upper._process(0.0)
	upper.hide()
	check(not guard(west) and not guard(east),"Upper hide synchronously clears both guards without recursion")
	upper.show();check(upper._last_lower_state==[true,true],"Upper show reauthenticates exact current owners")
	# Pair unload must release v4's west input immediately, with strips still owned.
	check(map.set_west_hd_resident(false),"Actual west display pair unloads")
	check(upper._last_lower_state==[false,true],"Direct lower restore notifies v4 before any later process frame")
	check(upper.get_diagnostics().new_gpu_texture_bytes==9689195,"Owned cropped band allocation stays accurately charged after lower unload")
	check(authority(map)==before,"Actual west display unload leaves repaired source route/physics intact")
	check(map.set_west_hd_resident(true),"Actual west pair reinstalls beside resident v4")
	await settle();west=map.west_hd_regions[0];upper._process(0.0)
	check(upper._last_lower_state==[true,true] and guard(west),"Fresh exact west instance rebinds; stale instance cannot remain resident")
	# Direct east detach similarly changes no road authority under the repaired base.
	map.world.remove_child(east)
	check(upper._last_lower_state==[true,false] and not guard(east),"Direct east detach immediately releases only east input")
	check(authority(map)==before,"Direct east display detach leaves exact original geometry")
	east.free();map.north_hd_region=null
	map.north_hd_region=REGION.install(map,EAST_PROFILE);east=map.north_hd_region
	check(east!=null,"Exact existing north region reinstalls without recreating roads")
	await settle();upper._process(0.0)
	check(upper._last_lower_state==[true,true],"New exact north instance rebinds without stale resource references")
	# Direct upper detach releases resources and originals synchronously.
	map.world.remove_child(upper)
	check(not guard(west) and not guard(east) and not upper._committed,"Direct upper detach releases both guards before free")
	check(upper.ground_texture==null and upper.lower_strip_textures.is_empty() and upper._gpu_bytes==0,"Upper exit releases owned textures and allocation counters")
	upper.free()
	check(authority(map)==before and owner_visuals(map)==original_visuals,"Direct upper free preserves all predecessor authority/fallback visuals")
	upper=V4.install_region(map,CANDIDATE)
	check(upper!=null,"Candidate reinstalls after direct detach/free")
	if upper!=null:
		var ref=weakref(upper);upper.uninstall();upper=null;await settle()
		check(ref.get_ref()==null and not guard(west) and not guard(east),"Explicit uninstall releases node and both incoming guards")
	# The live-tree admission gate forbids detached scene commits.
	root.remove_child(map)
	var detached_before=owner_visuals(map)
	check(V4.install_region(map,CANDIDATE)==null,"Detached predecessor cannot commit or retire original owners")
	check(owner_visuals(map)==detached_before,"Rejected detached install leaves fallback visuals unchanged")
	map.free()
	var reentry=scene.instantiate();root.add_child(reentry);await settle()
	check(reentry.initialized and reentry.enable_north_large_hd_region and is_instance_valid(reentry.north_large_hd_region) and reentry.north_large_hd_region==reentry.world.get_node_or_null("RegisteredHDRegion_north_large"),"Fresh production reentry restores the default northern member")
	reentry.visitor.set_physics_process(false)
	var reentered=V4.install_region(reentry,CANDIDATE)
	check(reentered!=null and reentered==reentry.north_large_hd_region,"Explicit install on fresh default reentry returns the same real owner")
	if reentered!=null:records.append({"actual_candidate":reentered.get_diagnostics(),"geometry_snapshot":authority(reentry)})
	reentry.queue_free();await settle()
	finish()
func finish() -> void:
	var report={"checks":checks,"failures":failures,"records":records,"scope":"real candidate headless lifecycle/ownership/source-geometry only; no visual or GPU acceptance","script_user_data_writes":false,"gpu_run":false}
	if _external_output_ready:
		var file=FileAccess.open(output.path_join("additional-v4-native-result.json"),FileAccess.WRITE)
		if file!=null:file.store_string(JSON.stringify(report,"  "));file.close()
	print("BUCT_ADDITIONAL_V4 "+JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
