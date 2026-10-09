extends SceneTree
## Presentation fixtures only; no earned catch or model clock authority.
const Model = preload("res://scripts/games/rhythm_fishing_model.gd")
const Motion = preload("res://scripts/ui/lake_fishing_motion.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FISHING DEPTH: "+label)
func depth(m: RefCounted,reduced: bool=false) -> Dictionary:return Motion.depth_sample(m,Motion.sample(m,reduced))
func snapshot(m: RefCounted) -> String:
	var values: Dictionary={}
	for property: Dictionary in m.get_property_list():
		if int(property.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE:values[property.name]=m.get(property.name)
	return JSON.stringify(values)
func run() -> void:
	for id: String in ["locker_key","net_frame","fish","paper"]:
		var m:=Model.new();m.configure(id,Model.load_chart(id));m.phase="running"
		var casting:=depth(m)
		check(is_equal_approx(casting.creature_depth,.16),id+": casting retains original deep position")
		m.cast_at=0;m.stage="count_in";m.elapsed=2*m.beat_sec
		var bite:=depth(m)
		check(bite.creature_depth<casting.creature_depth and bite.creature_alpha>casting.creature_alpha and bite.creature_veil<casting.creature_veil,id+": bite rises and becomes identifiable")
		m.stage="fighting";m.elapsed=4*m.beat_sec
		var early:=depth(m)
		check(early.creature_depth<bite.creature_depth,id+": completed count-in continues rising into struggle")
		var previous: Dictionary=early
		for index in range(m.notes.size()):
			m.notes[index].judgment="perfect";m.judged=index+1
			var current:=depth(m)
			check(current.creature_depth<previous.creature_depth,id+": each successful retrieval moves closer to surface")
			check(current.creature_alpha>=previous.creature_alpha and current.creature_veil<=previous.creature_veil,id+": retrieval reveals rather than hides fish")
			check(current.progress<=1 and current.creature_depth>=.004,id+": all depth values stay bounded")
			previous=current
		check(previous.target_alpha<.001 and previous.fish_merge>.999,id+": near surface has one fish silhouette")
		check(early.target_alpha==1 and early.fish_merge==0,id+": early tracking retains original small fish")
		check(previous.creature_depth<.02 and previous.creature_veil<=.05,id+": near completion is close to water surface")
		for note: Dictionary in m.notes:note.judgment="miss"
		var all_misses:=depth(m)
		check(all_misses.successful_notes==0 and all_misses.progress==0,id+": judged misses never fake retrieval progress")
		check(is_equal_approx(all_misses.creature_depth,early.creature_depth),id+": all misses stay at early fight depth")
		m.notes[0].judgment="great";m.notes[1].judgment="good"
		check(depth(m).successful_notes==2,id+": mixed great/good count while remaining misses do not")
		m.phase="completed";m.final_result={"passed":false}
		check(depth(m).surface==0,id+": a completed failed chart retreats")
		m.phase="running";m.final_result={}
		for note: Dictionary in m.notes:note.judgment=""
		m.judged=0;m.elapsed=4*m.beat_sec+m.phrase_time(1.3);m.controls={"hook":true};m.tension=20
		var low:=depth(m)
		m.tension=90
		var high:=depth(m)
		check(high.creature_depth>low.creature_depth and high.progress==low.progress,id+": loaded fish thrust dives, never grants progress")
		m.elapsed=4*m.beat_sec+m.phrase_time(2.5)
		var held:=depth(m)
		m.controls={}
		var release:=depth(m)
		check(held.creature_depth<release.creature_depth and held.progress==release.progress,id+": held pull raises the silhouette without creating progress")
		var reduced0:=depth(m,true)
		m.elapsed=4*m.beat_sec+m.phrase_time(1.6)
		var reduced1:=depth(m,true)
		check(reduced0==reduced1,id+": reduced motion removes beat-driven depth bobbing")
		var before:=snapshot(m)
		for i in range(240):depth(m)
		check(snapshot(m)==before,id+": repeated depth sampling cannot alter any model property")
		m.phase="failed"
		var failed:=depth(m)
		check(failed.surface==0 and failed.creature_depth==casting.creature_depth,id+": failed encounter retreats without an apparent catch")
		m.phase="completed";m.final_result={"passed":true}
		check(depth(m).surface==1,id+": real completed success reaches surface")
	# Real view owner: pause and retry still own lifecycle, across layout sizes.
	root.get_node("State").developer_mode=true
	for extent: Vector2i in [Vector2i(1180,812),Vector2i(430,860),Vector2i(844,390)]:
		root.size=extent
		var host: Control=load("res://scripts/ui/minigame_host.gd").new();root.add_child(host);await process_frame
		host.setup({"type":"rhythm","chartId":"locker_key","spotId":"locker_key","session_id":"depth-fixture"})
		host.configure_activity_layout(Vector2(extent),extent.x<1100);host.set_process(false);host.begin();host.set_process(false)
		host.model.phase="running";host.model.stage="fighting";host.model.cast_at=0;host.model.elapsed=4*host.model.beat_sec+host.model.phrase_time(2.5);host.model.tension=90;host.model.controls={"hook":true};host.model.physics_tick=roundi(host.model.elapsed*120)
		host.fishing_view.current_motion=Motion.sample(host.model)
		host.fishing_view.current_depth=depth(host.model)
		var prior_depth: Dictionary=host.fishing_view.current_depth.duplicate()
		for i in range(4):host.model.notes[i].judgment="good"
		var target_depth:=depth(host.model)
		host.fishing_view.advance_view(1.0/60.0)
		check(host.fishing_view.current_depth.fish_merge>prior_depth.fish_merge and host.fishing_view.current_depth.fish_merge<target_depth.fish_merge,"a scored hit eases through intermediate projection at "+str(extent))
		check(is_equal_approx(float(host.fishing_view.current_depth.target_alpha)+float(host.fishing_view.current_depth.fish_merge),1.0),"crossfade remains complementary during interpolation")
		host.toggle_pause()
		var frozen:=JSON.stringify(host.fishing_view.current_depth)
		check(not is_equal_approx(float(host.fishing_view.current_depth.creature_depth),float(depth(host.model).creature_depth)),"held pose differs from neutralized model target at "+str(extent))
		for i in range(4):host.fishing_view.advance_view(.25);await process_frame
		check(JSON.stringify(host.fishing_view.current_depth)==frozen,"pause preserves displayed depth at "+str(extent))
		var near_depth:=depth(host.model).duplicate()
		near_depth.creature_depth=.012;near_depth.fish_merge=1.0
		var geometry: Dictionary=host.fishing_view.creature_geometry(host.fishing_view.size.x*.5,host.fishing_view.size.y*.56,near_depth)
		check(absf(geometry.mouth.x-host.fishing_view.size.x*.5)<.001,"surfaced mouth converges to original fish anchor at "+str(extent))
		for target: float in [-.8,0,.8]:
			var anchor: float=host.fishing_view.size.x*(.5+target*.29)
			var location: Dictionary=host.fishing_view.creature_geometry(anchor,host.fishing_view.size.y*.56,near_depth)
			check(absf(location.mouth.x-anchor)<.001,"tracked head remains at the original aim point across swim range")
		check(Rect2(Vector2.ZERO,host.fishing_view.size).has_point(geometry.mouth) and Rect2(Vector2.ZERO,host.fishing_view.size).intersection(geometry.rect).size.x>=80,"tracked head and readable body remain visible at "+str(extent))
		if host.fishing_view.size.y<420:
			check(geometry.rect.position.y>=host.fishing_view.rhythm_y()+34,"compact rising fish clears beat panel")
			check(geometry.rect.end.y<host.fishing_view.meter_plate_rect().position.y,"compact rising fish clears tension panel")
		var breathing: Dictionary=host.fishing_view.creature_geometry(host.fishing_view.size.x*.5,host.fishing_view.size.y*.56,near_depth,1.0)
		check(is_equal_approx(float(breathing.mouth.y-geometry.mouth.y),float(breathing.position.y-geometry.position.y)),"leader mouth shares the rendered breathing offset")
		host.fishing_view.reset_view()
		check(host.fishing_view.current_depth.is_empty(),"retry clears previous depth at "+str(extent))
		host.restart();host.fishing_view.advance_view(0)
		check(is_equal_approx(float(host.fishing_view.current_depth.creature_depth),.16) and host.fishing_view.current_depth.target_alpha==1,"new attempt restores deep fish and original target visibility")
		host.fishing_view.reduced_motion=true
		host.model.phase="running";host.model.stage="fighting";host.model.cast_at=0;host.model.elapsed=4*host.model.beat_sec
		for note: Dictionary in host.model.notes:note.judgment="great"
		host.fishing_view.advance_view(1.0/60.0)
		check(host.fishing_view.current_depth==depth(host.model,true),"reduced motion updates semantic depth without easing")
		host.queue_free();await process_frame
	print("LAKE_FISHING_DEPTH: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
