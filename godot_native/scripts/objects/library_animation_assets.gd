extends RefCounted
## One coherent generated family. Rendering only; shared player metrics remain authoritative.
const Metrics=preload("res://scripts/player_metrics.gd")
const ROOT="res://assets/native/library_animation_20261105/"
const WALK_FRAMES:=16
const BOOK_CELL:=Vector2(192,160)
const BOOK_PIVOT:=Vector2(80,154)
const BOOK_HEIGHT:=110.0
var ready:=false
var walks:Dictionary={}
var idles:Dictionary={}
var seated:Texture2D
var book:Texture2D

func ensure_loaded()->bool:
	if ready:return true
	var pending:Dictionary={};var idle_pending:Dictionary={}
	for direction:String in ["down","up","side"]:
		var frames:Array[Texture2D]=[]
		for index:int in WALK_FRAMES:
			var path:String=ROOT+"player_%s_%02d.png"%[direction,index]
			if not ResourceLoader.exists(path):return false
			var texture:Texture2D=load(path)
			if texture.get_size()!=Metrics.FRAME:return false
			frames.append(texture)
		var idle_path:String=ROOT+"player_"+direction+"_idle.png"
		if not ResourceLoader.exists(idle_path):return false
		idle_pending[direction]=load(idle_path);pending[direction]=frames
	if not ResourceLoader.exists(ROOT+"library_book_sheet.png"):return false
	var original:Texture2D=load(ROOT+"library_book_sheet.png")
	if original.get_size()!=BOOK_CELL*4:return false
	# Shelf-scale detail is minified fivefold, so sample a filtered mip chain.
	var image:Image=original.get_image()
	if image.is_compressed():image.decompress()
	image.generate_mipmaps()
	var filtered:=CanvasTexture.new();filtered.diffuse_texture=ImageTexture.create_from_image(image)
	filtered.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if ResourceLoader.exists(ROOT+"player_seated.png"):
		seated=load(ROOT+"player_seated.png")
	book=filtered;walks=pending;idles=idle_pending;ready=true
	return true

func actor(direction:String,flip:bool,elapsed_ms:float,moving:bool)->Dictionary:
	var key:String="side" if direction=="left" else direction
	if not ready or not walks.has(key):return {}
	var mirrored:bool=direction=="left" or flip
	var index:int=Metrics.frame_for_count(elapsed_ms,WALK_FRAMES)
	return {"texture":walks[key][index] if moving else idles[key],"flip_h":mirrored,"direction":direction,"motion_frame":index if moving else -1,"animation":"library_generated_16"}

func book_source(index:int)->Rect2:
	return Rect2(Vector2(index%4,index/4)*BOOK_CELL,BOOK_CELL)
