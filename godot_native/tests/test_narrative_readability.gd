extends SceneTree
const View=preload("res://scripts/presentation/c3_narrative_view.gd")
var checks:=0
var failures:=0
class SourceLine extends RefCounted:
	var line: String="那正好，找盘子也算找。送回来给你两块。"
	func snapshot() -> Dictionary: return {"rawText":line,"text":line,"speaker":"阿姨"}
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("NARRATIVE READABILITY: "+label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var parent:=Control.new(); parent.size=Vector2(960,540); root.add_child(parent)
	var view:=View.new(); parent.add_child(view); view.session=SourceLine.new()
	await process_frame
	for physical_width: float in [390,430,960,1280,1440]:
		var factor: float=(physical_width-12)/980
		view.display_scale=factor; view.tick(); await process_frame; view.tick(); await process_frame
		check(not view.body_scroll.get_v_scroll_bar().visible,"short subtitle has no spurious scrollbar at width "+str(physical_width))
		check(Rect2(Vector2.ZERO,view.size).encloses(Rect2(view.panel.position,view.panel.size)),"panel stays in source world at width "+str(physical_width))
		check(view.body.get_theme_font_size("font_size")*factor>=14.99,"body is at least15 physical pixels at width "+str(physical_width))
		check(view.speaker.get_theme_font_size("font_size")*factor>=12.99,"speaker is at least13 physical pixels at width "+str(physical_width))
		var actual: Vector2=view.body.get_theme_font("font").get_multiline_string_size(view.body.text,HORIZONTAL_ALIGNMENT_LEFT,view.body.size.x,view.body.get_theme_font_size("font_size"))
		check(actual.y<=view.body.size.y+.5,"wrapped source line fits without clipping at width "+str(physical_width))
		check(view.body.text==view.session.line,"responsive layout does not rewrite source text")
	parent.queue_free(); await process_frame
	print("Narrative readability: ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)
