extends RefCounted
## One visual plate, two explicit units. Gameplay remains in its 960×540 world.
const TEXTURE_PATH="res://assets/native/liangzhu_performance_20261021/stage.png"
const COMPOSITION_SIZE=Vector2(240,135)
const WORLD_SIZE=Vector2(960,540)
const RASTER_SIZE=Vector2i(1200,675)
const REHEARSAL_RECEIVER=Rect2(118,44,724,204)
const REHEARSAL_LAMP=Rect2(438,436,84,88)
const FURNITURE_PATH="res://assets/native/liangzhu_performance_20261021/furniture.json"
const FURNITURE_IDS=["table","chair_left","chair_right"]
static var _furniture:Dictionary={}

static func valid_texture(texture:Texture2D)->bool:
	return texture!=null and Vector2i(texture.get_size())==RASTER_SIZE

static func draw(canvas:CanvasItem,texture:Texture2D,world_units:bool=false)->bool:
	if not valid_texture(texture):return false
	canvas.draw_texture_rect(texture,Rect2(Vector2.ZERO,WORLD_SIZE if world_units else COMPOSITION_SIZE),false)
	return true

static func furniture()->Dictionary:
	if _furniture.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(FURNITURE_PATH))
		if parsed is Dictionary:_furniture=parsed
	return _furniture

static func asset_id(id:String)->String:
	return {"study_table":"table","left_chair":"chair_left","right_chair":"chair_right"}.get(id,id)

static func furniture_entries(layout:String,poses:Array=[])->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var data:Dictionary=furniture()
	for id:String in FURNITURE_IDS:
		var placement:Dictionary=data.get("sets",{}).get(layout,{}).get(id,{})
		if placement.is_empty():continue
		var raw:Array=placement.compositionRect;var raw_foot:Array=placement.foot
		var entry:Dictionary={"id":id,"rect":Rect2(raw[0],raw[1],raw[2],raw[3]),"foot":Vector2(raw_foot[0],raw_foot[1]),"alpha":1.0}
		for pose:Dictionary in poses:
			if asset_id(str(pose.id))!=id:continue
			var rect:Array=pose.get("rect",raw);var foot:Array=pose.get("foot",raw_foot)
			entry.rect=Rect2(rect[0],rect[1],rect[2],rect[3]);entry.foot=Vector2(foot[0],foot[1]);entry.alpha=float(pose.get("alpha",1))
		result.append(entry)
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.foot.y<b.foot.y)
	return result

static func draw_prop(canvas:CanvasItem,textures:Dictionary,entry:Dictionary,world_units:bool=false)->void:
	var texture:Texture2D=textures.get(str(entry.id))
	if texture==null or float(entry.get("alpha",1))<=0:return
	var rect:Rect2=entry.rect
	if world_units:rect=Rect2(rect.position*4,rect.size*4)
	canvas.draw_texture_rect(texture,rect,false,Color(1,1,1,float(entry.get("alpha",1))))

static func furniture_ready(textures:Dictionary)->bool:
	var props:Dictionary=furniture().get("props",{})
	for id:String in FURNITURE_IDS:
		if not props.has(id) or not textures.get(id) is Texture2D:return false
		var expected:Array=props[id].nativeSize
		if textures[id].get_size()!=Vector2(expected[0],expected[1]):return false
	return true
