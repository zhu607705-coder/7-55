extends Control
## Decorative source art only. PhoneChrome and the entry session own all UI.
const ART = preload("res://assets/ui/zjuding_loading.png")
# The source's status/back controls end at y221; its home indicator starts
# below y1640. Crop both while retaining the full cyan-to-blue art gradient.
const SOURCE_REGION = Rect2(0,224,941,1408)
const BAKED_DOT_REGION = Rect2(340,950,262,92)
const CLEAN_DOT_OFFSET = Vector2(-300,0)
const CLEAN_ART_SHADER = """shader_type canvas_item;
render_mode unshaded;
varying vec4 art_tint;
void vertex() { art_tint = COLOR; }
void fragment() {
	vec4 sample_color = texture(TEXTURE, UV);
	vec2 source_pixel = UV * vec2(941.0, 1672.0);
	// Replace baked dots and their antialiased edges with blue on the same row.
	// Sampling a same-sized neighboring area preserves pixel density and
	// avoids painting a flat rectangular patch across the textured gradient.
	if (source_pixel.x >= 340.0 && source_pixel.x < 602.0 &&
		source_pixel.y >= 950.0 && source_pixel.y < 1042.0 &&
		min(sample_color.r, min(sample_color.g, sample_color.b)) > 0.06) {
		sample_color = texture(TEXTURE, UV - vec2(300.0 / 941.0, 0.0));
	}
	COLOR = sample_color * art_tint;
}
"""

func _init() -> void:
	name = "ZjudingLoadingArt"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	var shader := Shader.new()
	shader.code = CLEAN_ART_SHADER
	var art_material := ShaderMaterial.new()
	art_material.shader = shader
	material = art_material
	resized.connect(queue_redraw)

func fitted_art_rect() -> Rect2:
	var factor := maxf(size.x / SOURCE_REGION.size.x, size.y / SOURCE_REGION.size.y)
	var extent := SOURCE_REGION.size * factor
	return Rect2((size - extent) / 2.0, extent)

func _draw() -> void:
	draw_texture_rect_region(ART, fitted_art_rect(), SOURCE_REGION)
