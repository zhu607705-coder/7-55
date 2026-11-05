extends Control
## Bounded final-composite calibration. Never modifies art, input or story data.
## The same pass covers Entry and every pixel within the phone's glass.
const GRADE_SHADER = preload("res://shaders/phone_display_grade.gdshader")
const LIFT_AMOUNT := 0.60
var strength := 0.0
var back_buffer: BackBufferCopy
var surface: ColorRect

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	focus_mode=Control.FOCUS_NONE
	back_buffer=BackBufferCopy.new()
	back_buffer.name="CompletedPhoneComposition"
	# Full-viewport copy is deliberate. Rectangle copies on a translated,
	# scaled Control hierarchy can leave stale samples in Compatibility.
	# Only the bounded phone/Entry surface below writes any output pixels.
	back_buffer.copy_mode=BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(back_buffer)
	surface=ColorRect.new()
	surface.name="BoundedMidtoneLift"
	surface.mouse_filter=Control.MOUSE_FILTER_IGNORE
	surface.focus_mode=Control.FOCUS_NONE
	surface.z_index=1
	var grade:=ShaderMaterial.new()
	grade.shader=GRADE_SHADER
	grade.set_shader_parameter("lift_amount",LIFT_AMOUNT*strength)
	surface.material=grade
	add_child(surface)
	resized.connect(_layout)
	_layout()
	set_strength(strength)

func set_strength(value: float) -> void:
	strength=clampf(value,0.0,1.0)
	# Neutral is a true bypass, avoiding any shader rounding or screen copy.
	visible=strength>0.0
	if is_instance_valid(surface):
		(surface.material as ShaderMaterial).set_shader_parameter("lift_amount",LIFT_AMOUNT*strength)

func _layout() -> void:
	if not is_instance_valid(back_buffer) or not is_instance_valid(surface):return
	back_buffer.rect=Rect2(Vector2.ZERO,size)
	surface.size=size

static func calibrated_color(source: Color, amount: float=1.0) -> Color:
	# CPU mirror for dense boundedness/monotonicity checks, not production art.
	if amount<=0.0:return source
	var peak:=maxf(source.r,maxf(source.g,source.b))
	var low:=minf(source.r,minf(source.g,source.b))
	var lightness:=(peak+low)*.5
	var gate:=smoothstep(0.20,0.40,peak)
	var lifted:=lightness+LIFT_AMOUNT*clampf(amount,0.0,1.0)*lightness*(1.0-lightness)*gate
	var chroma_scale:=minf(lifted,1.0-lifted)/maxf(minf(lightness,1.0-lightness),.000001)
	return Color(lifted+(source.r-lightness)*chroma_scale,lifted+(source.g-lightness)*chroma_scale,lifted+(source.b-lightness)*chroma_scale,source.a)
