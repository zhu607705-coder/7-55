extends "res://scripts/player_walk_art.gd"
## Library poses use the shared player frame, pivot and stride clock.
const BOOK_CELL:=Vector2(192,160)
const BOOK_PIVOT:=Vector2(80,154)
const BOOK_HEIGHT:=110.0
const SEATED_HIP_Y := 93.0
const SEATED_VISIBLE_ROWS := 98.0
var seated:Texture2D
var book:Texture2D

func ensure_loaded() -> bool:
	if ready:
		return true
	var original: Texture2D = load(ROOT + "library_book_sheet.png")
	if original == null or original.get_size() != BOOK_CELL * 4:
		return false
	var shared := preload("res://scripts/player_walk_art.gd").shared()
	if not shared.ensure_loaded():
		return false
	walks = shared.walks
	idles = shared.idles
	if ResourceLoader.exists(ROOT + "player_seated.png"):
		seated = ActorTexture.prepare_player(load(ROOT + "player_seated.png"), 62, 98)
	book = original
	ready = true
	return true

func book_source(index:int)->Rect2:
	return Rect2(Vector2(index%4,index/4)*BOOK_CELL,BOOK_CELL)
