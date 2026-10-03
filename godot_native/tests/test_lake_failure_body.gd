extends SceneTree
## Input-only failed charts and presentation checks; never uses an earned profile.
const Host=preload("res://scripts/ui/minigame_host.gd")
const Fishing=preload("res://scripts/games/rhythm_fishing_model.gd")
const Solver=preload("res://tests/campaign_fishing_solver.gd")
var checks: int=0
var failures: int=0
var delivered: int=0
var cancelled: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(label)
func missed_chart(id: String) -> RefCounted:
	var fish: RefCounted=Fishing.new();fish.configure(id,Fishing.load_chart(id));fish.press("right")
	var cast_started: bool=false
	for i: int in range(16000):
		if fish.phase in ["completed","failed"]: break
		fish.update(1.0/120.0)
		var difference: float=fish.fish_x()-fish.line_x
		if difference>.018: fish.release("left");fish.press("right")
		elif difference<-.018: fish.release("right");fish.press("left")
		else: fish.release("right");fish.release("left")
		if fish.stage=="casting":
			if fish.aligned() and not cast_started: fish.press("hook");cast_started=true
			elif fish.held_at>=0 and fish.elapsed-fish.held_at>=.6: fish.release("hook")
		elif fish.stage=="fighting" and fish.judged>=3:
			var note: Dictionary=fish.current_note()
			if note.is_empty():continue
			if float(note.timeSec)-fish.elapsed<=0:fish.release("hook")
			elif int(fish.rhythm_position(fish.elapsed).x) in [0,2]:fish.press("hook")
			else:fish.release("hook")
	return fish
func run() -> void:
	root.get_node("State").developer_mode=true
	for id: String in ["locker_key","net_frame","fish","paper"]:
		var game: Control=Host.new();game.setup({"type":"rhythm","chartId":id,"spotId":id,"session_id":73,"chart":Fishing.load_chart(id),"instructions":"原始准备说明"});root.add_child(game);game.set_process(false)
		game.finished.connect(func(_result: Dictionary):delivered+=1);game.cancelled.connect(func():cancelled+=1)
		game._refresh();check(game.hint.text=="原始准备说明",id+" ready instructions preserved")
		game.begin();game.toggle_pause();check(game.hint.text=="已暂停。继续后从同一时刻恢复",id+" pause feedback preserved");game.begin()
		game.model=missed_chart(id)
		check(game.model.phase=="completed" and not game.model.final_result.passed,id+" original input rules produce failed completed chart")
		check(game.model.cue=="收近了！留意下一次猛拽",id+" last successful hook leaves historical misleading cue")
		var before: String=JSON.stringify(game.model.final_result)
		game._check_terminal();game._refresh()
		check(game.hint.text=="本轮成功收竿 %d / %d，尚未达成目标。\n点击重试重新抛竿，钓具保留。"%[game.model.final_result.notes_hit,game.model.notes.size()],id+" terminal result overrides last hook cue")
		check(game._modal_title()=="再试一次" and game.start_button.visible and not game.sent,id+" failure remains Retry")
		check(JSON.stringify(game.model.final_result)==before and game.model.cue=="收近了！留意下一次猛拽",id+" display leaves model/proof/cue untouched")
		game._process(2);check(delivered==0,id+" failure emits no completion")
		game.begin();check(game.running and game.model.phase=="idle" and game.hint.text=="左右移动浮漂，对准鱼影；按住蓄力，松手抛竿",id+" Retry renews original model and cue")
		game.model.press("hook");game.model.update(181);game._check_terminal();game._refresh()
		check(game.model.failure=="hook_escaped" and game.hint.text=="本轮目标已脱钩。\n点击重试重新抛竿，钓具保留。",id+" timeout feedback uses actual terminal reason")
		game.cancel_game();check(cancelled>0 and delivered==0,id+" Exit cancels without outcome")
		game.queue_free();await process_frame
	var snap: Control=Host.new();snap.setup({"type":"rhythm","chartId":"paper","chart":Fishing.load_chart("paper")});root.add_child(snap);snap.set_process(false);snap.begin()
	snap.model.press("right");snap.model.update(.7);snap.model.release("right");snap.model.press("hook");snap.model.update(.6);snap.model.release("hook");snap.model.update(1.9);snap.model.press("hook");snap.model.update(20);snap._check_terminal();snap._refresh()
	check(snap.model.failure=="line_snapped","held input creates real line break")
	check(snap.hint.text=="本轮鱼线已断。\n点击重试重新抛竿，钓具保留。","line-break outcome overrides transient hook feedback")
	snap.restart();snap.begin();snap.model=Solver.new().solve_fishing("paper");snap._check_terminal();snap._refresh()
	check(snap.sent and snap.hint.text=="收竿成功" and snap._modal_title()=="收竿成功","previous success-title fix retained")
	check(Fishing.validate_result(snap.pending_result,"paper"),"original successful replay proof retained")
	snap.queue_free();await process_frame
	print("LAKE_FAILURE_BODY: ",checks," checks; ",failures," failures");quit(1 if failures else 0)
