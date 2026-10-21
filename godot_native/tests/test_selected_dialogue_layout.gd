extends SceneTree
const Layout=preload("res://scripts/ui/selected_dialogue_layout.gd")
const Selected=preload("res://scripts/ui/selected_ui_theme.gd")
const Narrative=preload("res://scripts/presentation/c3_narrative_view.gd")
const Library=preload("res://scripts/presentation/library_story_view.gd")
var checks:=0
var failures:=0
class Line extends RefCounted:
	var paused:=false
	func snapshot()->Dictionary:return {"speaker":"管理员","text":"请保留原始记录，不要遗漏现场线索。","rawText":"请保留原始记录，不要遗漏现场线索。","paused":paused,"requiresConfirmation":false,"sequenceId":"selected_dialogue_test"}
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func run()->void:
	for extent:Vector2 in [Vector2(390,844),Vector2(568,320),Vector2(667,375),Vector2(1440,900)]:
		for content:String in ["一句原文。","原始故事文字保留完整。".repeat(300)]:
			var region:=Rect2(16,64,extent.x-32,extent.y-80)
			var metrics:=Layout.metrics(region,1,"管理员",content,"点击 / 空格 / 回车继续")
			check(region.encloses(metrics.panel),"right-side panel inside safe region")
			check(is_equal_approx(metrics.panel.end.x,region.end.x),"selected geometry is right anchored")
			check(metrics.speaker_font==18 and metrics.body_font==14 and metrics.prompt_font==11,"locked role sizes")
			var bounds:=Rect2(Vector2.ZERO,metrics.panel.size)
			for key:String in ["speaker","body_viewport","prompt"]:check(bounds.encloses(metrics[key]),"visible text region inside panel "+key)
			check(not metrics.speaker.intersects(metrics.body_viewport) and not metrics.body_viewport.intersects(metrics.prompt),"speaker/body/tip do not overlap")
			if content.length()>100:check(metrics.body_overflow,"long source prose gets scrolling, never truncation")
		var host:=Control.new();host.size=extent;root.add_child(host)
		for script:Script in [Narrative,Library]:
			var view=script.new();host.add_child(view);view.session=Line.new()
			await process_frame
			view.tick();await process_frame;view.tick()
			check(view.panel.get_theme_stylebox("panel") is StyleBoxEmpty,"none surface has no paper or scrim")
			check(is_equal_approx(view.panel.modulate.a,1),"none surface does not dim text to background opacity")
			check(view.speaker.get_theme_font("font")==Selected.font("dialogue","heading"),"heading uses real selected bold face")
			check(view.body.get_theme_color("font_color")==Color("f1efdd"),"locked body color")
			check(view.body.get_theme_constant("outline_size")==0,"no glyph outline")
			check(view.body.get_theme_constant("shadow_offset_y")==1,"locked shadow remains enabled")
			check(view.body.text==view.session.snapshot().text,"source words unchanged")
			view.free()
		host.free()
	print("Selected dialogue: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
