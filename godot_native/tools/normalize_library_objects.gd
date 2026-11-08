extends SceneTree
## Deterministic import only: preserve generated originals; binary alpha and uniform scale.

const ObjectScene = preload("res://scripts/objects/library_object_scene.gd")
const SpatialRules = preload("res://scripts/space/spatial_rules.gd")
const FURNITURE_SIZES := {"table": Vector2i(700, 537), "table_oblique": Vector2i(700, 391), "chair_north": Vector2i(466, 700)}
const WOOD_EDGE := Color("202b35")
const TABLE_SUPPORTS := {
	"table": {"apron": 381, "inset": 45, "width": 51},
	"table_oblique": {"apron": 282, "inset": 46, "width": 45},
}
# The dimensions below describe the painted wood. Ink sits outside each face.
# Preserve the approved rear view and the south-facing chair's lighting.
const NORTH_CHAIR_SIZE := Vector2i(384, 566)
const CHAIR_EDGE := 10
const POST_FACE_WIDTH := 46
const POST_WIDTH := POST_FACE_WIDTH + 2 * CHAIR_EDGE
const NORTH_CHAIR_POSTS := [
	Rect2i(0, 0, POST_WIDTH, NORTH_CHAIR_SIZE.y),
	Rect2i(NORTH_CHAIR_SIZE.x - POST_WIDTH, 0, POST_WIDTH, NORTH_CHAIR_SIZE.y),
]
const SLAT_LEFT := POST_WIDTH - CHAIR_EDGE
const SLAT_WIDTH := NORTH_CHAIR_SIZE.x - 2 * SLAT_LEFT
const NORTH_CHAIR_CROWN := Rect2i(79, 42, 226, 24)
const NORTH_CHAIR_UPPER_SLAT := Rect2i(SLAT_LEFT, 49, SLAT_WIDTH, 73)
const NORTH_CHAIR_LOWER_SLAT := Rect2i(SLAT_LEFT, 171, SLAT_WIDTH, 57)
# The full-width seat sits behind the backrest, including where its top plane
# shows through the slat gap. The near posts hide its side joints.
const NORTH_CHAIR_SEAT_BOARD := Rect2i(0, 132, 384, 268)
const NORTH_CHAIR_SEAT_PLANE := Rect2i(10, 132, 364, 234)
const NORTH_CHAIR_SEAT_APRON := Rect2i(10, 366, 364, 24)
const NORTH_CHAIR_SEAT := Vector2(192, 262)

# On the stack master these four cuts pass through uninterrupted book blocks.
# Remove equal lengths of shelving stock, preserving the posts, rails and foot cap.
func fit_stack_bays(master:Image, size:Vector2i)->Image:
	var scaled_height:=roundi(float(master.get_height())*size.x/master.get_width())
	master.resize(size.x,scaled_height,Image.INTERPOLATE_NEAREST)
	var trim:=scaled_height-size.y
	var stack:=Image.create_empty(size.x,size.y,false,Image.FORMAT_RGBA8)
	var source_y:=0
	var dest_y:=0
	for bay:int in 4:
		var cut:=roundi(trim*(bay+1)/4.0)-roundi(trim*bay/4.0)
		var center:=roundi(scaled_height*[.12,.30,.48,.665][bay])
		var length:=center-floori(cut/2.0)-source_y
		stack.blit_rect(master,Rect2i(0,source_y,size.x,length),Vector2i(0,dest_y))
		source_y+=length+cut
		dest_y+=length
	stack.blit_rect(master,Rect2i(0,source_y,size.x,scaled_height-source_y),Vector2i(0,dest_y))
	return stack

func fit_furniture(master: Image, size: Vector2i) -> Image:
	# Trim the middle of a wide tabletop without reshaping its outer supports.
	# A slightly narrower chair keeps transparent margins on both sides.
	var width := roundi(float(master.get_width()) * size.y / master.get_height())
	master.resize(width, size.y, Image.INTERPOLATE_NEAREST)
	var fitted := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	if width <= size.x:
		fitted.blit_rect(master, Rect2i(0, 0, width, size.y), Vector2i((size.x - width) / 2, 0))
		return fitted
	var left := size.x / 2
	fitted.blit_rect(master, Rect2i(0, 0, left, size.y), Vector2i.ZERO)
	fitted.blit_rect(master, Rect2i(width - (size.x - left), 0, size.x - left, size.y), Vector2i(left, 0))
	return fitted

