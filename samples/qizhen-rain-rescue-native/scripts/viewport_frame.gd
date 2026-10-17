extends Control
const LOGICAL:=Vector2(960,540)
var mobile_controls: HBoxContainer
var mobile_caption: Label
func _ready() -> void:
	mobile_controls=HBoxContainer.new()
	mobile_controls.add_theme_constant_override("separation",8)
	mobile_controls.add_theme_font_override("font",load("res://assets/font.ttf"))
	for name: String in ["暂停","重播","跳过"]:
		var button:=Button.new()
		button.text=name;button.custom_minimum_size=Vector2(0,48)
		button.focus_mode=Control.FOCUS_NONE
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",17)
		mobile_controls.add_child(button)
	mobile_controls.get_child(0).pressed.connect(func() -> void:$Presentation.timeline.paused=not $Presentation.timeline.paused)
	mobile_controls.get_child(1).pressed.connect($Presentation.replay)
	mobile_controls.get_child(2).pressed.connect($Presentation.skip)
	add_child(mobile_controls)
	mobile_caption=Label.new();mobile_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	mobile_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	mobile_caption.add_theme_font_override("font",load("res://assets/font.ttf"))
	mobile_caption.add_theme_font_size_override("font_size",18)
	add_child(mobile_caption)
	resized.connect(_layout)
	_layout()
func _process(_dt: float) -> void:
	if mobile_caption!=null:
		mobile_caption.text=$Presentation._caption($Presentation.timeline.elapsed)
		mobile_controls.get_child(0).text="继续" if $Presentation.timeline.paused else "暂停"
func _layout() -> void:
	var view: Control=$Presentation
	var f: float=minf(size.x/LOGICAL.x,size.y/LOGICAL.y)
	view.size=LOGICAL
	view.scale=Vector2.ONE*f
	view.position=(size-LOGICAL*f)/2
	if mobile_controls==null:return
	var compact: bool=size.x<650 and size.y>size.x
	mobile_controls.visible=compact;mobile_caption.visible=compact
	if compact:
		view.position.y=maxf(40,(size.y-LOGICAL.y*f-160)/2)
		mobile_controls.position=Vector2(14,view.position.y+LOGICAL.y*f+76)
		mobile_controls.size=Vector2(size.x-28,48)
		mobile_caption.position=Vector2(20,view.position.y+LOGICAL.y*f+14)
		mobile_caption.size=Vector2(size.x-40,52)
