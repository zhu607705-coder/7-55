extends SceneTree
const Model = preload("res://campuses/future_learning_center/scripts/signal_sync_model.gd")
var checks := 0
var failures := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(label)
func trial(model: RefCounted, dt := .05) -> void:
	model.change_pattern()
	for i: int in ceili(1.3/dt): model.step(dt)
func _initialize() -> void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save(): quit(2); return
	var m := Model.new()
	trial(m)
	check(not m.complete and m.displayed.left != m.displayed.right, "Original cached branch must visibly fail")
	trial(m) # Current A now looks like the cached A, but no live signal reached it.
	check(m.displayed.left == m.displayed.right and not m.complete, "A coincidentally identical still image cannot complete the puzzle")
	m.connect_ports("split_b", "right"); trial(m)
	check(not m.complete and m.verified_patterns.size() == 1, "One update is not repeatable verification")
	trial(m)
	check(m.complete and m.earned, "Two different actual live updates must complete")
	m.connect_ports("cached", "right")
	check(not m.complete and m.earned and m.verified_patterns.is_empty(), "Editing invalidates current evidence but retains earned local result")
	m.undo(); trial(m); m.change_pattern(); m.step(.3); m.cancel(); m.step(1.4)
	check(not m.complete and not m.running and m.verified_patterns.size() == 1, "Cancellation cannot finish an in-flight trial")
	m.change_pattern(); m.step(.3); m.disconnect_port("split"); m.step(1.4)
	check(not m.complete and not m.running and m.verified_patterns.is_empty(), "Unplugging during propagation invalidates pending evidence")
	var version: int = m.revision
	check(not m.connect_ports("split_a", "split") and not m.connect_ports("unknown", "left") and m.revision == version, "Illegal ports and self loops cannot change the model")
	m.connect_ports("live", "left"); m.connect_ports("live", "right")
	check(not m.wires.has("left") and m.wires.right == "live", "One socket cannot secretly fan out two cables")
	m.reset(); m.connect_ports("split_a", "right"); m.connect_ports("split_b", "left"); trial(m); trial(m)
	check(m.complete, "Both splitter output permutations are legal")
	m.reset(); m.connect_ports("cached", "split"); m.connect_ports("split_b", "right"); trial(m); trial(m); trial(m)
	check(not m.complete, "Two cached receivers cannot fake live synchronization")
	for step: float in [.016, .1, .7]:
		m.reset(); m.connect_ports("split_b", "right"); trial(m,step); trial(m,step)
		check(m.complete, "Frame intervals must not decide a valid connection")
	m.reset(); m.change_pattern(); m.step(NAN); m.step(-1)
	check(m.elapsed == 0 and not m.complete, "Invalid time cannot advance evidence")
	print("FLC_SIGNAL_MODEL: %d checks, %d failures" % [checks, failures]); quit(1 if failures else 0)
