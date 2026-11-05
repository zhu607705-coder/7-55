extends RefCounted
## Generated presentation only. Existing scene/session clocks select every pose.
const ROOT="res://assets/native/library_interactions_20261105/"
const CELLS={"backpack":Vector2(256,256),"paper":Vector2(192,144),"staff":Vector2(96,128)}
var ready:=false
var sheets:Dictionary={}

func ensure_loaded()->bool:
	if ready:return true
	var pending:Dictionary={}
	for id:String in CELLS:
		var path:String=ROOT+id+"_sheet.png"
		if not ResourceLoader.exists(path):return false
		var texture:Texture2D=load(path)
		if texture.get_size()!=CELLS[id]*4:return false
		if id!="staff":
			var pixels:=texture.get_image()
			if pixels.is_compressed():pixels.decompress()
			pixels.generate_mipmaps()
			var filtered:=CanvasTexture.new();filtered.diffuse_texture=ImageTexture.create_from_image(pixels)
			filtered.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			pending[id]=filtered
		else:pending[id]=texture
	sheets=pending;ready=true;return true

static func source(id:String,index:int)->Rect2:
	var cell:Vector2=CELLS[id];var frame:=clampi(index,0,15)
	return Rect2(Vector2(frame%4,frame/4)*cell,cell)

static func bag_frame(inspect_ms:float,inspected:bool,reduced:bool)->int:
	# Frames 8–15 contain a painted note. The physical loose note has its own
	# owner, so only the empty-pocket cells ship in this scene's choreography.
	if reduced or inspect_ms<0:return 7 if inspected else 0
	return mini(7,int(maxf(0,inspect_ms)/95.0))

static func paper_frame(inspect_ms:float,pickup_ms:float,reduced:bool)->int:
	if reduced:return 15
	if pickup_ms>=0:return clampi(15-int(pickup_ms/60.0),5,15)
	if inspect_ms>=0:return clampi(int(inspect_ms/52.0),0,15)
	return 15

static func staff_frame(clock:float,response_ms:float,scan_ms:float,stamp_ms:float,reduced:bool)->int:
	if reduced:return 0
	# Keep the physical stamp's source-sized head, contact and mark owner. The
	# alternate held-stamp cells 12–14 are retained as source, not double-painted.
	if stamp_ms>=0:return [8,9,10,11,3][mini(4,int(stamp_ms/250.0))]
	if scan_ms>=0:return mini(11,4+int(scan_ms/110.0)) if scan_ms<880 else 10 if fposmod(scan_ms,1400)<140 else 11
	if response_ms>=0:return [3,4,5,6,7,8,9,10,11,3][mini(9,int(response_ms/130.0))]
	var blink:=fposmod(maxf(0,clock),5400.0)
	return 1 if blink>=4550 and blink<4660 else 2 if blink>=4660 and blink<4770 else 3 if blink>=4770 and blink<4950 else 0

func backpack_geometry(original:Dictionary,index:int)->Dictionary:
	var geometry:=original.duplicate()
	var area:Rect2=original.rect
	# A fixed whole-family scale keeps zip movement from resizing the backpack.
	var factor:float=minf(area.size.x/199.0,area.size.y/220.0)
	geometry.rect=Rect2(Vector2(area.get_center().x,area.end.y)-Vector2(128,248)*factor,Vector2(256,256)*factor)
	geometry.texture=sheets.backpack;geometry.source=source("backpack",index)
	return geometry
