extends SceneTree
## Runtime-only contract tests. Render visibility is supplied here deliberately;
## actual mesh/light visibility and pixel counterexamples belong to render tests.
const Model = preload("res://scripts/raking_model.gd")
const GOOD := {"contrast":0.30,"coverage":0.92,"incidence":12.0}
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("TEST FAILED: "+message)
	else: print("PASS ",message)

func arrangement(model) -> Array:
	return [model.paper_tilt,model.lamp_azimuth,model.lamp_elevation]

func observe(model, seconds: float, visibility: Dictionary=GOOD, fps: int=30) -> void:
	for frame: int in range(int(ceil(seconds*fps))): model.update(1.0/fps,visibility)

func prepare(model) -> void:
	model.start(0,"paper"); model.drag(0,Vector2(12,16)); model.release(0)
	model.start(1,"lamp"); model.drag(1,Vector2(-10,20)); model.release(1)

func _init() -> void:
	var model=Model.new()
	var initial: Array=arrangement(model)
	observe(model,4)
	check(not model.completed and model.stable_time==0,"Waiting at entry cannot auto-complete, even with a fabricated good visibility fixture")
	check(not model.start(0,"button") and model.owners.is_empty(),"Unknown target cannot acquire an owner")
	check(model.start(0,"paper") and model.start(1,"lamp"),"Two fingers independently own paper and lamp")
	check(not model.start(0,"history") and model.owners[0]=="paper","One pointer cannot steal a second target")
	check(not model.start(2,"paper") and not model.owners.has(2),"Second pointer cannot steal an already-owned paper")
	model.drag(0,Vector2(20,10))
	check(model.paper_tilt!=initial[0] and model.lamp_azimuth==initial[1] and model.lamp_elevation==initial[2],"Paper drag changes only paper angles")
	var paper: Vector2=model.paper_tilt
	model.drag(1,Vector2(-20,30))
	check(model.paper_tilt==paper and model.lamp_azimuth!=initial[1] and model.lamp_elevation!=initial[2],"Lamp drag changes lighting angles without changing held paper")
	model.release(2)
	check(model.owners.size()==2,"Unowned release cannot release either real hand")
	model.release(0)
	check(not model.owners.has(0) and model.owners.has(1),"Releasing paper preserves lamp ownership")
	var before: Array=arrangement(model)
	model.drag(0,Vector2(100,100))
	check(arrangement(model)==before,"A stale paper drag after release cannot move the paper")
	model.release(1)
	check(model.owners.is_empty(),"Release completes pointer cleanup without extra gesture state")
	check(model.start(2,"history"),"History can be owned for read-only dragging")
	model.drag(2,Vector2(800,-800)); model.release(2)
	check(arrangement(model)==before and model.completion_count==0,"History drag cannot write present paper, lamp or completion")
	model.reset(); prepare(model)
	for field: String in ["contrast","coverage","incidence"]:
		var bad: Dictionary=GOOD.duplicate()
		bad[field]=0.0 if field!="incidence" else 60.0
		observe(model,3,bad)
		check(not model.completed and model.stable_time==0,"Bad "+field+" cannot complete regardless of waiting")
	observe(model,3,{})
	check(not model.completed,"Missing visibility evidence cannot complete")
	for field: String in ["contrast","coverage","incidence"]:
		var bad: Dictionary=GOOD.duplicate(); bad[field]=INF
		observe(model,3,bad)
		check(not model.completed,"Nonfinite "+field+" cannot count as visibility evidence")
	model.reset(); model.start(0,"paper"); model.drag(0,Vector2(20,20)); model.release(0)
	observe(model,3)
	check(not model.completed,"Only moving paper cannot solve without an actual lamp adjustment")
	model.reset(); model.start(0,"lamp"); model.drag(0,Vector2(20,20)); model.release(0)
	observe(model,3)
	check(not model.completed,"Only moving lamp cannot solve without an actual paper adjustment")
	model.reset(); prepare(model); observe(model,0.8)
	check(not model.completed and model.stable_time>0,"Good illumination requires a stable observation interval")
	model.start(0,"paper"); model.drag(0,Vector2(2,2))
	check(model.stable_time==0 and model.quiet_time==0,"Moving a real object clears partial stable observation")
	model.release(0); observe(model,0.8)
	model.update(0.1,{"contrast":0,"coverage":1,"incidence":12})
	check(model.stable_time==0 and not model.completed,"A visibility interruption invalidates accumulated progress")
	observe(model,0.8); model.cancel_all()
	check(model.owners.is_empty() and model.stable_time==0 and model.quiet_time==0 and not model.completed,"Cancel clears both owners and partial observation, never commits")
	observe(model,0.8); model.suspend(); var paused: Array=arrangement(model)
	observe(model,10)
	check(model.suspended and not model.completed and model.stable_time==0 and not model.start(9,"lamp"),"Suspended scene cannot acquire a new owner or finish in background")
	model.resume()
	check(not model.suspended and model.owners.is_empty() and arrangement(model)==paused and model.stable_time==0,"Explicit resume preserves arrangement but never resurrects stale pointers or progress")
	observe(model,0.8)
	check(not model.completed,"Resume starts a new complete observation interval")
	observe(model,1.0)
	check(model.completed and model.completion_count==1 and model.owners.is_empty(),"Stable visible actual arrangement completes exactly once")
	before=arrangement(model)
	observe(model,5); model.release(99); model.drag(0,Vector2(200,200))
	check(not model.start(0,"paper") and model.completion_count==1 and arrangement(model)==before,"Terminal inputs cannot award twice or mutate the solved arrangement")
	model.reset()
	check(arrangement(model)==initial and model.completion_count==0 and not model.completed and not model.suspended and not model.paper_moved and not model.lamp_moved,"Retry restores the entire local attempt without persistent facts")
	model.start(0,"paper"); before=arrangement(model)
	model.drag(0,Vector2(NAN,0)); model.drag(0,Vector2(0,INF))
	check(arrangement(model)==before and not model.paper_moved,"Malformed drag cannot poison angles or satisfy movement")
	model.drag(0,Vector2(100000,-100000)); model.release(0)
	check(absf(model.paper_tilt.x)<=18 and absf(model.paper_tilt.y)<=18,"Paper tilt remains in safe physical limits")
	model.start(1,"lamp"); model.drag(1,Vector2(-100000,100000)); model.release(1)
	check(model.lamp_azimuth>=-145 and model.lamp_azimuth<=145 and model.lamp_elevation>=8 and model.lamp_elevation<=65,"Lamp motion remains in reachable physical limits")
	model.reset(); prepare(model); observe(model,0.6)
	var timer: float=model.stable_time
	for dt: float in [-1.0,0.0,NAN,INF]: model.update(dt,GOOD)
	check(model.stable_time==timer and not model.completed,"Invalid frame deltas do not change progress")
	model.update(30.0,GOOD)
	check(not model.completed and model.stable_time==0 and model.quiet_time==0,"Large stalled frame cannot substitute for real observation")
	for fps: int in [15,30,60,120]:
		model.reset(); prepare(model); observe(model,2.0,GOOD,fps)
		check(model.completed and model.completion_count==1,"Ordinary observation completes at %d FPS" % fps)
	print("RAKING_MODEL checks=",checks," failures=",failures)
	quit(1 if failures else 0)
