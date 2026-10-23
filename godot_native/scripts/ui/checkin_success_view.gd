extends Control
## A fine-pixel parchment receipt is fed out by the owning game's clock.
## No local timer, tween, save write, or story intent lives in this view.
const PIXEL_FONT=preload("res://ui_assets/fonts/MorningNote-Regular.ttf")
static var paper_texture:ImageTexture
const INK = Color("44332D")
const MUTED = Color("70503B")
const DURATION = 3.8
const PRINT_DURATION = 1.8
const FINISH_START = 1.82
const FINISH_DURATION = .42
const PAPER_SIZE = Vector2(304,420)
const PAPER_ORIGIN = Vector2(63,180)
var receipt: Control
var seal: Control
var headline: Label
var detail: Control
var pause_card: Panel
var print_mask: Control
var printer_slot: Panel
var print_head: Panel
var head_cursor: Panel
var stamp_outline: Panel
var ink_finish: Control
var sample_time = 0.0
var reduced_motion = false
var print_progress = 0.0
var visible_paper_height = 0.0
var print_complete = false
var ink_progress = 0.0

class InkFinish extends Control:
	var progress = 0.0
	var active = false
	func _draw() -> void:
		if not active: return
		var alpha = sin(progress*PI)
		# One restrained paper reflection across the printed lettering.
		var x = 48+progress*204
		for row:int in range(0,64,4):
			draw_rect(Rect2(int(x)+int(row/8),280+row,2,3),Color("FFF0B2",alpha*.75))

