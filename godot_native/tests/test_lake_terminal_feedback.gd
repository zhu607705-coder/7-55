extends SceneTree
## Automated presentation/target lifecycle; this never advances the manual profile.
const Host=preload("res://scripts/ui/minigame_host.gd")
const Fishing=preload("res://scripts/games/rhythm_fishing_model.gd")
const Solver=preload("res://tests/campaign_fishing_solver.gd")
const Lake=preload("res://scripts/chapters/c3_lake.gd")
var checks: int=0
var failures: int=0
var delivered: Array=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func has_locker(lake: RefCounted,s: Dictionary) -> bool:
	return lake.targets("qizhen_lake",s).any(func(t: Dictionary):return t.action=="c3_lake_target:qizhen_use_item_1")
func run() -> void:
	var state: Node=root.get_node("State"); state.developer_mode=true
	var game: Control=Host.new()
	game.setup({"type":"rhythm","chartId":"locker_key","spotId":"locker_key","session_id":91,"chart":Fishing.load_chart("locker_key")})
	root.add_child(game);game.set_process(false)
	game.finished.connect(func(result: Dictionary):delivered.append(result))
	check(game._modal_title()=="准备好了吗？","ordinary ready title")
	game.begin();game.toggle_pause()
	check(game._modal_title()=="已暂停","ordinary pause title")
	game.begin()
	# The genuine input-only solver produces a replay-verifiable proof, not a forged outcome.
	var solved: RefCounted=Solver.new().solve_fishing("locker_key")
	check(Fishing.validate_result(solved.final_result,"locker_key"),"test win is a valid complete input trace")
	game.model=solved;game._check_terminal();game._refresh()
	check(game.sent and not game.running and not game.pending_result.is_empty(),"accepted terminal host waits for its existing handoff")
	check(game._modal_title()=="收竿成功","successful completed model keeps the success title")
	check(game.hint.text=="收竿成功" and not game.start_button.visible,"success hint and control visibility agree with outcome")
	check(delivered.is_empty(),"title lookup never emits completion")
	game._process(.89);check(delivered.is_empty(),"original0.9second presentation wait remains")
	game._process(.02)
	check(delivered.size()==1 and delivered[0].session_id==91,"original proof and session emitted exactly once")
	check(Fishing.validate_result(delivered[0],"locker_key"),"presentation does not alter proof")
	game._process(1);check(delivered.size()==1,"terminal redraw does not duplicate completion")
	game.restart();game.begin()
	game.model.press("right");game.model.update(.7);game.model.release("right")
	game.model.press("hook");game.model.update(.6);game.model.release("hook");game.model.update(30)
	check(game.model.phase=="completed" and not game.model.final_result.passed,"ordinary missed chart is unsuccessful completion")
	game._check_terminal();game._refresh()
	check(not game.sent and game._modal_title()=="再试一次" and game.start_button.visible,"missed chart remains a retry instead of success")
	game.begin();check(game.running and game.model.phase=="idle" and game._modal_title()=="准备好了吗？","retry renews chart and clears terminal presentation")
	game.model.press("hook");game.model.update(181);game._check_terminal()
	check(game.model.phase=="failed" and game._modal_title()=="再试一次","hard failure retains retry")
	game.queue_free();await process_frame
	var lake: RefCounted=Lake.new();var s: Dictionary=state.initial()
	s.native.chapter=3;s.native.scene="qizhen_lake";s.native.mode="light";s.rpgScene="qizhen_lake"
	s.qizhenLake.merge({"active":true,"phase":"tool_chain","zone":"dock","vehicle":"on_foot","lockerOpened":false},true)
	s.items.rustedLockerKey=true
	var target: Dictionary={}
	for entry: Dictionary in lake.definitions():
		if entry.id=="qizhen_use_item_1":target=entry;break
	s.native.player={"x":target.x,"y":target.y};s.native.selected_item="rustedLockerKey"
	check(has_locker(lake,s),"earned key exposes the original locker action")
	var result: Dictionary=lake.physical(s,"qizhen_use_item_1")
	check(result.get("message","")=="储物柜打开，获得尼龙绳。" and s.items.nylonCord and not s.items.rustedLockerKey and s.qizhenLake.lockerOpened,"unchanged controller consumes key and grants cord")
	var earned: Dictionary=s.duplicate(true)
	check(not has_locker(lake,s),"completed locker no longer advertises a consumed-item action")
	var loaded: Dictionary=JSON.parse_string(JSON.stringify(s))
	check(not has_locker(lake,loaded),"saved/reloaded completed locker stays retired")
	lake.physical(s,"qizhen_use_item_1")
	check(s==earned,"repeated direct request grants nothing and does not alter state")
	s.native.mode="dark"
	check(not has_locker(lake,s),"completed locker remains retired in observation mode")
	print("LAKE_TERMINAL_FEEDBACK: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
