extends Control
## A clipped thermal receipt is fed out by the owning game's clock.
## No local timer, tween, save write, or story intent lives in this view.
const PAPER_TEXTURE = preload("res://assets/native/checkin/checkin_receipt_v1.png")
const INK = Color("193f38")
const MUTED = Color("60766c")
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
		draw_line(Vector2(x,280),Vector2(x+10,343),Color("fffdf2",alpha*.75),3,true)

func _ready() -> void:
	name = "CheckinSuccessPresentation"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(430,820)
	theme=Theme.new();theme.default_font=preload("res://scripts/ui/native_typography.gd").body_font()
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
	var paper = _texture(receipt,PAPER_TEXTURE,Rect2(244,100,766,1059),Rect2(Vector2.ZERO,PAPER_SIZE))
	paper.name = "CheckinReceiptPaper"
	_label(receipt,"课堂签到回执",Rect2(20,25,264,28),17,INK).name = "CheckinReceiptCaption"
	_panel(receipt,Rect2(30,66,244,2),Color("59605b"))
	_panel(receipt,Rect2(30,72,244,1),Color("b0b3a9"))
	seal = Control.new(); seal.name = "CheckinPrintedStamp"
	seal.position = Vector2(35,272); seal.size = Vector2(234,78)
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE; receipt.add_child(seal)
	stamp_outline = _panel(seal,Rect2(0,0,234,78),Color.TRANSPARENT,Color("3c4340"),2)
	stamp_outline.name = "CheckinPrintedStampFrame"
	stamp_outline.get_theme_stylebox("panel").set_border_width_all(2)
	_panel(seal,Rect2(5,5,224,68),Color.TRANSPARENT,Color("59605b"),0)
	headline = _label(seal,"签到成功",Rect2(8,12,218,54),35,Color("3c4340"))
	headline.name = "CheckinSuccessLabel"
	detail = Control.new(); detail.name = "CheckinReceiptDetails"; detail.size = PAPER_SIZE
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE; receipt.add_child(detail)
	_label(detail,"高等数学（早八特供版）",Rect2(16,91,272,32),17,INK)
	_label(detail,"签到",Rect2(30,151,100,28),15,MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label(detail,"07:55",Rect2(174,151,100,28),18,INK).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_panel(detail,Rect2(30,187,244,1),Color("d0d0c2"))
	_label(detail,"校园网",Rect2(30,199,100,28),15,MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label(detail,"已接入",Rect2(174,199,100,28),15,INK).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label(detail,"课程记录已提交",Rect2(20,367,264,26),14,MUTED)
	ink_finish = InkFinish.new(); ink_finish.name = "CheckinPrintedInkFinish"
	ink_finish.size = PAPER_SIZE; ink_finish.mouse_filter = Control.MOUSE_FILTER_IGNORE; receipt.add_child(ink_finish)
	# The machine is in front of the moving paper. Its dark opening is exactly
	# above the mask, so nothing can appear to arrive from the surrounding air.
	var machine = _panel(self,Rect2(34,130,362,50),Color("e4e9df"),Color("c5d0c1"),12)
	machine.name = "CheckinPrinterBody"; machine.z_index = 10
	_panel(machine,Rect2(14,7,334,1),Color("f9fbf5"))
	printer_slot = _panel(self,Rect2(49,166,332,14),Color("1e3932"),Color("9bab9b"),5)
	printer_slot.name = "CheckinPrinterSlot"; printer_slot.z_index = 11
	_panel(printer_slot,Rect2(8,2,316,3),Color("0f241f"),Color.TRANSPARENT,1)
	print_head = _panel(self,Rect2(63,178,304,2),Color("99b4a2"))
	print_head.name = "CheckinPrintHead"; print_head.z_index = 12
	head_cursor = _panel(print_head,Rect2(0,0,32,2),Color("e3e8c9"))
	head_cursor.name = "CheckinPrintHeadReflection"
	pause_card = _panel(self,Rect2(50,294,330,230),Color("faf8ef"),Color("ccd7cc"),22)
	pause_card.name = "CheckinSuccessPause"
	var pause_style: StyleBoxFlat = pause_card.get_theme_stylebox("panel")
	pause_style.shadow_color = Color("15372e",.12); pause_style.shadow_size = 24
	_label(pause_card,"已暂停",Rect2(20,26,290,38),25,INK)
	_label(pause_card,"继续后从这里播放",Rect2(20,83,290,26),14,MUTED)
	pose(0.0,false,false)

func _texture(parent: Control,texture: Texture2D,region: Rect2,rect: Rect2) -> TextureRect:
	var atlas = AtlasTexture.new(); atlas.atlas = texture; atlas.region = region
	var object = TextureRect.new(); object.texture = atlas; object.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; object.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	object.position = rect.position; object.size = rect.size; object.mouse_filter = Control.MOUSE_FILTER_IGNORE
	object.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR; parent.add_child(object); return object

func _panel(parent: Control,rect: Rect2,fill: Color,border: Color=Color.TRANSPARENT,radius: int=0) -> Panel:
	var panel = Panel.new(); panel.position = rect.position; panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new(); style.bg_color = fill; style.border_color = border
	style.set_border_width_all(1 if border.a>0 else 0); style.set_corner_radius_all(radius)
	panel.add_theme_stylebox_override("panel",style); parent.add_child(panel); return panel

func _label(parent: Control,text: String,rect: Rect2,font_size: int,color: Color) -> Label:
	var label = Label.new(); label.text = text; label.position = rect.position; label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE; label.add_theme_font_size_override("font_size",font_size); label.add_theme_color_override("font_color",color)
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
	draw_rect(Rect2(0,0,430,820),Color("f1f4ed"))
	# Quiet machine shadow and feed guide stay behind the real clipped paper.
	draw_style_box(_shadow_box(),Rect2(45,146,340,39))
	draw_line(Vector2(63,608),Vector2(367,608),Color("d9e2d5"),1,true)

func _shadow_box() -> StyleBoxFlat:
	var style = StyleBoxFlat.new(); style.bg_color = Color.TRANSPARENT
	style.set_corner_radius_all(12); style.shadow_color = Color("173d30",.08); style.shadow_size = 10
	return style

func read_presentation() -> Dictionary:
	return {"seconds":sample_time,"reduced_motion":reduced_motion,"receipt_position":receipt.position,"seal_scale":seal.scale,"paused":pause_card.visible,"print_progress":print_progress,"visible_paper_height":visible_paper_height,"leading_edge_y":PAPER_ORIGIN.y+visible_paper_height,"print_complete":print_complete,"ink_progress":ink_progress,"printer_slot":Rect2(printer_slot.position,printer_slot.size),"print_mask":Rect2(print_mask.position,print_mask.size),"paper_axis_aligned":receipt.rotation==0.0 and receipt.scale==Vector2.ONE}
