extends RefCounted
## Library poses use the shared player frame, pivot and stride clock.
const Metrics=preload("res://scripts/player_metrics.gd")
const ActorTexture=preload("res://scripts/objects/library_actor_texture.gd")
const ROOT="res://assets/native/library_animation_20261105/"
const WALK_PATH := ROOT + "player_walk_full.png"
const WALK_DIRECTIONS := ["side", "down", "up"]
const WALK_FRAMES := 8
const WALK_CELL := Vector2i(120, 160)
const BOOK_CELL:=Vector2(192,160)
const BOOK_PIVOT:=Vector2(80,154)
const BOOK_HEIGHT:=110.0
const SEATED_HIP_Y := 93.0
const SEATED_VISIBLE_ROWS := 98.0
var ready:=false
var walks:Dictionary={}
var idles:Dictionary={}
var seated:Texture2D
var book:Texture2D

static func walk_region(direction_index: int, frame: int) -> Rect2i:
	return Rect2i(Vector2i(frame, direction_index) * WALK_CELL, WALK_CELL)

static func atlas_size() -> Vector2i:
	return WALK_CELL * Vector2i(WALK_FRAMES, WALK_DIRECTIONS.size())

func ensure_loaded()->bool:
	if ready:return true
	if not ResourceLoader.exists(WALK_PATH): return false
	var atlas: Texture2D = load(WALK_PATH)
	if atlas == null or atlas.get_size() != Vector2(atlas_size()): return false
	var sheet := atlas.get_image()
	if sheet == null or sheet.is_empty() or sheet.is_compressed(): return false
	var pending:Dictionary={};var idle_pending:Dictionary={}
	for row in WALK_DIRECTIONS.size():
		var direction: String = WALK_DIRECTIONS[row]
		var frames: Array[Texture2D] = []
		for index in WALK_FRAMES:
			frames.append(ImageTexture.create_from_image(sheet.get_region(walk_region(row, index))))
		var idle_path := ROOT + "player_" + direction + "_idle.png"
		if not ResourceLoader.exists(idle_path): return false
		idle_pending[direction] = ActorTexture.prepare_player(load(idle_path))
		pending[direction] = frames
	if not ResourceLoader.exists(ROOT+"library_book_sheet.png"):return false
	var original:Texture2D=load(ROOT+"library_book_sheet.png")
	if original.get_size()!=BOOK_CELL*4:return false
	if ResourceLoader.exists(ROOT+"player_seated.png"):
		seated=ActorTexture.prepare_player(load(ROOT+"player_seated.png"), 62, 98)
	book=original;walks=pending;idles=idle_pending;ready=true
	return true

func actor(direction:String,flip:bool,elapsed_ms:float,moving:bool)->Dictionary:
	var key:String="side" if direction=="left" else direction
	if not ready or not walks.has(key):return {}
	var mirrored:bool=direction=="left" or flip
	var frames: Array = walks[key]
	var index := Metrics.frame_for_count(elapsed_ms, frames.size())
	return {
		"texture": frames[index] if moving else idles[key],
		"flip_h": mirrored,
		"direction": direction,
		"motion_frame": index if moving else -1,
		"frame_count": frames.size(),
		"animation": "library_full_walk",
	}

func book_source(index:int)->Rect2:
	return Rect2(Vector2(index%4,index/4)*BOOK_CELL,BOOK_CELL)
