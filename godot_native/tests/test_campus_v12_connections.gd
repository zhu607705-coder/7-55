extends SceneTree
## Optimized focused contract: unchanged 2px/five-offset axis coverage;
## actual tap traversal is center-only in both directions, not five repetitions.
## Focused source-foot navigation contract. Fixture inputs are not authority to
## mutate geometry, weaken feet, bypass gates, or teleport to claim arrival.
const Metrics = preload("res://scripts/player_metrics.gd")
const DEFAULT_FIXTURE := "res://tests/fixtures/campus_navigation_v12_chengyue.json"
const DEFAULT_OFFSETS := [[0.0,0.0],[0.25,0.0],[-0.25,0.0],[0.0,0.25],[0.0,-0.25]]
const TAP_OFFSETS := [[0.0,0.0]]
const SAVE_FILES := ["user://save.json","user://save.previous.json","user://save.json.tmp"]
const EPSILON := 0.05
var checks := 0
var failures := 0
var group_reports: Dictionary = {}
var fixture: Dictionary = {}
var world: Variant
var state: Variant
var shell: Variant
var fixture_path := ""
var fixture_sha := ""
var started_ms := 0

func default_fixture_path() -> String:
	return DEFAULT_FIXTURE

func _initialize() -> void:
	run.call_deferred()

