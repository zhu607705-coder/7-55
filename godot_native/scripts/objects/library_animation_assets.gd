extends "res://scripts/player_walk_art.gd"
## Library poses use the shared player frame, pivot and stride clock.
const BOOK_CELL:=Vector2(192,160)
const BOOK_PIVOT:=Vector2(80,154)
const BOOK_HEIGHT:=110.0
const SEATED_HIP_Y := 93.0
const SEATED_VISIBLE_ROWS := SEATED_HIP_Y
var seated:Texture2D
var book:Texture2D
var _female_seated: Texture2D

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
	seated_for(Protagonist.MALE)
	book = original
	ready = true
	return true

func seated_for(variant: String) -> Texture2D:
	if variant == Protagonist.FEMALE:
		var path := Protagonist.FEMALE_ROOT + "player_seated.png"
		if _female_seated == null and ResourceLoader.exists(path):
			_female_seated = load(path)
		return _female_seated
	if seated == null and ResourceLoader.exists(ROOT + "player_seated.png"):
		seated = load(ROOT + "player_seated.png")
	return seated

func book_source(index:int)->Rect2:
	return Rect2(Vector2(index%4,index/4)*BOOK_CELL,BOOK_CELL)
