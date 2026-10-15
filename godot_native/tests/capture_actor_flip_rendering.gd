extends SceneTree
## Native-renderer fixture. Uses real Main viewport layout and inherited World._draw.
## Source-seeded isolation is not manual campaign evidence; no earned save is used.
const Metrics = preload("res://scripts/player_metrics.gd")
var state: Node
var shell: Control
var world: Control
var blank: Texture2D
var actual_frames: Array
var idle: Texture2D
var checks := 0
var failures := 0
var records: Array = []
var output := ""
func _initialize() -> void: run.call_deferred()
func frames(count := 3) -> void:
	for i in count: await process_frame
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ACTOR_RENDER: " + label)
func render() -> Image:
	world.queue_redraw()
	await frames(2)
	await RenderingServer.frame_post_draw
	return shell.world_viewport.get_texture().get_image()
func color_delta(a: Color, b: Color) -> float:
	return maxf(absf(a.r-b.r), maxf(absf(a.g-b.g), absf(a.b-b.b)))
func clear_region(image: Image, baseline: Image, x: int, y: int) -> bool:
	# Require a rendered 3x3 clear neighborhood. A single same-color texel
	# inside the sprite is visually indistinguishable from the backdrop.
	for dy in range(-1,2):
		for dx in range(-1,2):
			var at := Vector2i(x+dx,y+dy)
			if at.x<0 or at.y<0 or at.x>=image.get_width() or at.y>=image.get_height(): return false
			if color_delta(image.get_pixelv(at),baseline.get_pixelv(at)) >= .001: return false
	return true