func project_table(sprite: Image, apron_ratio: float) -> Image:
	# Extend the horizontal wood plane and shorten a straight section of each
	# support. The tabletop edges and all four painted feet stay at their scale.
	var extent := sprite.get_size()
	var rise := roundi(extent.y * .10)
	var join := roundi(extent.y * .32)
	var leg_cut := roundi(extent.y * apron_ratio + extent.y * .07)
	var projected := Image.create_empty(extent.x, extent.y, false, Image.FORMAT_RGBA8)
	projected.blit_rect(sprite, Rect2i(0, 0, extent.x, join), Vector2i.ZERO)
	projected.blit_rect(sprite, Rect2i(0, join - rise, extent.x, rise), Vector2i(0, join))
	projected.blit_rect(sprite, Rect2i(0, join, extent.x, leg_cut - join), Vector2i(0, join + rise))
	projected.blit_rect(sprite, Rect2i(0, leg_cut + rise, extent.x, extent.y - leg_cut - rise), Vector2i(0, leg_cut + rise))
	return projected

func square_table_legs(sprite: Image, apron: int, inset: int, width: int) -> void:
	var height := sprite.get_height() - apron
	const EDGE := 5
	var positions := [inset, sprite.get_width() - inset - width]
	var grain: Array[Image] = []
	for x: int in positions:
		grain.append(sprite.get_region(Rect2i(x + EDGE, apron, width - EDGE * 2, height - EDGE)))
	sprite.fill_rect(Rect2i(0, apron, sprite.get_width(), height), Color.TRANSPARENT)
	# Far supports project directly behind these front supports.
	for side: int in positions.size():
		var x: int = positions[side]
		sprite.fill_rect(Rect2i(x, apron, width, height), WOOD_EDGE)
		sprite.blend_rect(grain[side], Rect2i(Vector2i.ZERO, grain[side].get_size()), Vector2i(x + EDGE, apron))

func paint_chair_piece(target: Image, family: Image, source: Rect2i, part: Rect2i) -> void:
	var piece := family.get_region(source)
	piece.resize(part.size.x, part.size.y, Image.INTERPOLATE_NEAREST)
	target.blend_rect(piece, Rect2i(Vector2i.ZERO, part.size), part.position)

func chair_slat_outlines() -> Array[Rect2i]:
	# Keep the horizontal ink on the nearest-sampled grid without cutting the wood.
	return [
		NORTH_CHAIR_CROWN.grow_individual(CHAIR_EDGE, 15, CHAIR_EDGE, CHAIR_EDGE),
		NORTH_CHAIR_UPPER_SLAT.grow(CHAIR_EDGE),
		NORTH_CHAIR_LOWER_SLAT.grow_individual(CHAIR_EDGE, 16, CHAIR_EDGE, 16),
	]

func fit_chair(family: Image, size: Vector2i) -> Image:
	var registered := Image.create_empty(NORTH_CHAIR_SIZE.x, NORTH_CHAIR_SIZE.y, false, Image.FORMAT_RGBA8)
	registered.fill_rect(NORTH_CHAIR_SEAT_BOARD, WOOD_EDGE)
	paint_chair_piece(registered, family, Rect2i(21, 270, 345, 204), NORTH_CHAIR_SEAT_PLANE)
	paint_chair_piece(registered, family, Rect2i(21, 474, 345, 29), NORTH_CHAIR_SEAT_APRON)
	for outline: Rect2i in chair_slat_outlines():
		registered.fill_rect(outline, WOOD_EDGE)
	paint_chair_piece(registered, family, Rect2i(76, 51, 235, 66), NORTH_CHAIR_UPPER_SLAT)
	paint_chair_piece(registered, family, Rect2i(113, 39, 161, 18), NORTH_CHAIR_CROWN)
	paint_chair_piece(registered, family, Rect2i(76, 164, 235, 42), NORTH_CHAIR_LOWER_SLAT)
	for side: int in NORTH_CHAIR_POSTS.size():
		var post: Rect2i = NORTH_CHAIR_POSTS[side]
		var face_x := post.position.x + CHAIR_EDGE
		var cap_x := 20 if side == 0 else 322
		var leg_x := 25 if side == 0 else 322
		registered.fill_rect(post, WOOD_EDGE)
		paint_chair_piece(registered, family, Rect2i(cap_x, 12, 45, 52), Rect2i(face_x, CHAIR_EDGE, POST_FACE_WIDTH, 44))
		paint_chair_piece(registered, family, Rect2i(leg_x, 526, 41, 133), Rect2i(face_x, 54, POST_FACE_WIDTH, 470))
		paint_chair_piece(registered, family, Rect2i(leg_x, 659, 41, 31), Rect2i(face_x, 524, POST_FACE_WIDTH, 32))
	var factor := minf(float(size.x) / NORTH_CHAIR_SIZE.x, float(size.y) / NORTH_CHAIR_SIZE.y)
	var extent := Vector2i((Vector2(NORTH_CHAIR_SIZE) * factor).round())
	registered.resize(extent.x, extent.y, Image.INTERPOLATE_NEAREST)
	var fitted := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var origin := Vector2i((size.x - extent.x) / 2, size.y - extent.y)
	fitted.blit_rect(registered, Rect2i(Vector2i.ZERO, extent), origin)
	return fitted

