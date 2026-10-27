extends SceneTree

const Model = preload("res://scripts/paper_rewind_model.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS ", message)

func _init() -> void:
	var paper := Model.new()
	var entry := paper.snapshot()
	paper.advance(100.0)
	check(paper.snapshot() == entry, "Intro has no unattended timeline or completion")
	check(not paper.play() and not paper.rewind() and not paper.open_folder() and not paper.seek(0), "Intro ignores inactive controls")
	check(not paper.collect(), "Cannot collect a page before a real catch")
	check(paper.start() and not paper.start(), "Start is one-shot and repeated input cannot restart")
	paper.advance(20.0)
	check(paper.mode == "failed" and paper.catch_time < 0 and paper.completion_count == 0, "Untouched closed folder cannot catch paper by waiting")
	check(paper.open_folder() and not paper.open_folder(), "Folder placement is idempotent under duplicate input")
	paper.advance(20.0)
	check(paper.mode == "failed" and paper.completion_count == 0, "Late placement cannot retroactively catch escaped paper")
	check(paper.rewind(), "Failure permits rewind without resetting environment")
	var before: Vector2 = paper.paper_position()
	paper.advance(1.0)
	check(paper.paper_position().x < before.x and paper.time < Model.DURATION, "Paper really travels backward")
	check(paper.folder_open and paper.catch_time < 0, "Rewind retains present folder and cannot catch in reverse")
	check(paper.pause(), "Reverse can pause at any point")
	var paused := paper.snapshot()
	paper.advance(20.0)
	check(paper.snapshot() == paused, "Pause freezes paper and progress")
	check(paper.rewind(), "Reverse resumes after pause")
	paper.advance(20.0)
	check(paper.time == 0.0 and paper.mode == "paused" and paper.folder_open, "Rewind clamps at start but leaves folder deployed")
	check(paper.completion_count == 0, "Even complete rewind through open folder cannot solve")
	check(paper.play() and not paper.play(), "Forward playback is idempotent")
	paper.advance(20.0)
	check(paper.mode == "landed" and paper.catch_time >= 0 and paper.completion_count == 0, "Actual forward spatial contact lands but does not auto-complete")
	check(paper.collect() and not paper.collect(), "Manual collection completes once; double collection is rejected")
	check(paper.paper_position().is_equal_approx(Model.REST_POINT), "Changed trajectory lands inside folder")
	check(not paper.paper_position().is_equal_approx(Model.free_position(paper.time)), "Successful paper differs from original miss trajectory")
	var solved := paper.snapshot()
	for index: int in range(8):
		paper.play(); paper.start(); paper.rewind(); paper.open_folder(); paper.seek(0); paper.advance(20)
	check(paper.snapshot() == solved and paper.completion_count == 1, "Duplicate terminal inputs cannot award twice")
	check(paper.retry_paper() and paper.time == 0 and paper.folder_open and paper.catch_time < 0, "Explicit retry restores only paper")
	paper.play(); paper.advance(20); paper.collect()
	check(paper.completion_count == 2, "A genuine replay may complete a second local attempt")
	paper.reset()
	check(paper.snapshot() == entry, "Full reset restores entire initial state")
	paper.start(); paper.open_folder(); paper.advance(20)
	check(paper.mode == "failed", "Opening after starting past the folder still requires bringing paper back")
	paper.seek(-500)
	check(paper.time == 0 and paper.mode == "paused" and paper.folder_open, "Negative seek clamps without reverting environment")
	paper.seek(500)
	check(paper.time == Model.DURATION and paper.mode == "paused" and paper.completion_count == 0, "Forward seek is preview only, not a catch or victory")
	check(not paper.play(), "Cannot play past final paper timestamp")
	paper.seek(4.8)
	check(paper.catch_time < 0 and paper.completion_count == 0, "Preview inside open folder does not solve")
	var valid := paper.snapshot()
	check(not paper.seek(NAN) and not paper.seek(INF), "Nonfinite seek rejected")
	paper.advance(NAN); paper.advance(INF); paper.advance(-1)
	check(paper.snapshot() == valid, "Malformed frame deltas cannot mutate paper")
	paper.play(); paper.advance(0.2)
	check(paper.catch_time >= 0 and paper.mode == "forward", "Contact precedes landing; intermediate state is not a win")
	var contact := paper.time
	paper.rewind(); paper.advance(0.1)
	check(paper.time < contact and paper.folder_open, "Rewind during landing leaves the folder in place")
	paper.advance(5)
	check(paper.catch_time < 0 and paper.completion_count == 0, "Rewinding before contact undoes local paper capture")
	paper.play(); paper.advance(20)
	check(paper.mode == "landed", "Interrupted landing can be solved by a new real contact")
	for start: float in [0.0, 0.3, 1.0, 2.0, 3.0, 3.8, 4.2, 4.8, 5.3, 5.7]:
		var wide := Model.new()
		wide.start(); wide.seek(start); wide.open_folder(); wide.play(); wide.advance(20)
		check(wide.mode == "landed", "Wide placement/replay window accepts start %.1f" % start)
	for start: float in [6.3, 6.5, 7.0, 8.0]:
		var late := Model.new()
		late.start(); late.seek(start); late.open_folder(); late.play(); late.advance(20)
		check(late.mode == "failed", "Paper already beyond folder is not teleported back %.1f" % start)
	var reference := Model.new()
	reference.start(); reference.seek(0); reference.open_folder(); reference.play(); reference.advance(20)
	for fps: int in [15, 30, 60, 120, 144]:
		var chunked := Model.new()
		chunked.start(); chunked.seek(0); chunked.open_folder(); chunked.play()
		for frame: int in range(20 * fps):
			chunked.advance(1.0 / fps)
		check(chunked.mode == reference.mode and is_equal_approx(chunked.catch_time, reference.catch_time) and chunked.paper_position().is_equal_approx(reference.paper_position()), "Deterministic fixed-step contact at %d FPS" % fps)
	check(Model.segment_hits_rect(Vector2(0, 250), Vector2(900, 250), Model.CATCH_RECT), "Swept contact cannot tunnel across whole opening")
	check(not Model.segment_hits_rect(Vector2(0, 50), Vector2(900, 50), Model.CATCH_RECT), "Spatial counterexample: same time crossing outside opening fails")
	for phase: String in ["intro", "forward", "rewind", "paused", "failed", "landed"]:
		var cancelled := Model.new()
		cancelled.mode = phase
		check(cancelled.cancel() and not cancelled.cancel(), "Cancel idempotent from " + phase)
		var cancelled_snapshot := cancelled.snapshot()
		cancelled.advance(500); cancelled.start(); cancelled.play(); cancelled.rewind(); cancelled.open_folder(); cancelled.seek(0); cancelled.retry_paper(); cancelled.collect()
		check(cancelled.snapshot() == cancelled_snapshot and cancelled.completion_count == 0, "Skip/cancel cannot complete or resurrect " + phase)
	print("PAPER_REWIND_MODEL checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
