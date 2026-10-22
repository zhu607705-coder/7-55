extends TextureRect
## Native object composition. Texture metadata still supplies original hit geometry;
## all visible art belongs to separately addressable child CanvasItems.
const Art = preload("res://scripts/presentation/bonsai_growth_art.gd")
const Session = preload("res://scripts/presentation/bonsai_growth_session.gd")
const Blossom = preload("res://scripts/ui/bonsai_blossom_node.gd")
var session: RefCounted
var reduced := false
var _was_active := false
var source_space: Node2D
var background: Sprite2D
var pot_base: Sprite2D
var blossoms: Array[Node2D] = []
var handoff: Sprite2D
var bloomed := false

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
	handoff = _sprite("BudSceneHandoff", Art.source_bud)
	_was_active = session.active()
	handoff.visible = _was_active
	resized.connect(_layout_objects)
	_layout_objects()
	_present()
	set_process(_was_active)

func _sprite(object_name: String, art: Texture2D) -> Sprite2D:
	var object := Sprite2D.new(); object.name = object_name
	object.texture = art; object.centered = false; source_space.add_child(object)
	return object

func _layout_objects() -> void:
	var factor := maxf(size.x/941.0, size.y/1672.0)
	source_space.scale = Vector2.ONE * factor
	source_space.position = (size-Vector2(941,1672)*factor)/2.0

func _present() -> void:
	var age: float = session.age_ms()
	for blossom in blossoms: blossom.present(age, reduced)
	handoff.visible = _was_active and age < 320.0
	handoff.modulate.a = 1.0-smoothstep(0,320,age)

func _process(_delta: float) -> void:
	if not session.active():
		texture = Art.source_bloom
		_was_active = false
		set_process(false)
	_present()

func finish() -> void:
	session.finish()
	if _was_active: _process(0)
