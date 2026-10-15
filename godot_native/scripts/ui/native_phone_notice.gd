extends RefCounted
## Source phone notification composition from subtitles.css and
## SubtitleSpeakerIcon.tsx. Pure presentation: no queue, timing or story state.
const FONT=preload("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const INK=Color("222322")
const PAPER=Color("fff8e2",.85)
const SPEAKERS={"system":"系统","narrator":"旁白","task":"任务","success":"记录","error":"提示","broadcast":"广播","player":"我","xiaoying":"小影"}
const ICONS={
	"系统":"M4 3h8v10H4z M2 1h2v3H2z M6 0h1v3H6z M9 0h1v3H9z M12 1h2v3h-2z M0 5h3v1H0z M0 9h3v1H0z M13 5h3v1h-3z M13 9h3v1h-3z M5 14h1v2H5z M10 14h1v2h-1z",
	"小影":"M7 0h2v4h2v2h4v2h-4v2H9v5H7v-5H5V8H1V6h4V4h2z M13 12h2v2h-2z",
	"旁白":"M1 2h6v6H4v3H1V7h1V5H1z M9 2h6v6h-3v3H9V7h1V5H9z",
	"任务":"M4 1h8v2h2v12H2V3h2z M6 0h4v4H6z",
	"记录":"M1 2h5v1h1v11H6v-1H1z M10 2h5v11h-5v1H9V3h1z",
	"提示":"M7 1h2v8H7z M7 12h2v3H7z",
	"广播":"M1 6h4l5-4h2v12h-2l-5-4H1z M4 11h2v4H4z M14 5h2v6h-2z",
	"我":"M6 1h4v1h2v5h-2v2H6V7H4V2h2z M4 10h8v2h2v3H2v-3h2z",
}
static var _icons: Dictionary={}

static func create(text: String="",speaker: String="系统") -> Label:
	var label:=Label.new()
	label.name="PhoneNotification"
	label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",FONT)
	label.add_theme_font_size_override("font_size",16)
	label.add_theme_color_override("font_color",INK)
	label.add_theme_constant_override("line_spacing",2)
	var card:=Ui.box(PAPER,INK,2)
	card.content_margin_left=66; card.content_margin_right=10
	card.content_margin_top=37; card.content_margin_bottom=8
	card.shadow_color=Color("775c31",.25); card.shadow_offset=Vector2(2,2); card.shadow_size=0
	label.add_theme_stylebox_override("normal",card)
	var avatar:=Panel.new(); avatar.name="NoticeAvatar"; avatar.size=Vector2(36,36); avatar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	avatar.add_theme_stylebox_override("panel",Ui.box(Color.TRANSPARENT,INK,2)); label.add_child(avatar)
	var icon:=TextureRect.new(); icon.name="Icon"; icon.position=Vector2(8,8); icon.size=Vector2(20,20); icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST; icon.mouse_filter=Control.MOUSE_FILTER_IGNORE; avatar.add_child(icon)
	var heading:=Label.new(); heading.name="NoticeSpeaker"; heading.mouse_filter=Control.MOUSE_FILTER_IGNORE
	heading.add_theme_font_override("font",FONT); heading.add_theme_font_size_override("font_size",16); heading.add_theme_color_override("font_color",INK)
	label.add_child(heading)
	set_message(label,text,speaker)
	return label

static func icon_for(speaker: String) -> Texture2D:
	if _icons.has(speaker): return _icons[speaker]
	var cutout: String='<path d="M6 5h4v6H6z" fill="#fff8e2"/>' if speaker=="系统" else '<path d="M5 7h6v1H5z M5 10h5v1H5z" fill="#fff8e2"/>' if speaker=="任务" else ""
	var svg: String='<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16"><path d="'+str(ICONS.get(speaker,ICONS["系统"]))+'" fill="#222322" fill-rule="evenodd"/>'+cutout+'</svg>'
	var image:=Image.new()
	if image.load_svg_from_string(svg)!=OK: return null
	var texture:=ImageTexture.create_from_image(image)
	_icons[speaker]=texture
	return texture

static func set_message(label: Label,text: String,speaker: String="系统") -> void:
	label.text=text
	label.visible=not text.is_empty()
	label.get_node("NoticeSpeaker").text=speaker
	label.get_node("NoticeAvatar/Icon").texture=icon_for(speaker)

static func layout(label: Label,width: float) -> Vector2:
	var inner_width:=maxf(24,width-76)
	var measured:=FONT.get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,inner_width,16)
	var line_count:=maxi(1,ceili(measured.y/FONT.get_height(16)))
	var height:=maxf(69,37+measured.y+maxi(0,line_count-1)*2+8)
	label.size=Vector2(width,height)
	label.get_node("NoticeSpeaker").position=Vector2(66,8)
	label.get_node("NoticeSpeaker").size=Vector2(inner_width,26)
	label.get_node("NoticeAvatar").position=Vector2(10,(height-36)/2)
	return label.size
