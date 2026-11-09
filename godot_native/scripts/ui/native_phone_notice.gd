extends RefCounted
## Source phone notification composition from subtitles.css and
## SubtitleSpeakerIcon.tsx. Pure presentation: no queue, timing or story state.
static var FONT: Font=preload("res://scripts/ui/native_typography.gd").body_font()
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
# One flat phone-paper container for banners, inbox summaries and system feedback.
# Queue/timers, app routes and puzzle actions remain with their existing owners.
const MUTED=Color("625b50")
const WARNING_PAPER=Color("fff0e7")
const SUMMARY_BODY_SIZE=13
const SUMMARY_TITLE_SIZE=16
const INK=Color("222322")
const PAPER=Ui.PAPER
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
	Typography.apply_body(label)
	label.add_theme_font_size_override("font_size",16)
	label.add_theme_color_override("font_color",INK)
	label.add_theme_constant_override("line_spacing",2)
	var card:=card_style()
	card.content_margin_left=60; card.content_margin_right=12
	card.content_margin_top=35; card.content_margin_bottom=10
	label.add_theme_stylebox_override("normal",card)
	var avatar:=Panel.new(); avatar.name="NoticeAvatar"; avatar.size=Vector2(36,36); avatar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	avatar.add_theme_stylebox_override("panel",Ui.box(Color("eee5d1"),INK,1)); label.add_child(avatar)
	var icon:=TextureRect.new(); icon.name="Icon"; icon.position=Vector2(8,8); icon.size=Vector2(20,20); icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST; icon.mouse_filter=Control.MOUSE_FILTER_IGNORE; avatar.add_child(icon)
	var heading:=Label.new(); heading.name="NoticeSpeaker"; heading.mouse_filter=Control.MOUSE_FILTER_IGNORE
	Typography.apply_display(heading); heading.add_theme_font_size_override("font_size",16); heading.add_theme_color_override("font_color",INK)
	label.add_child(heading)
	set_message(label,text,speaker)
	return label

static func icon_for(speaker: String) -> Texture2D:
	if speaker=="林星宇": speaker="我"
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
	var heading:Label=label.get_node("NoticeSpeaker")
	heading.text=speaker
	var accent:Color=accent_for(speaker)
	heading.add_theme_color_override("font_color",accent)
	# Role hierarchy is visual only; the existing queue owns message order and
	# lifetime, and avatar/speaker identities remain unchanged.
	var card:=card_style()
	card.content_margin_left=60; card.content_margin_right=12
	card.content_margin_top=35; card.content_margin_bottom=10
	card.bg_color=WARNING_PAPER if speaker=="提示" else PAPER
	card.border_color=INK
	card.set_border_width_all(2)
	label.add_theme_stylebox_override("normal",card)
	label.get_node("NoticeAvatar/Icon").texture=icon_for(speaker)

static func layout(label: Label,width: float) -> Vector2:
	# Resolve wrapping at the final width before reading the minimum height.
	# A newly attached zero-width Label otherwise caches one line per glyph.
	label.size.x=width
	label.update_minimum_size()
	var inner_width:=maxf(24,width-72)
	var font:Font=label.get_theme_font("font")
	var font_size:int=label.get_theme_font_size("font_size")
	var measured:=font.get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,inner_width,font_size)
	var line_count:=maxi(1,ceili(measured.y/font.get_height(font_size)))
	var height:=maxf(69,35+measured.y+maxi(0,line_count-1)*2+10)
	label.size=Vector2(width,height)
	label.get_node("NoticeSpeaker").position=Vector2(60,7)
	label.get_node("NoticeSpeaker").size=Vector2(maxf(24,inner_width-float(label.get_meta("notice_close_space",0))),26)
	label.get_node("NoticeAvatar").position=Vector2(10,(height-36)/2)
	return label.size

static func accent_for(speaker: String) -> Color:
	if speaker in ["提示","我"]: return Color("853e34")
	if speaker=="记录": return Color("365b42")
	return INK

static func card_style(fill: Color=PAPER) -> StyleBoxFlat:
	return Ui.box(fill,INK,2,0,Vector2.ZERO)

static func style_summary(card: Control) -> void:
	card.set_meta("phone_notification",true)
	if card is Button:
		# The notice owns its children and flat paper state as one composition.
		# Do not infer a ghost/hotspot from this deliberately blank Button text.
		card.set_meta("tactile_exempt",true)
		card.set_meta("phone_button_role","composite")
		var styles:=Ui.button_styles(PAPER,INK,INK,0,2,Vector2.ZERO)
		for state: String in styles: card.add_theme_stylebox_override(state,styles[state])
	else: card.add_theme_stylebox_override("panel",card_style())

static func summary_height(width: float,text: String) -> float:
	var body:=FONT.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,maxf(24,width-66),SUMMARY_BODY_SIZE)
	return maxf(58,30+body.y+10)

static func add_summary(card: Control,title: String,body: String,time: String="") -> void:
	style_summary(card)
	var width:=card.size.x
	var heading:=Label.new(); heading.name="NoticeTitle"; heading.text=title
	Typography.apply_display(heading); heading.add_theme_font_size_override("font_size",SUMMARY_TITLE_SIZE)
	heading.add_theme_color_override("font_color",INK); heading.position=Vector2(54,6)
	heading.size=Vector2(maxf(24,width-66-(62 if not time.is_empty() else 0)),24)
	heading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; heading.clip_text=true
	heading.mouse_filter=Control.MOUSE_FILTER_IGNORE; card.add_child(heading)
	var text:=Label.new(); text.name="NoticeBody"; text.text=body
	Typography.apply_body(text); text.add_theme_font_size_override("font_size",SUMMARY_BODY_SIZE)
	text.add_theme_color_override("font_color",MUTED); text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text.position=Vector2(54,30); text.size=Vector2(maxf(24,width-66),maxf(20,card.size.y-40))
	text.mouse_filter=Control.MOUSE_FILTER_IGNORE; card.add_child(text)
	if not time.is_empty():
		var stamp:=Label.new(); stamp.name="NoticeTime"; stamp.text=time
		Typography.apply_body(stamp); stamp.add_theme_font_size_override("font_size",11)
		stamp.add_theme_color_override("font_color",MUTED); stamp.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		stamp.position=Vector2(width-70,9); stamp.size=Vector2(58,18)
		stamp.mouse_filter=Control.MOUSE_FILTER_IGNORE; card.add_child(stamp)
	if card is Button: card.tooltip_text=title+"："+body

static func inline_style(role: String="system") -> StyleBoxFlat:
	# Form results stay beside their fields, rather than entering the transient
	# lane. The same paper, stroke and type roles work at their compact size.
	var fill:Color=WARNING_PAPER if role in ["error","warning"] else Color("edf3e6") if role=="success" else PAPER
	return Ui.box(fill,INK,2,0,Vector2(12,8))

static func style_inline(label: Label,role: String="system",font_size: int=14) -> void:
	label.set_meta("phone_notice_surface","inline")
	label.set_meta("phone_notice_role",role)
	Typography.apply_body(label)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",accent_for("提示" if role in ["error","warning"] else "记录" if role=="success" else "系统"))
	label.add_theme_constant_override("line_spacing",2)
	label.add_theme_stylebox_override("normal",inline_style(role))
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE

static func dialog_style(padding: Vector2=Vector2(16,16)) -> StyleBoxFlat:
	return Ui.box(PAPER,INK,2,0,padding)