func _ready() -> void:
	name = "CheckinSuccessPresentation"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(430,820)
	theme=Theme.new();theme.default_font=PIXEL_FONT
	_label(self,"学在浙大",Rect2(36,48,358,24),14,MUTED).name = "CheckinSuccessApp"
	_label(self,"课堂签到",Rect2(36,80,358,42),29,INK).name = "CheckinSuccessHeading"
	# Paper keeps its full size. A growing clipped feed region and a small
	# downward advance expose the caption/course before the final printed mark.
	print_mask = Control.new(); print_mask.name = "CheckinPrintMask"
	print_mask.position = PAPER_ORIGIN; print_mask.size = PAPER_SIZE
	print_mask.clip_contents = true; print_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(print_mask)
	receipt = Control.new(); receipt.name = "CheckinReceiptObject"; receipt.size = PAPER_SIZE
	receipt.mouse_filter = Control.MOUSE_FILTER_IGNORE; print_mask.add_child(receipt)
	var paper = _texture(receipt,parchment_texture(),Rect2(Vector2.ZERO,PAPER_SIZE),Rect2(Vector2.ZERO,PAPER_SIZE))
	paper.name = "CheckinReceiptPaper"
	_label(receipt,"课堂签到回执",Rect2(20,25,264,28),17,INK).name = "CheckinReceiptCaption"
	_panel(receipt,Rect2(30,66,244,2),Color("A1744E"))
	_panel(receipt,Rect2(30,72,244,1),Color("D8C7A0"))
	seal = Control.new(); seal.name = "CheckinPrintedStamp"
	seal.position = Vector2(35,272); seal.size = Vector2(234,78)
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE; receipt.add_child(seal)
	stamp_outline = _panel(seal,Rect2(0,0,234,78),Color.TRANSPARENT,Color("9A514A"),2)
	stamp_outline.name = "CheckinPrintedStampFrame"
	stamp_outline.get_theme_stylebox("panel").set_border_width_all(2)
	_panel(seal,Rect2(5,5,224,68),Color.TRANSPARENT,Color("A1744E"),0)
	headline = _label(seal,"签到成功",Rect2(8,12,218,54),35,Color("9A514A"))
	headline.name = "CheckinSuccessLabel"
	detail = Control.new(); detail.name = "CheckinReceiptDetails"; detail.size = PAPER_SIZE
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE; receipt.add_child(detail)
	_label(detail,"高等数学（早八特供版）",Rect2(16,91,272,32),17,INK)
	_label(detail,"签到",Rect2(30,151,100,28),15,MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label(detail,"07:55",Rect2(174,151,100,28),18,INK).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_panel(detail,Rect2(30,187,244,1),Color("D8C7A0"))
	_label(detail,"校园网",Rect2(30,199,100,28),15,MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label(detail,"已接入",Rect2(174,199,100,28),15,INK).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label(detail,"课程记录已提交",Rect2(20,367,264,26),14,MUTED)
	ink_finish = InkFinish.new(); ink_finish.name = "CheckinPrintedInkFinish"
	ink_finish.size = PAPER_SIZE; ink_finish.mouse_filter = Control.MOUSE_FILTER_IGNORE; receipt.add_child(ink_finish)
	# The machine is in front of the moving paper. Its dark opening is exactly
	# above the mask, so nothing can appear to arrive from the surrounding air.
	var machine = _panel(self,Rect2(34,130,362,50),Color("C5C1A9"),Color("7993A1"),12)
	machine.name = "CheckinPrinterBody"; machine.z_index = 10
	_panel(machine,Rect2(14,7,334,1),Color("E8E0C8"))
	printer_slot = _panel(self,Rect2(49,166,332,14),Color("344452"),Color("7993A1"),5)
	printer_slot.name = "CheckinPrinterSlot"; printer_slot.z_index = 11
	_panel(printer_slot,Rect2(8,2,316,3),Color("202B35"),Color.TRANSPARENT,1)
	print_head = _panel(self,Rect2(63,178,304,2),Color("A1744E"))
	print_head.name = "CheckinPrintHead"; print_head.z_index = 12
	head_cursor = _panel(print_head,Rect2(0,0,32,2),Color("F4CD77"))
	head_cursor.name = "CheckinPrintHeadReflection"
	pause_card = _panel(self,Rect2(50,294,330,230),Color("F4EAD5"),Color("A1744E"),22)
	pause_card.name = "CheckinSuccessPause"
	var pause_style: StyleBoxFlat = pause_card.get_theme_stylebox("panel")
	pause_style.shadow_color = Color("70503B",.2); pause_style.shadow_size = 2;pause_style.shadow_offset=Vector2(3,3)
	_label(pause_card,"已暂停",Rect2(20,26,290,38),25,INK)
	_label(pause_card,"继续后从这里播放",Rect2(20,83,290,26),14,MUTED)
	pose(0.0,false,false)

static func parchment_texture()->ImageTexture:
	if paper_texture==null:paper_texture=ImageTexture.create_from_image(paint_parchment())
	return paper_texture

static func paint_parchment()->Image:
	# Native304x420 pixels, not a small sheet enlarged or a filtered photo.
	# Transparent stepped tears surround a quiet writing surface.
	var image:=Image.create(304,420,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y:int in range(420):
		var left:int=2+(2 if y%71>=10 and y%71<17 else 0)+(1 if y%17<3 else 0)
		var right:int=301-(2 if y%59>=25 and y%59<31 else 0)
		for x:int in range(left,right+1):
			var top:int=2+(2 if int(x/7)%5==0 else 0)
			var bottom:int=417-(3 if int(x/6)%3==0 else 0)
			if y<top or y>bottom:continue
			var edge:int=mini(mini(x-left,right-x),mini(y-top,bottom-y))
			var color:=Color("F4EAD5")
			if edge==0:color=Color("A1744E")
			elif edge<2:color=Color("C79B62")
			elif edge<6:color=Color("D8C7A0")
			elif edge<11 and (x*13+y*7)%11<6:color=Color("E8E0C8")
			elif (x*17+y*31)%991<3:color=Color("E8E0C8")
			image.set_pixel(x,y,color)
	return image

func _texture(parent: Control,texture: Texture2D,region: Rect2,rect: Rect2) -> TextureRect:
	var atlas = AtlasTexture.new(); atlas.atlas = texture; atlas.region = region
	var object = TextureRect.new(); object.texture = atlas; object.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; object.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	object.position = rect.position; object.size = rect.size; object.mouse_filter = Control.MOUSE_FILTER_IGNORE
	object.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; parent.add_child(object); return object

func _panel(parent: Control,rect: Rect2,fill: Color,border: Color=Color.TRANSPARENT,radius: int=0) -> Panel:
	var panel = Panel.new(); panel.position = rect.position; panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new(); style.bg_color = fill; style.border_color = border
	style.set_border_width_all(1 if border.a>0 else 0); style.set_corner_radius_all(0);style.anti_aliasing=false
	panel.add_theme_stylebox_override("panel",style); parent.add_child(panel); return panel

func _label(parent: Control,text: String,rect: Rect2,font_size: int,color: Color) -> Label:
	var label = Label.new(); label.text = text; label.position = rect.position; label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE;label.add_theme_font_override("font",PIXEL_FONT); label.add_theme_font_size_override("font_size",font_size); label.add_theme_color_override("font_color",color)
	parent.add_child(label); return label

func pose(seconds: float,reduced: bool,frozen: bool) -> void:
	if not is_instance_valid(receipt): return
	sample_time = maxf(0,seconds); reduced_motion = reduced
	print_progress = 1.0 if reduced else clampf(sample_time/PRINT_DURATION,0,1)
	visible_paper_height = PAPER_SIZE.y*print_progress
	print_complete = print_progress>=1.0
	print_mask.size = Vector2(PAPER_SIZE.x,visible_paper_height)
	receipt.position = Vector2(0,-20*(1.0-print_progress))
	receipt.rotation = 0.0; receipt.scale = Vector2.ONE; receipt.modulate.a = 1.0
	# Ink belongs to the paper from the first pixel. The mask alone reveals it;
	# there is no hovering badge, falling stamp or second alpha-fade entrance.
	ink_progress = clampf((visible_paper_height-receipt.position.y-seal.position.y)/seal.size.y,0,1)
	seal.scale = Vector2.ONE; seal.modulate.a = 1.0
	stamp_outline.modulate.a = 1.0; headline.modulate.a = 1.0; detail.modulate.a = 1.0
	print_head.visible = not reduced and sample_time>0 and not print_complete
	head_cursor.position.x = (print_head.size.x-head_cursor.size.x)*(.5-.5*cos(print_progress*TAU*5))
	ink_finish.active = not reduced and sample_time>=FINISH_START and sample_time<FINISH_START+FINISH_DURATION
	ink_finish.progress = clampf((sample_time-FINISH_START)/FINISH_DURATION,0,1); ink_finish.queue_redraw()
	pause_card.visible = frozen
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0,0,430,820),Color("E8E0C8"))
	# Quiet machine shadow and feed guide stay behind the real clipped paper.
	draw_style_box(_shadow_box(),Rect2(45,146,340,39))
	draw_line(Vector2(63,608),Vector2(367,608),Color("D8C7A0"),1,false)

func _shadow_box() -> StyleBoxFlat:
	var style = StyleBoxFlat.new(); style.bg_color = Color.TRANSPARENT
	style.set_corner_radius_all(0);style.anti_aliasing=false; style.shadow_color = Color("70503B",.2); style.shadow_size = 2;style.shadow_offset=Vector2(2,3)
	return style

func read_presentation() -> Dictionary:
	return {"seconds":sample_time,"reduced_motion":reduced_motion,"receipt_position":receipt.position,"seal_scale":seal.scale,"paused":pause_card.visible,"print_progress":print_progress,"visible_paper_height":visible_paper_height,"leading_edge_y":PAPER_ORIGIN.y+visible_paper_height,"print_complete":print_complete,"ink_progress":ink_progress,"printer_slot":Rect2(printer_slot.position,printer_slot.size),"print_mask":Rect2(print_mask.position,print_mask.size),"paper_axis_aligned":receipt.rotation==0.0 and receipt.scale==Vector2.ONE}
