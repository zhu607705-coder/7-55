extends Control
## Independent scene chooser. Never resets, advances, or saves story state.
const STORY_SCENE := "res://scenes/main.tscn"
const BUCT_SCENE := "res://campuses/buct/scenes/playable.tscn"
const HAIDIAN_SCENE := "res://campuses/buct_haidian/scenes/playable.tscn"
const CHANGPING_SCENE := "res://campuses/buct_changping/scenes/playable.tscn"
const FOLDED_SCENE := "res://scenes/chapter4_folded_chase_preview.tscn"
const ENDLESS_SCENE := "res://scenes/chapter4_endless_stair_preview.tscn"
const TREE_PILOT_SCENE := "res://campuses/buct_pilots/chaoyang/scenes/promenade.tscn"
var opening := false
var previews_open := false
var closing_preview := false
var preview_instance: Node
var preview_bar: CanvasLayer
var preview_menu: VBoxContainer
var preview_scroll: ScrollContainer
var preview_rows: VBoxContainer
var preview_status: Label
var preview_back: Button
var preview_button: Button
var subtitle: Label
var card: PanelContainer
var story_button: Button
var campus_button: Button
var haidian_button: Button
var changping_button: Button
var content: VBoxContainer
var title: Label
var detail: Label

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	# Preserve established direct-entry launch arguments for QA and story recovery.
	if not get_tree().root.has_meta("entry_arguments_consumed"):
		get_tree().root.set_meta("entry_arguments_consumed",true)
		for argument in OS.get_cmdline_user_args():
			if argument in ["--fresh","--story","--screenshot"] or argument.begins_with("--preview=") or argument.begins_with("--checkpoint=") or argument.begins_with("--page="):
				open_story.call_deferred()
	var font: Font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	theme=Theme.new();theme.default_font=font;theme.default_font_size=20
	var background:=ColorRect.new();background.mouse_filter=Control.MOUSE_FILTER_IGNORE;background.color=Color("101e28")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	card=PanelContainer.new();add_child(card)
	var style:=StyleBoxFlat.new();style.bg_color=Color("f1f0e5");style.set_corner_radius_all(16)
	style.content_margin_left=24;style.content_margin_right=24;style.content_margin_top=28;style.content_margin_bottom=28
	card.add_theme_stylebox_override("panel",style)
	content=VBoxContainer.new();content.add_theme_constant_override("separation",18);card.add_child(content)
	title=Label.new();title.text="7:55";title.add_theme_font_size_override("font_size",42);title.add_theme_color_override("font_color",Color("284e48"));content.add_child(title)
	subtitle=Label.new();subtitle.text="选择入口";subtitle.add_theme_color_override("font_color",Color("435f56"));content.add_child(subtitle)
	story_button=_button("继续《7:55》",open_story);story_button.name="ContinueStory";content.add_child(story_button)
	campus_button=_button("朝阳校园漫游",open_campus);campus_button.name="OpenBuctCampus";content.add_child(campus_button)
	haidian_button=_button("海淀校园漫游",open_haidian);haidian_button.name="OpenBuctHaidian";content.add_child(haidian_button)
	changping_button=_button("昌平校园漫游",open_changping);changping_button.name="OpenBuctChangping";content.add_child(changping_button)
	preview_button=_button("动画与原型预览",open_previews);preview_button.name="OpenPrototypePreviews";content.add_child(preview_button)
	detail=Label.new();detail.text="三处校园均为独立漫游\n原有剧情与存档保持不变"
	detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.add_theme_font_size_override("font_size",17);detail.add_theme_color_override("font_color",Color("435f56"));content.add_child(detail)
	_build_preview_menu()
	resized.connect(_layout);card.minimum_size_changed.connect(_layout.call_deferred)
	_layout.call_deferred();story_button.grab_focus()

func _button(text: String, action: Callable) -> Button:
	var result:=Button.new();result.text=text;result.custom_minimum_size.y=58
	result.clip_text=true;result.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	result.pressed.connect(action)
	return result

func _layout() -> void:
	if not is_inside_tree() or not is_instance_valid(card) or not card.visible:return
	var available:=get_viewport_rect().size
	var width:=minf(640 if previews_open else 500,available.x-32)
	var compact:=available.y<740
	content.add_theme_constant_override("separation",6 if compact else 18)
	title.add_theme_font_size_override("font_size",28 if compact else 42)
	detail.add_theme_font_size_override("font_size",15 if compact else 17)
	detail.visible=available.y>=500
	subtitle.visible=available.y>=420
	for button: Button in [story_button,campus_button,haidian_button,changping_button,preview_button]:
		button.custom_minimum_size.y=44 if compact else 58
	var panel_style: StyleBoxFlat=card.get_theme_stylebox("panel")
	panel_style.content_margin_top=12 if compact else 28
	panel_style.content_margin_bottom=12 if compact else 28
	if previews_open:
		preview_scroll.custom_minimum_size=Vector2(0,maxf(90,minf(540,available.y-210)))
	card.size=Vector2(width,0)
	card.position=Vector2((available.x-width)/2,maxf(12,(available.y-card.get_combined_minimum_size().y)/2))

