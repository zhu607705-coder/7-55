extends Control
## Presentation only. Original PhotoEvidenceOverlay.tsx owns the <=20 reveal contract;
## controllers continue to own photoCaptured/photoDimmed and report generation.
const ART = "res://assets/ui/photo-evidence/library_022_reflection.webp"
const FRAME_SIZE = Vector2(346,300)
const LABEL_RECT = Rect2(165,48,173,217)
const LABEL_PAPER = Color("f5ecd7")
const LABEL_INK = Color("0e1b12")
const CLUE_LINES = ["书包标签","高数教材 x1","水杯 x1　充电器 x1","半包纸 x1","姓名：未检测到","学号：未检测到","人格：加载失败"]
# Process-local immutable paper resources; brightness never changes their pixels.
static var _paper_image_cache: Image
static var _paper_texture_cache: ImageTexture
var exposure: Dictionary = {}

static func parameters(brightness: float, puzzle: Dictionary) -> Dictionary:
	# Do not reveal from brightness alone, a theme switch, or a stale dimmed flag.
	var valid := is_finite(brightness)
	var progress := clampf((72.0-brightness)/52.0,0,1) if valid else 0.0
	var readable := valid and brightness<=20.0 and bool(puzzle.get("backpackInspected",false)) and bool(puzzle.get("photoCaptured",false)) and bool(puzzle.get("photoDimmed",false))
	return {"progress":progress,"readable":readable,"contrast":.9+progress*.18,"saturation":.72+progress*.3,"glare":0.0 if readable else maxf(.08,.94-progress*.78)}

static func toned_image(source: Image, info: Dictionary) -> Image:
	var result := source.duplicate() as Image
	if result.is_compressed(): result.decompress()
	# Local image contrast/saturation, not a white or black veil over clue text.
	result.adjust_bcs(1.0,float(info.contrast),float(info.saturation))
	return result

static func paper_image() -> Image:
	if _paper_image_cache!=null:return _paper_image_cache
	# Deterministic low-contrast fibres and edge falloff match the existing pixel art.
	var result := Image.create(173,217,false,Image.FORMAT_RGBA8)
	for y in range(217):
		for x in range(173):
			var fibre := float((x*17+y*29+(x*y)%23)%17-8)/1600.0
			var edge := minf(minf(x,172-x),minf(y,216-y))
			var shade := (1.0-smoothstep(0.0,5.0,edge))*.035+float(y)/217.0*.025
			var crease := exp(-pow((float(x)-139.0-float(y)*.025)/2.5,2.0))*.012
			var tone := fibre-shade+crease
			result.set_pixel(x,y,Color(clampf(LABEL_PAPER.r+tone,0,1),clampf(LABEL_PAPER.g+tone,0,1),clampf(LABEL_PAPER.b+tone,0,1),1))
	_paper_image_cache=result
	return _paper_image_cache

static func paper_texture() -> ImageTexture:
	if _paper_texture_cache==null:
		_paper_texture_cache=ImageTexture.create_from_image(paper_image())
	return _paper_texture_cache

static func glare_image(alpha: float) -> Image:
	var result := Image.create(173,217,false,Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	var progress := clampf((.94-alpha)/.78,0,1)
	for y in range(217):
		for x in range(173):
			# Soft warm reflected light retreats toward the edge as brightness falls.
			# There is no flat white core, hard polygon, or veil over the backpack.
			var distance := float(x)+float(y)*.325-(129.0+progress*39.0)
			var core := exp(-pow(distance/27.0,2.0))*.57
			var halo := exp(-pow(distance/55.0,2.0))*.16
			var falloff := .82+.18*(1.0-float(y)/217.0)
			result.set_pixel(x,y,Color(1.0,.99,.93,clampf((core+halo)*alpha*falloff,0,1)))
	return result

func configure(brightness: float, puzzle: Dictionary, reduced_motion: bool=false) -> void:
	name = "PhotoEvidenceSurface"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = FRAME_SIZE
	size = FRAME_SIZE
	exposure = parameters(brightness,puzzle)
	set_meta("photo_readable",exposure.readable)
	var scene := TextureRect.new()
	scene.name = "PhotoArtwork"
	scene.size = FRAME_SIZE
	scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	scene.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var original := load(ART) as Texture2D
	scene.texture = ImageTexture.create_from_image(toned_image(original.get_image(),exposure))
	add_child(scene)
	var paper := Panel.new()
	paper.name = "PhotoPaper"
	paper.position = LABEL_RECT.position
	paper.size = LABEL_RECT.size
	paper.clip_contents = true
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = LABEL_PAPER
	style.shadow_color = Color("211b14",.32)
	style.shadow_size = 5
	style.shadow_offset = Vector2(2,3)
	style.border_color = Color("81735b")
	style.set_border_width_all(1)
	paper.add_theme_stylebox_override("panel",style)
	add_child(paper)
	var fibres := TextureRect.new()
	fibres.name = "PaperFibres"
	fibres.position = Vector2(1,1)
	fibres.size = LABEL_RECT.size-Vector2(2,2)
	fibres.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fibres.texture = paper_texture()
	fibres.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fibres.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_child(fibres)
	var rule := ColorRect.new()
	rule.position=Vector2(9,29);rule.size=Vector2(155,1)
	rule.color=Color("9c8f72",.35);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE
	paper.add_child(rule)
	_label(paper,"OCR",Rect2(9,5,69,22),12,Color("536447"))
	_label(paper,"LOCK" if exposure.readable else "SCAN",Rect2(107,5,57,22),12,Color("285f4c") if exposure.readable else Color("655e49"))
	if exposure.readable:
		for i in range(CLUE_LINES.size()):
			var line := _label(paper,CLUE_LINES[i],Rect2(9,34+i*23,155,22),15,LABEL_INK)
			line.name = "PhotoClueLine%d"%i
			if not reduced_motion:
				# A short focus-in is presentation only; labels exist only after the gate.
				line.modulate.a=0.0
				var delay: float=float(i)*.025
				ready.connect(func():
					if not is_instance_valid(line):return
					var reveal:=line.create_tween()
					reveal.tween_interval(delay)
					reveal.tween_property(line,"modulate:a",1.0,.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT))
	else:
		_label(paper,"标签反光，无法识别",Rect2(9,34,155,29),14,Color("777467"))
		for i in range(4):
			var bar := ColorRect.new()
			bar.name = "ObscuredLine%d"%i
			bar.position = Vector2(10,78+i*25)
			bar.size = Vector2([129,102,139,81][i],7)
			bar.color = Color("857e6c",.36+float(exposure.progress)*.18)
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			paper.add_child(bar)
	var glare := TextureRect.new()
	glare.name = "LocalizedPaperGlare"
	glare.position = Vector2(2,28)
	glare.size = Vector2(169,187)
	glare.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glare.texture = ImageTexture.create_from_image(glare_image(float(exposure.glare)))
	glare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_child(glare)
	if not exposure.readable:
		var scan := ColorRect.new()
		scan.name = "PhotoScanLine"
		scan.position = Vector2(4,14+float(exposure.progress)*258)
		scan.size = Vector2(338,1)
		scan.color = Color("70babe",.38)
		scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(scan)

func _label(parent: Control, value: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
