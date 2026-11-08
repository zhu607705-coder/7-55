extends RefCounted
## Independent transparent objects: one source-pixel geometry for paint, picking and feet.
const Rules=preload("res://scripts/space/spatial_rules.gd")
const Picker=preload("res://scripts/world_object_picker.gd")
const GRID_DATA := "res://data/native/library-object-pixel-grid.json"
const GRID_ATLAS := "res://assets/native/library_object_depth_20261104/pixel_grid.png"
var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/library-objects-v2.json"))
var interaction_assets:RefCounted
var backpack_frame:=0
var ready:=false
var clean_plate:Texture2D
var textures:Dictionary={}
var draw_tiles: Dictionary[String, AtlasTexture] = {}
var rows:Dictionary={}
var areas:Dictionary={}
var solids:Array=[]
var ordered:Array=[]
var issues:Array[String]=[]
var font:Font=preload("res://scripts/ui/native_typography.gd").body_font()

func ensure_loaded()->bool:
	if ready:return true
	issues.clear();textures.clear();draw_tiles.clear();rows.clear();areas.clear();solids.clear();ordered.clear()
	if not ResourceLoader.exists(data.cleanPlate) or not ResourceLoader.exists(GRID_ATLAS) or not FileAccess.file_exists(GRID_DATA):return false
	var grid: Variant = JSON.parse_string(FileAccess.get_file_as_string(GRID_DATA))
	if not grid is Dictionary:return false
	var atlas: Texture2D = load(GRID_ATLAS)
	if atlas == null:return false
	var atlas_bounds := Rect2i(Vector2i.ZERO, Vector2i(atlas.get_size()))
	var cached_tiles: Dictionary[Rect2i, AtlasTexture] = {}
	clean_plate=load(data.cleanPlate)
	for id:String in data.families:
		if not ResourceLoader.exists(data.families[id]):issues.append("Missing "+id);continue
		textures[id]=load(data.families[id])
	if not issues.is_empty():return false
	for row:Dictionary in data.instances:
		rows[row.id]=row
		var image_size:Vector2=textures[row.asset].get_size()
		var area := fit_art(Rules.rect(row.bounds), image_size)
		areas[row.id]=Rect2(area.position.round(),area.size.round())
		var paint_ids: Array[String] = [row.id]
		if row.has("seatPoint"): paint_ids.append_array([row.id + "@seat", row.id + "@back"])
		for paint_id: String in paint_ids:
			var region := Rect2i(Rules.rect(grid.get(paint_id, {})))
			if region.size != Vector2i(area.size.round()) or not atlas_bounds.encloses(region):
				issues.append("Invalid pixel grid region for " + paint_id)
				continue
			if not cached_tiles.has(region):
				var tile := AtlasTexture.new()
				tile.atlas = atlas
				tile.region = Rect2(region)
				tile.filter_clip = true
				cached_tiles[region] = tile
			draw_tiles[paint_id] = cached_tiles[region]
	if not issues.is_empty():return false
	for row:Dictionary in data.instances:
		var area:Rect2=areas[row.id]
		for f:Array in row.footprints:
			if row.has("chamfer"):
				# The printer's original back contact used its fitted source rectangle.
				var fitted:=fit_art(Rules.rect(row.bounds),textures[row.asset].get_size())
				var base:=Rect2(fitted.position+fitted.size*Vector2(f[0],f[1]),fitted.size*Vector2(f[2],f[3]))
				var bevel:=float(row.chamfer)
				solids.append(_solid(row.id,base.grow_individual(-bevel,0,-bevel,0)))
				# The solid side extends to the tray. Keep the original back edge.
				solids.append(_solid(row.id,Rect2(area.position.x,base.position.y+bevel,area.size.x,base.size.y-bevel)))
				continue
			var base:=_footprint(area,f)
			# Table and cabinet tops can extend sideways beyond the supporting legs.
			# Clear the solid side across its ground depth, including the counter's
			# front corners where the upper cabinet overhangs the angled toe-kick.
			if row.get("artSides",false) or base.position.y>=area.position.y+float(row.get("frontSideRow",INF)):
				base=Rect2(area.position.x,base.position.y,area.size.x,base.size.y)
			solids.append(_solid(row.id,base))
		if row.get("diagonalSolid",false):
			# Follow the measured post contacts all the way to each end.
			var line: Array = row.depthLine
			for i:int in 8:
				var fraction := float(i)/7
				var x := lerpf(line[0][0],line[1][0],fraction)
				var y := lerpf(line[0][1],line[1][1],fraction)
				var at := area.position+area.size*Vector2(x-.09,y-.10)
				solids.append(_solid(row.id,Rect2(at,area.size*Vector2(.18,.10))))
		ordered.append(row)
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_depth := baseline(a.id)
		var b_depth := baseline(b.id)
		if a_depth != b_depth: return a_depth < b_depth
		if a.has("depthOwner") != b.has("depthOwner"): return not a.has("depthOwner")
		return str(a.id) < str(b.id)
	)
	ready=clean_plate!=null and clean_plate.get_size()==Vector2(1500,900)
	return ready