func chair_parts(sprite: Image) -> Dictionary:
	var size := sprite.get_size()
	var ink := Rect2(sprite.get_used_rect())
	var ratio := ink.size / Vector2(NORTH_CHAIR_SIZE)
	var seat: Image = sprite.duplicate()
	var back := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var near_parts := NORTH_CHAIR_POSTS.duplicate()
	near_parts.append_array(chair_slat_outlines())
	for part: Rect2i in near_parts:
		var start := Vector2i((ink.position + Vector2(part.position) * ratio).round())
		var finish := Vector2i((ink.position + Vector2(part.end) * ratio).round())
		var region := Rect2i(start, finish - start)
		back.blit_rect(sprite, region, region.position)
		seat.fill_rect(region, Color.TRANSPARENT)
	return {"seat": seat, "back": back}

func clip_at_table(tile: Image, origin: Vector2i, table: Dictionary, cap: Image) -> Image:
	var cover := Rect2i(table.origin, Vector2i(cap.get_width(), table.cap))
	var overlap := Rect2i(origin, tile.get_size()).intersection(cover)
	if not overlap.has_area(): return tile
	var clipped: Image = tile.duplicate()
	for y: int in range(overlap.position.y, overlap.end.y):
		for x: int in range(overlap.position.x, overlap.end.x):
			var point := Vector2i(x, y)
			if cap.get_pixelv(point - Vector2i(table.origin)).a > .5:
				clipped.set_pixelv(point - origin, Color.TRANSPARENT)
	return clipped

func build_pixel_grid(base: String) -> int:
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base.path_join("data/native/library-objects-v2.json")))
	var source_images: Dictionary[String, Image] = {}
	var chair_sources: Dictionary = {}
	var placed: Dictionary = {}
	var render_keys: Dictionary[String, String] = {}
	var tiles: Dictionary[String, Rect2i] = {}
	var pixels: Dictionary[String, Image] = {}
	var regions: Dictionary = {}
	const ATLAS_WIDTH := 1024
	var cursor := Vector2i.ZERO
	var row_height := 0
	for instance: Dictionary in plan.instances:
		var family: String = instance.asset
		if not source_images.has(family):
			var source := Image.load_from_file(base.path_join(str(plan.families[family]).trim_prefix("res://")))
			if source == null or source.is_empty(): return 1
			source.convert(Image.FORMAT_RGBA8)
			source_images[family] = source
		var original := source_images[family]
		var area := ObjectScene.fit_art(SpatialRules.rect(instance.bounds), Vector2(original.get_size()))
		var dimensions := Vector2i(area.size.round())
		var key := "%s:%dx%d" % [family, dimensions.x, dimensions.y]
		if not pixels.has(key):
			var tile: Image = original.duplicate()
			tile.resize(dimensions.x, dimensions.y, Image.INTERPOLATE_NEAREST)
			pixels[key] = tile
		placed[instance.id] = {"key": key, "origin": Vector2i(area.position.round()), "cap": roundi(float(instance.get("tableCap", 0.0)) * dimensions.y)}
	for instance: Dictionary in plan.instances:
		var placement: Dictionary = placed[instance.id]
		var key: String = placement.key
		var tile := pixels[key]
		var table: Dictionary = placed.get(instance.get("underTable", ""), {})
		if instance.has("seatPoint"):
			var family: String = instance.asset
			if not chair_sources.has(family):
				chair_sources[family] = chair_parts(source_images[family])
			var layers: Dictionary = chair_sources[family]
			var seat: Image = layers.seat.duplicate()
			var back: Image = layers.back.duplicate()
			seat.resize(tile.get_width(), tile.get_height(), Image.INTERPOLATE_NEAREST)
			back.resize(tile.get_width(), tile.get_height(), Image.INTERPOLATE_NEAREST)
			seat = clip_at_table(seat, placement.origin, table, pixels[table.key])
			var assembled: Image = seat.duplicate()
			assembled.blend_rect(back, Rect2i(Vector2i.ZERO, back.get_size()), Vector2i.ZERO)
			key = str(instance.id)
			pixels[key] = assembled
			pixels[key + "@seat"] = seat
			pixels[key + "@back"] = back
			render_keys[key + "@seat"] = key + "@seat"
			render_keys[key + "@back"] = key + "@back"
		elif instance.has("underTable"):
			var clipped := clip_at_table(tile, placement.origin, table, pixels[table.key])
			if clipped != tile:
				key = str(instance.id)
				pixels[key] = clipped
		render_keys[instance.id] = key
	for id: String in render_keys:
		var key := render_keys[id]
		var dimensions := pixels[key].get_size()
		if not tiles.has(key):
			if dimensions.x <= 0 or dimensions.y <= 0 or dimensions.x >= ATLAS_WIDTH: return 1
			if cursor.x + dimensions.x > ATLAS_WIDTH:
				cursor = Vector2i(0, cursor.y + row_height + 1)
				row_height = 0
			tiles[key] = Rect2i(cursor, dimensions)
			cursor.x += dimensions.x + 1
			row_height = maxi(row_height, dimensions.y)
		var region := tiles[key]
		regions[id] = [region.position.x, region.position.y, region.size.x, region.size.y]
	var atlas := Image.create_empty(ATLAS_WIDTH, cursor.y + row_height, false, Image.FORMAT_RGBA8)
	for key: String in tiles:
		var tile := pixels[key]
		atlas.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), tiles[key].position)
	if atlas.save_png(base.path_join(ObjectScene.GRID_ATLAS.trim_prefix("res://"))) != OK: return 1
	var metadata := FileAccess.open(base.path_join(ObjectScene.GRID_DATA.trim_prefix("res://")), FileAccess.WRITE)
	if metadata == null: return 1
	metadata.store_string(JSON.stringify(regions, "\t") + "\n")
	metadata.close()
	print("LIBRARY_PIXEL_GRID ", tiles.size(), " tiles for ", regions.size(), " paint regions at ", atlas.get_size())
	return 0

