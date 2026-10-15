extends SceneTree
## Default scene, unchanged physics, atomic failure and reversible lifecycle.
const HD = preload("res://campuses/buct_changping/scripts/wenli_hd_region.gd")
var checks := 0
var failures: Array[String] = []
var output := ""
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label);push_error(label)
func settle() -> void:
	await process_frame;await physics_frame;await process_frame
func _run() -> void:
	output = OS.get_environment("BUCT_HD_QA_DIR")
	if output.is_empty(): output = ProjectSettings.globalize_path("user://wenli-hd-test")
	DirAccess.make_dir_recursive_absolute(output)
	var scene: PackedScene = load("res://campuses/buct_changping/scenes/playable.tscn")
	var baseline = scene.instantiate();baseline.enable_wenli_hd_region = false;baseline.enable_north_hd_region = false
	root.add_child(baseline);await settle()
	check(baseline.initialized and baseline.wenli_hd_region == null,"Explicit opt-out uses exact #138 scene")
	var unchanged_signature := _physics_signature(baseline)
	baseline.queue_free();baseline = null;await settle()
	var campus = scene.instantiate();campus.enable_north_hd_region = false;root.add_child(campus);await settle()
	check(campus.initialized,"Default Changping scene initializes")
	var region = campus.wenli_hd_region
	check(is_instance_valid(region) and region.get_diagnostics().active,"Default scene installs approved full ground region")
	if not is_instance_valid(region): campus.queue_free();await settle();finish();return
	campus.visitor.set_physics_process(false)
	check(_physics_signature(campus)==unchanged_signature,"All walking polygons, blockers, grid cells, speed and feet are unchanged")
	check(region.ground_texture.get_image().has_mipmaps(),"Validation never mutates imported texture mip data")
	check(region.get_diagnostics().new_gpu_texture_bytes==9599600,"Actual fixed mip-chain allocation is within12MB")
	check(region.get_diagnostics().leaf_derived_rgb_textures==0,"Nine leaf layers share one ground RGB texture")
	check(region.get_diagnostics().stable_retained_new_cpu_rgba_bytes==0,"Component retains no decoded CPU RGB image")
	check(region.find_children("*","CollisionObject2D",true,false).is_empty(),"New region adds no physical bodies")
	var legacy: Sprite2D = campus.world.get_node("WenliInferredGroundWithinOriginalBodyOnly")
	check(not legacy.visible,"Superseded old inferred ground is hidden only after successful install")
	var prior_count: int = campus.world.get_child_count()
	var same = HD.install(campus)
	check(same==region and campus.world.get_child_count()==prior_count,"Double install is a no-op")
	var originals: Array[Dictionary] = []
	for entry in region.leaf_restore:
		originals.append({"sprite":entry.sprite,"material":entry.old_material,"filter":entry.old_filter,"texture":entry.original_texture})
		check(entry.sprite.texture==entry.original_texture,"Original LOD0 alpha texture identity retained")
		check(entry.sprite.material.get_shader_parameter("region_rgb")==region.ground_texture,"Foreground RGB samples the exact shared ground texture")
	var old_ground_ref: WeakRef = weakref(region.ground_texture)
	var old_shadow_ref: WeakRef = weakref(region.shadow_texture)
	region.uninstall();region = null;campus.wenli_hd_region = null;same = null
	await settle()
	check(legacy.visible,"Uninstall restores #138 ground visibility")
	for entry in originals:
		check(entry.sprite.material==entry.material and entry.sprite.texture_filter==entry.filter and entry.sprite.texture==entry.texture,"Uninstall restores original leaf material, filter and texture")
	check(old_ground_ref.get_ref()==null and old_shadow_ref.get_ref()==null,"Uninstall releases both new texture resources")
	check(_physics_signature(campus)==unchanged_signature,"Uninstall never changes walking or physical ownership")
	var golden: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HD.PROFILE))
	var roundtrip_path: String = output.path_join("valid-roundtrip-profile.json")
	var roundtrip_file := FileAccess.open(roundtrip_path,FileAccess.WRITE)
	roundtrip_file.store_string(JSON.stringify(golden,"",true,true));roundtrip_file.close()
	var roundtrip = HD.install(campus,{"profile_path":roundtrip_path})
	check(is_instance_valid(roundtrip),"Full-precision JSON roundtrip reaches all downstream profile validation")
	if is_instance_valid(roundtrip): roundtrip.uninstall()
	roundtrip = null;await settle()
	var cases: Array[Dictionary] = []
	var malformed = golden.duplicate(true);malformed.foreground[0].bbox_xywh = null;cases.append({"id":"bbox_null","profile":malformed})
	malformed = golden.duplicate(true);malformed.foreground[0].bbox_xywh = "invalid";cases.append({"id":"bbox_string","profile":malformed})
	malformed = golden.duplicate(true);malformed.foreground[0].bbox_xywh[2] = "nine";cases.append({"id":"bbox_member","profile":malformed})
	malformed = golden.duplicate(true);malformed.foreground[0].baseline_y = null;cases.append({"id":"baseline_null","profile":malformed})
	malformed = golden.duplicate(true);malformed.shadow_opacity = {};cases.append({"id":"opacity_dictionary","profile":malformed})
	malformed = golden.duplicate(true);malformed.quality_approved = "true";cases.append({"id":"approval_string","profile":malformed})
	malformed = golden.duplicate(true);malformed.ground_asset = "res://campuses/buct_changping/scenes/playable.tscn";cases.append({"id":"wrong_resource_type","profile":malformed})
	malformed = golden.duplicate(true);malformed.ground_asset = "res://campuses/buct_changping/assets/missing_hd_ground.png";cases.append({"id":"missing_texture","profile":malformed})
	malformed = golden.duplicate(true);malformed.foreground[0] = golden.foreground[1].duplicate(true);malformed.foreground[3] = golden.foreground[6].duplicate(true);cases.append({"id":"same798pixels_duplicate_owners","profile":malformed})
	for item in cases:
		var path: String = output.path_join("malformed-"+str(item.id)+".json")
		var file := FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(item.profile,"",true,true));file.close()
		var failed = HD.install(campus,{"profile_path":path})
		check(failed==null,"Malformed profile cleanly falls back: "+str(item.id))
		check(legacy.visible and not campus.world.has_node("WenliHighDetailRegion"),"Failed install leaves no partial ground node: "+str(item.id))
		for entry in originals:
			check(entry.sprite.material==entry.material and entry.sprite.texture==entry.texture,"Failed install leaves original leaf intact: "+str(item.id))
	check(not HD._number(NAN) and not HD._number(INF),"Nonfinite metadata is rejected")
	region = HD.install(campus);campus.wenli_hd_region = region
	check(is_instance_valid(region),"Valid reinstall succeeds after every failed attempt")
	root.remove_child(campus)
	check(not region.get_diagnostics().active and not region.visible and legacy.visible,"Detached cached scene retires enhancement and restores fallback")
	root.add_child(campus);await settle()
	check(not region.visible and legacy.visible,"Re-added cached scene cannot display mixed stale layers")
	var retired_ref: WeakRef = weakref(region)
	region = HD.install(campus);campus.wenli_hd_region = region;await settle()
	check(is_instance_valid(region) and region.get_diagnostics().active and retired_ref.get_ref()==null,"Explicit re-install replaces retired cached component")
	check(_physics_signature(campus)==unchanged_signature,"Re-entry preserves complete physical signature")
	var node_refs: Array[WeakRef] = [];_collect(campus,node_refs)
	var texture_ref: WeakRef = weakref(region.ground_texture)
	originals.clear();region = null;legacy = null;campus.queue_free();campus = null
	await settle()
	for ref in node_refs: check(ref.get_ref()==null,"Every scene node releases on final exit")
	check(texture_ref.get_ref()==null,"Region texture releases on scene exit")
	finish()
func _physics_signature(campus: Node) -> String:
	return HD._sha(var_to_bytes([campus.walk_polys,campus.blockers,campus.walk_cells,
		campus.data.route_waypoints,campus.data.landmarks,campus.visitor.speed,
		campus.visitor.display_height,campus.visitor.get_node("FeetCollision").shape.radius]))
func _collect(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child in node.get_children(): _collect(child,refs)
func finish() -> void:
	var file := FileAccess.open(output.path_join("headless-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));file.close()
	print("BUCT_CHANGPING_HD_REGION checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
