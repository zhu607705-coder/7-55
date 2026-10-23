extends RefCounted
## A source-pixel object decomposition. Atlas parts are transparent polygons;
## local clean-floor patches use unchanged nearby pixels from the same plate.
## Scene objects, picking, and physical footprints share the same selected mode.
const DATA_PATH="res://data/native/theater-object-layout.json"
const Picker=preload("res://scripts/world_object_picker.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
var data: Dictionary={}
var textures: Dictionary={}
var source_texture: Texture2D
var generated_ready := false
var scene_id := ""
var replacement_geometry: Dictionary={}
var candidate_cache: Dictionary={}
var next_retry_ms := 0
var clean_mesh_cache: Array=[]

func _init(definition: Dictionary={}) -> void:
	data=definition.duplicate(true) if not definition.is_empty() else JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
func _texture(path: String) -> Texture2D:
	if textures.has(path):return textures[path]
	var value: Texture2D=load(path) if ResourceLoader.exists(path) else null
	if value!=null:textures[path]=value
	return value
func sync(state: Dictionary,_scene_changed: bool=false) -> void:
	scene_id=str(state.get("native",{}).get("scene",""))
	if scene_id==str(data.sceneId) and not generated_ready and Time.get_ticks_msec()>=next_retry_ms:refresh_assets()
func refresh_assets() -> void:
	if generated_ready:return
	next_retry_ms=Time.get_ticks_msec()+250
	source_texture=_texture(str(data.source.asset))
	if source_texture!=null and clean_mesh_cache.is_empty():
		for object: Dictionary in data.objects:
			for part: Dictionary in object.parts:clean_mesh_cache.append_array(_clean_meshes(part))
		for patch: Dictionary in data.get("backgroundPatches",[]):clean_mesh_cache.append_array(_clean_meshes(patch))
	var candidates: Dictionary={};var complete: bool=source_texture!=null
	for object: Dictionary in data.objects:
		if not object.has("replacement"):continue
		if candidate_cache.has(object.id):candidates[object.id]=candidate_cache[object.id];continue
		var replacement: Dictionary=object.replacement
		var texture: Texture2D=_texture(str(replacement.asset))
		if texture==null:complete=false;continue
		var image: Image=texture.get_image()
		if image==null or image.is_empty():complete=false;continue
		if image.is_compressed():image.decompress()
		var used: Rect2=Rect2(image.get_used_rect())
		if not used.has_area() or replacement.get("requireAlpha",false) and image.detect_alpha()==Image.ALPHA_NONE:complete=false;continue
		var bounds: Rect2=rect(replacement.destinationRect)
		var factor: float=minf(bounds.size.x/used.size.x,bounds.size.y/used.size.y)
		# No per-axis stretch. The authored source bottom is the physical ground.
		var extent: Vector2=used.size*factor
		var destination=Rect2(Vector2(bounds.get_center().x-extent.x/2,bounds.end.y-extent.y),extent)
		candidates[object.id]={"texture":texture,"source":used,"destination":destination,"scale":factor}
		candidate_cache[object.id]=candidates[object.id]
	generated_ready=complete
	replacement_geometry=candidates if complete else {}
func ready() -> bool:return scene_id==str(data.sceneId) and source_texture!=null
static func rect(values: Array) -> Rect2:return Rect2(float(values[0]),float(values[1]),float(values[2]),float(values[3]))
static func points(values: Array) -> PackedVector2Array:
	var result=PackedVector2Array()
	for point: Array in values:result.append(Vector2(float(point[0]),float(point[1])))
	return result
func objects() -> Array:return data.objects.duplicate(true)
func mode() -> String:return "generated" if generated_ready else "source_atlas"
func entries(state: Dictionary) -> Array:
	if not ready() or str(state.get("native",{}).get("scene",""))!=str(data.sceneId):return []
	var result: Array=[]
	var body_bottom: float=Metrics.foot_rect(Vector2.ZERO).end.y
	for object: Dictionary in data.objects:
		if generated_ready and object.has("replacement"):
			var destination: Rect2=replacement_geometry[object.id].destination
			result.append({"id":"rebuild_"+str(object.id),"kind":"theater_rebuild","objectId":object.id,"partIndex":-1,"depth":destination.end.y+120-body_bottom})
		else:
			for index in object.parts.size():
				result.append({"id":"rebuild_"+str(object.id)+"_"+str(index),"kind":"theater_rebuild","objectId":object.id,"partIndex":index,"depth":float(object.parts[index].baselineY)+120-body_bottom})
	return result
func _object(id: String) -> Dictionary:
	for object: Dictionary in data.objects:
		if str(object.id)==id:return object
	return {}
func owns_target(target: Dictionary) -> bool:
	if not ready():return false
	for object: Dictionary in data.objects:
		if str(target.get("id","")) in object.targetIds:return true
	return false
func owns_legacy_cover(cover: Dictionary) -> bool:
	if not ready():return false
	for object: Dictionary in data.objects:
		if str(cover.get("id","")) in object.legacyCoverIds:return true
	return false
func draw_background(canvas: CanvasItem,context: Dictionary,state: Dictionary) -> void:
	if not ready() or str(state.get("native",{}).get("scene",""))!=str(data.sceneId):return
	for mesh: Dictionary in clean_mesh_cache:_draw_polygon(canvas,context,mesh.polygon,mesh.uv,source_texture)
func _clean_meshes(part: Dictionary) -> Array:
	var result: Array=[]
	var outline: PackedVector2Array=points(part.polygon)
	for band: Dictionary in part.cleanBands:
		var target: Rect2=rect(band.targetRect);var donor: Rect2=rect(band.donorRect)
		var y: float=target.position.y
		while y<target.end.y-0.01:
			var height: float=minf(donor.size.y,target.end.y-y);var x: float=target.position.x
			while x<target.end.x-0.01:
				var width: float=minf(donor.size.x,target.end.x-x)
				var tile=Rect2(x,y,width,height)
				var tile_polygon=PackedVector2Array([tile.position,Vector2(tile.end.x,tile.position.y),tile.end,Vector2(tile.position.x,tile.end.y)])
				for clipped: PackedVector2Array in Geometry2D.intersect_polygons(outline,tile_polygon):
					var uv=PackedVector2Array()
					for point: Vector2 in clipped:uv.append((donor.position+point-tile.position)/source_texture.get_size())
					result.append({"polygon":clipped,"uv":uv,"sourcePart":part.sourceRect.duplicate()})
				x+=width
			y+=height
	return result
func _draw_polygon(canvas: CanvasItem,context: Dictionary,polygon: PackedVector2Array,uv: PackedVector2Array,texture: Texture2D) -> void:
	var projected=PackedVector2Array()
	for point: Vector2 in polygon:projected.append(Vector2(context.origin)+point*float(context.zoom))
	canvas.draw_polygon(projected,PackedColorArray([Color.WHITE]),uv,texture)
func draw_entry(canvas: CanvasItem,context: Dictionary,entry: Dictionary,state: Dictionary) -> void:
	if not ready():return
	var object: Dictionary=_object(str(entry.objectId))
	if object.is_empty():return
	canvas.draw_set_transform(Vector2.ZERO)
	if int(entry.partIndex)<0:
		if not generated_ready or not replacement_geometry.has(object.id):return
		var geometry: Dictionary=replacement_geometry[object.id]
		var destination: Rect2=geometry.destination
		var projected=Rect2(Vector2(context.origin)+destination.position*float(context.zoom),destination.size*float(context.zoom))
		Picker.record(canvas,object.targetIds,surface_geometry(entry))
		var mix: float=float(context.get("mode_mix",1.0 if str(state.native.get("mode","light"))=="dark" else 0.0))
		canvas.draw_texture_rect_region(geometry.texture,projected,geometry.source,Color.WHITE.lerp(Color(.03,.15,.26),mix*.3))
	else:
		var part: Dictionary=object.parts[int(entry.partIndex)]
		var polygon: PackedVector2Array=points(part.polygon);var uv=PackedVector2Array()
		for point: Vector2 in polygon:uv.append(point/source_texture.get_size())
		Picker.record(canvas,object.targetIds,surface_geometry(entry))
		_draw_polygon(canvas,context,polygon,uv,source_texture)
		# The base receives the global dark wash before actors. Apply the same
		# wash to independent source parts so its atlas edge cannot form a box.
		var mix: float=float(context.get("mode_mix",1.0 if str(state.native.get("mode","light"))=="dark" else 0.0))
		if mix>0:
			var projected=PackedVector2Array()
			for point: Vector2 in polygon:projected.append(Vector2(context.origin)+point*float(context.zoom))
			canvas.draw_colored_polygon(projected,Color(.03,.15,.26,mix*.3))
	canvas.draw_set_transform(Vector2.ZERO)
func surface_geometry(entry: Dictionary) -> Dictionary:
	var object: Dictionary=_object(str(entry.get("objectId","")))
	if object.is_empty():return {}
	if int(entry.partIndex)<0:
		if not generated_ready or not replacement_geometry.has(object.id):return {}
		var geometry: Dictionary=replacement_geometry[object.id]
		return {"rect":geometry.destination,"texture":geometry.texture,"source":geometry.source}
	return {"polygon":points(object.parts[int(entry.partIndex)].polygon)}
func adjusted_collisions(base: Array,state: Dictionary) -> Array:
	if not ready() or str(state.get("native",{}).get("scene",""))!=str(data.sceneId):return base
	var output: Array=base.duplicate(true)
	for object: Dictionary in data.objects:
		var key: String="collisionGenerated" if generated_ready and object.has("collisionGenerated") else "collisionFallback"
		if not object.has(key) or object.sourceCollisionIds.is_empty():continue
		var active: bool=false
		for box: Dictionary in base:
			if str(box.get("id","")) in object.sourceCollisionIds:active=true;break
		if not active:continue
		output=output.filter(func(box: Dictionary):return str(box.get("id","")) not in object.sourceCollisionIds and not str(box.get("id","")).begins_with("c3_rebuild_"+str(object.id)+"_"))
		for index in object[key].size():
			var box: Dictionary=object[key][index].duplicate(true)
			box.id=str(object.sourceCollisionIds[0]) if index==0 else "c3_rebuild_"+str(object.id)+"_"+str(index)
			output.append(box)
	return output
func geometry_snapshot() -> Dictionary:
	var generated: Dictionary={}
	for id: String in replacement_geometry:
		var geometry: Dictionary=replacement_geometry[id]
		var destination: Rect2=geometry.destination
		generated[id]={"source":[geometry.source.position.x,geometry.source.position.y,geometry.source.size.x,geometry.source.size.y],"destination":[destination.position.x,destination.position.y,destination.size.x,destination.size.y],"scale":geometry.scale}
	return {"mode":mode(),"sourceSize":data.source.size.duplicate(),"objects":objects(),"generated":generated}
