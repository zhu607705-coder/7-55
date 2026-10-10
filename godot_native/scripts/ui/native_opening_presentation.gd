extends Node
## P00/P01 CSS art and motion only. No controller events, audio or progression.
## Source: scenes/p00-alarm.css, p01-desktop.css and base.css --ease-* tokens.
const FONT=preload("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
const INK=Color("222322")
const YELLOW=Color("f5c542")
const SHAKE_SECONDS:=0.12
const WAVE_SECONDS:=0.5
const SHAKE_POINTS=[Vector2.ZERO,Vector2(4,-3),Vector2(-4,3),Vector2(3,4),Vector2(-3,-4)]
const BELL_PERCENTAGES=[Vector2(.5,0),Vector2(.72,.1),Vector2(.82,.34),Vector2(.86,.7),Vector2(1,.88),Vector2(1,1),Vector2(0,1),Vector2(0,.88),Vector2(.14,.7),Vector2(.18,.34),Vector2(.28,.1)]
var scene: Control
var bell: Control
var art_scale:=1.0
var origin:=Vector2.ZERO
var elapsed:=0.0

static func clock_size(viewport_width: float) -> float:
	# rem resolves against the final13px root; vw is the actual app viewport.
	return clampf(viewport_width*.2,4.4*13,6.4*13)

static func shake_at(seconds: float) -> Vector2:
	var progress:=fposmod(seconds,SHAKE_SECONDS)/SHAKE_SECONDS*4
	var index:=mini(3,int(floor(progress)))
	var stepped:=floorf((progress-index)*2)/2
	return SHAKE_POINTS[index].lerp(SHAKE_POINTS[index+1],stepped)

static func wave_alpha_at(seconds: float) -> float:
	var progress:=fposmod(seconds,WAVE_SECONDS)/WAVE_SECONDS*2
	var stepped:=floorf(fposmod(progress,1)*3)/3
	return lerpf(.2,1,stepped) if progress<1 else lerpf(1,.2,stepped)

static func create_clock(parent: Control,rect: Rect2,scale: float) -> Control:
	var clock:=AlarmClock.new(); clock.name="AlarmClock"; clock.position=rect.position; clock.size=rect.size
	clock.art_scale=scale; clock.mouse_filter=Control.MOUSE_FILTER_IGNORE; parent.add_child(clock)
	return clock

static func create_bell(parent: Control,center: Vector2,scale: float) -> Control:
	var artwork:=AlarmBell.new(); artwork.name="AlarmBellArtwork"; artwork.art_scale=scale
	artwork.size=Vector2(90,74)/scale; artwork.position=center-artwork.size/2; artwork.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(artwork)
	return artwork

static func create_wake_flash(parent: Control,rect: Rect2,scale: float,reduced_motion: bool=false) -> Control:
	var flash:=WakeFlash.new(); flash.name="WakeFlash"; flash.position=rect.position; flash.size=rect.size
	flash.art_scale=scale; flash.reduced_motion=reduced_motion
	flash.mouse_filter=Control.MOUSE_FILTER_IGNORE; flash.tooltip_text="起床蠢货！！！"
	parent.add_child(flash)
	return flash

static func animate(parent: Control,artwork: Control,scale: float) -> Node:
	var motion: Node=load("res://scripts/ui/native_opening_presentation.gd").new()
	motion.name="AlarmSceneMotion"; motion.scene=parent; motion.bell=artwork; motion.art_scale=scale; motion.origin=parent.position
	parent.add_child(motion)
	return motion

func _process(delta: float) -> void:
	elapsed+=delta
	scene.position=origin+shake_at(elapsed)/art_scale
	bell.wave_alpha=wave_alpha_at(elapsed)
	bell.queue_redraw()

class WakeFlash extends Control:
	## One runtime-only owner for both text lines. CSS steps(2,end) applies
	## separately to the two keyframe segments of the original420ms cycle.
	const CYCLE_SECONDS:=0.42
	const RED=Color("c85454")
	const SHADOW_OFFSET=Vector2(4,4)
	const MARK_SPACING:=8.0
	const MARK_SHIFT:=10.0
	var art_scale:=1.0
	var elapsed:=0.0
	var reduced_motion:=false
	var logical_font_size:=59.8
	var text: String="起床蠢货\n！！！"
	static func font_size_at(viewport_width: float) -> float:
		return clampf(viewport_width*.15,2.8*13,4.6*13)
	static func sample_at(seconds: float) -> Vector2:
		var quarter:=mini(3,int(floor(fposmod(maxf(0,seconds),CYCLE_SECONDS)/(CYCLE_SECONDS/4))))
		var weight: float=[0.0,.5,1.0,.5][quarter]
		return Vector2(lerpf(1,.24,weight),lerpf(1,1.06,weight))
	func _ready() -> void:
		get_viewport().size_changed.connect(_resize_text)
		_resize_text()
		_apply_motion()
	func _resize_text() -> void:
		logical_font_size=font_size_at(get_viewport_rect().size.x)
		pivot_offset=size/2
		queue_redraw()
	func _process(delta: float) -> void:
		elapsed=0 if reduced_motion else fposmod(elapsed+maxf(0,delta),CYCLE_SECONDS)
		_apply_motion()
	func _apply_motion() -> void:
		var sample:=Vector2.ONE if reduced_motion else sample_at(elapsed)
		modulate.a=sample.x
		scale=Vector2.ONE*sample.y
	func line_width(line: String,spacing: float=0.0) -> float:
		var pixels:=ceili(logical_font_size)
		var ratio:=logical_font_size/pixels
		return FONT.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x*ratio+line.length()*spacing
	func _draw_line(line: String,top: float,spacing: float,shift: float) -> void:
		var pixels:=ceili(logical_font_size)
		var ratio:=logical_font_size/pixels
		var line_height:=logical_font_size*1.15
		var cursor:=Vector2((size.x*art_scale-line_width(line,spacing))/2+shift,top+(line_height-FONT.get_height(pixels)*ratio)/2+FONT.get_ascent(pixels)*ratio)
		# Draw one shared shadow pass before the red glyph pass. Letter spacing
		# and shadow stay in logical pixels, independent of the phone scale.
		for shadow: bool in [true,false]:
			var pen:=cursor
			for character: String in line:
				draw_set_transform((pen+(SHADOW_OFFSET if shadow else Vector2.ZERO))/art_scale,0,Vector2.ONE*ratio/art_scale)
				draw_string(FONT,Vector2.ZERO,character,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,INK if shadow else RED)
				pen.x+=FONT.get_string_size(character,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x*ratio+spacing
		draw_set_transform(Vector2.ZERO)
	func _draw() -> void:
		var line_height:=logical_font_size*1.15
		var top: float=(size.y*art_scale-line_height*2)/2
		_draw_line("起床蠢货",top,0,0)
		_draw_line("！！！",top+line_height,MARK_SPACING,MARK_SHIFT)

class AlarmClock extends Control:
	var text: String="07:55"
	var art_scale:=1.0
	var logical_font_size:=83.2
	var logical_letter_spacing:=4.0
	func _ready() -> void:
		get_viewport().size_changed.connect(_resize_clock)
		_resize_clock()
	func _resize_clock() -> void:
		logical_font_size=clampf(get_viewport_rect().size.x*.2,4.4*13,6.4*13)
		queue_redraw()
	func text_width() -> float:
		var pixels:=ceili(logical_font_size)
		var ratio:=logical_font_size/pixels
		var width:=text.length()*logical_letter_spacing
		for character: String in text: width+=FONT.get_string_size(character,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x*ratio
		return width
	func _draw() -> void:
		var pixels:=ceili(logical_font_size)
		var ratio:=logical_font_size/pixels
		var line_size:=FONT.get_height(pixels)*ratio
		var cursor:=Vector2((size.x*art_scale-text_width())/2,(size.y*art_scale-line_size)/2+FONT.get_ascent(pixels)*ratio)
		# Integer raster size plus a uniform draw transform retains the exact
		# fractional CSS clamp and4px glyph spacing without changing the frame.
		for character: String in text:
			draw_set_transform(cursor/art_scale,0,Vector2.ONE*ratio/art_scale)
			draw_string(FONT,Vector2.ZERO,character,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,INK)
			cursor.x+=FONT.get_string_size(character,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x*ratio+logical_letter_spacing
		draw_set_transform(Vector2.ZERO)

class AlarmBell extends Control:
	var art_scale:=1.0
	var wave_alpha:=0.0
	func body_polygon() -> PackedVector2Array:
		var points:=PackedVector2Array()
		for point: Vector2 in BELL_PERCENTAGES: points.append(Vector2(15,8)+point*Vector2(60,58))
		return points
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO,0,Vector2.ONE/art_scale)
		var body:=body_polygon()
		draw_colored_polygon(body,YELLOW)
		# CSS clips a rectangular3px border along with its background. It does
		# not stroke the sloping edges of the polygon or add a clapper.
		for edge: Rect2 in [Rect2(15,8,60,3),Rect2(15,63,60,3),Rect2(15,8,3,58),Rect2(72,8,3,58)]:
			var box:=PackedVector2Array([edge.position,Vector2(edge.end.x,edge.position.y),edge.end,Vector2(edge.position.x,edge.end.y)])
			for shape: PackedVector2Array in Geometry2D.intersect_polygons(body,box): draw_colored_polygon(shape,INK)
		if wave_alpha>0:
			for side: int in [-1,1]:
				var center:=Vector2(-3 if side<0 else 93,15)
				var points:=PackedVector2Array()
				for i in range(17):
					var angle:=deg_to_rad(225+i*90.0/16)
					points.append(center+(Vector2(cos(angle)*9,sin(angle)*11)).rotated(deg_to_rad(side*40)))
				for i in range(16,-1,-1):
					var angle:=deg_to_rad(225+i*90.0/16)
					points.append(center+(Vector2(cos(angle)*6,sin(angle)*8)).rotated(deg_to_rad(side*40)))
				draw_colored_polygon(points,Color(INK,wave_alpha))
		draw_set_transform(Vector2.ZERO)
