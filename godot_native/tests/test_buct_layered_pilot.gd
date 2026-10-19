extends SceneTree
## Uses the four accepted PNGs directly. No generated art or disk fixtures.
## Run with an isolated XDG_DATA_HOME so the application's autoload cannot read a player's save.

const PILOT_ROOT := "res://campuses/buct_pilots/chaoyang/"
const PILOT_SCENE := PILOT_ROOT + "scenes/promenade.tscn"
const ACTIONS := ["buct_pilot_walk_left", "buct_pilot_walk_right", "buct_pilot_walk_up", "buct_pilot_walk_down", "buct_pilot_walk_fast"]
const ACCEPTED_SHA256 := {
	"promenade-ground.png": "cf8162bb50f2e83e41eb26ff2f74eeae16272008a75547e8ba6e09868b1ab6b6",
	"promenade-crowns.png": "f7bf9dc9ce5e6ce5858851b94f24276a46f8bb1b726654b818f68d6aac90f425",
	"promenade-trunks.png": "c5b6442f7667d889fae040f931aff4fecb84d8af6b01430100bf9a04ae14d10d",
	"promenade-shadows.png": "3e202a27829b5868b069ac3a7d0f72baa5d6105c14018bde2e573062547be53f",
}

var checks := 0
var failures: Array[String] = []
var guide_ticks := 0

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("BUCT_LAYERED_PILOT: " + message)

func run() -> void:
	var config := _check_assets()
	if config.is_empty() or not failures.is_empty():
		_finish()
		return
	var input_before := _input_snapshot()
	var packed: PackedScene = load(PILOT_SCENE)
	check(packed != null, "integrated pilot scene loads")
	if packed == null:
		_finish()
		return
	var app = packed.instantiate()
	root.add_child(app)
	await process_frame
	await physics_frame
	check(app.trees.size() == 2, "exactly the two accepted trees are independent native objects")
	if app.trees.size() != 2:
		app.queue_free()
		await process_frame
		_finish()
		return
	check(app.world_size == Vector2(256, 160), "pilot keeps its own 256 by 160 source world")
	check(app.actors.y_sort_enabled, "visitor and tree roots share feet-depth sorting")
	check(app.visitor is CharacterBody2D, "guide and manual movement use a real CharacterBody2D")
	check(app.visitor.get_parent() == app.trees[0].get_parent(), "visitor and trees share the same depth-sorted parent")
	check(app.visitor.get_node("FeetCollision").shape is CircleShape2D, "visitor collision is a foot circle")
	check(is_equal_approx(app.visitor.get_node("FeetCollision").shape.radius, 1.65) and app.visitor.scale == Vector2.ONE, "visitor collision excludes its tall drawn body")
	for action in ACTIONS:
		check(InputMap.has_action(action), "namespaced movement is installed: " + action)
	for action in InputMap.get_actions():
		if not input_before.has(str(action)):
			check(str(action).begins_with("buct_pilot_walk_"), "pilot adds no global movement action: " + str(action))
	_check_original_actions(input_before, "entry")
	app.reset_demo()
	for tree in app.trees:
		tree.set_process(false)
	for index in range(app.trees.size()):
		await _check_tree(app, app.trees[index], config.objects[index])
	_check_walkability(app)
	await _check_native_collision(app)
	await _check_arrow_key_events(app)
	await _check_manual_and_route(app, config)
	var shadow_refs := _shadow_refs(app)
	check(shadow_refs.size() == 2, "both ground shadows are included in lifetime checks")
	Input.action_press("buct_pilot_walk_right")
	app.queue_free()
	await _process_frames(4)
	for reference in shadow_refs:
		check(reference.get_ref() == null, "map exit releases every independently parented ground shadow")
	check(_input_snapshot() == input_before, "map exit restores the complete original InputMap")
	await _check_existing_action_and_tree_exit(packed)
	_finish()

