extends SceneTree
const Activity=preload("res://scripts/games/chapter4_activity.gd")
const Chapter=preload("res://scripts/chapters/chapter4.gd")
const Director=preload("res://scripts/media/audio_director.gd")
var checks: int=0
var failures: int=0
var cues: Array=[]
var proofs: Array=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func _initialize() -> void: call_deferred("run")
func drain() -> void: await process_frame; await process_frame
func game(config: Dictionary) -> Control:
	var control: Control=Activity.new(); root.add_child(control); control.set_process(false)
	control.presentation_requested.connect(func(id,payload): cues.append(id))
	control.completed.connect(func(result): proofs.append(result))
	control.setup(config); return control
func run() -> void:
	var a: Control=game({"kind":"prologue","session":"missing","video":"res://missing-prologue-test.ogv"})
	check(a.prologue_fallback and is_instance_valid(a.prologue_notice) and a.prologue_notice.visible,"Missing video shows explicit source static fallback notice")
	check(a.controls.get_children().any(func(n): return n is Button and n.text=="跳过恢复回放"),"Authored skip control is available during recovery")
	a.elapsed=25000; a.queue_redraw(); await drain()
	check(a.prologue_portraits.size()==2,"Fallback retains both original departing student portrait frames")
	a._skip_prologue(); await drain()
	check(a.stage=="card" and a.elapsed==43834 and not a.running and proofs.is_empty(),"Skip reaches task card without forging chapter handoff")
	check(cues==["chapter4_prologue_skip","chapter4_prologue_task_card"],"Skip silences remaining timeline without playing missed story beats")
	check(a.cues_fired.size()==a.source.prologue.beats.size(),"Skipped beats cannot replay on next frame")
	var count: int=cues.size(); a._skip_prologue(); check(cues.size()==count,"Repeated skip is idempotent")
	a._restart_prologue(); await drain()
	check(a.stage=="playback" and a.elapsed==0 and a.running and a.cues_fired.is_empty(),"Replay resets only runtime timeline and owned cues")
	a._process(1.0); check(a.elapsed==48,"Prologue elapsed uses source 48ms frame cap")
	var key: InputEventKey=InputEventKey.new(); key.keycode=KEY_ESCAPE; key.pressed=true; a._unhandled_key_input(key)
	check(a.stage=="card" and proofs.is_empty(),"Escape uses source skip-to-card behavior")
	a._finish({"acknowledged":true}); check(proofs.size()==1 and proofs[0].elapsedMs==43834 and proofs[0].acknowledged,"Explicit confirmation emits one terminal handoff after skip")
	a.queue_free(); await drain()
	var reduced: Control=game({"kind":"prologue","session":"reduce","video":"res://assets/rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition.ogv","settings":{"reduced_motion":true}})
	check(reduced.prologue_fallback and reduced.video==null and reduced.prologue_notice.text.begins_with("减少动态效果"),"Reduced motion avoids video decoding and retains honest static scene")
	reduced.queue_free(); await drain()
	var live: Control=game({"kind":"prologue","session":"live","video":"res://assets/rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition.ogv"})
	await drain(); check(is_instance_valid(live.video) and not live.prologue_fallback,"Bundled original H3 OGV loads with an actual Godot VideoStreamPlayer")
	if is_instance_valid(live.video):
		live.video.paused=true; live.elapsed=2200; live._sync_prologue_video(true)
		check(absf(live.video.stream_position-2.2)<=0.05,"Godot4.6 actual stream seek resynchronizes video to cue/subtitle clock")
		live.video.stream_position=6; live._sync_prologue_video()
		check(absf(live.video.stream_position-2.2)<=0.05,"Greater-than250ms playback drift is corrected")
		live._skip_prologue(); check(live.video.paused,"Task card freezes H3 playback")
		live._restart_prologue(); check(live.video.stream_position<0.05 and not live.video.paused,"Replay resets video clock and resumes decoding")
	live.queue_free(); await drain()
	var s: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json")); s.native={"chapter":4,"settings":{}}; s.qizhenLake.phase="complete"; s.chapterThreeInterlude.phase="replay_ready"; s.chapterThreeInterlude.replayUnlocked=true
	var chapter: RefCounted=Chapter.new(); var request: Dictionary=chapter.dispatch(s,"c4_prologue")
	chapter.dispatch(s,"c4_prologue_end",{"session":request.game.session,"elapsedMs":43834,"acknowledged":false}); check(not s.chapter4.prologueSeen,"Skip/card time alone cannot advance controller without acknowledgement")
	chapter.dispatch(s,"c4_prologue_end",{"session":request.game.session,"elapsedMs":43834,"acknowledged":true}); check(s.chapter4.prologueSeen,"Authorized source skip plus explicit confirmation advances normal handoff")
	await create_timer(0.3).timeout
	print("CHAPTER4_PROLOGUE_MEDIA_TESTS ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
