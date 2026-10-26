extends RefCounted
## A1 production keeps the existing wall/combined-desk pilot. The 53-object
## reconstruction is an explicit debug-only preview until clean floors pass QA.
## Source-native cleanup samples the current time plate; no mother image is edited.
## No input or progression authority. Missing chapter art preserves the source plate.
const Metrics=preload("res://scripts/player_metrics.gd")
const DeveloperPolicy=preload("res://scripts/developer_tools_policy.gd")
const PREVIEW_ENV:="NORTH_PROP_OBJECT_PREVIEW"
var independent_preview:=false
var data:Dictionary
var active:=false
var desk_texture:Texture2D
var wall_texture:Texture2D
var prop_textures:Dictionary={}
var prop_tints:Dictionary={}
var plate:Texture2D
var wall_composite:ImageTexture
var composite_plate_id:=0
var desk_tints:Dictionary={}
var wall_tint:=Color.WHITE
const WALL_COMPOSITE_BOUNDS:=Rect2(1226,473,381,145)
const COMPOSITE_SCALE:=3
var issues:Array[String]=[]

func _init()->void:
	independent_preview=preview_allowed(DeveloperPolicy.available(),OS.get_environment(PREVIEW_ENV))
	var path:="res://data/native/north-generated-objects.json" if independent_preview else "res://data/native/north-baseline-objects.json"
	data=JSON.parse_string(FileAccess.get_file_as_string(path))

static func preview_allowed(developer_available:bool,requested:String)->bool:
	return developer_available and requested=="1"

static func rect(row:Array)->Rect2:return Rect2(float(row[0]),float(row[1]),float(row[2]),float(row[3]))

func configure(scene:String,floor_id:String,source_plate:Texture2D)->void:
	active=false;plate=source_plate
	if scene!=str(data.sceneId) or floor_id!=str(data.floor) or plate==null:return
	issues.clear()
	if desk_texture==null:desk_texture=_texture(data.desk.texture,Vector2(242,281))
	if wall_texture==null:wall_texture=_texture(data.wall.texture,Vector2(559,182))
	var props_ready:=true
	for object:Dictionary in asset_registrations():
		if not prop_textures.has(object.id):
			var dimensions:Array=object.textureSize
			var loaded:=_texture(object.texture,Vector2(float(dimensions[0]),float(dimensions[1])))
			if loaded!=null:prop_textures[object.id]=loaded
		if not prop_textures.has(object.id):props_ready=false
	# One transaction: never erase a baked object until every replacement exists.
	active=desk_texture!=null and wall_texture!=null and props_ready and plate.get_size()==Vector2(1672,941)
	if active and (wall_composite==null or composite_plate_id!=plate.get_instance_id()):
		var source:Image=plate.get_image()
		if source.is_compressed():source.decompress()
		var reference:Image=load("res://assets/rpg/interiors/finale/chapter4-755/base/a1.png").get_image()
		if reference.is_compressed():reference.decompress()
		wall_tint=_material_tint(source,reference,Rect2i(1294,520,20,30))
		desk_tints.clear()
		for object:Dictionary in data.desks:
			desk_tints[object.id]=_material_tint(source,reference,Rect2i(int(object.centerX)-12,int(object.baselineY)-48,24,10))
		prop_tints.clear()
		for object:Dictionary in data.get("props",[]):
			prop_tints[object.id]=_material_tint(source,reference,Rect2i(rect(object.tintSampleRect)))
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

func prop_rect(object:Dictionary)->Rect2:
	var extent:=rect(object.visibleRect).size*float(object.scale)
	return Rect2(Vector2(float(object.centerX)-extent.x/2,float(object.baselineY)-extent.y),extent)

func prop_in_front(object:Dictionary,player:Vector2)->bool:
	return active and Metrics.foot_rect(player).end.y<=float(object.get("depthBaselineY",object.baselineY))

func source_part_keeps_pixel(point:Vector2)->bool:
	for excluded:Array in data.wall.get("sourceExclusions",[]):
		if rect(excluded).has_point(point):return false
	return true

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
	if not active:return false
	var id:=str(cover.get("id",""))
	if id=="a1_classroom_partition_face":return true
	# The old 105 lectern also has an independent source foreground crop.
	# Retire it only with the complete generated family, or it redraws the old
	# podium over both the new sprite and the player during the actor pass.
	for object:Dictionary in data.get("props",[]):
		if id in object.get("sourceForegroundIds",[]):return true
	return false

