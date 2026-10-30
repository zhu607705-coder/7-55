extends SceneTree
const Model=preload("res://campuses/future_learning_center/scripts/pantry_tray_model.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func advance(m:RefCounted,seconds:float,dt:=.025)->void:
	for i:int in floori(seconds/dt):m.step(dt)
	var remainder:=seconds-floorf(seconds/dt)*dt
	if remainder>0:m.step(remainder)
func fill(m:RefCounted,slot:int,ml:float)->void:
	m.dock(slot);m.set_tap(true);advance(m,ml/4.0);m.undock(slot)
func _initialize()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	var m=Model.new()
	check(m.water==[0.0,0.0,0.0,0.0] and m.stable(),"Four glasses start genuinely empty")
	m.lift();advance(m,1)
	check(m.phase=="held" and not m.send() and not m.earned,"Empty balanced tray cannot bypass water preparation")
	m.lower();check(not m.set_tap(true),"No unattended flow without a cup")
	check(m.dock(0) and not m.dock(1) and not m.lift(),"One real docked cup removes it from carry trial")
	m.set_tap(true);advance(m,5)
	check(is_equal_approx(m.water[0],20) and m.water[1]==0,"Five real seconds add only 20 ml to selected cup")
	m.set_tap(false);advance(m,10)
	check(is_equal_approx(m.water[0],20),"Closed tap stops addition")
	m.set_tap(true);m.step(NAN);m.step(-1);m.step(INF)
	check(is_equal_approx(m.water[0],20),"Non-finite and negative time cannot fill")
	m.step(999)
	check(is_equal_approx(m.water[0],20.4),"A delayed frame cannot fast-forward the water")
	m.cancel();var preserved:float=m.water[0];advance(m,30)
	check(m.water[0]==preserved and m.dock_slot==0 and not m.tap_open,"Focus cancellation stops valve and retains real water and cup")
	m.set_tap(true);advance(m,60)
	check(is_equal_approx(m.water[0],180) and not m.tap_open,"Full cup caps at real capacity and shuts valve")
	m.set_draining(true);advance(m,1)
	check(is_equal_approx(m.water[0],132) and not m.tap_open,"Holding cup over basin drains actual volume")
	m.set_draining(false);advance(m,4)
	check(is_equal_approx(m.water[0],132),"Returning cup stops drain immediately")
	m.set_draining(true);advance(m,4);m.set_draining(false)
	check(m.water[0]==0,"Drain recovery never produces negative water")
	m.undock(0);check(not m.undock(0) and m.cups==[0,1,2,3],"Returning a cup conserves identities")
	for i:int in 4:fill(m,i,Model.TARGETS[i])
	check(m.portions_ready() and not m.ready(),"Matching all four portions alone still leaves a balance problem")
	# None of the 24 exact centre fills balances: within-band fine adjustment matters.
	var permutations:=0
	for a:int in 4:
		for b:int in 4:
			for c:int in 4:
				for d:int in 4:
					if [a,b,c,d].count(a)!=1 or [a,b,c,d].count(b)!=1 or [a,b,c,d].count(c)!=1:continue
					m.cups.assign([a,b,c,d]);check(not m.stable(),"Target-centre permutation requires fine adjustment");permutations+=1
	check(permutations==24,"Examined all distinct cup orders")
	# Two different authored witnesses demonstrate alternate solutions, no answer whitelist.
	for volumes:Array in [[65.0,85.0,115.0,155.0],[66.0,86.0,114.0,154.0]]:
		var solved=Model.new()
		for i:int in 4:fill(solved,i,volumes[i])
		solved.swap(1,3);check(solved.ready(),"Feasible water and order witness")
		solved.lift();advance(solved,1);solved.send();advance(solved,.4);solved.cancel();advance(solved,2)
		check(not solved.earned and solved.phase=="table","Interrupted transport does not award completion")
		solved.lift();advance(solved,1);solved.send();advance(solved,2)
		check(solved.earned and solved.deliveries==1,"Only complete real water-ready delivery earns result")
		solved.send();advance(solved,2);check(solved.deliveries==1,"Duplicate delivery rejected")
	var advanced=Model.new()
	for i:int in 4:fill(advanced,i,[65.0,85.0,115.0,155.0][i])
	advanced.swap(1,3);advanced.lift();advance(advanced,1);advanced.send();advance(advanced,2);advanced.lower()
	advanced.move_support(.25);advanced.swap(0,3);advanced.swap(1,3)
	advanced.dock(3);advanced.set_draining(true);advance(advanced,5.0/48);advanced.set_draining(false);advanced.undock(3)
	check(advanced.ready(),"Shifted-support challenge has a feasible water-adjusted solution")
	advanced.lift();advance(advanced,1);advanced.send();advance(advanced,2)
	check(advanced.advanced_earned,"Changed support requires its own validated carry")
	advanced.lower();advanced.lift();advanced.revision+=1;advance(advanced,1)
	check(advanced.phase=="table","Stale preparation revision cancels lift")
	check(not advanced.dock(-1) and not advanced.dock(4) and not advanced.move_support(INF),"Invalid cup or support rejected")
	print("FLC_PANTRY_MODEL: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