func measure(image: Image, baseline: Image, tag: String) -> Dictionary:
	var strong := 0
	var missing := 0
	var transparent := 0
	var false_positive := 0
	var low := Vector2i(image.get_width(), image.get_height())
	var high := Vector2i(-1,-1)
	var min_visible := Vector2i(image.get_width(), image.get_height())
	var max_visible := Vector2i(-1,-1)
	var visual: Rect2 = Metrics.visual_rect(world.player, world.display_scale_at(world.player))
	var origin: Vector2 = world.size / 2 - world.camera * world.zoom
	var draw_box := Rect2(origin + visual.position * world.zoom, visual.size * world.zoom)
	var area: Rect2i = Rect2i(draw_box.grow(draw_box.size.x * 1.5))
	area = area.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var delta := color_delta(image.get_pixel(x,y), baseline.get_pixel(x,y))
			var source: Vector2 = (Vector2(x+.5,y+.5)-origin) / world.zoom
			var picked: bool = world.object_picker.pick(source, world.targets, true).get("id", "") == "actor_fixture"
			if delta > .1:
				strong += 1
				if not picked: missing += 1
				low = Vector2i(mini(low.x,x),mini(low.y,y))
				high = Vector2i(maxi(high.x,x),maxi(high.y,y))
			if delta > .02:
				min_visible = Vector2i(mini(min_visible.x,x),mini(min_visible.y,y))
				max_visible = Vector2i(maxi(max_visible.x,x),maxi(max_visible.y,y))
			if draw_box.has_point(Vector2(x+.5,y+.5)) and delta < .001 and clear_region(image,baseline,x,y):
				transparent += 1
				if picked: false_positive += 1
	check(strong > 100, tag+" has real rendered actor pixels")
	check(missing == 0, tag+" opaque rendered pixels resolve exact actor picker (missing=%d/%d)" % [missing,strong])
	check(transparent > 100 and false_positive == 0, tag+" transparent rendered pixels remain unpickable (false=%d/%d)" % [false_positive,transparent])
	check(draw_box.grow(1).encloses(Rect2(Vector2(min_visible),Vector2(max_visible-min_visible+Vector2i.ONE))), tag+" sprite stays over its unchanged visual/physics frame")
	var ground: Vector2 = origin+(world.player+Vector2(0,39))*world.zoom
	check(absf((low.x+high.x+1)/2.0-ground.x) < 12*world.zoom, tag+" visible sprite remains centered above shadow")
	var result := {"tag":tag,"opaque_pixels":strong,"picker_misses":missing,"transparent_pixels":transparent,"false_picks":false_positive,"opaque_bounds":[low.x,low.y,high.x+1,high.y+1],"ground":[ground.x,ground.y],"visual_frame":[draw_box.position.x,draw_box.position.y,draw_box.size.x,draw_box.size.y],"player":[world.player.x,world.player.y],"foot":[Metrics.foot_rect(world.player).position.x,Metrics.foot_rect(world.player).position.y]}
	records.append(result)
	return result
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("ACTOR_RENDER_REQUIRES_NATIVE_RENDERER: headless is parse-only, not rendering evidence")
		quit(2)
		return
	output = OS.get_environment("ACTOR_FLIP_REPORT_DIR")
	if output.is_empty(): output = ProjectSettings.globalize_path("res://.screenshots/actor-flip")
	DirAccess.make_dir_recursive_absolute(output)
	state = root.get_node("State")
	state.developer_mode = true
	state.d = state.initial()
	state.d.native.chapter=2; state.d.native.scene="library_interior"; state.d.native.page="phone_home"; state.d.native.mode="light"
	state.d.rpgScene="library_interior"; state.d.runtimeMode="rpg"; state.d.ui.libraryFinalsPhase="evidence_gathering"
	state.d.actOne.movementEnabled=true; state.d.actOne.controlsInstalled=true
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell)
	await frames(5)
	shell.set_process(false); shell._close_modal()
	world=shell.world; world.set_process(false)
	actual_frames=world.player_frames.side.duplicate(); idle=world.player_side_idle
	var transparent_image := Image.create(96,128,false,Image.FORMAT_RGBA8)
	transparent_image.fill(Color.TRANSPARENT)
	blank=ImageTexture.create_from_image(transparent_image)
	# Isolate painting only: authored actor art, scale, foot metrics, shadow,
	# camera transform, renderer and picker remain the production implementations.
	world.background=null; world.foreground=[]; world.chapter3_layers=null; world.chapter4_layers=null; world.library_layers=null; world.lake_session=null
	world.targets=[{"id":"actor_fixture","follow_player":true,"item":"gamepad"}]
	world.capture_mode=true; world.facing="side"; world.transition_alpha=0; world.mode_mix=0; world.guard_visible=false
	world.player=Vector2(710,430); world.camera=world.player
	state.d.playerName=""; state.d.characterName=""
	var before_state: String = JSON.stringify(state.d)
	var before_position: Vector2 = world.player
	var before_foot: Rect2 = Metrics.foot_rect(world.player)
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		DisplayServer.window_set_size(dimensions); root.size=dimensions; shell.size=Vector2(dimensions)
		shell.mobile_world=true; shell.compact_inventory_open=false; shell._layout()
		await frames(5)
		world.camera=world.player
		world.zoom=.85 if dimensions.x < 1100 else 1.17
		world.player_frames.side=[blank,blank,blank,blank,blank,blank,blank,blank]; world.player_side_idle=blank
		world.walk_clock=0; world.player_flip=false
		var baseline: Image = await render()
		baseline.save_png(output.path_join("%dx%d-shadow-only.png" % [dimensions.x,dimensions.y]))
		world.player_frames.side=actual_frames; world.player_side_idle=idle
		for frame_index in range(-1,8):
			world.walk_clock=0 if frame_index<0 else (frame_index*110+1)/1000.0
			var mirrored: Array=[]
			for flip in [false,true]:
				world.player_flip=flip
				var rendered: Image = await render()
				var tag := "%dx%d-%s-%s" % [dimensions.x,dimensions.y,"idle" if frame_index<0 else str(frame_index),"left" if flip else "right"]
				mirrored.append(measure(rendered,baseline,tag))
				if frame_index<0:
					rendered.save_png(output.path_join(tag+"-world.png"))
					root.get_texture().get_image().save_png(output.path_join(tag+"-screen.png"))
			var right: Dictionary=mirrored[0]; var left: Dictionary=mirrored[1]
			var reflected_center: float=(right.opaque_bounds[0]+right.opaque_bounds[2]+left.opaque_bounds[0]+left.opaque_bounds[2])/4.0
			check(absf(reflected_center-float(left.ground[0]))<=1.01,"left/right rendered bounds mirror about the unchanged shadow at "+left.tag)
			check(right.opaque_bounds[1]==left.opaque_bounds[1] and right.opaque_bounds[3]==left.opaque_bounds[3],"facing never changes vertical grounding at "+left.tag)
		check(world.player==before_position and Metrics.foot_rect(world.player)==before_foot,"rendering leaves actor and physics coordinates unchanged")
	check(JSON.stringify(state.d)==before_state,"rendering and picker never mutate story/save state")
	var report := {"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),"render_method":RenderingServer.get_current_rendering_method(),"checks":checks,"failures":failures,"cases":records,"note":"Source-seeded native render fixture, not earned manual campaign proof"}
	var file := FileAccess.open(output.path_join("results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")); file.close()
	print("ACTOR_FLIP_RENDER_RESULT: ",checks," checks; ",failures," failures; ",records.size()," native rendered cases; report=",output)
	await shell.shutdown(); shell.queue_free(); await frames(2)
	quit(1 if failures else 0)
