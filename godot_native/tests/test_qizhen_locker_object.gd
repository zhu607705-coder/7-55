extends SceneTree
const Locker=preload("res://scripts/presentation/qizhen_locker_object.gd")
const Lake=preload("res://scripts/chapters/c3_lake.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("QIZHEN LOCKER: "+label)
func fixture()->Dictionary:
	var s:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":3,"scene":"qizhen_lake","page":"c3_lake","mode":"light","player":{"x":430.,"y":835.},"settings":{"reduced_motion":false},"selected_item":"rustedLockerKey"}
	s.qizhenLake.merge({"active":true,"phase":"tool_chain","zone":"dock","vehicle":"on_foot","lockerOpened":false},true)
	s.items.rustedLockerKey=true;s.items.nylonCord=false;s.ui.selectedItem="rustedLockerKey"
	return s
func advance(item:RefCounted,state:Dictionary,seconds:float)->void:
	while seconds>0:
		var step:=minf(.04,seconds);item.tick(step,state);seconds-=step
func run()->void:
	var s:=fixture();var item:RefCounted=Locker.new();item.attach(root);item.sync(s)
	check(item.actor is Node2D and item.actor.get_node("DoorMotion") is AnimationPlayer,"one real independent object owns an AnimationPlayer")
	check(item.snapshot().phase=="closed" and item.snapshot().slidePixels==0,"fresh closed state keeps the exact authored leaves")
	var unchanged:=JSON.stringify(s);advance(item,s,.6)
	check(JSON.stringify(s)==unchanged and item.play_count==0,"time alone grants no key, cord or opening")
	var rejected:=s.duplicate(true);rejected.items.rustedLockerKey=false
	var controller:RefCounted=Lake.new();controller.dispatch(rejected,"c3_lake_target:qizhen_use_item_1")
	item.sync(rejected)
	check(item.snapshot().phase=="closed" and item.play_count==0,"rejected original key operation cannot animate an opening")
	item.sync(s)
	controller.dispatch(s,"c3_lake_target:qizhen_use_item_1")
	check(s.qizhenLake.lockerOpened and s.items.nylonCord and not s.items.rustedLockerKey,"original controller commits the key-to-cord transaction")
	var committed:=JSON.stringify(s);item.sync(s)
	check(item.snapshot().phase=="unlatching" and item.play_count==1,"only an observed accepted false-to-true edge starts one motion")
	advance(item,s,.65)
	check(item.snapshot().phase=="opening" and item.snapshot().slidePixels>0 and item.snapshot().slidePixels<30,"AnimationPlayer moves both leaves through a partial source-pixel pose")
	var time:float=item.elapsed;item.tick(0,s)
	check(item.elapsed==time,"paused world time does not advance motion")
	advance(item,s,2)
	check(item.snapshot().phase=="open" and item.snapshot().slidePixels==30 and not item.playing,"accepted cabinet stays visibly unlocked at the settled open pose")
	check(item.actor.cord_alpha==0 and JSON.stringify(s)==committed,"the take-out illustration settles without another item grant or save mutation")
	for i:int in 8:item.sync(s);item.tick(.05,s)
	check(item.play_count==1,"ordinary redraws and syncs never replay the acquisition")
	s.native.scene="campus_qizhen_loop";item.sync(s)
	check(not item.active and not item.playing,"scene exit retires the object clock")
	s.native.scene="qizhen_lake";item.sync(s)
	check(item.snapshot().phase=="open" and item.play_count==1,"returning to the dock restores the earned open pose without replay")
	var imported:=s.duplicate(true);item.sync(imported)
	check(item.snapshot().phase=="open" and not item.playing and item.actor.cord_alpha==0,"a replacement save derives the terminal pose without a stale take-out")
	var fresh:=fixture();item.sync(fresh);controller.dispatch(fresh,"c3_lake_target:qizhen_use_item_1");item.sync(fresh);advance(item,fresh,.4)
	fresh.qizhenLake.zone="open_water";item.sync(fresh);fresh.qizhenLake.zone="dock";item.sync(fresh)
	check(item.snapshot().phase=="open" and not item.playing and fresh.items.nylonCord,"interrupting mid-motion preserves the committed transaction and open return pose")
	fresh=fixture();fresh.native.settings.reduced_motion=true;item.sync(fresh);controller.dispatch(fresh,"c3_lake_target:qizhen_use_item_1");item.sync(fresh)
	check(item.snapshot().phase=="open" and not item.playing and item.snapshot().slidePixels==30,"reduced motion settles directly without shaking or a delayed grant")
	var final:Dictionary=item.snapshot()
	check(final.leftLeaf.size==Vector2(6,61) and final.rightLeaf.size==Vector2(6,61),"opened leaves crop original pixels instead of compressing the metal texture")
	check(Locker.FACE==Rect2(277,744,72,61),"the independent face stays inside the measured source door frame")
	item=null
	await process_frame
	check(root.get_node_or_null("QizhenLockerObject")==null,"disposing the presentation releases its owned object and AnimationPlayer")
	print("QIZHEN_LOCKER_OBJECT: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
