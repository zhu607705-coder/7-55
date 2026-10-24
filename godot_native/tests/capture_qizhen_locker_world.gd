extends SceneTree
## Source-coordinate fixture; real World drawing, walking/collision, item drop,
## State dispatch and original lake transaction. No controller outcome injection.
const Locker=preload("res://scripts/presentation/qizhen_locker_object.gd")
var checks:=0
var failures:=0
var observations:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1;observations.append({"passed":ok,"label":label})
	if not ok:failures+=1;push_error(label)
func _initialize()->void:run.call_deferred()
func capture(vp:SubViewport,world:Control,path:String)->void:
	world.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(path)
func run()->void:
	if DisplayServer.get_name()=="headless" or not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS,true)
	var out:=OS.get_environment("QIZHEN_LOCKER_OUTPUT")
	if out.is_empty():quit(2);return
	DirAccess.make_dir_recursive_absolute(out)
	var state:Node=root.get_node("State");state.developer_mode=false;state.d=state.initial()
	var s:Dictionary=state.d
	s.native.merge({"chapter":3,"scene":"qizhen_lake","page":"c3_lake","mode":"light"},true)
	s.runtimeMode="rpg";s.rpgScene="qizhen_lake"
	s.qizhenLake.merge({"active":true,"phase":"tool_chain","zone":"dock","vehicle":"on_foot","lockerOpened":false,"rainSafetyCleared":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true,"boardingTutorialCompleted":true},true)
	s.items.rustedLockerKey=true;s.items.nylonCord=false
	var vp:=SubViewport.new();vp.size=Vector2i(960,540);vp.disable_3d=true;vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
	var world:Control=load("res://scripts/world.gd").new();world.size=Vector2(960,540);vp.add_child(world);world.set_process(false)
	state.changed.connect(world.refresh_world)
	# Initial fixture only. Reaching the original stand uses World movement and
	# the existing collision mask, from a clear dock-floor point.
	world.player=Vector2(590,870);world._sync_player();world.transition_alpha=0
	check(world.can_stand(world.player),"initial dock floor is legal")
	world.move_target=Vector2(430,835)
	var walked:=0.;var clear_steps:=true
	for frame:int in 100:
		var before:Vector2=world.player;world._process(1./60)
		walked+=world.player.distance_to(before);clear_steps=clear_steps and world.can_stand(world.player)
		if world.move_target==Vector2.INF:break
	check(walked>150 and clear_steps and world.player.distance_to(Vector2(430,835))<6,"original stand is reached along the real collision-resolved dock floor")
	world.camera=Vector2(430,720);world.zoom=1.;world.transition_alpha=0
	await capture(vp,world,out.path_join("06-world-closed.png"))
	var face:Vector2=Locker.FACE.get_center()
	var picked:Dictionary=world._pick_target(face,true)
	check(str(picked.get("id",""))==Locker.TARGET,"the drawn source door face is the actual inventory-drop surface")
	check(world._distance(picked)<=float(picked.get("radius",0)),"original proximity contract accepts the unchanged authored stand")
	var local:Vector2=world.size/2+(face-world.camera)*world.zoom
	world._drop_data(local,{"kind":"inventory_item","item":"rustedLockerKey"})
	check(s.qizhenLake.lockerOpened and s.items.nylonCord and not s.items.rustedLockerKey,"real World item drop invokes State and the original atomic key-to-cord transaction")
	check(str(s.native.selected_item).is_empty() and s.ui.selectedItem==null,"consumed key selection is cleared by the existing controller")
	check(world.chapter3_layers.qizhen_locker.play_count==1,"real State changed refresh starts one independent object motion")
	for frame:int in 13:world._process(1./60)
	world.transition_alpha=0;await capture(vp,world,out.path_join("07-world-unlatch.png"))
	for frame:int in 27:world._process(1./60)
	await capture(vp,world,out.path_join("08-world-opening.png"))
	for frame:int in 70:world._process(1./60)
	await capture(vp,world,out.path_join("09-world-open.png"))
	check(world.chapter3_layers.qizhen_locker.snapshot().phase=="open","actual World tick settles the cabinet open")
	check(world._pick_target(face,true).is_empty(),"taken cord retires the usable door surface without a ghost key target")
	var earned:Dictionary=s.duplicate(true)
	world._drop_data(local,{"kind":"inventory_item","item":"rustedLockerKey"})
	check(s==earned,"repeated physical drop cannot repeat the reward")
	s.native.mode="dark";world.mode_mix=1.;world.refresh_world();world.transition_alpha=0
	await capture(vp,world,out.path_join("10-world-open-dark.png"))
	check(world.chapter3_layers.qizhen_locker.snapshot().phase=="open" and world.chapter3_layers.qizhen_locker.play_count==1,"mode refresh preserves the earned pose without replay")
	var report={"checks":checks,"failures":failures,"walkedSourcePixels":walked,"player":world.player,"pickedAtSourceFace":face,"snapshot":world.chapter3_layers.qizhen_locker.snapshot(),"observations":observations,"scope":"Godot4.7.1 GPU World instance with isolated fixture prerequisites, collision-resolved on-foot approach and real World item-drop handler through State; no Main shell, browser or physical-device claim."}
	var file:=FileAccess.open(out.path_join("world-report.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("QIZHEN_LOCKER_WORLD ",JSON.stringify(report));world.free();vp.free();quit(1 if failures else 0)