func _check_assets() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PILOT_ROOT + "data/asset-contract.json"))
	var recorded = JSON.parse_string(FileAccess.get_file_as_string(PILOT_ROOT + "data/provenance.json"))
	check(parsed is Dictionary and recorded is Dictionary, "asset contract and provenance are valid JSON objects")
	if not parsed is Dictionary or not recorded is Dictionary:
		return {}
	var config: Dictionary = parsed
	var provenance: Dictionary = recorded
	check(config.source_image == "res://campuses/buct/assets/approved-chaoyang.png", "source attribution identifies the approved Chaoyang image")
	check(Rect2(config.source_rect[0], config.source_rect[1], config.source_rect[2], config.source_rect[3]) == Rect2(625, 565, 256, 160), "pilot source rectangle stays registered to the approved crop")
	check(provenance.source_image == config.source_image and provenance.source_rect == config.source_rect, "provenance agrees with the source image and rectangle")
	check(provenance.campus == "chaoyang", "provenance identifies the correct campus")
	check(provenance.outputs.size() == 4, "provenance lists exactly the four accepted PNGs")
	check(provenance.limitations.size() >= 4, "provenance retains the reconstruction and two-tree scope limitations")
	check(config.objects.size() == 2, "manifest contains only the accepted two-tree pilot")
	check(Vector2(config.world_size[0], config.world_size[1]) == Vector2(256, 160) and Vector2(config.spawn[0], config.spawn[1]) == Vector2(70, 127), "manifest keeps independent world and safe spawn coordinates")
	var fixed_roots := [Vector2(87,124),Vector2(165,122)]
	var fixed_joints := [Vector2(87,114),Vector2(165,112)]
	for index in range(config.objects.size()):
		var item:Dictionary=config.objects[index]
		check(Vector2(item.anchor[0],item.anchor[1])==fixed_roots[index],"style revision preserves the original source root")
		check(Vector2(item.crown_joint[0],item.crown_joint[1])==fixed_joints[index],"style revision preserves the original crown hinge")
		check(is_equal_approx(float(item.trunk_radius),2.2),"style revision preserves the original trunk collider")
	var seen: Array[String] = []
	for output in provenance.outputs:
		var filename := str(output.file).get_file()
		check(ACCEPTED_SHA256.has(filename), "provenance references an accepted layer: " + filename)
		if not ACCEPTED_SHA256.has(filename):
			continue
		check(not filename in seen, "each accepted PNG is listed once: " + filename)
		seen.append(filename)
		var path := PILOT_ROOT + "assets/" + filename
		check(str(output.file) == "assets/" + filename and output.selected_for_native_pilot, "provenance selects the checked-in pilot layer: " + filename)
		check(output.sha256 == ACCEPTED_SHA256[filename], "provenance retains the accepted hash: " + filename)
		check(FileAccess.get_sha256(path) == ACCEPTED_SHA256[filename], "accepted PNG bytes remain unchanged: " + filename)
		var image := Image.new()
		var decode_error := image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
		check(decode_error == OK and not image.is_empty(), "actual PNG decodes: " + filename)
		if decode_error != OK or image.is_empty():
			continue
		check(image.get_size() == Vector2i(1586, 992) and Vector2(output.size[0], output.size[1]) == Vector2(1586, 992), "actual PNG dimensions agree with provenance: " + filename)
		if filename == "promenade-ground.png":
			check(image.get_format() == Image.FORMAT_RGB8 and output.mode == "RGB", "reconstructed ground is the accepted RGB base layer")
		else:
			check(image.get_format() == Image.FORMAT_RGBA8 and output.mode == "RGBA", "separated layer contains real PNG alpha: " + filename)
			var alpha := _alpha_counts(image)
			check(alpha.transparent > 0 and alpha.visible > 0, "PNG has transparent background and visible object pixels: " + filename)
			if filename == "promenade-shadows.png":
				check(alpha.translucent > 0 and alpha.opaque == 0, "ground shadows retain genuine translucent alpha")
			else:
				check(alpha.opaque > 0, "tree layer includes genuinely opaque authored pixels: " + filename)
	check(seen.size() == ACCEPTED_SHA256.size(), "all four accepted files are covered by provenance")
	return config

func _alpha_counts(image: Image) -> Dictionary:
	var counts := {"transparent": 0, "visible": 0, "translucent": 0, "opaque": 0}
	for y in range(0, image.get_height(), 3):
		for x in range(0, image.get_width(), 3):
			var alpha := image.get_pixel(x, y).a
			if alpha < 0.04: counts.transparent += 1
			if alpha > 0.12: counts.visible += 1
			if alpha > 0.12 and alpha < 0.95: counts.translucent += 1
			if alpha > 0.95: counts.opaque += 1
	return counts