func vector(value: Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

func coordinates(point: Vector2) -> Array:
	return [point.x,point.y]

func anchor(foot: Vector2) -> Vector2:
	return foot-Metrics.foot_center_offset("campus_bootstrap")

func valid_point(value: Variant) -> bool:
	return value is Array and value.size()==2 and (value[0] is int or value[0] is float) and (value[1] is int or value[1] is float) and is_finite(float(value[0])) and is_finite(float(value[1]))

func group_report(id: String) -> Dictionary:
	if not group_reports.has(id):
		group_reports[id]={"checks":0,"failures":0,"categories":{},"failureSamples":[],"coverageNotes":[],"tapArrivals":0,"tapExemptions":0,"routes":{}}
	return group_reports[id]

func check(value: bool, group: String, category: String, detail: Dictionary={}) -> void:
	checks+=1
	var result:=group_report(group)
	result.checks+=1
	if not result.categories.has(category):result.categories[category]={"checks":0,"failures":0}
	result.categories[category].checks+=1
	var route_id:=str(detail.get("route",""))
	if not route_id.is_empty():
		if not result.routes.has(route_id):result.routes[route_id]={"checks":0,"failures":0}
		result.routes[route_id].checks+=1
		if not value:result.routes[route_id].failures+=1
	if value:return
	failures+=1;result.failures+=1;result.categories[category].failures+=1
	if result.failureSamples.size()<24:
		var row:=detail.duplicate(true);row["category"]=category
		result.failureSamples.append(row)
		push_error("Campus v12 ["+group+"] "+JSON.stringify(row))

func note(group: String, kind: String, detail: Dictionary) -> void:
	var result:=group_report(group)
	if result.coverageNotes.size()<40:
		var row:=detail.duplicate(true);row["kind"]=kind;result.coverageNotes.append(row)

func diagnostic(foot: Vector2) -> Dictionary:
	var feet:=Metrics.foot_rect(anchor(foot),"campus_bootstrap")
	var art: Variant=world.campus_layers
	var kinds: Array=[]
	for region: Dictionary in art.water_regions:
		if not feet.intersects(region.bounds):continue
		for water: Rect2 in region.rects:
			if feet.intersects(water):
				kinds.append("water:"+str(region.id));break
	var box:=PackedVector2Array([feet.position,Vector2(feet.end.x,feet.position.y),feet.end,Vector2(feet.position.x,feet.end.y)])
	for i: int in art.solid_polygons.size():
		if not Geometry2D.intersect_polygons(box,art.solid_polygons[i]).is_empty():
			var rows: Array=art.manifest.navigation.get("footprints",[])
			kinds.append("solid:"+str(rows[i].get("id",i)) if i<rows.size() else "solid:"+str(i))
	var source_mask: bool=world.SpatialRules.mask_allows_rect(feet,world.mask,world.mask_meta)
	var union: bool=art.reviewed_support_covers(feet,world.mask,world.mask_meta)
	if kinds.is_empty() and not source_mask and not union:kinds.append("unsupported_ground")
	if kinds.is_empty() and not world.can_stand(anchor(foot)):kinds.append("other_collision_or_story_gate")
	return {"foot":coordinates(foot),"footRect":[feet.position.x,feet.position.y,feet.size.x,feet.size.y],"physicalKinds":kinds,"hazardDecision":art.navigation_decision(feet,Callable(),true),"oldMask":source_mask,"reviewedUnion":union}

func expect_stand(foot: Vector2, expected: bool, group: String, category: String, context: Dictionary) -> void:
	var actual: bool=world.can_stand(anchor(foot))
	var detail:=context.duplicate(true)
	if actual!=expected and group_report(group).failureSamples.size()<24:detail.merge(diagnostic(foot));detail["expectedOpen"]=expected;detail["actualOpen"]=actual
	check(actual==expected,group,category,detail)

func validate_fixture() -> bool:
	check(fixture.get("schema","")=="755-campus-navigation-v10-fixture-v1","setup","fixture_schema")
	check(fixture.get("coordinateConvention","")=="world-foot-center","setup","coordinate_convention")
	check(valid_point(fixture.get("footSize")) and vector(fixture.footSize).is_equal_approx(Vector2(16,10)),"setup","fixture_full_foot")
	check(valid_point(fixture.get("footCenterOffset")) and vector(fixture.footCenterOffset).is_equal_approx(Metrics.foot_center_offset("campus_bootstrap")),"setup","fixture_foot_offset")
	check(fixture.get("groups") is Array and not fixture.get("groups",[]).is_empty(),"setup","nonempty_groups")
	if failures:return false
	var group_ids: Dictionary={}
	for group_value: Variant in fixture.groups:
		if not group_value is Dictionary:check(false,"setup","group_dictionary");continue
		var group: Dictionary=group_value
		var id:=str(group.get("id",""))
		check(not id.is_empty() and not group_ids.has(id),"setup","unique_group",{"group":id});group_ids[id]=true
		check(group.get("routes") is Array and not group.get("routes",[]).is_empty(),id,"nonempty_routes")
		check(group.get("blocked") is Array and not group.get("blocked",[]).is_empty(),id,"entity_negative_examples")
		check(group.get("tapRoutes",[]) is Array,id,"explicit_tap_routes_array")
		if not group.get("routes") is Array or not group.get("blocked") is Array or not group.get("tapRoutes",[]) is Array:continue
		var route_ids: Dictionary={}
		for route_value: Variant in group.get("routes",[])+group.get("tapRoutes",[]):
			if not route_value is Dictionary:check(false,id,"route_dictionary");continue
			var route: Dictionary=route_value
			var route_id:=str(route.get("id",""))
			check(not route_id.is_empty() and not route_ids.has(route_id),id,"unique_route",{"route":route_id});route_ids[route_id]=true
			check(route.get("points") is Array and route.get("points",[]).size()>=2,id,"route_points",{"route":route_id})
			if not route.get("points") is Array:continue
			for point: Variant in route.get("points",[]):check(valid_point(point),id,"finite_route_point",{"route":route_id})
			var offsets: Variant=route.get("offsets",DEFAULT_OFFSETS)
			check(offsets is Array and offsets.size()>=2,id,"center_and_edge_offsets",{"route":route_id})
			var center:=false;var edge:=false
			if offsets is Array:
				for offset: Variant in offsets:
					check(valid_point(offset),id,"finite_offset",{"route":route_id})
					if valid_point(offset):
						center=center or vector(offset).is_zero_approx();edge=edge or not vector(offset).is_zero_approx()
			check(center and edge,id,"center_and_edge_coverage",{"route":route_id})
			check(offsets==DEFAULT_OFFSETS,id,"exact_five_fractional_offsets",{"route":route_id})
		for field: String in ["blocked","open","edgeProbes"]:
			check(group.get(field,[]) is Array,id,"probe_array",{"field":field})
			if not group.get(field,[]) is Array:continue
			for probe: Variant in group.get(field,[]):
				check(probe is Dictionary and valid_point(probe.get("point")),id,"valid_probe",{"field":field})
				if not probe is Dictionary:continue
				if field=="edgeProbes":check(probe.get("expectedOpen") is bool,id,"edge_probe_explicit_expectation")
				check(probe.get("approaches",[]) is Array,id,"negative_approaches_array")
				if probe.get("approaches",[]) is Array:
					for approach: Variant in probe.get("approaches",[]):check(valid_point(approach),id,"negative_approach_point")
	return failures==0

func sweep_route(group: String, route: Dictionary) -> void:
	var step_pixels:=clampf(float(route.get("stepPixels",fixture.get("stepPixels",2.0))),0.25,2.0)
	for offset_value: Array in route.get("offsets",DEFAULT_OFFSETS):
		var offset:=vector(offset_value)
		for reverse: bool in [false,true]:
			var points: Array=route.points.duplicate(true)
			if reverse:points.reverse()
			var actual_xy:=anchor(vector(points[0])+offset)
			var actual_yx:=actual_xy
			var context: Dictionary={"route":route.id,"reverse":reverse,"offset":coordinates(offset)}
			expect_stand(vector(points[0])+offset,true,group,"route_start",context)
			for segment: int in range(points.size()-1):
				var start:=vector(points[segment])+offset;var goal:=vector(points[segment+1])+offset
				var steps:=maxi(1,ceili(start.distance_to(goal)/step_pixels))
				for step: int in range(1,steps+1):
					var foot:=start.lerp(goal,float(step)/steps);var next:=anchor(foot)
					context["segment"]=segment;context["sample"]=step
					expect_stand(foot,true,group,"whole_foot_can_stand",context)
					# Carry the ACTUAL resolved positions across every sample and turn.
					# A blocked step cannot be hidden by resetting to the ideal path.
					actual_xy=world._axis_destination(actual_xy,Vector2(next.x-actual_xy.x,0))
					actual_xy=world._axis_destination(actual_xy,Vector2(0,next.y-actual_xy.y))
					actual_yx=world._axis_destination(actual_yx,Vector2(0,next.y-actual_yx.y))
					actual_yx=world._axis_destination(actual_yx,Vector2(next.x-actual_yx.x,0))
					for row: Array in [["axis_xy",actual_xy],["axis_yx",actual_yx]]:
						var actual: Vector2=row[1];var exact:=actual.distance_to(next)<=EPSILON
						var detail:=context.duplicate(true)
						if not exact and group_report(group).failureSamples.size()<24:detail.merge(diagnostic(foot));detail["actualFoot"]=coordinates(actual+Metrics.foot_center_offset("campus_bootstrap"))
						check(exact,group,str(row[0]),detail)
				print("CAMPUS_V12_SEGMENT ",JSON.stringify({"phase":"sweep_complete","group":group,"route":route.id,"offset":coordinates(offset),"reverse":reverse,"segment":segment,"samples":steps,"groupChecks":group_report(group).checks,"groupFailures":group_report(group).failures}))

func picker_owner(foot: Vector2) -> String:
	if not world._pick_target(foot).is_empty():return "interactive_target"
	for surface: Dictionary in world.object_picker.surfaces:
		if surface.painted and world.object_picker.contains(surface.geometry,foot):return "painted_object"
	var actor: Dictionary=world.player_visual()
	if actor.texture!=null and world.object_picker.contains(world.player_geometry(),foot):return "player_sprite"
	return ""

func tap_leg(group: String, context: Dictionary, start: Vector2, goal: Vector2, strict: bool) -> void:
	world.cancel_exploration_gestures()
	# Arrange only the START fixture. All movement after the press is the real
	# world's _process route follower, not a direct player assignment.
	world.player=anchor(start);world.safe_player=world.player;world.touch_axis=Vector2.ZERO
	world._sync_player();world._update_camera()
	var local: Vector2=(goal-world.camera)*world.zoom+world.size*.5
	check(world.can_stand(world.player),group,"tap_start",context)
	var owner:=picker_owner(goal)
	if not owner.is_empty():
		group_report(group).tapExemptions+=1
		var detail:=context.duplicate(true);detail["owner"]=owner;detail["goal"]=coordinates(goal)
		note(group,"tap_picker_owned_not_accepted",detail)
		if strict:check(false,group,"explicit_tap_picker_owned",detail)
		return
	if not world.exploration_safe_rect(true).has_point(local):
		check(false,group,"tap_outside_viewport",context.merged({"goal":coordinates(goal),"local":coordinates(local)}));return
	print("CAMPUS_V12_TAP ",JSON.stringify(context.merged({"phase":"begin","group":group,"start":coordinates(start),"goal":coordinates(goal)})))
	world._mobile_floor_tap(local)
	var moving: bool=world._floor_status=="moving" and not world._floor_route.is_empty()
	check(moving,group,"tap_planned",context.merged({"goal":coordinates(goal),"status":world._floor_status}))
	if not moving:return
	if bool(context.get("requireDetour",false)):
		check(world._floor_route.size()>1 and not world._floor_segment_clear(world.player,anchor(goal)),group,"tap_requires_real_detour",context.merged({"waypoints":world._floor_route.size()}))
	var previous: Vector2=world.player;var route_length:=0.0
	for next: Vector2 in world._floor_route:
		check(world._floor_segment_clear(previous,next),group,"tap_planned_whole_foot_segment",context)
		route_length+=previous.distance_to(next);previous=next
	var max_frames:=mini(7200,ceili(route_length/165.0*60.0)+120)
	var frames:=0
	while not world._floor_route.is_empty() and frames<max_frames:
		world._process(1.0/60.0);frames+=1
		check(world.can_stand(world.player),group,"tap_travel_whole_foot",context.merged({"frame":frames,"actualFoot":coordinates(world.player+Metrics.foot_center_offset("campus_bootstrap"))}))
		if str(state.d.native.scene)!="campus_bootstrap":break
	var actual_foot: Vector2=world.player+Metrics.foot_center_offset("campus_bootstrap")
	var arrived: bool=world._floor_status=="arrived" and actual_foot.distance_to(goal)<=EPSILON
	check(arrived,group,"tap_exact_arrival",context.merged({"goal":coordinates(goal),"actualFoot":coordinates(actual_foot),"status":world._floor_status,"frames":frames,"maxFrames":max_frames}))
	check(str(state.d.native.scene)=="campus_bootstrap",group,"tap_preserves_scene",context)
	if arrived:group_report(group).tapArrivals+=1
	print("CAMPUS_V12_TAP ",JSON.stringify(context.merged({"phase":"complete","group":group,"arrived":arrived,"frames":frames,"groupChecks":group_report(group).checks,"groupFailures":group_report(group).failures})))
	world.cancel_exploration_gestures()

func tap_route(group: String, route: Dictionary, strict: bool=false) -> void:
	# Offset feet remain fully checked by sweep_route. Tap input/route following
	# is exercised once per direction at the exact authored centerline.
	for offset_value: Array in TAP_OFFSETS:
		var offset:=vector(offset_value)
		for reverse: bool in [false,true]:
			var points: Array=route.points.duplicate(true)
			if reverse:points.reverse()
			for segment: int in range(points.size()-1):
				var start:=vector(points[segment])+offset;var goal:=vector(points[segment+1])+offset
				var context: Dictionary={"route":route.id,"reverse":reverse,"offset":coordinates(offset),"segment":segment,"requireDetour":bool(route.get("requireDetour",false))}
				if start.distance_to(goal)<55.0:
					group_report(group).tapExemptions+=1
					note(group,"short_segment_sweep_only",context)
					if strict:check(false,group,"explicit_tap_too_short",context)
					continue
				# Explicit taps retain their original endpoints, including real detours.
				var sections:=1 if strict else maxi(1,ceili(start.distance_to(goal)/140.0))
				for section: int in range(sections):
					context["section"]=section
					tap_leg(group,context,start.lerp(goal,float(section)/sections),start.lerp(goal,float(section+1)/sections),strict)

func negative_probe(group: String, probe: Dictionary) -> void:
	var foot:=vector(probe.point)
	var context: Dictionary={"probe":probe.get("id","unnamed"),"kind":probe.get("kind","unspecified")}
	expect_stand(foot,false,group,"unsupported_ground_negative" if str(probe.get("kind",""))=="unsupported_ground" else "physical_negative",context)
	# Read-only search for safe cardinal approach fixtures. No geometry is
	# removed to make one. A large building can have no nearby safe approach.
	var approaches: Array=probe.get("approaches",[]).duplicate(true)
	if approaches.is_empty():
		for offset: Vector2 in [Vector2(28,0),Vector2(-28,0),Vector2(0,28),Vector2(0,-28)]:
			if world.can_stand(anchor(foot+offset)):approaches.append(coordinates(foot+offset))
	if approaches.is_empty():note(group,"negative_has_no_nearby_safe_approach",context)
	for approach_value: Array in approaches:
		var start:=anchor(vector(approach_value));var target:=anchor(foot)
		check(world.can_stand(start),group,"negative_approach_safe",context)
		if not world.can_stand(start):continue
		var actual: Vector2=world._axis_destination(start,Vector2(target.x-start.x,0))
		actual=world._axis_destination(actual,Vector2(0,target.y-actual.y))
		check(actual.distance_to(target)>EPSILON and world.can_stand(actual),group,"negative_axis_stops_before_entity",context.merged({"approach":approach_value,"actualFoot":coordinates(actual+Metrics.foot_center_offset("campus_bootstrap"))}))

func finish() -> void:
	var report: Dictionary={"schema":"755-campus-v10-native-results-v1","passed":failures==0,"checks":checks,"failures":failures,"fixturePath":fixture_path,"fixtureSha256":fixture_sha,"engine":Engine.get_version_info().string,"elapsedMs":Time.get_ticks_msec()-started_ms,"groups":group_reports,"coverage":"Focused runtime whole-foot geometry and native tap routing; not browser/physical-device or complete game acceptance","coveragePlan":{"variant":"center-tap-optimized-v1","axisSampleStepMaxPixels":2.0,"axisOffsets":"all original route offsets; default center and four 0.25px shifts","axisDirections":"forward and reverse","axisOrders":["XY","YX"],"tapOffsets":TAP_OFFSETS,"tapDirections":"forward and reverse","tapCountReducedFromFiveOffsets":true,"axisInternalExactPixelSweep":false}}
	for id: String in group_reports:print("CAMPUS_V12_GROUP ",id," ",JSON.stringify(group_reports[id]))
	print("CAMPUS_V12_RESULT ",JSON.stringify(report))
	var output:=OS.get_environment("CAMPUS_V12_REPORT")
	if not output.is_empty():
		if not output.is_absolute_path():push_error("CAMPUS_V12_REPORT must be an absolute evidence path");quit(1);return
		var file:=FileAccess.open(output,FileAccess.WRITE)
		if file==null:push_error("Cannot write CAMPUS_V12_REPORT: "+output);quit(1);return
		file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	quit(0 if failures==0 else 1)

func run() -> void:
	started_ms=Time.get_ticks_msec()
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"setup","isolated_user_directory")
	if failures:finish();return
	for file: String in SAVE_FILES:check(not FileAccess.file_exists(file),"setup","fresh_no_save",{"file":file})
	if failures:finish();return
	fixture_path=OS.get_environment("CAMPUS_V12_FIXTURE")
	if fixture_path.is_empty():fixture_path=default_fixture_path()
	check(FileAccess.file_exists(fixture_path),"setup","fixture_exists",{"path":fixture_path})
	if failures:finish();return
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	check(parsed is Dictionary,"setup","fixture_json_dictionary")
	if failures:finish();return
	fixture=parsed;fixture_sha=FileAccess.get_sha256(fixture_path)
	if not validate_fixture():finish();return
	check(Metrics.foot_rect(Vector2.ZERO,"campus_bootstrap").size.is_equal_approx(Vector2(16,10)),"setup","authorized_campus_full_foot")
	var manifest_hash:=str(fixture.get("expectedManifestSha256",""))
	if not manifest_hash.is_empty():check(FileAccess.get_sha256("res://data/native/campus_layered_map.json")==manifest_hash,"setup","exact_candidate_manifest")
	if failures:finish();return
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	state.d.native.chapter=2;state.d.native.scene="campus_bootstrap";state.d.native.page="phone_home"
	state.d.runtimeMode="rpg";state.d.rpgScene="campus_bootstrap";state.d.actOne.phase="complete"
	state.d.native.settings.music=false;state.d.native.settings.effects=false
	root.size=Vector2i(1440,900)
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
	await process_frame
	state.d.native.scene="campus_bootstrap";state.d.rpgCheckpoint="";state.d.native.positions={}
	world=shell.world;world.refresh_world();shell._layout()
	await process_frame
	await process_frame
	world.set_process(false)
	check(shell.world_frame.is_visible_in_tree() and world.is_visible_in_tree(),"setup","real_main_world_visible")
	check(world.campus_layers.ready and world.background==null,"setup","layered_renderer_not_old_plate")
	check(int(world.campus_layers.manifest.get("semanticLayerVersion",0))==2,"setup","semantic_version")
	if failures:shell.queue_free();await process_frame;finish();return
	for group: Dictionary in fixture.groups:
		var id:=str(group.id)
		for route: Dictionary in group.routes:
			var route_started:=Time.get_ticks_msec()
			sweep_route(id,route);tap_route(id,route)
			print("CAMPUS_V12_ROUTE ",JSON.stringify({"group":id,"route":route.id,"checks":group_report(id).routes.get(str(route.id),{}).get("checks",0),"failures":group_report(id).routes.get(str(route.id),{}).get("failures",0),"groupChecks":group_report(id).checks,"groupFailures":group_report(id).failures,"elapsedMs":Time.get_ticks_msec()-route_started,"complete":true}))
		for route: Dictionary in group.get("tapRoutes",[]):
			var route_started:=Time.get_ticks_msec()
			tap_route(id,route,true)
			print("CAMPUS_V12_ROUTE ",JSON.stringify({"group":id,"route":route.id,"kind":"explicit_tap","checks":group_report(id).routes.get(str(route.id),{}).get("checks",0),"failures":group_report(id).routes.get(str(route.id),{}).get("failures",0),"groupChecks":group_report(id).checks,"groupFailures":group_report(id).failures,"elapsedMs":Time.get_ticks_msec()-route_started,"complete":true}))
		for probe: Dictionary in group.get("open",[]):expect_stand(vector(probe.point),true,id,"open_probe",{"probe":probe.get("id","unnamed")})
		for probe: Dictionary in group.blocked:negative_probe(id,probe)
		for probe: Dictionary in group.get("edgeProbes",[]):expect_stand(vector(probe.point),bool(probe.get("expectedOpen",false)),id,"boundary_full_foot",{"probe":probe.get("id","unnamed")})
		check(int(group_report(id).tapArrivals)>=2,id,"at_least_two_actual_tap_arrivals")
		check(state.developer_mode,id,"no_save_guard_retained")
		for file: String in SAVE_FILES:check(not FileAccess.file_exists(file),id,"no_save_after_group",{"file":file})
	check(not state.save_game(),"teardown","formal_save_explicitly_refused")
	check(Metrics.foot_rect(Vector2.ZERO,"campus_bootstrap").size.is_equal_approx(Vector2(16,10)),"teardown","campus_full_foot_unchanged")
	shell.queue_free();await process_frame
	for file: String in SAVE_FILES:check(not FileAccess.file_exists(file),"teardown","no_save_written",{"file":file})
	finish()