static func fit_art(box: Rect2, image_size: Vector2) -> Rect2:
	var factor := minf(box.size.x / image_size.x, box.size.y / image_size.y)
	var dimensions := image_size * factor
	return Rect2(Vector2(box.get_center().x - dimensions.x / 2, box.end.y - dimensions.y), dimensions)
func _minified_texture(original:Texture2D)->Texture2D:
	# Preserve the source grid. Filter architectural trim and book patterns
	# when the viewport samples below their original resolution.
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
func _footprint(area:Rect2,contact:Array)->Rect2:
	var start:Vector2=(area.size*Vector2(contact[0],contact[1])).round()
	var end:Vector2=(area.size*Vector2(contact[0]+contact[2],contact[1]+contact[3])).round()
	return Rect2(area.position+start,end-start)
func baseline(id:String)->float:
	var row:Dictionary=rows[id]
	return baseline(str(row.depthOwner)) if row.has("depthOwner") else float(areas[id].end.y)

func baseline_at(id: String, foot_x: float) -> float:
	var row: Dictionary = rows[id]
	if not row.has("depthLine"): return baseline(id)
	var area: Rect2 = areas[id]
	var line: Array = row.depthLine
	var from := area.position + area.size * Vector2(float(line[0][0]), float(line[0][1]))
	var to := area.position + area.size * Vector2(float(line[1][0]), float(line[1][1]))
	return lerpf(from.y, to.y, clampf(inverse_lerp(from.x, to.x, foot_x), 0, 1))
func geometry(id:String,offset:=Vector2.ZERO,part: String="")->Dictionary:
	# Paint and the physical footprint start on the same plate pixel.
	var area: Rect2 = areas[id]
	var tile: AtlasTexture = draw_tiles[id if part.is_empty() else id + "@" + part]
	return {"rect": Rect2((area.position + offset).round(), tile.get_size()), "texture": tile, "source": Rect2(Vector2.ZERO, tile.get_size())}

func table_surface(id: String) -> Rect2:
	var area: Rect2 = geometry(id).rect
	if rows[id].has("surfaceRect"):
		var surface:=Rules.rect(rows[id].surfaceRect)
		return Rect2(area.position+area.size*surface.position,area.size*surface.size)
	area.size.y = roundf(area.size.y * float(rows[id].tableSurface))
	return area

func seat_point(id: String) -> Vector2:
	var area: Rect2 = geometry(id).rect
	var point: Array = rows[id].seatPoint
	return area.position + area.size * Vector2(float(point[0]), float(point[1]))
func collisions(source:Array)->Array:
	# Exterior and closed architectural alcove retain their original source boundaries.
	var out:Array=[]
	for row:Dictionary in source:
		var id := str(row.id)
		if id in ["entrance_west_glass", "entrance_east_glass"]: continue
		if not ready or "wall" in id or id=="lost_found_room": out.append(row.duplicate(true))
	if ready: out.append_array(solids)
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
			var rect:=_footprint(area,base)
			var cast:=Vector2(3,3) if row.asset!="shelf_broad" else Vector2(6,5)
			canvas.draw_colored_polygon(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),Vector2(rect.end.x,rect.position.y)+cast,rect.end+cast,Vector2(rect.position.x,rect.end.y)+cast,Vector2(rect.position.x,rect.end.y)]),Color(.17,.14,.12,.18))

func draw(canvas:CanvasItem,context:Dictionary,front:bool,shelf_offset:float,bag_pose:Dictionary)->void:
	var ground:float=context.get("player_ground_y",Rules.foot_y(context.player))
	var foot_x: float = Vector2(context.player).x
	for row:Dictionary in ordered:
		if row.id in ["front_desk_counter","desk_terminal","printer"]:continue # Existing motion owners paint these.
		var seated_chair: bool = row.id == context.get("seated_chair","")
		if not seated_chair and Rules.depth_in_front(baseline_at(row.id,foot_x),ground)!=front:continue
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
		# A seated actor is drawn between the seat and its independently painted rail.
		var part := ("back" if front else "seat") if seated_chair else ""
		var g:=geometry(row.id,offset,part)
		if row.id!="north_display_shelf":Picker.record(canvas,row.targets,g)
		canvas.draw_texture_rect_region(g.texture,g.rect,g.source)
		if row.has("shelfNumber"):
			var sign_rect:=Rect2(Vector2(g.rect.get_center().x-18,g.rect.position.y-19),Vector2(36,17))
			canvas.draw_rect(sign_rect,Color("e8d9b8"))
			canvas.draw_rect(sign_rect,Color("654b35"),false,1)
			canvas.draw_string(font,sign_rect.position+Vector2(0,13),"%02d"%int(row.shelfNumber),HORIZONTAL_ALIGNMENT_CENTER,36,14,Color("263c43"))

func snapshot()->Dictionary:
	return {"ready":ready,"families":textures.size(),"instances":rows.size(),"solids":solids.size(),"issues":issues.duplicate(),"shelfSharesTexture":ready and rows.north_display_shelf.asset==rows.row_shelf_0.asset}
