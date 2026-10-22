extends SceneTree
const Entry=preload("res://scripts/presentation/c3_canteen_paper_view.gd")
const Session=preload("res://scripts/presentation/c3_scene_session.gd")
const Effects=preload("res://scripts/presentation/c3_defense_effects.gd")
const Model=preload("res://scripts/games/canteen_defense_model.gd")
var checks:=0
var failures:=0
var dump: Dictionary={"entry":[],"contacts":[]}
func check(ok: bool,label: String)->void:
	checks+=1
	if not ok: failures+=1;push_error(label)
func stable(run: RefCounted)->String:
	return JSON.stringify([run.result(),run.rng_s0,run.rng_s1,run.rng_s2,run.paper_frame,run.paper_frame_ms,run.route_flash,run.paper_hit_cooldown])
func ghost_record(pose: Dictionary)->Dictionary:
	return {"point":[pose.point.x,pose.point.y],"angle":pose.angle,"frame":pose.frame,"scale":pose.scale,"alpha":pose.alpha,"tint":pose.tint.to_html(false)}
func _initialize()->void:
	for reduced: bool in [false,true]:
		var session:=Session.new({},"canteen",reduced)
		session.status="playing"
		session.trigger_paper=Vector2(1053,302)
		var view:=Entry.new(); view.session=session
		var interval: float=120 if reduced else 78
		for t: float in [0,1,interval,interval*2-0.01]:
			session.elapsed_ms=session.route_start_ms+t; view.tick(100)
			check(view.ghosts.is_empty(),"entry does not emit on initial frame0 or frame1")
		session.elapsed_ms=session.route_start_ms+interval*2;view.tick(100)
		check(view.ghosts.size()==1 and view.ghosts[0].frame==2 and view.ghosts[0].age==0,"first source callback emits frame2 exactly")
		var first:=view.ghost_pose(view.ghosts[0])
		check(first.tint==Color("bdefff") and is_equal_approx(first.alpha,.24) and is_equal_approx(first.scale,.82),"authored ghost tint opacity and captured uniform scale")
		dump.entry.append({"reduced":reduced,"at":interval*2,"pose":ghost_record(first),"duration":view.ghosts[0].duration})
		var frozen:=view.ghosts.duplicate(true);var session_before:=session.snapshot()
		session.paused=true;view.tick(5000);view.tick(100)
		check(view.ghosts==frozen and session.snapshot()==session_before,"paused ghost and controller-issued route remain frozen")
		session.paused=false;view.tick(100)
		check(view.ghosts==frozen,"repaint with unchanged session time cannot age or duplicate ghosts")
		var duration: float=90 if reduced else 220
		session.elapsed_ms+=duration/2;view.tick(100)
		var half:=view.ghost_pose(view.ghosts[0])
		check(is_equal_approx(half.alpha,.12) and is_equal_approx(half.scale,.82*.91),"source linear half-life fade and two-axis0.82 shrink")
		check(half.point==first.point and half.angle==first.angle,"afterimage does not follow live paper")
		dump.entry[-1].half=ghost_record(half)
		# Rewind represents a new attempt. No old frame count survives.
		session.elapsed_ms=session.route_start_ms;view.tick(1)
		check(view.ghosts.is_empty(),"rewind clears old ghosts without emitting frame0")
		session.elapsed_ms+=interval*3+5;view.tick(100)
		check(view.ghosts.size()==(0 if reduced else 1),"coarse step preserves crossed even callback and expires old ghosts")
		if not reduced: check(is_equal_approx(view.ghosts[0].age,interval+5),"crossed event retains correct age")
		view.reset();view.session=session;session.elapsed_ms=session.route_start_ms
		view.tick(0);session.elapsed_ms+=interval*2;view.tick(0)
		check(view.ghosts.size()==1,"reset/re-entry restarts timer phase exactly once")
		session.elapsed_ms=session.escape_end_ms+duration;view.tick(100)
		check(view.ghosts.is_empty(),"invisible escaped paper stops emission and drains ghosts")
		view.reset();check(view.session==null and view.ghosts.is_empty() and view.last_frame==-1,"exit clears all ghost state")
		view.free()
		check_contacts(reduced)
	check_full_replay()
	var path:=OS.get_environment("CANTEEN_EFFECTS_DUMP")
	if not path.is_empty():
		var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(dump))
	call_deferred("check_draw")
