extends Control
## Independent scene chooser. Never resets, advances, or saves story state.
const STORY_SCENE := "res://scenes/main.tscn"
const BUCT_SCENE := "res://campuses/buct/scenes/playable.tscn"
const HAIDIAN_SCENE := "res://campuses/buct_haidian/scenes/playable.tscn"
const CHANGPING_SCENE := "res://campuses/buct_changping/scenes/playable.tscn"
var opening := false
var card: PanelContainer
var story_button: Button
var campus_button: Button
var haidian_button: Button
var changping_button: Button
var content: VBoxContainer
var title: Label
var detail: Label

func _ready() -> void:
	# Preserve established direct-entry launch arguments for QA and story recovery.
	if not get_tree().root.has_meta("entry_arguments_consumed"):
		get_tree().root.set_meta("entry_arguments_consumed",true)
		for argument in OS.get_cmdline_user_args():
			if argument in ["--fresh","--story","--screenshot"] or argument.begins_with("--preview=") or argument.begins_with("--checkpoint=") or argument.begins_with("--page="):
				open_story.call_deferred()
	var font: Font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	theme=Theme.new();theme.default_font=font;theme.default_font_size=20
	var background:=ColorRect.new();background.color=Color("101e28")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	card=PanelContainer.new();add_child(card)
	var style:=StyleBoxFlat.new();style.bg_color=Color("f1f0e5");style.set_corner_radius_all(16)
	style.content_margin_left=24;style.content_margin_right=24;style.content_margin_top=28;style.content_margin_bottom=28
	card.add_theme_stylebox_override("panel",style)
	content=VBoxContainer.new();content.add_theme_constant_override("separation",18);card.add_child(content)
	title=Label.new();title.text="7:55";title.add_theme_font_size_override("font_size",42);title.add_theme_color_override("font_color",Color("284e48"));content.add_child(title)
	var subtitle:=Label.new();subtitle.text="选择入口";subtitle.add_theme_color_override("font_color",Color("435f56"));content.add_child(subtitle)
	story_button=_button("继续《7:55》",open_story);story_button.name="ContinueStory";content.add_child(story_button)
	campus_button=_button("朝阳校园漫游",open_campus);campus_button.name="OpenBuctCampus";content.add_child(campus_button)
	haidian_button=_button("海淀校园漫游",open_haidian);haidian_button.name="OpenBuctHaidian";content.add_child(haidian_button)
	changping_button=_button("昌平校园漫游",open_changping);changping_button.name="OpenBuctChangping";content.add_child(changping_button)
	detail=Label.new();detail.text="三处校园均为独立漫游\n原有剧情与存档保持不变"
	detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.add_theme_font_size_override("font_size",17);detail.add_theme_color_override("font_color",Color("435f56"));content.add_child(detail)
	resized.connect(_layout);card.minimum_size_changed.connect(_layout.call_deferred)
	_layout.call_deferred();story_button.grab_focus()

func _button(text: String, action: Callable) -> Button:
	var result:=Button.new();result.text=text;result.custom_minimum_size.y=58
	result.pressed.connect(action)
	return result

func _layout() -> void:
	if not is_inside_tree() or not is_instance_valid(card):return
	var available:=get_viewport_rect().size
	var width:=minf(500,available.x-32)
	var short:=available.y<500
	content.add_theme_constant_override("separation",6 if short else 18)
	title.add_theme_font_size_override("font_size",28 if short else 42)
	detail.add_theme_font_size_override("font_size",15 if short else 17)
	story_button.custom_minimum_size.y=44 if short else 58
	campus_button.custom_minimum_size.y=44 if short else 58
	haidian_button.custom_minimum_size.y=44 if short else 58
	changping_button.custom_minimum_size.y=44 if short else 58
	var panel_style: StyleBoxFlat=card.get_theme_stylebox("panel")
	panel_style.content_margin_top=12 if short else 28
	panel_style.content_margin_bottom=12 if short else 28
	card.size=Vector2(width,0)
	card.position=Vector2((available.x-width)/2,maxf(12,(available.y-card.get_combined_minimum_size().y)/2))

func open_story() -> void:
	_open(STORY_SCENE)

func open_campus() -> void:
	_open(BUCT_SCENE)

func open_haidian() -> void:
	_open(HAIDIAN_SCENE)

func open_changping() -> void:
	_open(CHANGPING_SCENE)

func _open(path: String) -> void:
	if opening:return
	opening=true
	_change_scene.call_deferred(path)

func _change_scene(path: String) -> void:
	var error:=get_tree().change_scene_to_file(path)
	if error!=OK:
		opening=false
		detail.text="暂时无法打开，请重试（%s）"%error