func _check_tree(app: Node2D, tree: Node2D, item: Dictionary) -> void:
	var label := str(item.id) + ": "
	var anchor := Vector2(item.anchor[0], item.anchor[1])
	tree.reset_pose()
	check(tree.source_anchor == anchor and tree.position == anchor, label + "each tree retains its own immutable source anchor")
	check(tree.canopy != tree.trunk and tree.canopy != tree.ground_shadow and tree.trunk != tree.ground_shadow, label + "crown, trunk and shadow are distinct sprites")
	check(tree.canopy.get_parent() == tree.canopy_pivot and tree.trunk.get_parent() == tree, label + "only the crown belongs to the movable hinge")
	check(tree.ground_shadow.get_parent() != tree and tree.ground_shadow.get_parent().z_index < app.actors.z_index, label + "independent ground shadow remains below visitor depth")
	check(tree.canopy_pivot.global_position.is_equal_approx(Vector2(item.crown_joint[0], item.crown_joint[1])), label + "crown rotates about its measured joint")
	for pair in [["canopy", tree.canopy], ["trunk", tree.trunk], ["shadow", tree.ground_shadow]]:
		var key: String = pair[0]
		var sprite: Sprite2D = pair[1]
		check(sprite.texture is AtlasTexture, label + key + " is an independent native atlas region")
		if not sprite.texture is AtlasTexture:
			continue
		var region: Array = item[key + "_region"]
		var rect: Array = item[key + "_world_rect"]
		check(sprite.texture.atlas.resource_path == PILOT_ROOT + "assets/" + str(item[key]), label + key + " consumes the accepted PNG, not the source overview")
		check(sprite.texture.region == Rect2(region[0], region[1], region[2], region[3]), label + key + " uses its own measured pixel crop")
		check(Rect2(Vector2.ZERO, sprite.texture.atlas.get_size()).encloses(sprite.texture.region), label + key + " crop stays inside the actual PNG")
		check(sprite.global_position.is_equal_approx(Vector2(rect[0], rect[1])), label + key + " retains its registered world origin")
		check((sprite.texture.get_size() * sprite.scale).is_equal_approx(Vector2(rect[2], rect[3])), label + key + " retains its measured world footprint")
		var alpha := _alpha_counts(sprite.texture.get_image())
		check(alpha.transparent > 0 and alpha.visible > 0, label + key + " crop preserves actual alpha edges")
	var crown_point := _find_pixel(tree.canopy, 0.95, 1.0, [tree.trunk])
	var trunk_point := _find_pixel(tree.trunk, 0.95, 1.0, [tree.canopy])
	var blank_point := _find_pixel(tree.canopy, 0.0, 0.039, [tree.trunk])
	var shadow_point := _find_pixel(tree.ground_shadow, 0.12, 0.95, [tree.canopy, tree.trunk])
	check(crown_point.is_finite() and trunk_point.is_finite(), label + "real atlas has independently testable visible crown and trunk pixels")
	check(blank_point.is_finite() and shadow_point.is_finite(), label + "real atlas has independently testable transparent and shadow-only pixels")
	if crown_point.is_finite():
		check(tree.hit_test_world(crown_point), label + "opaque crown selects its object")
		app.select_at(crown_point)
		check(app.selected_tree == tree and tree.selected, label + "scene selection resolves the real crown")
		tree.canopy.hide()
		check(not tree.hit_test_world(crown_point), label + "hidden crown is not clickable")
		app.select_at(crown_point)
		check(app.selected_tree == null, label + "hidden crown also fails scene-level selection")
		tree.canopy.show()
	if trunk_point.is_finite():
		check(tree.hit_test_world(trunk_point), label + "opaque exposed trunk selects its object")
		app.select_at(trunk_point)
		check(app.selected_tree == tree, label + "scene selection resolves the fixed trunk")
	if blank_point.is_finite():
		check(not tree.hit_test_world(blank_point), label + "transparent pixels inside the crop are not rectangle hits")
		app.select_at(blank_point)
		check(app.selected_tree == null, label + "transparent click clears scene selection")
	if shadow_point.is_finite():
		check(not tree.hit_test_world(shadow_point), label + "ground-shadow-only pixels cannot select a tree")
		app.select_at(shadow_point)
		check(app.selected_tree == null, label + "ground shadow cannot steal scene-level selection")
	var rest: Transform2D = tree.canopy.global_transform
	var trunk_rest: Transform2D = tree.trunk.global_transform
	var shadow_rest: Transform2D = tree.ground_shadow.global_transform
	var collision_rest: Transform2D = tree.collision_body.global_transform
	var other: Node2D = app.trees[1] if tree == app.trees[0] else app.trees[0]
	var other_rest: Transform2D = other.canopy.global_transform
	tree.wind_enabled = true
	tree._process(0.7)
	check(tree.canopy.global_transform != rest, label + "wind moves the real crown")
	check(tree.trunk.global_transform == trunk_rest and tree.collision_body.global_transform == collision_rest, label + "wind cannot move the trunk or foot collider")
	check(tree.ground_shadow.global_transform == shadow_rest, label + "crown wind cannot move the ground shadow")
	tree.reset_pose()
	tree.nudge_crown(0.07)
	check(tree.canopy.global_transform != rest and tree.canopy_pivot.rotation > 0.0, label + "manual nudge rotates the crown hinge")
	check(tree.trunk.global_transform == trunk_rest and tree.ground_shadow.global_transform == shadow_rest, label + "manual crown edit leaves trunk and shadow fixed")
	check(other.canopy.global_transform == other_rest, label + "editing one tree cannot move the other crown")
	for index in range(30):
		tree.nudge_crown(0.05)
		tree.nudge_crown(-0.03)
		tree.reset_pose()
		check(tree.canopy.global_transform == rest and tree.trunk.global_transform == trunk_rest and tree.ground_shadow.global_transform == shadow_rest, label + "reset %d restores exact layer transforms without drift" % (index + 1))
	tree.position += Vector2(12, -8)
	tree._process(0.0)
	check(tree.ground_shadow.global_position.is_equal_approx(shadow_rest.origin + Vector2(12, -8)), label + "ground shadow follows whole-object translation")
	check(tree.source_anchor == anchor, label + "translation cannot overwrite source anchor")
	tree.reset_pose()
	check(tree.position == anchor and tree.ground_shadow.global_transform == shadow_rest, label + "reset restores this tree's own anchor and registered shadow")
	var footprint: CollisionShape2D = tree.collision_body.get_node("GroundFootprint")
	check(footprint.shape is CircleShape2D and is_equal_approx(footprint.shape.radius, float(item.trunk_radius)) and footprint.shape.radius < 3.0, label + "collision follows only the small trunk base")
	tree.set_object_visible(false)
	await process_frame
	check(not tree.ground_shadow.visible and footprint.disabled, label + "hiding the object hides its shadow and disables collision")
	if crown_point.is_finite(): check(not tree.hit_test_world(crown_point), label + "hidden whole tree cannot select")
	tree.set_object_visible(true)
	await process_frame
	check(tree.ground_shadow.visible and not footprint.disabled, label + "show restores only this object's shadow and collider")

