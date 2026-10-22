extends SceneTree
## Failed presenters cannot restore or cancel state owned by another presenter.
const Session=preload("res://scripts/media/c3_rain_rescue_session.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("RAIN OWNERSHIP: "+label)
func view() -> Control:
	var result: Control=load("res://scripts/media/c3_rain_rescue.gd").new(); root.add_child(result); result.set_process(false)
	return result
func world_state(world: Control) -> Array:
	return [world.camera,world.zoom,world.presentation_actor_hidden,world.move_target,world.touch_axis]
func run() -> void:
	var state: Node=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	state.d.native.merge({"chapter":3,"scene":"qizhen_lake","page":"c3_lake","mode":"light","positions":{}},true)
	state.d.runtimeMode="rpg"; state.d.rpgScene="qizhen_lake"
	state.d.qizhenLake.merge({"active":true,"phase":"boarding_tutorial","zone":"dock","vehicle":"on_foot","rainWarningSeen":true,"rainSafetyCleared":false,"rainRescueCompleted":false},true)
	var world: Control=load("res://scripts/world.gd").new(); root.add_child(world); world.set_process(false)
	world.camera=Vector2(643,487); world.zoom=.73; world.presentation_actor_hidden=true
	world.move_target=Vector2(510,650); world.touch_axis=Vector2.LEFT
	var original: Array=world_state(world)
	var reader: Callable=func(): return state.d
	var events: Array=[]
	for rejected in [null,RefCounted.new(),17]:
		var invalid:=view(); invalid.event.connect(func(action,value): events.append([action,value]))
		invalid.setup({"session":rejected,"read_state":reader,"world":world})
		check(world_state(world)==original,"invalid session preserves camera, zoom, actor and input")
		await process_frame
		check(not is_instance_valid(invalid),"invalid session frees only the rejected presenter")
	for rejected_reader in [Callable(),17,func(): return {},func(): return null]:
		var receipt:=Session.new(); receipt.configure(false,Vector2(690,620),state.d)
		var invalid:=view(); invalid.event.connect(func(action,value): events.append([action,value]))
		invalid.setup({"session":receipt,"read_state":rejected_reader,"world":world})
		check(world_state(world)==original and receipt.phase()=="issued","invalid reader/state leaves world and unowned receipt unchanged")
		await process_frame
	for rejected_world in [null,Node.new(),Control.new()]:
		var receipt:=Session.new(); receipt.configure(false,Vector2(690,620),state.d)
		var invalid:=view(); invalid.event.connect(func(action,value): events.append([action,value]))
		invalid.setup({"session":receipt,"read_state":reader,"world":rejected_world})
		check(world_state(world)==original and receipt.phase()=="issued","invalid world leaves live world and unowned receipt unchanged")
		if is_instance_valid(rejected_world): rejected_world.free()
		await process_frame
	var owner:=Node.new(); root.add_child(owner)
	var foreign:=Session.new(); foreign.configure(false,Vector2(690,620),state.d)
	check(foreign.begin(owner),"foreign presenter registers its own receipt")
	var refused:=view(); refused.event.connect(func(action,value): events.append([action,value]))
	refused.setup({"session":foreign,"read_state":reader,"world":world})
	check(world_state(world)==original and foreign.phase()=="route" and foreign._owns(owner),"refused begin cannot cancel another presenter or change world")
	await process_frame
	check(events.is_empty(),"rejected setup cannot emit a foreign controller result")
	foreign.cancel(); owner.queue_free()
	var before: String=JSON.stringify(state.d)
	var receipt:=Session.new(); receipt.configure(false,Vector2(690,620),state.d)
	var active:=view(); active.event.connect(func(action,value): events.append([action,value]))
	active.setup({"session":receipt,"read_state":reader,"world":world})
	check(active.owns_world and active.owns_session and receipt.phase()=="route","valid setup acquires explicit world and session ownership")
	world.camera=Vector2(700,300); world.zoom=1.4; world.presentation_actor_hidden=false
	active._restore()
	check(world.camera==original[0] and world.zoom==original[1] and world.presentation_actor_hidden==original[2],"restore retains originally hidden actor as well as camera and zoom")
	world.camera=Vector2(900,500); world.zoom=.9; world.presentation_actor_hidden=false
	world.move_target=Vector2(800,510); world.touch_axis=Vector2.RIGHT
	var successor: Array=world_state(world)
	active._restore(); active.cancel(); active.cancel()
	check(world_state(world)==successor,"repeat restore and cancel cannot overwrite successor presentation")
	check(events.size()==1 and receipt.phase()=="cancelled","owned session reports cancellation once")
	await process_frame
	check(world_state(world)==successor,"deferred destruction cannot restore a second time")
	check(JSON.stringify(state.d)==before,"ownership operations never author progression")
	world.presentation_actor_hidden=false
	var visible_receipt:=Session.new(); visible_receipt.configure(false,Vector2(690,620),state.d)
	var visible:=view(); visible.setup({"session":visible_receipt,"read_state":reader,"world":world}); visible.cancel()
	check(not world.presentation_actor_hidden,"ordinary cancellation restores originally visible actor")
	await process_frame
	var descendant: Control=load("res://tests/world_object_probe.gd").new(); root.add_child(descendant); descendant.set_process(false)
	var descendant_receipt:=Session.new(); descendant_receipt.configure(false,Vector2(690,620),state.d)
	var descendant_view:=view(); descendant_view.setup({"session":descendant_receipt,"read_state":reader,"world":descendant})
	check(descendant_view.owns_world and descendant_receipt.phase()=="route","real world subclass remains an eligible presentation host")
	descendant_view.cancel()
	check(not descendant.presentation_actor_hidden and descendant_receipt.phase()=="cancelled","subclass cancellation retains the same ownership cleanup")
	await process_frame; descendant.free()
	world.free()
	print("Rain ownership: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