func _build_preview_menu() -> void:
	preview_menu=VBoxContainer.new();preview_menu.visible=false
	preview_menu.add_theme_constant_override("separation",10);card.add_child(preview_menu)
	var heading:=Label.new();heading.text="动画与原型预览"
	heading.add_theme_font_size_override("font_size",26);heading.add_theme_color_override("font_color",Color("284e48"));preview_menu.add_child(heading)
	preview_back=_button("返回入口",close_previews);preview_back.name="ClosePrototypePreviews";preview_back.custom_minimum_size.y=44;preview_menu.add_child(preview_back)
	preview_scroll=ScrollContainer.new();preview_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	preview_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;preview_menu.add_child(preview_scroll)
	preview_rows=VBoxContainer.new();preview_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	preview_rows.add_theme_constant_override("separation",10);preview_scroll.add_child(preview_rows)
	_add_preview("折叠楼梯与手机灯","四跑追逐、保安手电和手机近身照明",_open_preview.bind(FOLDED_SCENE))
	_add_preview("无尽楼梯","十二跑楼梯与快慢保安追逐",_open_preview.bind(ENDLESS_SCENE))
	_add_preview("朝阳双树与学生","独立分层树冠、暖棕树干、四向学生与导览",_open_preview.bind(TREE_PILOT_SCENE))
	_add_preview("启真湖追逐","独立工程，在新窗口打开",_launch_example.bind("examples/qizhen_playable_chase"))
	_add_preview("启真湖大地图","独立工程，在新窗口打开",_launch_example.bind("examples/qizhen_large_world"))
	_add_preview("Blender 楼梯","独立工程，在新窗口打开",_launch_example.bind("examples/blender_stair_sample/preview"))
	_add_preview("Blender 启真湖近岸","划离平台、取回防水袋与系泊；新窗口打开",_launch_example.bind("examples/qizhen_blender_nearshore/preview"))
	_add_preview("早期剧院空间实验","保留原始空间迁移实验；新窗口打开",_launch_example.bind("examples/legacy_godot_theater/godot-port"))
	preview_status=Label.new();preview_status.text="预览独立于剧情，完成样例不推进章节。"
	preview_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;preview_status.add_theme_font_size_override("font_size",15)
	preview_status.add_theme_color_override("font_color",Color("435f56"));preview_rows.add_child(preview_status)

func _add_preview(text: String, description: String, action: Callable) -> void:
	var button:=_button(text,action);preview_rows.add_child(button)
	var label:=Label.new();label.text=description;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",15);label.add_theme_color_override("font_color",Color("435f56"));preview_rows.add_child(label)

func open_previews() -> void:
	if opening:return
	previews_open=true;content.hide();preview_menu.show();_layout.call_deferred();preview_back.grab_focus()

func close_previews() -> void:
	previews_open=false;preview_menu.hide();content.show();_layout.call_deferred();preview_button.grab_focus()

func _open_preview(path: String) -> void:
	if opening or is_instance_valid(preview_instance):return
	var resource:=load(path) as PackedScene
	if resource==null:
		preview_status.text="预览资源暂不可用："+path
		return
	preview_instance=resource.instantiate()
	if preview_instance.has_signal("exited"):preview_instance.connect("exited",_close_preview)
	card.hide();add_child(preview_instance)
	preview_bar=CanvasLayer.new();preview_bar.layer=30;add_child(preview_bar)
	var back:=_button("返回预览目录",_request_preview_exit);back.custom_minimum_size=Vector2(168,44);back.position=Vector2(12,12)
	preview_bar.add_child(back)

func _request_preview_exit() -> void:
	if not is_instance_valid(preview_instance):return
	if preview_instance.has_method("_request_exit"):
		preview_instance.call("_request_exit")
	else:
		if preview_instance.has_method("_release_movement"):preview_instance.call("_release_movement")
		_close_preview()

func _close_preview() -> void:
	# Defer destruction but immediately stop callbacks; the preview's own exit
	# clears input/audio without quitting because the entry remains current_scene.
	if closing_preview or not is_instance_valid(preview_instance):return
	closing_preview=true
	preview_instance.process_mode=Node.PROCESS_MODE_DISABLED
	preview_instance.queue_free();preview_instance=null
	if is_instance_valid(preview_bar):preview_bar.queue_free();preview_bar=null
	closing_preview=false
	card.show();_layout.call_deferred();preview_back.grab_focus.call_deferred()

func _launch_example(relative_path: String) -> void:
	var repository:=ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir()
	var project:=repository.path_join(relative_path)
	if not FileAccess.file_exists(project.path_join("project.godot")):
		preview_status.text="此安装包未附带独立工程。源码位置："+relative_path
		return
	if not OS.has_feature("editor"):
		preview_status.text="独立工程请用 Godot 编辑器打开："+relative_path
		return
	if relative_path.ends_with("legacy_godot_theater/godot-port") and not FileAccess.file_exists(project.path_join("generated/theater.json")):
		preview_status.text="剧院实验尚需导出素材，请按 examples/legacy_godot_theater/README.md 完成准备。"
		return
	var process:=OS.create_process(OS.get_executable_path(),PackedStringArray(["--path",project]))
	preview_status.text="已在独立窗口打开；关闭样例后可继续选择。" if process>0 else "暂时无法启动独立窗口。源码位置："+relative_path

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_ESCAPE and previews_open and not is_instance_valid(preview_instance):
		close_previews();get_viewport().set_input_as_handled()

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
