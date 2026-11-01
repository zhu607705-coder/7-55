extends SceneTree
const Model=preload("res://campuses/future_learning_center/scripts/coupling_tray_model.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func drag(m:RefCounted,i:int,points:Array[Vector2])->void:
	check(m.begin_drag(),"begin owned movement")
	for point:Vector2 in points:
		m.move_block(i,point)
		check(m.positions[i].distance_to(point)<.01 and m.legal(m.positions,m.linked),"collision-safe route reaches "+str(point))
	m.end_drag()
func solve(m:RefCounted)->void:
	m.detach_bridge()
	if m.level==0:
		drag(m,0,[Vector2(230,274),Vector2(230,302),Vector2(430,302),Vector2(430,230),Vector2(568,230),Vector2(568,274)])
		drag(m,1,[Vector2(156,302),Vector2(430,302),Vector2(430,370),Vector2(568,370),Vector2(568,334)])
	else:
		drag(m,0,[Vector2(230,274),Vector2(230,372),Vector2(584,372),Vector2(584,218),Vector2(474,218)])
		drag(m,1,[Vector2(156,372),Vector2(584,372),Vector2(584,218),Vector2(534,218)])
	check(m.contact(0) and m.contact(1) and not m.trial() and m.outcome=="bridge","two loose contacts cannot power receiver")
	check(m.attach_bridge() and m.trial(),"aligned physical bridge closes circuit")
func _initialize()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	var m=Model.new()
	check(m.legal(m.positions,m.linked) and not m.next_tray(),"valid initial assembly; second tray gated by real trial")
	m.begin_drag();m.move_block(0,Vector2(600,274))
	check(m.blocked and m.positions[0].x<=300 and m.positions[1].x<=300,"linked blocks cannot jump through throat")
	m.end_drag(true);check(m.positions[0]==Vector2(156,274),"cancel rolls whole assembly back")
	check(m.detach_bridge() and m.undo() and m.linked,"detach is one reversible transaction")
	m.detach_bridge();m.begin_drag();m.move_block(0,Vector2(600,220))
	check(m.positions[0].x<=300 and m.blocked,"fast disconnected drag cannot tunnel through wall")
	m.end_drag(true);m.begin_drag();m.move_block(0,Vector2(-500,274))
	check(m.positions[0].x>=76 and m.blocked,"outer rim confines entire foot")
	m.end_drag(true);m.begin_drag();m.move_block(0,Vector2(156,400))
	check(m.positions[0].y<=286 and m.blocked,"slider blocks another slider")
	m.end_drag(true);m.begin_drag();var before:Dictionary=m.snapshot()
	check(not m.move_block(0,Vector2(NAN,0)) and m.snapshot()==before,"nonfinite input rejected")
	m.end_drag(true)
	m.positions.assign([Vector2(300,210),Vector2(368,210)])
	check(m.legal(m.positions,false) and not m.attach_bridge(),"bridge cannot snap through solid wall")
	m.reset();solve(m)
	m.step(INF);m.step(NAN);m.step(-1);check(m.elapsed==0,"invalid time cannot grant completion")
	m.step(90);check(not m.completed[0] and is_equal_approx(m.elapsed,.1),"long frame bounded")
	m.cancel();check(not m.completed[0] and not m.running,"interrupted current never earns")
	m.trial()
	for i:int in 60:m.step(.025)
	check(m.completed[0] and m.powered,"continuous validated current earns first tray")
	m.begin_drag();m.move_block(0,Vector2(490,274));m.end_drag()
	check(not m.powered and m.completed[0],"moving contacts cuts current; historical record remains")
	check(m.next_tray() and m.level==1 and not m.completed[1],"new tray resets assembly without granting second result")
	solve(m)
	for i:int in 60:m.step(.025)
	check(m.completed==[true,true] and m.powered,"perpendicular route validated independently")
	m.reset();check(not m.powered and m.completed==[true,true] and m.history.is_empty(),"physical reset preserves only completed records")
	# Contact assignment is geometric, not a block-id answer whitelist.
	m.positions.assign([Vector2(534,218),Vector2(474,218)]);m.linked=false
	check(m.attach_bridge() and m.ready(),"swapped identities accepted at identical physical contacts")
	print("FLC_COUPLING_MODEL: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
