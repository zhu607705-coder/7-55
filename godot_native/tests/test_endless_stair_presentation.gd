extends SceneTree
const View=preload("res://scripts/presentation/chapter4_endless_stair_view.gd")
var checks:=0
var failures:=0
func check(ok:bool,note:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(note)
func _initialize()->void:run.call_deferred()
func run()->void:
	DirAccess.make_dir_recursive_absolute("user://endless_stair_b3")
	var v=View.new()
	root.add_child(v)
	await process_frame
	v.set_process(false);v.set_physics_process(false)
	v._start();v.demo_mode=true;v.capture_frames.clear()
	var max_markers:=0
	var max_candidates:=0
	var step_seated:=true
	var opaque:=true
	var marker_transitions:Array=[]
	var old_marker:=-1
	var min_candidate:=99999
	while v.model.status=="running":
		v._physics_process(1.0/60)
		v._present(1.0/60)
		max_candidates=maxi(max_candidates,v.beam_candidate_count)
		min_candidate=mini(min_candidate,v.beam_candidate_count)
		var visible_count:=0
		for marker in v.floor_markers:
			if marker.modulate.a>.001:visible_count+=1
		max_markers=maxi(max_markers,visible_count)
		if v.active_marker!=old_marker:
			marker_transitions.append({"tick":v.model.tick,"marker":v.active_marker,"old_alpha":v.marker_alpha})
			old_marker=v.active_marker
		for batch in v.visual_batches:
			if batch.always:continue
			for i in batch.progresses.size():
				if batch.progresses[i]<=v.model.player.x+4.69:
					# Dummy/headless renderer does not roundtrip MultiMesh GPU transforms.
					# settled_count advances only after uploading the exact source transform.
					step_seated=step_seated and i<batch.mesh.visible_instance_count and i<int(batch.settled_count)
		if v.model.tick%180==0:
			for group in v.groups:
				for mat in group.get_meta("materials").values():
					opaque=opaque and mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and is_equal_approx(mat.albedo_color.a,1)
	check(v.model.status=="finished" and v.model.gates_passed==12,"complete native view/input run reaches finite exit")
	check(max_markers==1,"at most one 04 has nonzero alpha at every frame")
	check(step_seated,"every visual piece is fully assembled at least 4.69m before player")
	check(opaque,"all visible structural surfaces stay opaque throughout full run")
	check(v.shadow_groups.size()==25,"stable independent shadow geometry for every route section")
	var proxies_ok:=true
	for entry in v.shadow_groups:
		proxies_ok=proxies_ok and entry.node.get_parent()==v.world and entry.node.material_override.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and entry.node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	check(proxies_ok,"shadow proxies are not children of assembled visual groups")
	check(max_candidates<v.blocker_cache.size()/4,"local range broad phase reduces beam candidate set")
	check(v.static_mesh_instances_after<v.static_mesh_instances_before/2,"static mesh instance batching removes more than half of submissions")
	var previous_progress:float=v.highest_visual_progress
	v.model.player.x-=8
	v._present(1.0/60)
	check(v.highest_visual_progress==previous_progress,"reversing cannot remove assembled treads")
	v._start();v._present(0)
	check(v.highest_visual_progress==1 and v.model.tick==0,"restart resets presentation frontier and model")
	var result={"checks":checks,"failures":failures,"maxSimultaneous04":max_markers,"minimumFullySeatedAheadMetres":4.69,"markers":marker_transitions,"staticInstancesBefore":v.static_mesh_instances_before,"staticBatchesAfter":v.static_mesh_instances_after,"blockers":v.blocker_cache.size(),"beamCandidatesMin":min_candidate,"beamCandidatesMax":max_candidates,"shadowGroups":v.shadow_groups.size(),"input":"simulated 60Hz full route, not human play"}
	FileAccess.open("user://endless_stair_b3/B3_presentation_checks.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("B3_PRESENTATION: ",JSON.stringify(result))
	v.queue_free()
	await process_frame
	await create_timer(.12).timeout
	quit(1 if failures else 0)
