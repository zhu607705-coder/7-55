extends RefCounted
## Shared generated physical button artwork. The clock is presentation-only.
const ATLAS_PATH := "res://assets/native/canteen_animation/drink_machine_press_4f.png"
const ATLAS = preload(ATLAS_PATH)
const CELL_STRIDE := 543.0
const REGION_SIZE := Vector2(466, 470)

static func frame_at(progress: float, reduced: bool = false) -> int:
	if reduced: return 2 if progress < 0.68 else 0
	if progress < 0.08: return 1
	if progress < 0.68: return 2
	if progress < 0.88: return 3
	return 0

static func region(frame: int) -> Rect2:
	return Rect2(Vector2(clampi(frame, 0, 3) * CELL_STRIDE + 39, 125), REGION_SIZE)

static func material(color: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
varying vec4 item_color;
void vertex() { item_color = COLOR; }
uniform vec4 drink_color : source_color = vec4(0.3,0.75,0.9,1.0);
void fragment() {
 vec4 c = texture(TEXTURE, UV);
 vec2 cell = vec2(mod(UV.x*2172.0,543.0),UV.y*724.0);
 float pad = step(137.0,cell.x)*step(cell.x,397.0)*step(234.0,cell.y)*step(cell.y,481.0);
 float lum = dot(c.rgb,vec3(0.2126,0.7152,0.0722));
 float paint = pad*smoothstep(0.28,0.55,lum);
 vec3 tinted = mix(drink_color.rgb*0.68,drink_color.rgb,lum);
 COLOR = vec4(mix(c.rgb,tinted,paint*0.90),c.a)*item_color;
}"""
	var value := ShaderMaterial.new()
	value.shader = shader
	value.set_shader_parameter("drink_color", color)
	return value

static func sprite(color: Color) -> Sprite2D:
	var value := Sprite2D.new()
	value.centered = false
	value.region_enabled = true
	value.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	value.texture = ATLAS
	value.region_rect = region(0)
	value.material = material(color)
	return value
