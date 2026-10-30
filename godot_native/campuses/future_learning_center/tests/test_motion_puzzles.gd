extends SceneTree
const Solar=preload("res://campuses/future_learning_center/scripts/solar_race_model.gd")
const Robot=preload("res://campuses/future_learning_center/scripts/robot_delivery_model.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	var m:=Solar.new();m.start();m.step(30)
	check(not m.complete and is_equal_approx(m.cars[0].distance,m.cars[1].distance),"Identical cars must tie")
	m.configure("tilt",1);m.start();m.step(29.95)
	check(m.running and not m.complete and not m.earned,"A partial lead cannot complete")
	m.step(.05);check(m.complete and m.ticks==600 and m.last_trial.trace.size()==60,"Full race beats baseline from observable distance")
	var distance:float=m.cars[0].distance;m.start()
	for i:int in 1800:m.step(1.0/60)
	check(is_equal_approx(m.cars[0].distance,distance),"Frame rate must not change distance")
	m.start();m.step(12);m.cancel();m.step(40)
	check(not m.complete and m.ticks==240 and m.best[0]==distance,"Cancelled trial cannot record a partial best")
	m.start();m.step(3);m.configure("panel",1);m.step(30)
	check(not m.running and not m.complete,"Editing invalidates an in-flight race")
	check(m.undo() and m.setup.panel==0 and not m.complete,"Undo restores configuration, not completion")
	m.configure("sky",2);m.start();m.step(30)
	check(m.cars[0].distance==0 and m.cars[1].distance==0 and not m.complete,"No light from rest cannot move or win")
	m.configure("sky",1);m.configure("tilt",2);m.start();m.step(30)
	check(m.complete and m.best.has(1) and m.best.has(0),"Side light uses separate best and correct tilt")
	m.start();m.step(NAN);m.step(-1);m.step(INF)
	check(m.ticks==0,"Invalid elapsed time cannot advance")
	check(not m.configure("panel",-1) and not m.configure("gear",99) and not m.configure("unknown",0),"Reject invalid parts")
	var wins:=0
	for panel:int in 2:
		for tilt:int in 3:
			for gear:int in 3:
				var trial:=Solar.new();trial.configure("panel",panel);trial.configure("tilt",tilt);trial.configure("gear",gear);trial.start();trial.step(30)
				if trial.complete:wins+=1
				check(is_finite(trial.cars[0].distance) and trial.cars[0].distance>=0,"Legal setup has finite nonnegative motion")
	check(wins>1 and wins<18,"Challenge accepts multiple builds without making every build win")
	var r:=Robot.new();r.start();r.step(20)
	check(r.phase=="blocked" and r.delivered and not r.complete and r.returning,"Outward delivery alone must fail at return one-way")
	check(r.position.x<3 and r.visible_front().x>=2.5 and r.cargo=="destination","Visible front stays outside wrong-direction entry, cargo remains at station")
	check(r.last_trace.size()>4,"Failure retains actual outbound and return trace")
	r.edit(Vector2i(2,1),true);r.start();r.step(5)
	check(not r.complete and r.phase=="unloading","Arrival without unloading/return is incomplete")
	r.step(5);check(r.complete and r.cell==Robot.BASE and r.cargo=="destination","Bidirectional module permits true empty return")
	r.edit(Vector2i(1,1));check(not r.complete and r.cargo=="base" and r.position==Vector2(Robot.BASE),"Post-success edits invalidate evidence and reset physical cargo")
	r.undo();r.start();r.step(20);check(r.complete,"Undo can restore an actually traversable route")
	var upper:=Robot.new();upper.change_outlet();upper.edit(Vector2i(0,0));upper.edit(Vector2i(4,0));upper.edit(Vector2i(4,0));upper.start();upper.step(30)
	check(upper.complete and upper.tiles[Vector2i(2,1)].kind=="oneway","Alternate upper loop succeeds without replacing one-way")
	var lower:=Robot.new();lower.change_outlet();lower.change_outlet()
	for i:int in 2:lower.edit(Vector2i(4,2))
	for i:int in 3:lower.edit(Vector2i(0,2))
	lower.start();lower.step(30);check(lower.complete,"Lower loop is also accepted")
	var gap:=Robot.new();gap.edit(Vector2i(1,1));gap.start();gap.step(20)
	check(gap.phase=="blocked" and not gap.delivered and gap.visible_front().x<=.5,"Visible front stops before disconnected entry")
	var discrete:=Robot.new();discrete.edit(Vector2i(2,1),true)
	for i:int in 10:discrete.advance_one()
	check(discrete.complete,"Single-segment controls obey same traversal as continuous")
	var cancelled:=Robot.new();cancelled.start();cancelled.step(6.4);cancelled.cancel();cancelled.step(30)
	check(not cancelled.complete and cancelled.cargo=="base" and cancelled.position==Vector2(Robot.BASE),"Cancellation returns safe reusable cargo")
	var paused:=Robot.new();paused.start();paused.step(2.3);paused.pause();var position:Vector2=paused.position;paused.step(10)
	check(paused.position==position and paused.resume(),"Pause/resume preserves physical location")
	paused.step(NAN);paused.step(-1);check(paused.position==position,"Robot rejects invalid time")
	check(not paused.edit(Robot.BASE) and not paused.edit(Vector2i(12,0)),"Cannot rotate origin or nonexistent tile")
	var frame_data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/future_learning_center/assets/puzzles/oblique45_frames.json")).vehicles
	var held:=Solar.new();held.start();held.step(7.3);held.pause();var held_distance:float=held.cars[0].distance;held.step(20)
	check(held.cars[0].distance==held_distance and not held.complete,"Neutral lever cannot advance a paused solar race")
	check(held.resume(),"Valid paused solar race resumes on forward lever")
	held.step(30);var previous_best:float=held.best[0];held.return_to_start()
	check(held.ticks==0 and held.cars[0].distance==0 and held.best[0]==previous_best and not held.complete,"Physical return preserves record but resets transient race")
	held.start();held.step(3);held.pause();held.configure("tilt",1)
	check(not held.resume(),"Configuration change rejects stale paused trial")
	var placement:=Robot.new()
	check(not placement.place_module(Robot.BASE,"straight",0) and not placement.place_module(Vector2i(2,1),"unknown",0),"Physical module placement protects fixed stations and part types")
	check(placement.place_module(Vector2i(2,1),"straight",0),"Direct placement installs a valid module")
	placement.start();placement.step(20);placement.return_to_start()
	check(placement.earned and not placement.complete and placement.cargo=="base","Returning completed robot preserves earned record without an active proof")
	var before_swap:Dictionary=placement.tiles[Vector2i(0,0)].duplicate()
	check(placement.swap_modules(Vector2i(0,0),Vector2i(1,0)) and placement.tiles[Vector2i(1,0)]==before_swap,"Dragging a module exchanges its complete orientation and kind")
	check(placement.undo() and placement.tiles[Vector2i(0,0)]==before_swap,"One physical swap is one reversible transaction")
	check(not placement.set_outlet(0) and placement.set_outlet(3),"Guide accepts only physical return exits")
	for direction:int in 4:
		check(is_equal_approx(Robot.Props.front_distance(direction),41.5*(1.0 if direction%2==0 else sin(PI/4))),"The physical nose uses the same ground footprint in every direction")
		var contact:=Robot.new();contact.cell=Vector2i(1,1);contact.position=Vector2(contact.cell);contact.run_revision=contact.revision;contact.running=true
		contact.tiles.erase(contact.cell+Robot.DIRECTIONS[direction]);contact._begin_edge(direction);contact.step(3)
		var front_offset:Vector2=(contact.visible_front()-Vector2(contact.cell))*Robot.Props.CELL
		var contact_limit:float=(Robot.Props.CELL.x if direction%2==0 else Robot.Props.CELL.y)*.5
		check(contact.phase=="blocked" and front_offset.length()<=contact_limit-Robot.Props.STOP_MARGIN+.01,"All four visible noses stop before entry with margin")
	print("FLC_MOTION_MODELS: %d checks, %d failures; %d winning solar builds"%[checks,failures,wins]);quit(1 if failures else 0)