func check_contacts(reduced: bool)->void:
	var run:=Model.new();run.configure("paper-effects")
	var effects:=Effects.new();effects.reset(reduced)
	var proof:=stable(run)
	effects.observe(run)
	check(effects.points.is_empty() and stable(run)==proof,"no fabricated initial contact or model writes")
	# Real model collision owns recoil, next exit, route and proof.
	run.paper=Vector2(750,520);run.player=run.paper-Model.BODY_CENTER
	run.route.assign([run.paper+Vector2(100,0)]);run.route_index=0;run.paper_hit_cooldown=0
	run.update_paper()
	check(run.turnarounds==1 and run.route_flash==760,"real model contact remains unchanged in reduced mode")
	proof=stable(run);effects.observe(run)
	var pose:=effects.snapshot()
	check(pose.points[0]==run.paper and pose.points.size()==run.route.size()+1,"route starts at post-recoil paper and copies full contact route")
	for i: int in range(pose.dots.size()):check(pose.dots[i]==run.route[i*2],"only even-index original waypoints receive dots")
	check(is_equal_approx(pose.alpha,.95) and is_equal_approx(pose.line_color.a,.95*.88) and is_equal_approx(pose.dot_color.a,.95*.9),"source composite line/dot opacity")
	check(pose.width==5 and pose.radius==5 and effects.duration_ms==(420 if reduced else 760),"source line radius and reduced duration")
	dump.contacts.append({"reduced":reduced,"duration":effects.duration_ms,"alpha":pose.alpha,"lineAlpha":pose.line_color.a,"dotAlpha":pose.dot_color.a,"width":pose.width,"radius":pose.radius})
	var frozen: Dictionary=effects.snapshot()
	for repaint in range(20):
		effects.observe(run);effects.snapshot();effects.camera_offset(Vector2(960,540),.56525)
	check(effects.snapshot()==frozen and stable(run)==proof,"pause/repaint changes neither effect clocks nor proof/RNG")
	effects.advance(25)
	for layout: Array in [[Vector2(960,540),.56525],[Vector2(366,250),.68],[Vector2(366,206),.2189],[Vector2(548,302),.32]]:
		var extent: Vector2=layout[0];var zoom: float=layout[1]
		var shake: Vector2=effects.camera_offset(extent,zoom)
		check(shake==Vector2.ZERO if reduced else absf(shake.x)<=(extent.x*.0025*zoom+.5)*zoom and absf(shake.y)<=(extent.y*.0025*zoom+.5)*zoom,"desktop/portrait/overview/landscape source shake envelope")
		check(shake==effects.camera_offset(extent,zoom),"camera repaint is deterministic and cannot consume RNG")
		var offset:=Vector2(12,37)+shake
		var camera:=Transform2D(0,Vector2.ONE*zoom,0,offset)
		check((camera*run.paper).is_equal_approx(run.paper*zoom+offset),"one camera composition moves paper room and route together")
	check(stable(run)==proof,"shake and layout composition do not mutate gameplay")
	effects.advance(50);check(effects.camera_offset(Vector2(960,540),1)==Vector2.ZERO,"shake expires exactly at75ms (zero for reduced)")
	# Model movement must not drag the captured flash. Snapshot consumers cannot mutate it.
	run.paper+=Vector2(30,0);run.route[0]+=Vector2(12,0)
	check(effects.snapshot().points==frozen.points,"flash route is frozen at contact")
	pose.points[0]=Vector2.ZERO;check(effects.snapshot().points[0]!=Vector2.ZERO,"snapshot cannot overwrite owned contact geometry")
	effects.advance(effects.duration_ms/2-75)
	check(is_equal_approx(effects.snapshot().alpha,.475),"route linear fade reaches source half alpha")
	# A fresh real contact replaces the old flash, never layers stale waypoints.
	run.player=run.paper-Model.BODY_CENTER;run.paper_hit_cooldown=0;run.update_paper();proof=stable(run)
	effects.observe(run)
	check(effects.contact_count==2 and effects.age_ms==0 and effects.points[0]==run.paper,"repeated contact replaces path and resets fade")
	check(stable(run)==proof,"observing a repeated contact preserves source proof/RNG")
	effects.advance(effects.duration_ms)
	check(effects.snapshot().points.is_empty() and effects.snapshot().dots.is_empty() and effects.snapshot().alpha==0,"source duration clears graphics")
	run.restart_attempt();proof=stable(run);effects.reset(reduced);effects.observe(run)
	check(effects.points.is_empty() and effects.contact_count==0 and stable(run)==proof,"retry clears effects without changing fresh attempt RNG")
func check_full_replay()->void:
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_defense.json"))
	for reduced: bool in [false,true]:
		var run:=Model.new();run.configure(fixture.seed)
		var baseline:=Model.new();baseline.configure(fixture.seed)
		var effects:=Effects.new();effects.reset(reduced)
		for input: Dictionary in fixture.inputs:
			effects.advance(Model.DT*1000);run.step(input);baseline.step(input);effects.observe(run)
			effects.snapshot();effects.camera_offset(Vector2(960,540),.56525)
		check(run.status=="won" and run.tick==3600 and run.turnarounds==82,"complete source60s/82-contact trace remains accepted")
		check(stable(run)==stable(baseline),"normal/reduced effect consumers preserve complete gameplay proof and RNG")

class DrawProbe extends Node2D:
	var drawn:=false
	func _draw()->void:
		var effects:=Effects.new();effects.points=PackedVector2Array([Vector2(10,10),Vector2(70,20),Vector2(80,50),Vector2(120,40)])
		effects.draw(self)
		var paper=Entry.Paper
		paper.draw(self,Vector2(60,100),.82,-6,2,.24,false,Transform2D.IDENTITY,Vector2.ONE,Color("bdefff"))
		drawn=true
func check_draw()->void:
	var probe=DrawProbe.new();root.add_child(probe)
	await process_frame;await process_frame
	check(probe.drawn,"native Canvas executes route dots and tinted original paper")
	probe.free()
	print("CANTEEN_PAPER_EFFECTS ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