func _initialize()->void:
	var args:=OS.get_cmdline_user_args()
	if args.is_empty():quit(2);return
	var base:String=args[0]
	if "--grid" in args:quit(build_pixel_grid(base));return
	var source_dir:=base.path_join("art_source/library_object_depth_20261104")
	var output:=base.path_join("assets/native/library_object_depth_20261104")
	DirAccess.make_dir_recursive_absolute(output)
	var sources:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source_dir.path_join("sources.json")))
	var report:Dictionary={"engine":Engine.get_version_info().string,"assets":{}}
	var furniture_only := "--furniture" in args
	var turnstile_only := "--turnstile" in args
	if furniture_only or turnstile_only:
		report = JSON.parse_string(FileAccess.get_file_as_string(source_dir.path_join("normalization.json")))
		for record: Dictionary in report.assets.values():
			for field: String in ["masterSize", "size"]:
				record[field] = record[field].map(func(value: Variant) -> int: return int(value))
			if record.has("southFacePixels"): record.southFacePixels = int(record.southFacePixels)
	var direction:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("docs/art/art_direction_v1.json")))
	var palette:Array=[]
	for hex:String in direction.palette.colors:palette.append(Color(hex))
	var color_cache:Dictionary={}
	var ordered_sources := sources.keys()
	if ordered_sources.has("chair_north"):
		ordered_sources.erase("chair_north")
		ordered_sources.append("chair_north")
	for id:String in ordered_sources:
		if furniture_only and not FURNITURE_SIZES.has(id): continue
		if turnstile_only and id != "turnstile": continue
		var source_path:String=sources[id]
		var path:String=source_path if source_path.is_absolute_path() else source_dir.path_join(source_path)
		var image := Image.load_from_file(path)
		if image==null or image.is_empty():push_error("Missing generated source "+id);quit(1);return
		image.convert(Image.FORMAT_RGBA8)
		var original_size:=image.get_size()
		var is_base:=id.begins_with("clean_plate")
		var face_pixels:=0
		if is_base:
			# Crop to the source aspect, then scale uniformly. Never stretch the map.
			var ratio:=minf(float(image.get_width())/1500,float(image.get_height())/900)
			var extent:=Vector2i(roundi(1500*ratio),roundi(900*ratio))
			image=image.get_region(Rect2i((image.get_size()-extent)/2,extent))
			image.resize(1500,900,Image.INTERPOLATE_NEAREST)
		else:
			# Remove semitransparent generated halos; do not key out a background color.
			var bytes:=image.get_data()
			for index:int in range(3,bytes.size(),4):bytes[index]=255 if bytes[index]>=128 else 0
			image=Image.create_from_data(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8,bytes)
			var ink:=image.get_used_rect()
			image=image.get_region(ink)
			# Keep five native pixels per original-world pixel; every resize is uniform.
			if id in ["shelf_divider","shelf_row"]:
				var size:=Vector2i(200,1370) if id=="shelf_divider" else Vector2i(225,1155)
				# In the master the vertical south elevation starts below the rail at y=1429.
				face_pixels=roundi((ink.end.y-1429)*float(size.x)/ink.size.x)
				image=fit_stack_bays(image,size)
			elif id == "chair_north":
				var family := Image.load_from_file(output.path_join("chair_south.png"))
				if family == null or family.get_size() != Vector2i(387, 700):
					push_error("Missing the matching south-facing chair materials")
					quit(1)
					return
				family.convert(Image.FORMAT_RGBA8)
				image = fit_chair(family, FURNITURE_SIZES[id])
			elif FURNITURE_SIZES.has(id):
				image = project_table(fit_furniture(image, FURNITURE_SIZES[id]), .622 if id == "table_oblique" else .608)
				var support: Dictionary = TABLE_SUPPORTS[id]
				square_table_legs(image, support.apron, support.inset, support.width)
			else:
				if id=="water_dispenser":
					# A short lower service panel and bottle suit a chest-high floor model.
					var compact:=Image.create_empty(ink.size.x,ink.size.y-350,false,Image.FORMAT_RGBA8)
					var first:=310-ink.position.y
					var second:=1250-ink.position.y
					compact.blit_rect(image,Rect2i(0,0,ink.size.x,first),Vector2i.ZERO)
					compact.blit_rect(image,Rect2i(0,first+110,ink.size.x,second-first-110),Vector2i(0,first))
					compact.blit_rect(image,Rect2i(0,second+240,ink.size.x,ink.size.y-second-240),Vector2i(0,second-110))
					image=compact
				var scale_value:=minf(1.0,700.0/maxi(image.get_width(),image.get_height()))
				image.resize(maxi(1,roundi(image.get_width()*scale_value)),maxi(1,roundi(image.get_height()*scale_value)),Image.INTERPOLATE_NEAREST)
				if id == "turnstile":
					# Cut a strip of unmarked housing below the reader. The cap,
					# card slot and foot retain their source scale.
					var size := image.get_size()
					var start := roundi(size.y * .65)
					var end := start + roundi(size.y * .20)
					var shorter := Image.create_empty(size.x, size.y - (end - start), false, Image.FORMAT_RGBA8)
					shorter.blit_rect(image, Rect2i(0, 0, size.x, start), Vector2i.ZERO)
					shorter.blit_rect(image, Rect2i(0, end, size.x, size.y - end), Vector2i(0, start))
					image = shorter
			if id=="glass_panel":
				for y:int in image.get_height():
					for x:int in image.get_width():
						var color:=image.get_pixel(x,y)
						if color.a>0 and color.b>color.r*1.1 and color.g>color.r*1.1 and color.v>.4:
							color.a=170.0/255;image.set_pixel(x,y,color)
		# One shared project palette; cached color buckets keep the transform reproducible.
		var pixels:=image.get_data()
		for index:int in range(0,pixels.size(),4):
			if pixels[index+3]==0:continue
			if is_base:
				# Nearby generated fabric values straddle palette ramps. Keep quiet carpet
				# clusters instead of turning that subpixel variation into scattered dots.
				var at:=Vector2((index/4)%image.get_width(),(index/4)/image.get_width())
				var carpet:bool=Rect2(944,87,510,475).has_point(at) or Rect2(156,435,333,222).has_point(at) or Rect2(590,435,340,222).has_point(at)
				if carpet and pixels[index+2]>pixels[index]*1.2 and pixels[index+1]>pixels[index]*1.2 and pixels[index+1]<105:
					var fabric:=Color("243F5A")
					pixels[index]=fabric.r8;pixels[index+1]=fabric.g8;pixels[index+2]=fabric.b8
					continue
			var key:int=(int(pixels[index])>>3)*1024+(int(pixels[index+1])>>3)*32+(int(pixels[index+2])>>3)
			if not color_cache.has(key):
				var sample:=Vector3((key/1024)*8+4,((key/32)%32)*8+4,(key%32)*8+4)/255.0
				var best:=0;var distance:=INF
				for p:int in palette.size():
					var color:Color=palette[p];var delta:=sample-Vector3(color.r,color.g,color.b)
					var cost:float=delta.x*delta.x*.30+delta.y*delta.y*.59+delta.z*delta.z*.11
					if cost<distance:distance=cost;best=p
				color_cache[key]=best
			var chosen:Color=palette[color_cache[key]]
			pixels[index]=chosen.r8;pixels[index+1]=chosen.g8;pixels[index+2]=chosen.b8
		image=Image.create_from_data(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8,pixels)
		if is_base:
			image=quiet_plate(image)
			apply_floor_joints(image)
		var destination:=output.path_join(id+".png")
		if image.save_png(destination)!=OK:quit(1);return
		var source_label := source_path if source_path.is_absolute_path() else "godot_native/art_source/library_object_depth_20261104/" + source_path
		report.assets[id]={"source":source_label,"sourceSha256":FileAccess.get_sha256(path),"outputSha256":FileAccess.get_sha256(destination),"masterSize":[original_size.x,original_size.y],"size":[image.get_width(),image.get_height()],"binaryAlpha":not is_base and id!="glass_panel","uniformScale":true,"palette":direction.palette.name}
		if id == "chair_north":
			var chair := Rect2(image.get_used_rect())
			var seat_point := (chair.position + chair.size * (NORTH_CHAIR_SEAT / Vector2(NORTH_CHAIR_SIZE))) / Vector2(image.get_size())
			report.assets[id].seatPoint = [seat_point.x, seat_point.y]
		if face_pixels>0:report.assets[id].southFacePixels=face_pixels
	var file:=FileAccess.open(source_dir.path_join("normalization.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close()
	print("LIBRARY_NORMALIZE ",1 if turnstile_only else FURNITURE_SIZES.size() if furniture_only else report.assets.size()," assets")
	quit()

func quiet_plate(plate:Image)->Image:
	# Work from the same source for every sample. Opposite matching neighbours
	# on both axes identify specks without breaking one-pixel grout or trim.
	var width:=plate.get_width()
	var height:=plate.get_height()
	var source:=plate.get_data()
	var pixels:=source.duplicate()
	for y:int in range(1,height-1):
		for x:int in range(1,width-1):
			var at:=(y*width+x)*4
			var color:=source.decode_u32(at)
			var surround:=source.decode_u32(at-4)
			if surround!=color and surround==source.decode_u32(at+4) and surround==source.decode_u32(at-4*width) and surround==source.decode_u32(at+4*width):
				pixels.encode_u32(at,surround)
	# Lower the contrast of the brush texture beside the stone apron.
	# Leave the blue vestibule and its tile seams between these x limits.
	var blue_fleck:=Color("243f5a").to_abgr32()
	var quiet_blue:=Color("202b35").to_abgr32()
	for y:int in range(847,height):
		for x:int in width:
			if x>=532 and x<967:continue
			var at:=(y*width+x)*4
			if pixels.decode_u32(at)==blue_fleck:
				pixels.encode_u32(at,quiet_blue)
	return Image.create_from_data(width,height,false,Image.FORMAT_RGBA8,pixels)

# Project a square floor tile to 40 x 22 world pixels. Only replace the connected
# sandstone floor; window frames, carpet, threshold and wall courses stay registered.
func apply_floor_joints(plate:Image)->void:
	var stone:=plate.get_pixel(520,350)
	var light_tile:=plate.get_pixel(530,403)
	var width:=plate.get_width()
	var height:=plate.get_height()
	var seen:=PackedByteArray()
	seen.resize(width*height)
	var todo:=PackedInt32Array([350*width+520])
	while not todo.is_empty():
		var at:=todo[-1]
		todo.resize(todo.size()-1)
		if seen[at]:continue
		seen[at]=1
		var x:=at%width
		var y:=floori(at/float(width))
		var tone:=plate.get_pixel(x,y)
		if tone!=stone and tone!=light_tile:continue
		var gx:=(x-4)%40
		var gy:=(y-3)%22
		plate.set_pixel(x,y,Color("c79b62") if gx==0 or gy==0 else stone)
		if x>0:todo.append(at-1)
		if x+1<width:todo.append(at+1)
		if y>0:todo.append(at-width)
		if y+1<height:todo.append(at+width)
