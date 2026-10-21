extends SceneTree
const View=preload("res://scripts/presentation/library_story_view.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
var checks:=0
var failures:=0
class Line extends RefCounted:
	var speaker:="旁白"
	var confirmation:=false
	func snapshot()->Dictionary:
		return {"speaker":speaker,"text":"在图书馆核对已经看到的记录。","requiresConfirmation":confirmation,"sequenceId":"material_test"}
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func run()->void:
	for extent:Vector2 in [Vector2(390,844),Vector2(844,390),Vector2(1440,900)]:
		var host:=Control.new();host.size=extent;root.add_child(host)
		var view:=View.new();host.add_child(view)
		var line:=Line.new();view.session=line
		await process_frame
		for who:String in ["旁白","玩家","我","管理员",""]:
			for confirmation:bool in [false,true]:
				line.speaker=who;line.confirmation=confirmation;view.tick()
				check(view.body.text==line.snapshot().text and view.speaker.text==who,"source words untouched")
				check(view.prompt.text==("点击 / 空格 / 回车确认" if confirmation else "点击 / 空格 / 回车继续"),"prompt follows actual source confirmation state")
				for field:Label in [view.speaker,view.body,view.prompt]:
					check(field.get_theme_font("font")==Typography.body_font(),"render and layout use actual body font")
				check(Ui._contrast(view.speaker.get_theme_color("font_color"),Ui.PAPER)>=4.5,"speaker contrast remains readable")
				check(Rect2(Vector2.ZERO,view.panel.size).encloses(view.panel.rule),"speaker rule bounded")
				check(not view.panel.rule.intersects(view.body_scroll.get_rect()),"speaker rule never paints body")
				check(view.mouse_filter==Control.MOUSE_FILTER_STOP and view.panel.mouse_filter==Control.MOUSE_FILTER_IGNORE,"existing modal pointer ownership retained")
		view.session=null;view.tick();check(not view.visible,"empty session hides panel")
		host.free()
	print("Library story material: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
