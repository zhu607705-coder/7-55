extends Node2D
## One physical scanner. The supplied case, movable film and scan light are native layers.
## The original controller/session remains the sole gameplay authority.
const Motion=preload("res://scripts/objects/room302_alignment_motion.gd")
const TRIM=Rect2(80,156,1134,868)
const GLASS=Rect2(253,224,629,538)
var appearance:Sprite2D
var _pick_image:Image
var film_carriage:Node2D
var film_strip:Polygon2D
var glass_clip:Polygon2D
var scan_light:Polygon2D
var aligned_outline:Line2D
var motion:RefCounted=Motion.new()
var factor:=1.0
var has_film:=false
var aligned:=false
var scan_elapsed:=-1.0
var scan_count:=0
var _seeded:=false
var _source_origin:=Vector2.ZERO

func configure(id:String,definition:Dictionary)->void:
	name=id
	position=definition.position
	appearance=Sprite2D.new();appearance.name="OriginalAppearance"
	appearance.texture=load(definition.path);appearance.centered=false
	appearance.region_enabled=true;appearance.region_rect=definition.trim
	appearance.region_filter_clip_enabled=true
	var art_scale:float=float(definition.width)/definition.trim.size.x
	appearance.scale=Vector2.ONE*art_scale
	appearance.position=Vector2(-definition.trim.size.x*.5,-definition.trim.size.y)*art_scale
	add_child(appearance)
	_pick_image=appearance.texture.get_image()
	factor=float(definition.width)/TRIM.size.x
	_source_origin=Vector2(-647,-1024)*factor
	# Reconstruct only the glass inset and the old film-clamp footprint. The
	# supplied outer case/dial/feet stay untouched. This prevents a baked film
	# remaining underneath the independent moving film or appearing without it.
	var shader:=Shader.new()
	shader.code="""shader_type canvas_item;
	varying vec2 source_pixel;
	varying vec4 item_tint;
	void vertex() { source_pixel=VERTEX+vec2(80.0,156.0);item_tint=COLOR; }
	void fragment() {
		vec2 p=source_pixel;
		if(p.x>=227.0 && p.x<=911.0 && p.y>=214.0 && p.y<=776.0) {
			vec3 c=vec3(.25,.27,.28);
			if(p.x>=253.0 && p.x<=882.0 && p.y>=224.0 && p.y<=762.0) {
				float t=clamp((p.y-224.0)/538.0,0.0,1.0);
				c=mix(vec3(.75,.79,.76),vec3(.86,.84,.73),t);
				float shine=1.0-smoothstep(0.0,35.0,abs(p.x+p.y*.65-706.0));
				c+=vec3(.07)*shine;
				bool is_mark=(abs(p.x-567.5)<2.0 && abs(p.y-493.0)<19.0)||(abs(p.y-493.0)<2.0 && abs(p.x-567.5)<19.0);
				if(is_mark)c=vec3(.26,.29,.27);
			}
			COLOR=vec4(c,1.0)*item_tint;
		}
	}"""
	var material:=ShaderMaterial.new();material.shader=shader;appearance.material=material
	glass_clip=Polygon2D.new();glass_clip.name="GlassWindowClip"
	glass_clip.polygon=_quad(GLASS);glass_clip.color=Color.WHITE
	glass_clip.clip_children=CanvasItem.CLIP_CHILDREN_ONLY
	add_child(glass_clip)
	film_carriage=Node2D.new();film_carriage.name="OriginalFilmCarriage";glass_clip.add_child(film_carriage)
	film_strip=Polygon2D.new();film_strip.name="SuppliedFilmStrip";film_strip.texture=appearance.texture
	var source:=PackedVector2Array([Vector2(290,550),Vector2(817,312),Vector2(841,410),Vector2(315,690)])
	film_strip.uv=source
	var relative:=PackedVector2Array()
	for point:Vector2 in source:relative.append((point-Vector2(565,502))*factor*.70)
	film_strip.polygon=relative;film_strip.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	film_carriage.add_child(film_strip)
	# The clamps travel with the film. Small native pins replace the removed
	# baked clamps; they never receive independent interaction/state.
	for center:Vector2 in [Vector2(292,598),Vector2(827,359)]:
		var pin:=Polygon2D.new();var circle:=PackedVector2Array()
		for i in range(16):circle.append((center-Vector2(565,502))*factor*.70+Vector2.from_angle(TAU*i/16)*2.5)
		pin.polygon=circle;pin.color=Color("c69639");film_carriage.add_child(pin)
	scan_light=Polygon2D.new();scan_light.name="AcceptedScanLine";scan_light.color=Color(.65,.96,.91,.52);glass_clip.add_child(scan_light)
	aligned_outline=Line2D.new();aligned_outline.name="OriginalAlignmentAccepted";aligned_outline.width=1;aligned_outline.default_color=Color(.72,.95,.78,.0)
	var points:=_quad(GLASS);points.append(points[0]);aligned_outline.points=points;glass_clip.add_child(aligned_outline)
	_apply_pose()

func _quad(rect:Rect2)->PackedVector2Array:
	return PackedVector2Array([rect.position*factor+_source_origin,Vector2(rect.end.x,rect.position.y)*factor+_source_origin,rect.end*factor+_source_origin,Vector2(rect.position.x,rect.end.y)*factor+_source_origin])

func synchronize(film_available:bool,complete:bool,draft:Dictionary,reduced:bool)->void:
	has_film=film_available;aligned=complete;motion.reduced_motion=reduced
	var point:=Vector2(float(draft.get("xOffset",0))*20,float(draft.get("yOffset",0))*20)
	var radians:=deg_to_rad(float(draft.get("rotationQuarterTurns",0))*90)
	if not _seeded:motion.seed_pose(point,radians,complete);_seeded=true
	else:motion.retarget(point,radians,complete)
	_apply_pose()

func settle(film_available:bool,complete:bool,draft:Dictionary,reduced:bool)->void:
	_seeded=false;scan_elapsed=-1;synchronize(film_available,complete,draft,reduced)

func start_accepted_scan()->void:
	scan_count+=1;scan_elapsed=-1 if motion.reduced_motion else 0
	_apply_pose()

func advance_feedback(delta:float)->void:
	motion.advance(delta)
	if scan_elapsed>=0:
		scan_elapsed+=maxf(delta,0)
		if scan_elapsed>=.6:scan_elapsed=-1
	_apply_pose()

func _apply_pose()->void:
	if film_carriage==null:return
	film_carriage.visible=has_film
	film_carriage.position=GLASS.get_center()*factor+_source_origin+motion.position*(GLASS.size.x*factor/280.0)
	film_carriage.rotation=deg_to_rad(24.3)+motion.angle
	scan_light.visible=has_film and scan_elapsed>=0
	if scan_light.visible:
		var x:=GLASS.position.x+GLASS.size.x*clampf(scan_elapsed/.6,0,1)
		scan_light.polygon=_quad(Rect2(x-5,GLASS.position.y,10,GLASS.size.y))
	aligned_outline.default_color.a=motion.success_alpha() if has_film and aligned else 0.0

func contains_source_point(point:Vector2)->bool:
	if appearance==null or _pick_image==null:return false
	var local:Vector2=transform.affine_inverse()*point
	var source:Vector2=(local-appearance.position)/appearance.scale+appearance.region_rect.position
	if not appearance.region_rect.has_point(source):return false
	var x:int=int(source.x);var y:int=int(source.y)
	return x>=0 and y>=0 and x<_pick_image.get_width() and y<_pick_image.get_height() and _pick_image.get_pixel(x,y).a>.08