func _find_pixel(sprite: Sprite2D, minimum: float, maximum: float, excluded: Array) -> Vector2:
	var image := sprite.texture.get_image()
	var excluded_images: Array[Image] = []
	for other: Sprite2D in excluded: excluded_images.append(other.texture.get_image())
	for y in range(0, image.get_height(), 3):
		for x in range(0, image.get_width(), 3):
			var alpha := image.get_pixel(x, y).a
			if alpha < minimum or alpha > maximum: continue
			var point := sprite.to_global(Vector2(x + 0.5, y + 0.5))
			var overlaps := false
			for index in range(excluded.size()):
				var pixel := Vector2i(excluded[index].to_local(point).floor())
				var other_image := excluded_images[index]
				if Rect2i(Vector2i.ZERO, other_image.get_size()).has_point(pixel) and other_image.get_pixelv(pixel).a > 0.12:
					overlaps = true
					break
			if not overlaps: return point
	return Vector2(INF, INF)

func _check_walkability(app: Node2D) -> void:
	for point in [Vector2(87, 124), Vector2(165, 122)]:
		check(not app.is_walkable(point), "actual trunk base is blocked: " + str(point))
	for point in [Vector2(85, 116), Vector2(166, 115), Vector2(96, 127), Vector2(173, 127)]:
		check(app.is_walkable(point), "feet can walk behind or in front of the real crowns: " + str(point))
	for point in [Vector2(70, 137), Vector2(125, 75), Vector2(-1, 120), Vector2(257, 120)]:
		check(not app.is_walkable(point), "flowerbed, lawn or outside world remains excluded: " + str(point))

