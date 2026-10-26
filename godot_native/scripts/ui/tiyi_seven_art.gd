extends RefCounted
## Native extraction of the verified right-hand7 from the original852×1846
## plate. No image is replaced, generated or moved as a whole.
const SOURCE=preload("res://assets/ui/tiyi_main.png")
const SOURCE_SIZE=Vector2(852,1846)
const SEVEN_REGION=Rect2(126,458,68,98)
const COUNT_REGION=Rect2(40,458,154,98)
const CUTOUT_SHADER="""shader_type canvas_item;
void fragment() {
    vec4 c=texture(TEXTURE,UV);
    // Only the original gold glyph and its dark source outline survive.
    // The neighboring paper is above0.86 in all three channels.
    c.a*=1.0-step(0.86,min(c.r,min(c.g,c.b)));
    COLOR=c;
}"""
const TAKEN_SHADER="""shader_type canvas_item;
void fragment() {
    vec4 c=texture(TEXTURE,UV);
    vec2 p=UV*vec2(852.0,1846.0);
    if (p.x>=126.0 && p.x<194.0 && p.y>=458.0 && p.y<556.0) {
        // Both samples are verified untouched paper beside the7 on the same
        // source row. Restrict replacement to this exact crop;4 stays intact.
        vec4 l=texture(TEXTURE,vec2(123.5/852.0,UV.y));
        vec4 r=texture(TEXTURE,vec2(199.5/852.0,UV.y));
        c=mix(l,r,clamp((p.x-123.5)/76.0,0.0,1.0));
    }
    COLOR=c;
}"""
const COUNT_TAKEN_SHADER="""shader_type canvas_item;
void fragment() {
    vec4 c=texture(TEXTURE,UV);
    c.a*=1.0-step(0.86,min(c.r,min(c.g,c.b)));
    if (UV.x>=126.0/852.0 && UV.x<194.0/852.0) { c.a=0.0; }
    COLOR=c;
}"""
static var _cutout: AtlasTexture
static var _count: AtlasTexture
static var _cutout_material: ShaderMaterial
static var _taken_material: ShaderMaterial
static func material_for(code: String) -> ShaderMaterial:
	var shader:=Shader.new(); shader.code=code
	var material:=ShaderMaterial.new(); material.shader=shader
	return material
static func cutout() -> AtlasTexture:
	if _cutout==null:
		_cutout=AtlasTexture.new(); _cutout.atlas=SOURCE; _cutout.region=SEVEN_REGION
	return _cutout
static func cutout_material() -> ShaderMaterial:
	if _cutout_material==null: _cutout_material=material_for(CUTOUT_SHADER)
	return _cutout_material
static func apply_taken(plate: TextureRect) -> void:
	if plate.texture is AtlasTexture and plate.texture.region==COUNT_REGION:
		style_count(plate,true)
		return
	if _taken_material==null: _taken_material=material_for(TAKEN_SHADER)
	plate.material=_taken_material
static func source_rect(plate: TextureRect) -> Rect2:
	var region: Rect2=plate.texture.region if plate.texture is AtlasTexture else Rect2(Vector2.ZERO,SOURCE_SIZE)
	var factor: float=minf(plate.size.x/region.size.x,plate.size.y/region.size.y)
	var origin=plate.position+(plate.size-region.size*factor)/2
	return Rect2(origin+(SEVEN_REGION.position-region.position)*factor,SEVEN_REGION.size*factor)

static func count_texture() -> AtlasTexture:
	if _count==null:
		_count=AtlasTexture.new();_count.atlas=SOURCE;_count.region=COUNT_REGION
	return _count

static func style_count(plate: TextureRect,taken: bool) -> void:
	# Atlas UVs still address the original source image. Retain the original
	# gold 7 and navy 4, removing only their photographed paper background.
	plate.material=material_for(COUNT_TAKEN_SHADER if taken else CUTOUT_SHADER)
static func bind_source(parent: Control,plate: TextureRect) -> Control:
	var marker:=Control.new(); marker.name="TiyiSevenPickupSource"
	var rect:=source_rect(plate); marker.position=rect.position; marker.size=rect.size
	marker.mouse_filter=Control.MOUSE_FILTER_IGNORE
	marker.set_meta("pickup_texture",cutout()); marker.set_meta("pickup_material",cutout_material())
	parent.add_child(marker)
	return marker
