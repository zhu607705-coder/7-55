extends SceneTree
const Model = preload("res://campuses/future_learning_center/scripts/locker_cipher_model.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func _initialize() -> void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save(): quit(2); return
	var model = Model.new()
	check(model.answer() == [6, 4, 5], "the engraved shape order and visible window pairs determine three digits")
	check(Model.WINDOWS.size() == 5 and Model.LOCK_SHAPES.size() == 3, "five different shapes include two decoy shapes")
	var occupied: Array[Vector2i] = []
	for shape: String in Model.WINDOWS:
		var pair: Array = Model.WINDOWS[shape]
		check(pair.size() == 2 and pair[0] != pair[1], "each shape marks exactly two different apertures")
		for cell: Vector2i in pair:
			check(cell.x >= 0 and cell.x < 4 and cell.y >= 0 and cell.y < 4 and cell not in occupied and Model.window_shape(cell) == shape, "apertures occupy unique cells and agree with their stamps")
			occupied.append(cell)
	check(Model.window_shape(Vector2i(2, 0)).is_empty() and occupied.size() == 10, "unmarked cells stay covered as additional decoys")
	check(not model.try_handle() and not model.unlocked and model.failed_attempts == 1, "wrong combination is recoverable")
	check(not model.turn(-1, 1) and not model.turn(3, 1), "invalid rollers cannot change the lock")
	check(model.turn(0, -1) and model.digits[0] == 9, "negative wheel rotation wraps")
	check(model.turn(0, 1) and model.digits[0] == 0, "positive wheel rotation wraps")
	for i: int in 3: model.turn(i, model.answer()[i])
	check(model.try_handle() and model.unlocked, "sheet windows provide a valid solution without mandatory hints")
	var result: Array[int] = model.digits.duplicate()
	check(not model.turn(0, 1) and model.digits == result, "open lock cannot silently mutate")
	for col: int in 3:
		var shape: String = Model.LOCK_SHAPES[col]
		var first: Vector2i = Model.WINDOWS[shape][0]
		var second: Vector2i = Model.WINDOWS[shape][1]
		check(first != second and model.answer()[col] == Model.GRID[first.y][first.x] + Model.GRID[second.y][second.x] and model.answer()[col] < 10, "each wheel is derived from its matching scattered pair")
		var wrong = Model.new()
		for i: int in 3: wrong.turn(i, wrong.answer()[i])
		wrong.turn(col, 1)
		check(not wrong.try_handle() and not wrong.unlocked, "changing any one sum cannot unlock")
	for shape: String in ["square", "star"]:
		var first: Vector2i = Model.WINDOWS[shape][0]
		var second: Vector2i = Model.WINDOWS[shape][1]
		var decoy_sum: int = Model.GRID[first.y][first.x] + Model.GRID[second.y][second.x]
		for col: int in 3:
			var wrong = Model.new()
			for i: int in 3: wrong.turn(i, decoy_sum if i == col else model.answer()[i])
			check(not wrong.try_handle(), "substituting a decoy pair cannot open any wheel")
	check(model.next_hint() == 1 and model.next_hint() == 2 and model.next_hint() == 3 and model.next_hint() == 3, "hints progress and clamp without changing the result")
	print("FLC_LOCKER_MODEL: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
