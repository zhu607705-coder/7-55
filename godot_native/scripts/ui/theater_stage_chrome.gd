extends RefCounted
## Screen-space paper captions and navigation. Stage objects remain untouched.
const PaperInk=preload("res://scripts/ui/paper_ink_material.gd")
const INK=PaperInk.INK
const PAPER=PaperInk.PAPER

class PaperSurface extends Control:
	var caption_rail:=false
	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw()->void:
		var bounds:=Rect2(Vector2.ZERO,size)
		# Identical bounds to the previous title/caption rail; no extra curtain cover.
		draw_rect(bounds,PAPER)
		PaperInk.draw_panel(get_canvas_item(),bounds)

static func surface(caption_rail:bool=false)->Control:
	var node:=PaperSurface.new();node.caption_rail=caption_rail;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return node

static func button(id:String,text:String,action:Callable)->Button:
	var node:=Button.new();node.name=id;node.text=text
	if id!="PerformanceProgramme":
		node.set_meta("tactile_paper_ink",true)
		node.set_meta("tactile_variant","secondary")
	# Native Button owns text alignment, drawing and pointer hit area.
	# Preserve the performance root as the existing keyboard/QTE owner.
	# The complete key scales with the stage frame; no separate floating label.
	node.alignment=HORIZONTAL_ALIGNMENT_CENTER;node.focus_mode=Control.FOCUS_NONE
	for state:String in ["normal","hover","pressed","focus","disabled"]:
		var style:=StyleBoxEmpty.new()
		style.content_margin_left=14;style.content_margin_right=14
		style.content_margin_top=8;style.content_margin_bottom=8
		node.add_theme_stylebox_override(state,style)
	for state:String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:node.add_theme_color_override(state,INK)
	node.add_theme_color_override("font_disabled_color",PaperInk.SOFT_INK)
	node.pressed.connect(action)
	return node
