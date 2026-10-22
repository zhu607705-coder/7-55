extends SceneTree
## Actual native UI input from an isolated activity fixture, not an earned route.
const Stairs=preload("res://scripts/games/chapter4_stairs.gd")
const Model=preload("res://scripts/games/chapter4_stair_model.gd")
var checks:=0
var failures:=0
var game: Control
var results: Array=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> bool:
	checks+=1
	if not ok: failures+=1; push_error(message)
	return ok
func frames(count: int=2) -> void:
	for i in range(count): await process_frame
func point_click(point: Vector2) -> void:
	var motion=InputEventMouseMotion.new(); motion.position=point; root.push_input(motion,true)
	for down in [true,false]:
		var e=InputEventMouseButton.new(); e.position=point; e.global_position=point; e.pressed=down; e.button_index=MOUSE_BUTTON_LEFT
		root.push_input(e,true); await frames(1)
func click(control: Control) -> void:
	await point_click(control.get_global_transform_with_canvas()*(control.size*.5))
func settle() -> bool:
	var deadline=Time.get_ticks_msec()+30000
	while game.busy and results.is_empty() and Time.get_ticks_msec()<deadline: await process_frame
	return check(not game.busy or not results.is_empty(),"stair UI tween settles")
func mechanism(id: String,value: int) -> bool:
	var index: int=-1
	for i in range(game.level.mechanisms.size()):
		if game.level.mechanisms[i].id==id: index=i
	if not check(index>=0,"live mechanism exists"): return false
	for turn in range(4):
		if int(game.state.values[id])==value: break
		await click(game.toolbar.get_child(index).get_child(2)); await settle()
	return check(int(game.state.values[id])==value,"actual button sets "+id)
func view(name: String) -> bool:
	var index=Model.VIEWS.find(name)
	await click(game.get_child(1).get_child(1).get_child(index)); await settle()
	return check(game.state.view==name,"actual view button "+name)
func walk(target: String) -> bool:
	var before: String=game.level.id
	var point: Vector2=Model.project(Model.position(game.level,game.state,target),game.source.cameras[game.level.id],game.state.view)
	var factor: float=minf(game.surface.size.x/960.0,game.surface.size.y/540.0)
	var origin: Vector2=(game.surface.size-Vector2(960,540)*factor)*.5
	await point_click(game.surface.get_global_transform_with_canvas()*(origin+point*factor*2))
	await settle()
	return check(game.state.node==target or game.level.id!=before or not results.is_empty(),"actual projected click reaches "+target)
func run() -> void:
	root.size=Vector2i(960,540)
	game=Stairs.new(); game.theme=preload("res://scripts/ui/native_ui_theme.gd").font_theme(load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"))
	root.add_child(game); game.completed.connect(func(result): results.append(result))
	game.setup({"session":"isolated-input-test"}); await frames(3)
	for index in range(4):
		if not await settle(): break
		var level: Dictionary=game.level.duplicate(true)
		if not check(game.level_index==index,"real input campaign enters sequential level "+str(index)): break
		if level.id=="stair_a":
			await mechanism("a_slide",1); await mechanism("a_stair",0); await mechanism("a_lift",1); await view("south_west"); await walk("A_EXIT")
		elif level.id=="stair_b":
			await mechanism("b_lower_stair",3); await mechanism("b_mid_lift",0); await mechanism("b_upper_stair",1); await mechanism("b_exit_slide",2); await view("south_west")
			await walk("B_MID_LIFT_LOW"); await mechanism("b_mid_lift",2); await view("top_oblique"); await walk("B_EXIT")
		else:
			for stage_index in range(level.ascentViewSequence.size()):
				var prefix: String=level.id+"_"+str(stage_index+1)
				await mechanism(prefix+"_rotate",0); await mechanism(prefix+"_transfer",0); await view(level.ascentViewSequence[stage_index]); await walk(prefix+"_car")
				await mechanism(prefix+"_transfer",2); await walk(level.exitNodeId if stage_index==level.ascentViewSequence.size()-1 else prefix+"_transfer_exit")
		if failures: break
	check(results.size()==1,"four actual levels and final door emit exactly one result")
	if results.size()==1: check(Model.validate_result(results[0]),"existing controller proof validator accepts actual input log")
	game.queue_free(); await frames(3)
	print("C4_STAIR_INPUTS: ",checks," checks; ",failures," failures"); quit(1 if failures else 0)