func _check_native_collision(app: Node2D) -> void:
	app.visitor.set_physics_process(false)
	for tree in app.trees:
		app.visitor.position = tree.source_anchor + Vector2(-10, 0)
		await physics_frame
		var contact: KinematicCollision2D = app.visitor.move_and_collide(Vector2(16, 0))
		check(contact != null, str(tree.name) + ": native trunk body really blocks visitor feet")
		if contact != null: check(contact.get_collider() == tree.collision_body, str(tree.name) + ": collision is with this tree's body")
		app.visitor.position = tree.source_anchor + Vector2(-10, -7)
		await physics_frame
		check(not app.visitor.test_move(app.visitor.global_transform, Vector2(16, 0)), str(tree.name) + ": canopy has no hidden full-width collision wall")
	app.visitor.set_physics_process(true)
	app.reset_demo()

func _check_arrow_key_events(app: Node2D) -> void:
	# Exercise real key events, not action_press, including focused native UI.
	var directions := {KEY_LEFT:Vector2.LEFT,KEY_RIGHT:Vector2.RIGHT,KEY_UP:Vector2.UP,KEY_DOWN:Vector2.DOWN}
	for focused in [false,true]:
		for key in directions:
			for mode in ["logical","physical","both"]:
				app.reset_demo()
				if focused:app.ui_controls.reset.grab_focus()
				else:app.get_viewport().gui_release_focus()
				var initial:Vector2=app.visitor.position
				var event:=InputEventKey.new();event.pressed=true
				if mode!="physical":event.keycode=key
				if mode!="logical":event.physical_keycode=key
				Input.parse_input_event(event);Input.flush_buffered_events()
				await _physics_frames(8)
				var displacement:Vector2=app.visitor.position-initial
				check(displacement.dot(directions[key])>0.5,"arrow %s %s focused=%s drives native movement"%[key,mode,focused])
				event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events()
				await _physics_frames(2)
				var stopped:Vector2=app.visitor.position
				await _physics_frames(4)
				check(app.visitor.position.is_equal_approx(stopped),"arrow %s %s focused=%s stops after key release"%[key,mode,focused])
	app.get_viewport().gui_release_focus()
	app.reset_demo()

func _check_manual_and_route(app: Node2D, config: Dictionary) -> void:
	var initial: Vector2 = app.visitor.position
	Input.action_press("buct_pilot_walk_right")
	await _physics_frames(12)
	Input.action_release("buct_pilot_walk_right")
	check(app.visitor.position.x > initial.x + 1.0 and app.is_walkable(app.visitor.position), "namespaced held action drives real foot motion")
	app.start_guide()
	await _physics_frames(3)
	Input.action_press("buct_pilot_walk_right")
	await _physics_frames(3)
	Input.action_release("buct_pilot_walk_right")
	check(not app.guide_active and app.route.is_empty(), "manual movement cancels the active guided route")
	app.reset_demo()
	app.start_guide()
	check(app.route.size() == config.route.size(), "guide consumes every authored route waypoint")
	for index in range(mini(app.route.size(), config.route.size())):
		check(app.route[index] == Vector2(config.route[index][0], config.route[index][1]), "guide waypoint %d retains the measured route" % index)
	var saw_back := [false, false]
	var saw_front := [false, false]
	var violations := 0
	var discontinuities := 0
	var previous: Vector2 = app.visitor.position
	while app.guide_active and guide_ticks < 1800:
		await physics_frame
		guide_ticks += 1
		var point: Vector2 = app.visitor.position
		if not app.is_walkable(point): violations += 1
		if point.distance_to(previous) > 1.0: discontinuities += 1
		previous = point
		for index in range(2):
			var anchor: Vector2 = app.trees[index].source_anchor
			if absf(point.x - anchor.x) < 14.0:
				if point.y < anchor.y - 5.0: saw_back[index] = true
				if point.y > anchor.y + 2.0: saw_front[index] = true
	check(not app.guide_active and guide_ticks < 1800, "real CharacterBody2D route completes without timing out")
	check(violations == 0, "every guide physics position stays on paving outside trunk feet")
	check(discontinuities == 0, "guide reaches its destination by continuous motion without teleporting")
	check(app.visitor.position.distance_to(Vector2(190, 127)) < 2.0, "guide actually reaches the accepted destination")
	for index in range(2):
		check(saw_back[index] and saw_front[index], "guide physically passes behind and in front of tree %d" % (index + 1))
	app.reset_demo()
	app.reset_demo()
	check(app.visitor.position == Vector2(70, 127) and not app.guide_active and app.route.is_empty(), "repeated demo reset restores spawn and clears active navigation")

