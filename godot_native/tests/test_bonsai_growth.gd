extends SceneTree
## Six source condition orders, rebuild/re-entry/load cancellation, exact endpoint
## and recovered atlas identity. Fixtures do not claim continuous manual play.
const Session = preload("res://scripts/presentation/bonsai_growth_session.gd")
const Art = preload("res://scripts/presentation/bonsai_growth_art.gd")
const Chapter = preload("res://scripts/chapters/chapter1_2.gd")
const Pages = preload("res://scripts/ui/phone_pages.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func frames(count := 3) -> void:
	for i in count: await process_frame
func run() -> void:
	var state = root.get_node("State")
	state.developer_mode = true
	var controller = Chapter.new()
	for order in [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]]:
		var s: Dictionary = state.initial()
		s.native.page = "bonsai"; s.ui.brightness = 90
		s.items.wateredHeadphone = true; s.items.fertilizer = true
		var session = Session.new(); session.observe(s)
		check(not session.active(), "Fresh unbloomed page does not replay")
		for step in range(3):
			var index: int = order[step]
			controller.dispatch(s, "c1_plant_light" if index == 1 else "c1_plant", ["wateredHeadphone",null,"fertilizer"][index])
			var immutable := JSON.stringify(s)
			session.observe(s)
			check(bool(s.flags.flowerBloomed) == (step == 2), "All three source conditions required")
			check(session.active() == (step == 2), "Only bloom rising edge starts animation")
			check(s.digits.d4 == null and not s.flags.flowerEightTaken, "Animation grants no digit")
			check(JSON.stringify(s) == immutable, "Presentation does not mutate state")
		var start: int = session.started_ms
		session.observe(s); session.observe(s)
		check(session.started_ms == start, "Same-page rebuild does not restart")
		controller.dispatch(s, "c1_plant", "fertilizer"); session.observe(s)
		check(session.started_ms == start, "Repeat rejected drop cannot restart bloom")
		var copy: Dictionary = s.duplicate(true); session.observe(copy)
		check(not session.active(), "Loaded state goes straight to stable final art")
		session.reset(); session.observe(s)
		check(not session.active(), "Re-entered completed page does not replay")
		controller.dispatch(s, "c1_collect_flower", null)
		check(not s.flags.flowerEightTaken, "Cannot collect before separate reveal")
		controller.dispatch(s, "c1_flower", null); session.observe(s)
		check(not session.active() and s.native.flower_eight_visible, "Reveal can skip presentation immediately")
		controller.dispatch(s, "c1_collect_flower", null)
		check(s.flags.flowerEightTaken and s.digits.d4 == "8", "Independent source action collects 8")
		var earned := JSON.stringify(s)
		controller.dispatch(s, "c1_collect_flower", null); controller.dispatch(s, "c1_flower", null)
		check(JSON.stringify(s) == earned, "Repeat collection cannot duplicate reward")
	var previous := -1
	for ms in range(0, 4251, 25):
		var pose: Dictionary = Session.pose(ms, 0)
		check(pose.frame >= previous, "Opening frame order never reverses")
		previous = pose.frame
	check(Session.pose(2150,0).frame > Session.pose(2150,3).frame, "Four flowers use independent staggered poses")
	check(Session.pose(0,0).lift > 0 and Session.pose(850,0).lift == 0, "Bud anticipation settles at fixed stem anchor")
	check(Session.pose(4730,3).frame == 23 and Session.pose(4730,3).source_mix == 1, "Last blossom reaches exact source by 4730 ms")
	check(Session.pose(4800,3).finished, "Presentation ends by 4800 ms")
	check(Session.pose(100,0,true).lift == 0 and Session.pose(3750,0,true).angle == 0, "Reduced motion suppresses extra translation/settle")
	var start := Time.get_ticks_msec()
	Art.ensure_ready()
	print("BONSAI_ATLAS_PREPARE_MS ", Time.get_ticks_msec() - start)
	check(Art.frames.size() == 24 and Art.endpoint_parts.size() == 4, "Twenty-four atlas drawings, four independent endpoints")
	var hashes: Dictionary = {}
	for frame in Art.frames:
		var img: Image = frame.get_image()
		var digest := img.get_data().hex_encode().sha256_text()
		hashes[digest] = true
		check(img.get_pixel(0,0).a == 0, "No atlas cell background rectangle")
		var corner_clear := true
		for y in range(148,img.get_height()):
			for x in range(img.get_width()):
				if img.get_pixel(x,y).a > 0: corner_clear = false
		check(corner_clear, "Neighboring sheet buds are not copied as stray petals")
	check(hashes.size() == 24, "All 24 supplied drawings are distinct")
	check(Art.clean_plate.get_size() == Art.source_bloom.get_size(), "Hit coordinates preserve exact source size")
	var base: Image = Art.clean_plate.get_image()
	var source: Image = Art.source_bloom.get_image()
	for p in [Vector2i(470,1150), Vector2i(370,1200), Vector2i(50,100), Vector2i(800,1000), Vector2i(470,1320)]:
		check(base.get_pixelv(p) == source.get_pixelv(p), "Pot, window and shelf pixels stay original")
	# Lossless native-object partitions reconstruct both original resting images.
	for bloom in [false, true]:
		var reconstructed: Image = (Art.bloom_background if bloom else Art.bud_background).get_image().duplicate()
		var pot: Image = (Art.bloom_pot if bloom else Art.bud_pot).get_image().duplicate()
		pot.convert(Image.FORMAT_RGBA8)
		reconstructed.blit_rect(pot, Rect2i(Vector2i.ZERO, Art.POT_REGION.size), Art.POT_REGION.position)
		if bloom:
			for index in range(4):
				var part: Image = Art.endpoint_parts[index].get_image().duplicate(); part.convert(Image.FORMAT_RGBA8)
				reconstructed.blit_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), Art.REGIONS[index].position)
		var expected: Image = (Art.source_bloom if bloom else Art.source_bud).get_image().duplicate()
		expected.convert(Image.FORMAT_RGBA8)
		check(reconstructed.get_data() == expected.get_data(), "Independent native objects exactly reconstruct original endpoint pixels")
	# Actual builder lifecycle and transparent hit control on the active rendering.
	var s: Dictionary = state.initial(); s.native.page = "bonsai"; s.ui.brightness = 35
	var pages = Pages.new()
	var initial: Control = pages.build("bonsai", {}, s); root.add_child(initial); await frames()
	s.flags.plantWatered = true; s.flags.plantLit = true; s.flags.plantFertilized = true; s.flags.flowerBloomed = true
	var active: Control = pages.build("bonsai", {}, s); initial.queue_free(); root.add_child(active); await frames()
	var view: TextureRect = active.find_child("BonsaiArtwork",true,false)
	check(view.scale == Vector2.ONE and view.session.active(), "Real page plays without scaling the room")
	check(view.source_space.name == "BonsaiObjects", "Native object root is independently addressable")
	check(view.pot_base is Sprite2D and view.pot_base.name == "PotBase", "Pot/root base is its own native sprite resource")
	check(view.blossoms.size() == 4, "Four persistent native blossom objects")
	for i in range(4):
		var blossom: Node2D = view.blossoms[i]
		check(blossom.name == "Blossom%d" % (i+1) and blossom.position == Art.ANCHORS[i], "Each blossom owns its original anchor and native transform")
		blossom.hide()
		check(not blossom.visible and view.pot_base.visible, "Blossom visibility does not hide the pot")
		blossom.show()
	var pot_pixel := Vector2i(470,1150)
	check(Art.bloom_background.get_image().get_pixelv(pot_pixel).a == 0, "Background contains no duplicate pot underneath its node")
	check(Art.bloom_pot.get_image().get_pixelv(pot_pixel-Art.POT_REGION.position) == source.get_pixelv(pot_pixel), "Pot object retains exact original source pixels")
	check(view.self_modulate.a == 0, "Root image is metadata only, not a duplicate render")
	var started: int = pages.bonsai_growth.started_ms
	var rebuilt: Control = pages.build("bonsai", {}, s); active.queue_free(); root.add_child(rebuilt); await frames()
	check(pages.bonsai_growth.started_ms == started, "Real builder reuses presentation clock")
	pages.bonsai_growth.finish(); view = rebuilt.find_child("BonsaiArtwork",true,false); view._process(0)
	check(view.texture == Art.source_bloom, "Skip restores exact source texture")
	check(view.scale == Vector2.ONE and view.material == null, "No residual scale or shader")
	pages.build("phone_home", {}, s).free()
	check(not pages.bonsai_growth.active(), "Leaving cancels mounted animation")
	rebuilt.queue_free(); await frames()
	# The actual save reader/writer, only inside a fresh isolated test profile.
	if ProjectSettings.globalize_path("user://").begins_with("/tmp/"):
		state.d = s; state.developer_mode = false
		check(state.save_game(), "Ordinary save accepts committed bloom while presentation is transient")
		state.d = state.initial()
		check(state.load_game(), "Ordinary reload restores saved bloom")
		check(state.d.flags.flowerBloomed and not state.d.flags.flowerEightTaken and state.d.digits.d4 == null, "Reload preserves bloom but grants no uncollected digit")
		pages.bonsai_growth.observe(state.d)
		check(not pages.bonsai_growth.active(), "Actual reload cannot replay transient opening")
		controller.dispatch(state.d, "c1_flower", null); controller.dispatch(state.d, "c1_collect_flower", null)
		check(state.save_game() and state.load_game(), "Ordinary earned-digit save/reload succeeds")
		check(state.d.flags.flowerEightTaken and state.d.digits.d4 == "8", "Earned 8 survives without second reward")
		state.developer_mode = true
	else:
		check(false, "Persistence tests require isolated /tmp HOME and XDG profile")
	print("BONSAI_GROWTH: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
