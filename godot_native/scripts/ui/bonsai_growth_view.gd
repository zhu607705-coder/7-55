extends TextureRect
## Native object composition. Texture metadata still supplies original hit geometry;
## all visible art belongs to separately addressable child CanvasItems.
signal growth_finished

const Art = preload("res://scripts/presentation/bonsai_growth_art.gd")
const Session = preload("res://scripts/presentation/bonsai_growth_session.gd")
const Blossom = preload("res://scripts/ui/bonsai_blossom_node.gd")
const GROWTH_ASSETS := "res://assets/native/bonsai/"
const GROWTH_FRAME_SIZE := Vector2(580, 590)
const GROWTH_ROOT := Vector2(469, 980)
const BUD_CAPTION := Rect2(334, 235, 273, 145)
const BLOOM_CAPTION_POS := Vector2(294, 181)
var session: RefCounted
var reduced := false
var _was_active := false
var source_space: Node2D
var background: Sprite2D
var pot_base: Sprite2D
var blossoms: Array[Node2D] = []
var handoff: Sprite2D
var bloomed := false
var handoff_caption: Sprite2D
var growth_layer: Node2D
var growth_frames: Array[AtlasTexture] = []
var growth_poses: Array[Sprite2D] = []

func configure(state: Dictionary, owner_session: RefCounted) -> void:
	session = owner_session
	reduced = bool(state.native.get("settings", {}).get("reduced_motion", false))
	bloomed = bool(state.flags.flowerBloomed)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	self_modulate.a = 0 # Keep TextureRect hit mapping; do not duplicate child art.
	Art.ensure_ready()
	texture = Art.source_bloom if bloomed else Art.source_bud
	source_space = Node2D.new(); source_space.name = "BonsaiObjects"; add_child(source_space)
	background = _sprite("RoomAndFoliage", Art.bloom_background if bloomed else Art.bud_background)
	pot_base = _sprite("PotBase", Art.bloom_pot if bloomed else Art.bud_pot)
	pot_base.position = Vector2(Art.POT_REGION.position)
	for index in range(4):
		var blossom := Blossom.new(); blossom.configure(index); source_space.add_child(blossom)
		blossom.visible = bloomed; blossoms.append(blossom)
	var empty_pot := load(GROWTH_ASSETS + "growth_empty_pot.png") as Texture2D
	var bud_caption := AtlasTexture.new()
	bud_caption.atlas = empty_pot
	bud_caption.region = BUD_CAPTION
	var cover := _sprite("CaptionBacking", load(GROWTH_ASSETS + "growth_bloom_caption_backing.png") if bloomed else bud_caption)
	cover.position = BLOOM_CAPTION_POS if bloomed else BUD_CAPTION.position
	handoff = _sprite("BudSceneHandoff", Art.source_bud)
	handoff_caption = _sprite("BudCaptionBacking", bud_caption)
	handoff_caption.position = BUD_CAPTION.position
	_was_active = session.active()
	if _was_active and not reduced: _build_growth_bridge(empty_pot)
	resized.connect(_layout_objects)
	_layout_objects()
	_present()
	set_process(_was_active)

func _sprite(object_name: String, art: Texture2D) -> Sprite2D:
	var object := Sprite2D.new(); object.name = object_name
	object.texture = art; object.centered = false; source_space.add_child(object)
	return object

func _build_growth_bridge(backing: Texture2D) -> void:
	growth_layer = Node2D.new()
	growth_layer.name = "GrowthIntermediateFrames"
	source_space.add_child(growth_layer)
	var plate := Sprite2D.new()
	plate.centered = false
	plate.texture = backing
	growth_layer.add_child(plate)
	var atlas := load(GROWTH_ASSETS + "growth_six_frames.png") as Texture2D
	for i: int in range(6):
		var frame := AtlasTexture.new()
		frame.atlas = atlas
		frame.region = Rect2(Vector2(i % 3, floori(i / 3.0)) * GROWTH_FRAME_SIZE, GROWTH_FRAME_SIZE)
		growth_frames.append(frame)
	for i: int in range(2):
		var pose := Sprite2D.new()
		pose.centered = false
		pose.position = GROWTH_ROOT - Vector2(290, 563)
		growth_layer.add_child(pose)
		growth_poses.append(pose)

func _layout_objects() -> void:
	var factor := maxf(size.x/941.0, size.y/1672.0)
	source_space.scale = Vector2.ONE * factor
	source_space.position = (size-Vector2(941,1672)*factor)/2.0

func _present() -> void:
	var age: float = session.age_ms()
	var blossom_age := age
	if is_instance_valid(growth_layer):
		# The last bridge pose is already open. Resume the source poses near the end of their unfurl.
		blossom_age = lerpf(4100.0, Session.DURATION_MS, inverse_lerp(2220.0, Session.DURATION_MS, clampf(age, 2220.0, Session.DURATION_MS)))
	for blossom in blossoms: blossom.present(blossom_age, reduced)
	handoff.visible = _was_active and not reduced and age < 260.0
	handoff_caption.visible = handoff.visible
	if not is_instance_valid(growth_layer): return
	growth_layer.visible = _was_active and age < 2600.0
	if not growth_layer.visible: return
	growth_layer.modulate.a = smoothstep(85.0, 240.0, age) * (1.0 - smoothstep(2220.0, 2420.0, age))
	var pose := clampf((age - 140.0) / 1810.0 * 5.0, 0.0, 5.0)
	var current := floori(pose)
	growth_poses[0].texture = growth_frames[current]
	growth_poses[1].texture = growth_frames[mini(current + 1, 5)]
	var mix := smoothstep(.62, 1.0, pose - current)
	growth_poses[0].modulate.a = 1.0 - mix
	growth_poses[1].modulate.a = mix

func _process(_delta: float) -> void:
	if not session.active():
		texture = Art.source_bloom
		var completed := _was_active
		_was_active = false
		set_process(false)
		if completed: growth_finished.emit()
	_present()

func finish() -> void:
	session.finish()
	if _was_active: _process(0)