func _check_existing_action_and_tree_exit(packed: PackedScene) -> void:
	var action := "buct_pilot_walk_left"
	var added_sentinel := not InputMap.has_action(action)
	if added_sentinel:
		InputMap.add_action(action, 0.37)
		var event := InputEventKey.new()
		event.physical_keycode = KEY_J
		InputMap.action_add_event(action, event)
	var before := _input_snapshot()
	var app = packed.instantiate()
	root.add_child(app)
	await process_frame
	check(_action_state(action) == before[action], "entry preserves a pre-existing namespaced binding and deadzone")
	Input.action_press(action)
	await _physics_frames(3)
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not Input.is_action_pressed(action) and app.movement_paused(), "focus loss releases a pre-existing pilot action and pauses movement")
	var stopped_at: Vector2 = app.visitor.position
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await _physics_frames(3)
	check(app.visitor.position == stopped_at and not app.movement_paused(), "focus return cannot resume stale pre-existing held movement")
	check(_action_state(action) == before[action], "focus changes preserve the pre-existing binding and deadzone")
	Input.action_press(action)
	app.reset_demo()
	check(not Input.is_action_pressed(action), "demo reset releases pre-existing held movement")
	await _physics_frames(3)
	check(app.visitor.position == Vector2(70, 127), "reset spawn remains still after a pre-existing held action")
	check(_action_state(action) == before[action], "demo reset preserves the pre-existing binding and deadzone")
	Input.action_press(action)
	app.start_guide()
	check(not Input.is_action_pressed(action), "guide start releases pre-existing held movement")
	await _physics_frames(3)
	check(app.guide_active and app.visitor.position.x > 70.0, "pre-existing held action cannot immediately cancel the new guide")
	check(_action_state(action) == before[action], "guide start preserves the pre-existing binding and deadzone")
	app.reset_demo()
	var shadow_refs := _shadow_refs(app)
	if app.trees.size() == 2:
		var first_shadow: WeakRef = weakref(app.trees[0].ground_shadow)
		var second_shadow: WeakRef = weakref(app.trees[1].ground_shadow)
		app.trees[0].queue_free()
		await _process_frames(3)
		check(first_shadow.get_ref() == null, "freeing a single tree releases its independent shadow")
		check(second_shadow.get_ref() != null, "freeing one tree keeps the other tree's shadow alive")
		app.trees.remove_at(0)
	Input.action_press(action)
	app.queue_free()
	await _process_frames(4)
	for reference in shadow_refs:
		check(reference.get_ref() == null, "repeated entry and partial teardown leak no ground shadow")
	check(not Input.is_action_pressed(action), "map exit releases pre-existing pressed state without deleting its mapping")
	check(_input_snapshot() == before, "exit preserves pre-existing actions while removing only pilot-owned actions")
	if added_sentinel: InputMap.erase_action(action)

func _shadow_refs(app: Node2D) -> Array[WeakRef]:
	var references: Array[WeakRef] = []
	for tree in app.trees: references.append(weakref(tree.ground_shadow))
	return references

func _input_snapshot() -> Dictionary:
	var result := {}
	for action in InputMap.get_actions(): result[str(action)] = _action_state(str(action))
	return result

func _action_state(action: String) -> Dictionary:
	var events: Array[String] = []
	for event in InputMap.action_get_events(action): events.append(event.as_text())
	return {"deadzone": InputMap.action_get_deadzone(action), "events": events}

func _check_original_actions(before: Dictionary, context: String) -> void:
	for action in before:
		check(InputMap.has_action(action) and _action_state(action) == before[action], context + " preserves existing action: " + str(action))

func _process_frames(count: int) -> void:
	for index in range(count): await process_frame

func _physics_frames(count: int) -> void:
	for index in range(count): await physics_frame

func _finish() -> void:
	print("BUCT_LAYERED_PILOT ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures.size(), " guide_physics_ticks=", guide_ticks, "; actual PNGs and native physics, no asset fixtures")
	quit(0 if failures.is_empty() else 1)
