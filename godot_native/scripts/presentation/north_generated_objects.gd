extends RefCounted
## A1 pilot: generated wall/desk art, source-sized cleanup and calibrated bases.
## No input or progression authority. Missing chapter art preserves the source plate.
const Metrics=preload("res://scripts/player_metrics.gd")
var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/north-generated-objects.json"))
var active:=false
var desk_texture:Texture2D
var wall_texture:Texture2D
var plate:Texture2D
var wall_composite:ImageTexture
var composite_plate_id:=0
var desk_tints:Dictionary={}
var wall_tint:=Color.WHITE
const WALL_COMPOSITE_BOUNDS:=Rect2(1226,473,381,145)
const COMPOSITE_SCALE:=3
var issues:Array[String]=[]

static func rect(row:Array)->Rect2:return Rect2(float(row[0]),float(row[1]),float(row[2]),float(row[3]))

func configure(scene:String,floor_id:String,source_plate:Texture2D)->void:
	active=false;plate=source_plate
	if scene!=str(data.sceneId) or floor_id!=str(data.floor) or plate==null:return
	issues.clear()
	if desk_texture==null:desk_texture=_texture(data.desk.texture,Vector2(242,281))
	if wall_texture==null:wall_texture=_texture(data.wall.texture,Vector2(559,182))
	active=desk_texture!=null and wall_texture!=null and plate.get_size()==Vector2(1672,941)
	if active and (wall_composite==null or composite_plate_id!=plate.get_instance_id()):
		var source:Image=plate.get_image()
		if source.is_compressed():source.decompress()
		var reference:Image=load("res://assets/rpg/interiors/finale/chapter4-755/base/a1.png").get_image()
		if reference.is_compressed():reference.decompress()
		wall_tint=_material_tint(source,reference,Rect2i(1294,520,20,30))
		desk_tints.clear()
		for object:Dictionary in data.desks:
			desk_tints[object.id]=_material_tint(source,reference,Rect2i(int(object.centerX)-12,int(object.baselineY)-48,24,10))
		_build_wall_composite(source)

func _material_tint(source:Image,reference:Image,bounds:Rect2i)->Color:
	# Match the current authored time plate; generated objects cannot stay sunlit
	# during 22:45 or blackout. Samples use the same source material locations.
	var current:=Vector3.ZERO;var original:=Vector3.ZERO
	for y in range(bounds.position.y,bounds.end.y,3):
		for x in range(bounds.position.x,bounds.end.x,3):
			var a:Color=source.get_pixel(x,y);var b:Color=reference.get_pixel(x,y)
			current+=Vector3(a.r,a.g,a.b);original+=Vector3(b.r,b.g,b.b)
	return Color(clampf(current.x/maxf(.001,original.x),0,1),clampf(current.y/maxf(.001,original.y),0,1),clampf(current.z/maxf(.001,original.z),0,1),1)

func _texture(path:String,expected:Vector2)->Texture2D:
	if not ResourceLoader.exists(path):issues.append("missing:"+path);return null
	var result:Texture2D=load(path)
	if result==null or result.get_size()!=expected:issues.append("size:"+path);return null
	var image:Image=result.get_image()
	if image==null:return null
	if image.is_compressed():image.decompress()
	if image.detect_alpha()==Image.ALPHA_NONE:issues.append("alpha:"+path);return null
	return result

func desk_rect(object:Dictionary)->Rect2:
	var extent:=rect(data.desk.visibleRect).size*float(data.desk.scale)
	return Rect2(Vector2(float(object.centerX)-extent.x/2,float(object.baselineY)-extent.y),extent)

func desk_solids(object:Dictionary)->Array[Rect2]:
	var result:Array[Rect2]=[];var destination:=desk_rect(object)
	for row:Array in data.desk.footprints:
		var local:=rect(row)
		result.append(Rect2(destination.position+local.position*float(data.desk.scale),local.size*float(data.desk.scale)))
	return result

func adjusted_collisions(original:Array)->Array:
	if not active:return original
	var result:Array=original.duplicate(true)
	for object:Dictionary in data.desks:
		var source_id:String=object.sourceCollisionId
		if original.filter(func(box:Dictionary):return box.get("id","")==source_id).is_empty():continue
		result=result.filter(func(box:Dictionary):return box.get("id","") not in [source_id,source_id+"_chair_base"])
		var bases:=desk_solids(object)
		for i:int in bases.size():
			var base:Rect2=bases[i]
			result.append({"id":source_id if i==0 else source_id+"_chair_base","x":base.position.x,"y":base.position.y,"width":base.size.x,"height":base.size.y,"generatedObjectId":object.id})
	return result

func owns_cover(cover:Dictionary)->bool:
	return active and cover.get("id","")=="a1_classroom_partition_face"

