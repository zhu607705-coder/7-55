extends SceneTree
const MixerTiming = preload("res://tests/mixer_timing.gd")
const Session = preload("res://scripts/presentation/c3_mixer_session.gd")
const MixerPanel = preload("res://scripts/ui/c3_mixer_panel.gd")
const Chapter = preload("res://scripts/chapters/chapter3.gd")
var checks: int = 0
var errors: int = 0
var s: Dictionary = {}
var controller: RefCounted = Chapter.new()
var dispatched: Array = []
var feedback: Array = []
var closes: Array = []
var source: Dictionary = {}

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		errors += 1
		push_error(label)

func initial() -> Dictionary:
	var value: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	value.native = {"chapter":3, "page":"c3_canteen", "scene":"canteen_interior", "mode":"light", "settings":{}, "player":{}}
	value.canteenHunt.active = true
	value.canteenHunt.phase = "tray_search"
	value.canteenHunt.entryPaperEscaped = true
	value.runtimeMode = "rpg"
	value.rpgScene = "canteen_interior"
	for id: String in Session.RECIPE: value.items[id] = true
	var mixer: Dictionary = controller.get_definition("canteen_interior", "canteen-mixer", value)
	var point: Dictionary = mixer.get("stand", {"x":mixer.x, "y":mixer.y})
	value.native.player = {"x":point.x, "y":point.y}
	return value

func random(seed_value: int = 8) -> RandomNumberGenerator:
	var value := RandomNumberGenerator.new()
	value.seed = seed_value
	return value

func snapshot_text(view: Dictionary, y: int) -> String:
	for text: Dictionary in view.texts:
		if text.y == y: return str(text.text)
	return ""

func dispatch(action: String, value: Variant) -> Dictionary:
	dispatched.append(action)
	return controller.dispatch(s, action, value)

func panel() -> Control:
	var view := MixerPanel.new()
	root.add_child(view)
	view.closed.connect(func(reason: String): closes.append(reason))
	view.setup(func() -> Dictionary: return s, dispatch, func(text: String): feedback.append(text), random())
	return view

func press(view: Control, id: String) -> void:
	var index: int = view.session.button_order.find(id)
	if index >= 0: view.slots[index].pressed.emit()
	else: check(false, "visible ingredient slot exists: "+id)

