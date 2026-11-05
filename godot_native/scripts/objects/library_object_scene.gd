extends RefCounted
## Independent transparent objects: one source-pixel geometry for paint, picking and feet.
const Rules=preload("res://scripts/space/spatial_rules.gd")
const Picker=preload("res://scripts/world_object_picker.gd")
const EntryPresentation=preload("res://scripts/presentation/library_object_motion.gd")
var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/library-objects-v2.json"))
var interaction_assets:RefCounted
var backpack_frame:=0
var ready:=false
var clean_plate:Texture2D
var textures:Dictionary={}
var rows:Dictionary={}
var areas:Dictionary={}
var solids:Array=[]
var ordered:Array=[]
var issues:Array[String]=[]
var font:Font=preload("res://scripts/ui/native_typography.gd").body_font()

func ensure_loaded()->bool:
	if ready:return true
	issues.clear();textures.clear();rows.clear();areas.clear();solids.clear();ordered.clear()
	if not ResourceLoader.exists(data.cleanPlate):return false
	clean_plate=load(data.cleanPlate)
	for id:String in data.families:
		if not ResourceLoader.exists(data.families[id]):issues.append("Missing "+id);continue
		var original:Texture2D=load(data.families[id])
		textures[id]=_minified_texture(original) if id in ["shelf_row","shelf_divider","low_bookcase"] else original
	if not issues.is_empty():return false
	for row:Dictionary in data.instances:
		rows[row.id]=row
		var box:=Rules.rect(row.bounds)
		var image_size:Vector2=textures[row.asset].get_size()
		var factor:=minf(box.size.x/image_size.x,box.size.y/image_size.y)
		var dimensions:=image_size*factor
		areas[row.id]=Rect2(Vector2(box.get_center().x-dimensions.x/2,box.end.y-dimensions.y),dimensions)
	for row:Dictionary in data.instances:
		var area:Rect2=areas[row.id]
		for f:Array in row.footprints:
			var footprint:=Rect2(area.position+area.size*Vector2(f[0],f[1]),area.size*Vector2(f[2],f[3]))
			var pieces:Array[Rect2]=[footprint]
			var corner:float=minf(float(row.get("chamfer",0)),minf(footprint.size.x,footprint.size.y)/4)
			if corner>0:
				# Bevel the real base corners; empty silhouette corners never become walls.
				pieces=[Rect2(footprint.position+Vector2(corner,0),footprint.size-Vector2(corner*2,0)),Rect2(footprint.position+Vector2(0,corner),Vector2(footprint.size.x,footprint.size.y-corner*2))]
			for piece:Rect2 in pieces:solids.append(_solid(row.id,piece))
		if row.get("diagonalSolid",false):
			for i:int in 8:
				var at:=area.position+area.size*Vector2(.08+float(i)*.10,.32+float(i)*.075)
				solids.append(_solid(row.id,Rect2(at,Vector2(area.size.x*.17,area.size.y*.10))))
		ordered.append(row)
	solids.append(_solid("entrance_record_post",EntryPresentation.ENTRY_FOOTPRINT))
	ordered.sort_custom(func(a:Dictionary,b:Dictionary):return baseline(a.id)<baseline(b.id))
	ready=clean_plate!=null and clean_plate.get_size()==Vector2(1500,900)
	return ready

func _minified_texture(original:Texture2D)->Texture2D:
	# Five-detail-pixel artwork is shown at about one fifth of its source size.
	# A single nearest sample changes book/wood patterns as the camera crosses
	# subpixels. Keep the full source and alpha, and filter only these shelves.
	var image:Image=original.get_image()
	if image==null or image.is_empty():return original
	if image.is_compressed() and image.decompress()!=OK:return original
	if not image.has_mipmaps() and image.generate_mipmaps()!=OK:return original
	var filtered:=CanvasTexture.new()
	filtered.diffuse_texture=ImageTexture.create_from_image(image)
	filtered.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return filtered

func _solid(id:String,rect:Rect2)->Dictionary:
	return {"id":id,"nativeLibraryObject":true,"left":rect.position.x,"top":rect.position.y,"right":rect.end.x,"bottom":rect.end.y}
func baseline(id:String)->float:
	var row:Dictionary=rows[id]
	return baseline(str(row.depthOwner))+.01 if row.has("depthOwner") else float(areas[id].end.y)
func geometry(id:String,offset:=Vector2.ZERO)->Dictionary:
	var row:Dictionary=rows[id]
	var area:Rect2=areas[id];area.position+=offset
	return {"rect":area,"texture":textures[row.asset],"source":Rect2(Vector2.ZERO,textures[row.asset].get_size())}