func wall_in_front(player:Vector2)->bool:
	return active and Metrics.foot_rect(player).end.y<float(data.wall.baselineY)

func _project(area:Rect2,context:Dictionary)->Rect2:
	return Rect2(Vector2(context.origin)+area.position*float(context.zoom),area.size*float(context.zoom))

func _clean(canvas:CanvasItem,area:Rect2,donor:Rect2,context:Dictionary)->void:
	# Repeat unchanged source floor pixels only inside the old object's bounds.
	var y:float=area.position.y
	while y<area.end.y-.01:
		var h:float=minf(donor.size.y,area.end.y-y);var x:float=area.position.x
		while x<area.end.x-.01:
			var w:float=minf(donor.size.x,area.end.x-x)
			canvas.draw_texture_rect_region(plate,_project(Rect2(x,y,w,h),context),Rect2(donor.position,Vector2(w,h)))
			x+=w
		y+=h

func wall_rect()->Rect2:
	var bounds:=rect(data.wall.destinationRect);var source:=rect(data.wall.visibleRect)
	var factor:float=minf(bounds.size.x/source.size.x,bounds.size.y/source.size.y)
	var extent:=source.size*factor
	return Rect2(Vector2(bounds.get_center().x-extent.x/2,bounds.end.y-extent.y),extent)

func _build_wall_composite(source:Image)->void:
	# Flatten one wall plus same-source evidence once, so the reveal-alpha pass
	# never paints a translucent wall stripe over a previously drawn blackboard.
	var material:Image=wall_texture.get_image()
	if material.is_compressed():material.decompress()
	var combined:=Image.create(1143,435,false,Image.FORMAT_RGBA8)
	material=material.get_region(Rect2i(rect(data.wall.visibleRect)))
	for y in material.get_height():
		for x in material.get_width():material.set_pixel(x,y,material.get_pixel(x,y)*wall_tint)
	var destination:=wall_rect()
	material.resize(roundi(destination.size.x*COMPOSITE_SCALE),roundi(destination.size.y*COMPOSITE_SCALE),Image.INTERPOLATE_NEAREST)
	combined.blit_rect(material,Rect2i(Vector2i.ZERO,material.get_size()),Vector2i((destination.position-WALL_COMPOSITE_BOUNDS.position)*COMPOSITE_SCALE))
	for part:Dictionary in data.wall.preservedSourceParts:
		var polygon:=PackedVector2Array()
		for row:Array in part.polygon:polygon.append(Vector2(float(row[0]),float(row[1])))
		var bounds:=Rect2(polygon[0],Vector2.ZERO)
		for point:Vector2 in polygon:bounds=bounds.expand(point)
		for y in range(int(bounds.position.y),int(bounds.end.y)):
			for x in range(int(bounds.position.x),int(bounds.end.x)):
				if Geometry2D.is_point_in_polygon(Vector2(x+.5,y+.5),polygon):
					combined.fill_rect(Rect2i(Vector2i((Vector2(x,y)-WALL_COMPOSITE_BOUNDS.position)*COMPOSITE_SCALE),Vector2i.ONE*COMPOSITE_SCALE),source.get_pixel(x,y))
	wall_composite=ImageTexture.create_from_image(combined);composite_plate_id=plate.get_instance_id()

func _wall(canvas:CanvasItem,context:Dictionary,tint:Color)->void:
	if wall_composite!=null:canvas.draw_texture_rect(wall_composite,_project(WALL_COMPOSITE_BOUNDS,context),false,tint)

func draw_background(canvas:CanvasItem,context:Dictionary)->void:
	if not active:return
	for object:Dictionary in data.desks:_clean(canvas,rect(object.cleanRect),rect(object.donorRect),context)
	_clean(canvas,rect(data.wall.destinationRect),rect(data.wall.donorRect),context)
	_wall(canvas,context,Color.WHITE)

func draw_objects(canvas:CanvasItem,context:Dictionary,front:bool)->void:
	if not active:return
	var player:Vector2=context.player
	var foot_bottom:float=Metrics.foot_rect(player).end.y
	var tint:=Color.WHITE.lerp(Color(.03,.15,.26),float(context.get("mode_mix",0))*.3)
	for object:Dictionary in data.desks:
		if (foot_bottom<float(object.baselineY))!=front:continue
		canvas.draw_texture_rect_region(desk_texture,_project(desk_rect(object),context),rect(data.desk.visibleRect),tint*desk_tints.get(object.id,Color.WHITE))
	if front and wall_in_front(player):
		tint.a=.78;_wall(canvas,context,tint)

func snapshot()->Dictionary:
	return {"active":active,"floor":"A1","generatedDesks":data.desks.size() if active else 0,"generatedWalls":1 if active else 0,"sourceSize":[1672,941],"issues":issues.duplicate()}
