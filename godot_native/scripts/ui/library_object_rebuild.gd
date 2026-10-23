extends RefCounted
## A source-sized clean plate and four independently generated library props.
## This adapter has no story state and never changes a collision footprint.
var layout: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/library-object-layout.json"))
var clean_plate: Texture2D
var textures: Dictionary={}
var visible_regions: Dictionary={}
var ready: bool=false
var issues: Array[String]=[]
var last_attempt_ms: int=-1000

func ensure_loaded(force: bool=false) -> bool:
	if ready: return true
	var now: int=Time.get_ticks_msec()
	if not force and now-last_attempt_ms<250: return false
	last_attempt_ms=now
	issues.clear(); textures.clear(); visible_regions.clear()
	var size_spec: Array=layout.get("cleanPlateSize",[])
	clean_plate=_load_texture(str(layout.get("cleanPlate","")),size_spec,false)
	for id: String in layout.get("objects",{}):
		var spec: Dictionary=layout.objects[id]
		var texture: Texture2D=_load_texture(str(spec.texture),spec.textureSize,true)
		if texture!=null:
			textures[id]=texture
			visible_regions[id]=_visible_region(texture)
	ready=clean_plate!=null and textures.size()==layout.get("objects",{}).size() and issues.is_empty()
	return ready

func _load_texture(path: String,expected: Array,transparent: bool) -> Texture2D:
	if not ResourceLoader.exists(path):
		issues.append("Missing generated library texture: "+path); return null
	var texture: Texture2D=load(path)
	if texture==null or expected.size()!=2 or texture.get_size()!=Vector2(float(expected[0]),float(expected[1])):
		issues.append("Generated library texture size mismatch: "+path); return null
	if transparent:
		var image: Image=texture.get_image()
		if image!=null and image.is_compressed(): image.decompress()
		if image==null or image.is_empty():
			issues.append("Cannot inspect generated library texture: "+path); return null
		var transparent_pixel: bool=false
		var opaque_pixel: bool=false
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var alpha: float=image.get_pixel(x,y).a
				transparent_pixel=transparent_pixel or alpha<0.05
				opaque_pixel=opaque_pixel or alpha>0.95
				if transparent_pixel and opaque_pixel: break
			if transparent_pixel and opaque_pixel: break
		if not transparent_pixel or not opaque_pixel:
			issues.append("Generated library prop needs real cutout alpha and visible art: "+path); return null
	return texture

func bounds(id: String) -> Rect2:
	var row: Array=layout.objects[id].sourceRect
	return Rect2(float(row[0]),float(row[1]),float(row[2]),float(row[3]))

func geometry(id: String,area: Rect2) -> Dictionary:
	var texture: Texture2D=textures[id]
	var region: Rect2=visible_regions[id]
	return _fit_geometry(texture,area,region)

func _fit_geometry(texture: Texture2D,area: Rect2,region: Rect2) -> Dictionary:
	# Remove transparent atlas padding, then fit the physical object uniformly
	# within its original source footprint. Its bottom stays on the floor.
	# The same measured region is used by drawing and alpha picking.
	var factor: float=minf(area.size.x/region.size.x,area.size.y/region.size.y)
	var dimensions: Vector2=region.size*factor
	area=Rect2(Vector2(area.get_center().x-dimensions.x/2,area.end.y-dimensions.y),dimensions)
	return {"rect":area,"texture":texture,"source":region}

func pieces(id: String,area: Rect2) -> Array:
	var whole: Dictionary=geometry(id,area)
	var regions: Array=[whole.source]
	for component: Dictionary in layout.objects[id].get("components",[]):
		var r: Array=component.textureRegion
		var cut:=Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3]))
		var next: Array=[]
		for region: Rect2 in regions: next.append_array(_without(region,cut))
		regions=next
	var result: Array=[]
	var scale_value: float=whole.rect.size.x/whole.source.size.x
	for region: Rect2 in regions:
		result.append({"rect":Rect2(whole.rect.position+(region.position-whole.source.position)*scale_value,region.size*scale_value),"texture":whole.texture,"source":region})
	return result

func component_geometry(id: String,component: Dictionary) -> Dictionary:
	var r: Array=component.sourceRect
	var t: Array=component.textureRegion
	return _fit_geometry(textures[id],Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3])),Rect2(float(t[0]),float(t[1]),float(t[2]),float(t[3])))

func _without(region: Rect2,cut: Rect2) -> Array:
	var middle: Rect2=region.intersection(cut)
	if not middle.has_area(): return [region]
	var result: Array=[]
	for part: Rect2 in [Rect2(region.position,Vector2(region.size.x,middle.position.y-region.position.y)),Rect2(Vector2(region.position.x,middle.end.y),Vector2(region.size.x,region.end.y-middle.end.y)),Rect2(Vector2(region.position.x,middle.position.y),Vector2(middle.position.x-region.position.x,middle.size.y)),Rect2(Vector2(middle.end.x,middle.position.y),Vector2(region.end.x-middle.end.x,middle.size.y))]:
		if part.has_area(): result.append(part)
	return result

func _visible_region(texture: Texture2D) -> Rect2:
	var image: Image=texture.get_image()
	if image.is_compressed(): image.decompress()
	var left: int=image.get_width(); var top: int=image.get_height()
	var right: int=0; var bottom: int=0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x,y).a<=0.05: continue
			left=mini(left,x); top=mini(top,y); right=maxi(right,x+1); bottom=maxi(bottom,y+1)
	return Rect2(left,top,right-left,bottom-top)

func snapshot() -> Dictionary:
	return {"ready":ready,"fallback":"" if ready else "original_source_layers","issues":issues.duplicate(),"loadedObjects":textures.keys(),"visibleRegions":visible_regions.duplicate()}
