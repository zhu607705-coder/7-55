extends RefCounted
## Drawing adapter, not another world/progression model. No oversized source is loaded.
const SOURCE="res://assets/rpg/campus/zijingang_campus_loop_panorama.png"
const MANIFEST="res://data/native/campus-loop-panorama-tiles.json"
var source_path:=""
var manifest:Dictionary={}
var textures:Array[Texture2D]=[]
var ready:=false
var issue:=""

static func supports(path:String)->bool:
	return path==SOURCE or path=="src/assets/rpg/campus/zijingang_campus_loop_panorama.png" or path=="assets/rpg/campus/zijingang_campus_loop_panorama.png"

func configure(path:String)->bool:
	if supports(path) and source_path==SOURCE:return true
	source_path=SOURCE if supports(path) else ""
	manifest={};textures.clear();ready=false;issue=""
	if not source_path.is_empty() and FileAccess.file_exists(MANIFEST):
		var value:Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		if value is Dictionary and str(value.get("schema",""))=="source-pixel-tiled-texture-v1":manifest=value
	return not source_path.is_empty()

func get_size()->Vector2:
	var dimensions:Array=manifest.get("sourceSize",[13668,1084] if not source_path.is_empty() else [0,0])
	return Vector2(float(dimensions[0]),float(dimensions[1]))

func ensure_loaded()->bool:
	if ready:return true
	if source_path.is_empty():return false
	if manifest.is_empty():
		# Manifest is core-owned; do not turn a temporarily unavailable pack into a permanent miss.
		var path:=source_path;source_path="";configure(path)
	if manifest.is_empty():issue="missing_tiled_manifest";return false
	var next:Array[Texture2D]=[]
	for tile:Dictionary in manifest.get("tiles",[]):
		var path:=str(tile.path)
		if not ResourceLoader.exists(path):issue="waiting_for_tiled_content";return false
		var texture:Texture2D=load(path)
		var expected:Array=tile.textureSize
		if texture==null or texture.get_size()!=Vector2(float(expected[0]),float(expected[1])) or maxi(texture.get_width(),texture.get_height())>2048:
			issue="invalid_tiled_texture";return false
		next.append(texture)
	if next.is_empty():issue="empty_tiled_manifest";return false
	textures=next;ready=true;issue="";return true

func pieces(destination:Rect2,source:Rect2)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if not destination.has_area() or not source.has_area():return result
	var factor:=destination.size/source.size
	var index:=0
	for tile:Dictionary in manifest.get("tiles",[]):
		var raw:Array=tile.sourceRect
		var world_rect:=Rect2(float(raw[0]),float(raw[1]),float(raw[2]),float(raw[3]))
		var overlap:=world_rect.intersection(source)
		if overlap.has_area():
			var uv:Array=tile.textureRegion
			result.append({"index":index,"destination":Rect2(destination.position+(overlap.position-source.position)*factor,overlap.size*factor),"source":Rect2(Vector2(float(uv[0]),float(uv[1]))+overlap.position-world_rect.position,overlap.size),"worldSource":overlap})
		index+=1
	return result

func draw_region(canvas:CanvasItem,destination:Rect2,source:Rect2,modulate:Color=Color.WHITE)->void:
	if not ensure_loaded():return
	for piece:Dictionary in pieces(destination,source):
		# Gutter must remain sampleable when inherited filtering is linear at non-integer zoom.
		canvas.draw_texture_rect_region(textures[int(piece.index)],piece.destination,piece.source,modulate,false,false)

func snapshot()->Dictionary:
	var largest:=0
	for texture:Texture2D in textures:largest=maxi(largest,maxi(texture.get_width(),texture.get_height()))
	var dimensions:=get_size()
	return {"kind":"source_pixel_tiles","source":source_path,"ready":ready,"sourceSize":{"x":dimensions.x,"y":dimensions.y},"tileCount":textures.size(),"plannedTileCount":manifest.get("tiles",[]).size(),"maxTextureDimension":largest,"physicalLimit":2048,"issue":issue}