func wall_in_front(player:Vector2)->bool:
	# The source collider permits exact contact at its north edge. Keep that
	# legal stand behind the wall until the feet actually cross the baseline.
	return active and Metrics.foot_rect(player).end.y<=float(data.wall.baselineY)

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
				if source_part_keeps_pixel(Vector2(x+.5,y+.5)) and Geometry2D.is_point_in_polygon(Vector2(x+.5,y+.5),polygon):
					combined.fill_rect(Rect2i(Vector2i((Vector2(x,y)-WALL_COMPOSITE_BOUNDS.position)*COMPOSITE_SCALE),Vector2i.ONE*COMPOSITE_SCALE),source.get_pixel(x,y))
	# The source lectern hid a section of the chalk shelf. Restore only that
	# measured strip from adjacent same-height/current-time shelf pixels, so a
	# transparent edge in the new silhouette cannot expose a gap or an old prop.
	for patch:Dictionary in data.wall.get("restoredSourceParts",[]):
		var area:=Rect2i(rect(patch.rect));var donor:=Rect2i(rect(patch.donorRect))
		for y in range(area.position.y,area.end.y):
			for x in range(area.position.x,area.end.x):
				var sample:=donor.position+Vector2i((x-area.position.x)%donor.size.x,(y-area.position.y)%donor.size.y)
				combined.fill_rect(Rect2i(Vector2i((Vector2(x,y)-WALL_COMPOSITE_BOUNDS.position)*COMPOSITE_SCALE),Vector2i.ONE*COMPOSITE_SCALE),source.get_pixelv(sample))
	wall_composite=ImageTexture.create_from_image(combined);composite_plate_id=plate.get_instance_id()

func _wall(canvas:CanvasItem,context:Dictionary,tint:Color)->void:
	if wall_composite!=null:canvas.draw_texture_rect(wall_composite,_project(WALL_COMPOSITE_BOUNDS,context),false,tint)

func draw_background(canvas:CanvasItem,context:Dictionary)->void:
	if not active:return
	for object:Dictionary in data.desks:_clean(canvas,rect(object.cleanRect),rect(object.donorRect),context)
	_clean(canvas,rect(data.wall.destinationRect),rect(data.wall.donorRect),context)
	for object:Dictionary in data.get("props",[]):
		for patch:Dictionary in object.cleanup:
			_clean(canvas,rect(patch.rect),rect(patch.donorRect),context)
	_wall(canvas,context,Color.WHITE)

func asset_registrations()->Array:
	return data.get("props",[])+data.get("deskParts",[])

func object_registrations()->Array:
	var result:Array=data.get("props",[]).duplicate(true)
	for group:Dictionary in data.desks:
		for part:Dictionary in data.get("deskParts",[]):
			var registration:Dictionary=part.duplicate(true)
			registration.assetId=part.id
			registration.id=str(group.id)+"_"+str(part.id)
			registration.nodeName=str(group.id)+"_"+str(part.nodeName)
			registration.groupId=group.id
			registration.centerX=group.centerX
			registration.baselineY=float(group.baselineY)+float(part.baselineOffsetY)
			result.append(registration)
	return result

func object_tint(registration:Dictionary)->Color:
	return desk_tints.get(registration.get("groupId",""),Color.WHITE) if registration.get("renderMode","")=="desk_part" else prop_tints.get(registration.id,Color.WHITE)

func draw_objects(canvas:CanvasItem,context:Dictionary,front:bool)->void:
	# Preserve main's combined-desk rendering outside the explicit preview.
	if not active or independent_preview:return
	var player:Vector2=context.player
	var foot_bottom:float=Metrics.foot_rect(player).end.y
	var tint:=Color.WHITE.lerp(Color(.03,.15,.26),float(context.get("mode_mix",0))*.3)
	for object:Dictionary in data.desks:
		if (foot_bottom<float(object.baselineY))!=front:continue
		canvas.draw_texture_rect_region(desk_texture,_project(desk_rect(object),context),rect(data.desk.visibleRect),tint*desk_tints.get(object.id,Color.WHITE))
	if front and wall_in_front(player):
		tint.a=.78;_wall(canvas,context,tint)

func draw_wall_reveal(canvas:CanvasItem,context:Dictionary)->void:
	# CanvasGroup composites the wall and independent wall-mounted appearances
	# together at 0.78, not twice (which would leave only 4.84% of the actor).
	if active and wall_in_front(context.player):
		_wall(canvas,context,Color.WHITE.lerp(Color(.03,.15,.26),float(context.get("mode_mix",0))*.3))

func snapshot()->Dictionary:
	return {"active":active,"independentPreview":independent_preview,"floor":"A1","generatedDesks":data.desks.size() if active else 0,"generatedWalls":1 if active else 0,"generatedIndependentProps":data.get("props",[]).size() if active else 0,"generatedStudentTables":data.desks.size() if active and independent_preview else 0,"generatedStudentChairs":data.desks.size() if active and independent_preview else 0,"generatedObjectNodes":object_registrations().size() if active else 0,"sourceSize":[1672,941],"issues":issues.duplicate()}
