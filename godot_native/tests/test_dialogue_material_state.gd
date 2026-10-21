extends SceneTree
const View=preload("res://scripts/presentation/c3_narrative_view.gd")
const Notice=preload("res://scripts/ui/native_phone_notice.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
var checks:=0
var failures:=0
class TimedLine extends RefCounted:
	var paused:=false
	var text:="在现场核对这条记录。"
	var speaker:="旁白"
	func snapshot()->Dictionary:return {"rawText":text,"text":text,"speaker":speaker,"paused":paused}
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func run()->void:
	var host:=Control.new();host.size=Vector2(390,844);root.add_child(host)
	var view:=View.new();host.add_child(view)
	var line:=TimedLine.new();view.session=line;view.exploration_rect=Rect2(0,0,390,600)
	await process_frame
	for who:String in ["旁白","玩家","系统","阿姨",""]:
		line.speaker=who
		for paused:bool in [false,true]:
			line.paused=paused;view.tick();await process_frame;view.tick()
			check(view.body.text==line.text and view.speaker.text==who,"source words and speaker unchanged")
			check(view.panel.paused==paused,"paused graphic follows only snapshot state")
			check(view.body.get_theme_font("font")==Typography.body_font(),"measured and rendered body font agree")
			check(view.mouse_filter==Control.MOUSE_FILTER_IGNORE and view.panel.mouse_filter==Control.MOUSE_FILTER_IGNORE,"narrative remains pointer transparent")
			check(Rect2(Vector2.ZERO,view.panel.size).encloses(view.panel.rule),"speaker rule remains inside panel")
			if view.panel.show_status:check(Rect2(Vector2.ZERO,view.panel.size).encloses(view.panel.status_rect),"timed status remains inside panel")
			check(Ui._contrast(view.speaker.get_theme_color("font_color"),Ui.PAPER)>=4.5,"speaker ink contrast")
	for who:String in ["系统","旁白","提示","我"]:
		var notice:Label=Notice.create("完整反馈不包含继续按钮。",who);host.add_child(notice)
		Notice.layout(notice,350)
		check(notice.text=="完整反馈不包含继续按钮。","notice source text retained")
		check(notice.get_theme_font("font")==Typography.body_font(),"notice uses actual bundled body font")
		check(notice.mouse_filter==Control.MOUSE_FILTER_IGNORE and notice.focus_mode==Control.FOCUS_NONE,"notice never steals pointer/focus")
		check(notice.get_node("NoticeSpeaker").text==who,"notice role retained")
		check(Ui._contrast(notice.get_node("NoticeSpeaker").get_theme_color("font_color"),Notice.PAPER)>=4.5,"notice speaker ink contrast")
		notice.free()
	view.session=null;view.tick();check(not view.visible,"empty session hides whole dialogue")
	host.free()
	print("Dialogue material state: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
