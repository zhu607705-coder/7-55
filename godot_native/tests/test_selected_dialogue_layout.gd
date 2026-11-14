extends SceneTree
const Layout=preload("res://scripts/ui/selected_dialogue_layout.gd")
const Selected=preload("res://scripts/ui/selected_ui_theme.gd")
const Narrative=preload("res://scripts/presentation/c3_narrative_view.gd")
const Library=preload("res://scripts/presentation/library_story_view.gd")
const Notice=preload("res://scripts/ui/native_phone_notice.gd")
const Overlay=preload("res://scripts/ui/world_overlay_layout.gd")
var checks:=0
var failures:=0
class Line extends RefCounted:
	var paused:=false
	var content:="请保留原始记录，不要遗漏现场线索。"
	func snapshot()->Dictionary:return {"speaker":"管理员","text":content,"rawText":content,"paused":paused,"requiresConfirmation":false,"sequenceId":"selected_dialogue_test"}
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func run()->void:
	for extent:Vector2 in [Vector2(390,844),Vector2(568,320),Vector2(667,375),Vector2(1440,900),Vector2(3840,2160)]:
		var ui_scale:=Overlay.ui_scale(extent)
		for content:String in ["一句原文。","原始故事文字保留完整。".repeat(300)]:
			var region:=Rect2(16,64,extent.x-32,extent.y-80)
			var metrics:=Layout.metrics(region,1,"管理员",content,"点击 / 空格 / 回车继续",1.0,0,ui_scale)
			check(region.encloses(metrics.panel),"panel stays inside its safe region")
			check(is_equal_approx(metrics.panel.get_center().x,region.get_center().x),"dialogue is centered in its safe region")
			check(is_equal_approx(metrics.panel.end.y,region.end.y),"short and overflowing dialogue stay on the bottom safe edge")
			check(metrics.speaker_font==ceili(18*ui_scale) and metrics.body_font==ceili(14*ui_scale) and metrics.prompt_font==ceili(11*ui_scale),"dialogue role sizes scale together")
			var bounds:=Rect2(Vector2.ZERO,metrics.panel.size)
			for key:String in ["speaker","body_viewport","prompt"]:check(bounds.encloses(metrics[key]),"visible text region inside panel "+key)
			check(not metrics.speaker.intersects(metrics.body_viewport) and not metrics.body_viewport.intersects(metrics.prompt),"speaker/body/tip do not overlap")
			if content.length()>100:check(metrics.body_overflow,"long source prose gets scrolling, never truncation")
		var host:=Control.new();host.size=extent;root.add_child(host)
		for script:Script in [Narrative,Library]:
			var view=script.new();host.add_child(view);view.session=Line.new()
			await process_frame
			view.tick();await process_frame;view.tick()
			check(is_equal_approx(view.panel.get_rect().end.y,extent.y-(8 if script==Narrative else 16)),"actual short dialogue uses the bottom safe edge")
			check(is_equal_approx(view.panel.get_rect().get_center().x,extent.x/2),"actual short dialogue is horizontally centered")
			var paper:StyleBox=view.panel.get_theme_stylebox("panel")
			check(paper is StyleBoxFlat and paper.bg_color==Notice.PAPER and paper.border_color==Notice.INK and paper.get_minimum_size()==Vector2.ZERO,"dialogue shares the notice paper without changing the measured rectangle")
			check(is_equal_approx(view.panel.modulate.a,1),"paper surface does not compound text opacity")
			check(view.speaker.get_theme_font("font")==Selected.font("dialogue","heading"),"heading uses real selected bold face")
			check(view.body.get_theme_color("font_color")==Notice.INK,"dialogue body uses shared paper ink")
			if script==Narrative:
				var intrinsic_px:=maxi(Overlay.BODY_PX,ceili(14.0/ui_scale))
				var rendered_px:int=view.body.get_theme_font_size("font_size")
				check(rendered_px==ceili(intrinsic_px*ui_scale) and rendered_px>=14,"map dialogue scales with the fitted game surface above its 14px floor")
			check(view.body.get_theme_constant("outline_size")==0,"no glyph outline")
			check(view.body.get_theme_constant("shadow_offset_y")==1 and view.body.get_theme_color("font_shadow_color").a==0,"paper text keeps its metrics without a dark halo")
			check(view.body.text==view.session.snapshot().text,"source words unchanged")
			view.session.content="请保留原始记录，不要遗漏现场线索。".repeat(4)
			view.tick();await process_frame;await process_frame;view.tick()
			var reading_rect: Rect2=view.body_scroll.get_rect()
			check(view.body.get_line_count()>1 and view.body.get_minimum_size().y<=reading_rect.size.y,"wrapped body fits at actual label height")
			check(Rect2(Vector2.ZERO,view.panel.size).encloses(reading_rect),"wrapped body fits the paper")
			if script==Library:
				check(not reading_rect.intersects(view.prompt.get_rect()),"wrapped body leaves the continue prompt clear")
			view.session.content="原始故事文字保留完整。".repeat(300)
			view.tick();await process_frame;await process_frame;view.tick()
			check(view.body_scroll.size.y>=view.body.get_theme_font("font").get_height(14),"overflow viewport preserves at least one complete glyph row")
			check(view.body_scroll.get_v_scroll_bar().visible,"actual long source label exposes bounded scrolling")
			view.body_scroll.scroll_vertical=100000
			await process_frame
			check(view.body_scroll.scroll_vertical>0 and view.body.text==view.session.content,"actual scroll reaches later preserved text without truncation")
			view.free()
		host.free()
	print("Selected dialogue: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