func _initialize() -> void: call_deferred("run")
func run() -> void:
	source = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_mixer_source.json"))
	for oracle: Dictionary in source.orders:
		check(Session.avoid_answer_order(oracle.input) == oracle.order, "all six source shuffle permutations and identity rotation")
		check(oracle.order == oracle.refreshOrder and oracle.closedOrder.is_empty(), "source oracle retains slots on refresh and clears on close")
	# Runtime randomization really permutes all three (including unowned), never
	# returns the recipe, and cannot reshuffle during a refresh.
	var seen: Dictionary = {}
	for seed_value in range(80):
		s = initial()
		var session := Session.new()
		check(session.open(s, random(seed_value)), "opens at canteen")
		var order: Array = session.button_order.duplicate()
		var sorted: Array = order.duplicate(); sorted.sort()
		var expected: Array = Session.RECIPE.duplicate(); expected.sort()
		check(order != Session.RECIPE and sorted == expected, "random order contains exactly all three without identity answer")
		s.items[order[0]] = false
		check(session.snapshot(s).slots.size() == 3 and session.button_order == order, "unowned ingredient retains original slot during refresh")
		seen[str(order)] = true
	check(seen.size() == 5, "seeded runtime reaches all five source-allowed presentation orders")
	# Source text/colors/glass rectangles are produced by executing original TS.
	s = initial()
	s.items.sparklingWater = false
	s.canteenHunt.drinkMixSequence = ["lemonTea", "blackCoffee"]
	var before: Dictionary = s.duplicate(true)
	var session := Session.new(); session.open(s, random())
	var view_model: Dictionary = session.snapshot(s)
	check(view_model.layers.size() == source.unread.layers.size(), "actual partial sequence shown in source layer count")
	for index in range(view_model.layers.size()):
		var layer: Dictionary = view_model.layers[index]
		var oracle: Dictionary = source.unread.layers[index]
		check(layer.color == oracle.color and is_equal_approx(layer.alpha, oracle.alpha), "actual ingredient retains original source color and opacity")
		check(layer.rect == Rect2(oracle.rect[0], oracle.rect[1], oracle.rect[2], oracle.rect[3]), "glass fills bottom-up at original source coordinates")
	check(view_model.shelfStatus == snapshot_text(source.unread, 122), "unread shelf reveals no solution")
	check(view_model.prompt == snapshot_text(source.unread, 98), "authored mixer prompt preserved")
	for slot: Dictionary in view_model.slots:
		var original_index: int = source.unread.order.find(slot.id)
		var original_x: int = Session.BUTTON_X[original_index]+10
		for text: Dictionary in source.unread.texts:
			if text.y == 160 and text.x == original_x: check(slot.label == text.text, "each owned/unowned label matches original source")
	check(s == before, "rendering and shuffle do not mutate inventory, clue or sequence")
	s.canteenHunt.drinkShelfRead = true
	check(session.snapshot(s).shelfStatus == snapshot_text(source.read, 122), "shelf order displayed only after controller fact")
	session.close()
	check(not session.active and session.button_order.is_empty() and s.canteenHunt.drinkMixSequence == before.canteenHunt.drinkMixSequence, "close clears only presentation order and preserves partial controller sequence")
	session.open(s, random(45))
	check(session.snapshot(s).layers.size() == 2, "reopened panel reconstructs real partially poured glass")
	check(session.open(s, random(18)) and session.button_order != Session.RECIPE, "duplicate open does not reset current lifetime")
	var replacement: Dictionary = s.duplicate(true)
	check(session.snapshot(replacement).is_empty() and session.close_reason == "context_changed", "save replacement invalidates old presentation")
	session.open(s, random()); s.native.scene = "campus_bootstrap"
	check(session.snapshot(s).is_empty() and session.button_order.is_empty(), "scene exit retires mixer and shuffled slots")
	# Real Control + untouched native controller: success and failure both close
	# only after three accepted pours, consume actual items, and grant one result.
	for recipe: Array in [Session.RECIPE, ["lemonTea", "blackCoffee", "sparklingWater"]]:
		s = initial(); dispatched.clear(); feedback.clear(); closes.clear()
		var view: Control = panel()
		var slot_order: Array = view.session.button_order.duplicate()
		check(view.blocks_world_input() and view.size == Vector2(960,540), "modal publishes input block and fixed logical world extent")
		for index in range(3):
			var target:=Rect2(view.slots[index].position,view.slots[index].size)
			var button: Sprite2D=view.surface.press_buttons[index]
			check(target.encloses(button.transform*button.get_rect()) and target.size.x>=44 and target.size.y>=44,"source ingredient slot targets its independently registered physical machine button")
		for index in range(3):
			var id: String = recipe[index]
			press(view, id)
			check(not s.items[id], "controller consumes exactly the requested owned ingredient")
			if index < 2:
				check(view.visible and view.session.button_order == slot_order and view.model.layers.size() == index+1, "accepted partial pour updates glass without shuffling or closing")
				var slot_index: int = slot_order.find(id)
				var active_press: bool=view.surface.motion.playing and view.surface.motion.item_id==id
				var button_alpha: float=view.surface.press_buttons[slot_index].modulate.a
				check(not view.slots[slot_index].disabled and view.slots[slot_index].tooltip_text.ends_with("·未持有") and (is_equal_approx(button_alpha,1.0) if active_press else button_alpha<0.3), "consumed slot retains its missing tooltip and keeps only the active physical press bright")
		check(view.finishing and closes.is_empty(), "terminal transaction retains optional presentation tail")
		for beat in range(3): MixerTiming.finish_current(view.surface.motion)
		view._process(1.0)
		check(closes == ["attempt_complete"] and not view.blocks_world_input() and not view.visible, "third success or failure closes modal exactly once")
		check(s.canteenHunt.drinkMixAttemptCount == 1 and s.canteenHunt.drinkMixSequence.is_empty(), "controller resets sequence and increments attempt exactly once")
		check(s.items.dailySpecialSparklingWater == (recipe == Session.RECIPE) and s.items.badDrink == (recipe != Session.RECIPE), "untouched controller awards only source success/failure item")
		view.slots[0].pressed.emit(); view.refresh()
		check(dispatched.size() == 3 and closes.size() == 1, "closed stale control cannot pour or emit close twice")
		view.free()
	# Missing controls stay actionable for readable feedback, without dispatching
	# a fake inventory operation. Controller rejections preserve the panel.
	s = initial(); s.items.sparklingWater = false
	dispatched.clear(); feedback.clear(); closes.clear()
	var view: Control = panel()
	before = s.duplicate(true)
	press(view, "sparklingWater")
	check(dispatched.is_empty() and s == before and view.visible, "missing-slot attempt neither consumes nor closes")
	check(feedback == [str(source.missing.feedback[0][0])], "missing-slot response matches source exactly")
	s.native.player = {"x":10,"y":10}; before = s.duplicate(true)
	press(view, "blackCoffee")
	check(s == before and view.visible, "real controller still rejects distant pour")
	var mixer: Dictionary = controller.get_definition("canteen_interior", "canteen-mixer", s)
	var point: Dictionary = mixer.get("stand", {"x":mixer.x,"y":mixer.y})
	s.native.player = {"x":point.x,"y":point.y}; s.native.mode = "dark"; s.canteenHunt.mode = "dark"
	before = s.duplicate(true); press(view, "blackCoffee")
	check(s == before and view.visible, "real controller rejects dark-mode operation without presentation closing")
	s = initial(); view.refresh()
	check(not view.visible and closes == ["context_changed"], "state replacement closes live control")
	view.free()
	# Interrupted / repeated flows: Escape, window teardown and a recollected
	# ingredient never discard controller sequence or grant a result.
	s = initial(); closes.clear(); dispatched.clear()
	view = panel(); press(view, "blackCoffee")
	var escaped: Dictionary = s.duplicate(true)
	var event := InputEventKey.new(); event.keycode = KEY_ESCAPE; event.pressed = true
	event.echo = true; view._input(event)
	check(view.visible and closes.is_empty(), "repeated Escape keydown does not dismiss")
	event.echo = false; view._input(event)
	check(closes == ["dismissed"] and s == escaped and view.session.button_order.is_empty(), "Escape cancels presentation only, retaining partial pour")
	view.free()
	view = panel()
	check(view.model.layers.size() == 1 and s.canteenHunt.drinkMixAttemptCount == 0, "cancel/reopen retains poured ingredient and attempt count")
	s.items.blackCoffee = true; view.refresh(); press(view, "blackCoffee")
	check(s.canteenHunt.drinkMixSequence == ["blackCoffee","blackCoffee"] and view.model.layers.size() == 2, "recollected duplicate ingredient is displayed truthfully, never coerced into recipe")
	before = s.duplicate(true)
	view.free()
	check(s == before, "teardown never writes progression")
	print("Canteen mixer source session/panel: ", checks, " checks, ", errors, " failures")
	quit(1 if errors else 0)
