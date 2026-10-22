extends SceneTree
const Guard=preload("res://scripts/games/chapter4_guard_model.gd")
const Navigation=preload("res://scripts/games/chapter4_guard_navigation.gd")
var failures: int=0
var checks: int=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1; push_error(label)
func _initialize() -> void:
	var state: Dictionary=Guard.maintenance_state()
	check(Guard.can_see(state,Vector2(900,560),[]),"220px forward cone")
	check(not Guard.can_see(state,Vector2(900,700),[]),"Cone angle rejects side target")
	check(Guard.can_see(state,Vector2(1150,560),[]),"56px close radius ignores facing")
	check(not Guard.can_see(state,Vector2(900,560),[Rect2(980,500,30,150)]),"Real wall blocks line of sight")
	var result: Dictionary=Guard.maintenance_step(state,399,Vector2(1105,560),Vector2(1005,560),[])
	check(result.state.mode=="confirming" and not result.enteredPursuit,"399ms cannot acquire pursuit")
	result=Guard.maintenance_step(result.state,1,result.state.position,Vector2(1005,560),[])
	check(result.state.mode=="pursuit" and result.enteredPursuit,"400ms acquires pursuit")
	result=Guard.maintenance_step(result.state,900,result.state.position,Vector2(100,100),[])
	check(result.state.mode=="returning" and result.disengaged,"900ms lost sight disengages")
	check(Guard.maintenance_contact(Vector2(100,100),Rect2(105,105,15,15)),"Foot-box contact")
	state=Guard.chase_state(4)
	var input: Dictionary={"deltaMs":500,"committedAndApplied":true,"floor":"A1","guardPosition":Vector2(590,724),"playerPosition":Vector2(590,612),"playerInsideFinish":false,"playerEnteredMainStair":false,"guardContact":false}
	for i in range(3): state=Guard.chase_step(state,input).state
	check(state.phase=="arming","Four committed frames and two-second grace")
	result=Guard.chase_step(state,input); state=result.state; check(state.phase=="running" and result.guardVisible,"Chase arms after both conditions")
	input.floor="A2"; input.playerInsideFinish=true; input.guardContact=true; result=Guard.chase_step(state,input)
	check(result.finishRequested and not result.failureRequested,"Finish wins same-frame contact")
	state=Guard.resolve_finish(result.state,false); check(state.phase=="running" and not state.finishRequestIssued,"Denied finish permits safe retry")
	input.floor="A1"; input.playerInsideFinish=false; input.guardContact=false; input.playerEnteredMainStair=true; result=Guard.chase_step(state,input)
	check(result.portalRequested and result.state.phase=="portal_transfer","Main stair starts guarded transfer")
	state=Guard.resolve_portal(result.state,true); check(state.portalApplied and state.floor=="A2","Accepted portal retains remaining guard route")
	var nav=Navigation.new(); nav.setup([Rect2(120,0,35,160)],320,240)
	check(not nav.line(Vector2(60,80),Vector2(260,80)),"Guard path never cuts blocked furniture")
	var route: Array=nav.path(Vector2(60,80),Vector2(260,80)); check(not route.is_empty(),"Source 14px A-star finds open detour")
	var cursor: Vector2=Vector2(60,80); var clear: bool=true
	for point in route:
		if not nav.line(cursor,point): clear=false
		cursor=point
	check(clear,"All smoothed guard segments retain expanded-foot clearance")
	print("CHAPTER4_GUARD_TESTS ",checks," checks; ",failures," failures"); quit(1 if failures else 0)
