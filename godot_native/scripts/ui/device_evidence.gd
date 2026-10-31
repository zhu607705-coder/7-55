extends Control
## A loose sheet on the workbench opens the visual evidence. Reading is optional.
const Folio=preload("res://scripts/ui/chapter4_evidence_folio.gd")
const Type=preload("res://scripts/ui/native_typography.gd")
var puzzle_id:=""
var source:Dictionary={}
var opened:=false
var paper:Control
var cover:Button
var shade:ColorRect
var paper_scroll:ScrollContainer
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	shade=ColorRect.new();shade.color=Color(0,0,0,.5);shade.mouse_filter=Control.MOUSE_FILTER_STOP;shade.hide();add_child(shade)
	paper_scroll=ScrollContainer.new();paper_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(paper_scroll)
	paper=Folio.new();paper.puzzle_id=puzzle_id;paper.source=source;paper.visible=false;paper_scroll.add_child(paper)
	cover=Button.new();cover.set_meta("tactile_exempt",true);cover.text="残签";cover.tooltip_text="拿起 / 放回纸页";cover.focus_mode=Control.FOCUS_ALL
	var style:=StyleBoxFlat.new();style.bg_color=Color("ded2af");style.border_color=Color("8c7352");style.set_border_width_all(2);style.shadow_color=Color("2e3027");style.shadow_size=3;style.shadow_offset=Vector2(3,4)
	for state:String in ["normal","hover","pressed","focus"]:cover.add_theme_stylebox_override(state,style)
	cover.add_theme_font_override("font",Type.body_font());cover.add_theme_color_override("font_color",Color("443e30"))
	cover.pressed.connect(func():opened=not opened;layout_sheet())
	add_child(cover);resized.connect(layout_sheet);layout_sheet()
func layout_sheet()->void:
	if cover==null:return
	var scale_value:float=preload("res://scripts/ui/device_layout.gd").scale_for(size)
	cover.add_theme_font_size_override("font_size",roundi(20*scale_value))
	cover.text="放回" if opened else "残签"
	cover.size=Vector2(80,54)*scale_value
	cover.position=Vector2(20*scale_value,size.y-112*scale_value)
	shade.visible=opened;shade.size=size
	paper.visible=opened
	var width:float=minf(430*scale_value,size.x-32*scale_value)
	paper_scroll.visible=opened
	paper_scroll.position=Vector2(16*scale_value,118*scale_value)
	paper_scroll.size=Vector2(width,maxf(80,cover.position.y-paper_scroll.position.y-12*scale_value))
	paper.custom_minimum_size=Vector2(width-14,width-14)
	paper.size=paper.custom_minimum_size

func close_sheet()->void:
	opened=false;layout_sheet()