func collisions(source:Array)->Array:
	if not ready:return source.duplicate(true)
	# Exterior and closed architectural alcove retain their original source boundaries.
	var out:Array=[]
	for row:Dictionary in source:
		if "wall" in str(row.id) or row.id=="lost_found_room" or str(row.id) in ["entrance_west_glass","entrance_east_glass"]:out.append(row.duplicate(true))
	out.append_array(solids)
	return out
func shifted_collision(row:Dictionary,shelf_offset:float)->Dictionary:
	if row.get("nativeLibraryObject",false) and row.id=="north_display_shelf":
		var shifted:=row.duplicate(true);shifted.left+=mini(0,shelf_offset);shifted.right+=maxi(0,shelf_offset);return shifted
	return row

func draw_ground_shadows(canvas:CanvasItem,shelf_offset:float)->void:
	for row:Dictionary in ordered:
		if row.footprints.is_empty():continue
		var area:Rect2=areas[row.id]
		if row.get("movable",false):area.position.x+=shelf_offset
		for base:Array in row.footprints:
			var rect:=Rect2(area.position+area.size*Vector2(base[0],base[1]),area.size*Vector2(base[2],base[3]))
			var cast:=Vector2(3,3) if row.asset!="shelf_broad" else Vector2(6,5)
			canvas.draw_colored_polygon(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),Vector2(rect.end.x,rect.position.y)+cast,rect.end+cast,Vector2(rect.position.x,rect.end.y)+cast,Vector2(rect.position.x,rect.end.y)]),Color(.17,.14,.12,.18))

func draw(canvas:CanvasItem,context:Dictionary,front:bool,shelf_offset:float,bag_pose:Dictionary)->void:
	var ground:float=context.get("player_ground_y",Rules.foot_y(context.player))
	for row:Dictionary in ordered:
		if row.id in ["front_desk_counter","desk_terminal","printer"]:continue # Existing motion owners paint these.
		var seated_chair: bool = row.id == context.get("seated_chair","")
		if not seated_chair and Rules.depth_in_front(baseline(row.id),ground)!=front:continue
		if row.get("dynamic","")=="backpack":
			if not bag_pose.visible:continue
			var g:=geometry(row.id)
			if interaction_assets!=null and interaction_assets.ready:g=interaction_assets.backpack_geometry(g,backpack_frame)
			var area:Rect2=g.rect
			area.position-=Vector2(1255,407)
			var transform:=Transform2D(deg_to_rad(float(bag_pose.angle)),Vector2(bag_pose.position))
			g.rect=area;g.transform=transform
			Picker.record(canvas,row.targets,g)
			canvas.draw_set_transform(context.origin+Vector2(bag_pose.position)*context.zoom,transform.get_rotation(),Vector2.ONE*context.zoom)
			canvas.draw_texture_rect_region(g.texture,area,g.source,Color(1,1,1,float(bag_pose.alpha)))
			canvas.draw_set_transform(context.origin,0,Vector2.ONE*context.zoom)
			continue
		var offset:=Vector2(shelf_offset,0) if row.get("movable",false) else Vector2.ZERO
		var g:=geometry(row.id,offset)
		if seated_chair and front:
			# The lower chair back covers the hips. Its top rail stays behind
			# the upper body so the seated pose reads at the actual game scale.
			var area: Rect2 = g.rect
			var region: Rect2 = g.source
			const BACK_CUT := 0.32
			area.position.y += area.size.y * BACK_CUT
			area.size.y *= 1.0 - BACK_CUT
			region.position.y += region.size.y * BACK_CUT
			region.size.y *= 1.0 - BACK_CUT
			g.rect = area
			g.source = region
		if row.id!="north_display_shelf":Picker.record(canvas,row.targets,g)
		canvas.draw_texture_rect_region(g.texture,g.rect,g.source)
		if row.has("shelfNumber"):
			var sign_rect:=Rect2(Vector2(g.rect.get_center().x-18,g.rect.position.y-19),Vector2(36,17))
			canvas.draw_rect(sign_rect,Color("e8d9b8"))
			canvas.draw_rect(sign_rect,Color("654b35"),false,1)
			canvas.draw_string(font,sign_rect.position+Vector2(0,13),"%02d"%int(row.shelfNumber),HORIZONTAL_ALIGNMENT_CENTER,36,14,Color("263c43"))

func snapshot()->Dictionary:
	return {"ready":ready,"families":textures.size(),"instances":rows.size(),"solids":solids.size(),"issues":issues.duplicate(),"shelfSharesTexture":ready and rows.north_display_shelf.asset==rows.row_shelf_0.asset}
