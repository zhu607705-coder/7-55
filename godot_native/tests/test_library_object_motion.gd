extends SceneTree
## Real controller outcomes drive disposable visual feedback; no parallel progress.
const Motion=preload("res://scripts/presentation/library_object_motion.gd")
const Library=preload("res://scripts/chapters/library022.gd")
var checks:=0
var failures:=0
var state:Node

func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("LIBRARY_OBJECT_MOTION "+label)
func fresh()->Dictionary:
	var s:Dictionary=state.initial()
	s.native.chapter=2;s.native.scene="library_interior";s.native.mode="light";s.native.page="phone_home"
	s.rpgScene="library_interior";s.runtimeMode="rpg";s.actOne.phase="complete"
	s.ui.libraryFinalsPhase="evidence_gathering";s.ui.libraryFinalsPuzzle.entranceRecordRead=true
	return s
func perform(motion:RefCounted,controller:RefCounted,s:Dictionary,action:String)->Dictionary:
	var before:=s.duplicate(true)
	var result:Dictionary=controller.dispatch(s,action)
	motion.sync(s);motion.observe(action,before,s.duplicate(true),result)
	return result
func advance(motion:RefCounted,ms:float)->void:
	for i:int in range(int(ms/10)):motion.advance(.01)

func run()->void:
	state=root.get_node("State")
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated native profile")
	if failures:quit(1);return
	var controller:RefCounted=Library.new()
	var motion:RefCounted=Motion.new()
	var s:=fresh();motion.sync(s)
	perform(motion,controller,s,"lib_catalog_terminal")
	check(motion.catalog_ms<0 and not s.ui.libraryFinalsPuzzle.catalogUnlocked,"story-locked terminal cannot manufacture an unlock animation")
	s.ui.libraryFinalsPuzzle.investigationOpened=true
	perform(motion,controller,s,"lib_catalog_terminal")
	check(motion.catalog_ms==0 and motion.catalog_pose().unlocked,"accepted terminal unlock starts physical screen feedback")
	var earned:=JSON.stringify(s)
	advance(motion,200)
	check(motion.catalog_pose().scanVisible and motion.catalog_pose().indicatorScale>1,"source scan and 130ms indicator pulse run independently")
	advance(motion,230)
	check(not motion.catalog_pose().scanVisible and motion.catalog_ms>0,"420ms source scan ends before its 780ms indicator cycles")
	advance(motion,350)
	check(motion.catalog_ms<0 and motion.catalog_pose().unlocked,"terminal settles to its saved unlocked lamp")
	check(JSON.stringify(s)==earned,"terminal animation changes no controller state")
	perform(motion,controller,s,"lib_catalog_terminal")
	check(motion.catalog_ms<0,"reopening a solved terminal does not replay first unlock")

	s=fresh();s.ui.libraryFinalsPhase="occupied_seat_found";s.ui.libraryFinalsPuzzle.backpackInspected=true;motion.sync(s)
	perform(motion,controller,s,"lib_note")
	check(motion.packets.size()==1 and motion.packets[0].item=="occupancyNote","accepted paper pickup starts one evidence transfer")
	earned=JSON.stringify(s);advance(motion,100)
	var destination:=Rect2(910,470,32,32)
	var poses:Array=motion.evidence_poses({"origin":Vector2(-300,-100),"zoom":.75},Vector2(960,540),destination)
	check(poses.size()==1 and poses[0].destination==destination.get_center(),"transfer uses the actual inventory receiver when supplied")
	check(poses[0].point.is_finite() and poses[0].rotation==PI/2,"packet uses source Stepped travel without changing physical note owner")
	perform(motion,controller,s,"lib_note")
	check(motion.packets.size()==1,"rejected duplicate pickup cannot duplicate a packet")
	advance(motion,920)
	check(motion.packets.is_empty() and JSON.stringify(s)==earned,"pickup retires after receiver pulse with earned inventory intact")

	s=fresh();s.items.rightArrow=true;motion.sync(s)
	perform(motion,controller,s,"lib_receipt")
	check(motion.packets.size()==1 and motion.evidence_poses({},Vector2(960,540)).is_empty(),"receipt waits for its existing physical extraction before transfer")
	advance(motion,520)
	check(motion.evidence_poses({},Vector2(960,540)).size()==1,"source 520ms receipt extraction reveals its transfer")
	check(s.items.seat022Receipt and not s.items.rightArrow,"receipt's original controller consume/reward contract remains authoritative")

	s=fresh();s.ui.libraryFinalsPhase="library_entered";s.ui.libraryFinalsPuzzle.entranceRecordRead=false;motion.sync(s)
	perform(motion,controller,s,"lib_record")
	check(motion.entry_ms==0 and motion.entry_pose().read,"controller-issued admission starts source door sensor feedback")
	advance(motion,430)
	check(not motion.entry_pose().scanVisible and motion.entry_ms>0,"420ms entry scan and 900ms sensor blink keep separate clocks")
	motion.sync(s.duplicate(true))
	check(motion.entry_ms<0 and motion.record_read,"imported read record keeps its solved lamp without replay")

	s=fresh();s.ui.libraryFinalsPhase="backpack_removed";s.ui.libraryFinalsPuzzle.backpackEvicted=true;motion.sync(s)
	motion.set_anchors(Vector2(1320,470),Vector2(1302,500),Rect2(624,519,58,36))
	perform(motion,controller,s,"lib_sit")
	earned=JSON.stringify(s)
	check(motion.sit_ms==0 and motion.actor_pose(Vector2.ZERO).point==Vector2(1320,470),"accepted sit begins at the actually rendered actor")
	advance(motion,10)
	check(motion.actor_pose(Vector2.ZERO).point==Vector2(1302,500) and motion.actor_pose(Vector2.ZERO).facing=="up","source Stepped sit faces the complete original cel up at its chair")
	advance(motion,420)
	check(not motion.actor_pose(Vector2.ZERO).moving and JSON.stringify(s)==earned,"sit completes without moving a body or writing a save")
	check(s.ui.libraryFinalsPhase=="seat_recovered" and s.ui.libraryFinalsPuzzle.nextQuestId==null,"sitting animation cannot grant the third chapter")

	# Lifecycle integration through the real singleton's accepted-action signal.
	var view:=Control.new();root.add_child(view);motion.bind_view(view)
	state.d=fresh();state.d.ui.libraryFinalsPuzzle.investigationOpened=true;motion.sync(state.d)
	state.act("lib_catalog_terminal")
	check(motion.catalog_ms==0 and motion.snapshot().stateConnected,"real action_completed signal starts one animation")
	view.hide()
	check(motion.catalog_ms<0 and motion.packets.is_empty(),"hiding the world cancels every transient feedback clock")
	view.show();motion.sync(state.d)
	check(motion.catalog_ms<0 and motion.catalog_unlocked,"returning keeps solved status without replay")
	state.d=fresh();state.d.ui.libraryFinalsPuzzle.backpackInspected=true;state.d.ui.libraryFinalsPhase="occupied_seat_found"
	state.d.native.settings.reduced_motion=true;motion.sync(state.d);state.act("lib_note");advance(motion,90)
	poses=motion.evidence_poses({},Vector2(390,844))
	check(poses.size()==1 and poses[0].rotation==0 and poses[0].alpha<1,"reduced motion uses a short stationary receiver fade")
	advance(motion,100)
	check(motion.packets.is_empty(),"reduced pickup finishes in 180ms")
	state.d.native.scene="campus_bootstrap";motion.sync(state.d)
	check(not motion.active and not motion.snapshot().stateConnected,"scene change releases the state listener")
	view.queue_free();await process_frame
	check(not motion.active,"destroying the view releases its motion owner")

	var handoff:Dictionary=Motion.handoff_pose(340)
	check(handoff.visible and handoff.bookAlpha==1 and handoff.bookScale==1.2,"source book handoff keeps the original 340ms reveal")
	check(not Motion.handoff_pose(960).visible,"book handoff retires at original yoyo completion")
	check(Motion.handoff_pose(90,true).bookAngle==0 and Motion.handoff_pose(90,true).bookScale==1,"reduced handoff avoids rotation and scale motion")
	motion.dispose()
	print("LIBRARY_OBJECT_MOTION ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
