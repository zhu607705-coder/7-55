extends "res://campuses/future_learning_center/scripts/puzzles/collab_view.gd"
const AssemblyModel=preload("res://campuses/future_learning_center/scripts/puzzles/assembly_model.gd")
var bracket_drag:=false
const BRACKET_TRAY:=Vector2(500,451)
func _init()->void:
	model=AssemblyModel.new();apparatus_title="整机复验 · 分开能用，装在一起呢"
	hints=["分开测试时没有的接触，在组合后出现在哪里？","只卸下一个附件比较送料，再装回比较，其他条件不动。","对照分体记录的活动范围与当前接触点，核对装配版本。"]
func bracket_position()->Vector2:
	return projected(model.rotate_point(Vector2(model.bracket_x,65))) if model.bracket_attached else BRACKET_TRAY
func _press(at:Vector2)->void:
	if not model.running and not model.paused and at.distance_to(bracket_position())<32:
		bracket_drag=true;pressed_at=at;pointer=at;action="";return
	super._press(at)
func _release(at:Vector2)->void:
	if bracket_drag:
		bracket_drag=false
		if Rect2(452,414,97,75).has_point(at):model.set_bracket(model.bracket_x,false);feedback="支架卸下，挡片也失去支撑。"
		else:
			var local:=Vector2(at.x-CENTER.x,(at.y-CENTER.y)/.66).rotated(-model.quarter_turn*PI/2)
			if absf(local.y-65)<40 and model.set_bracket(clampf(local.x,-138,138)):feedback="支架已换位，重新观察当前整机。"
		queue_redraw();return
	super._release(at)
func _cancel_pointer()->void:
	bracket_drag=false;super._cancel_pointer()
func _draw_apparatus_extra()->void:
	var rail_a:=projected(model.rotate_point(Vector2(-138,65)))
	var rail_b:=projected(model.rotate_point(Vector2(138,65)))
	draw_line(rail_a,rail_b,Color("6b7270"),8);draw_line(rail_a+Vector2(0,2),rail_b+Vector2(0,2),Color("d6d0b9"),2)
	var p:=pointer if bracket_drag else bracket_position()
	box(Rect2(p-Vector2(16,20),Vector2(32,30)),Color("655e52"),16)
	draw_line(p-Vector2(9,16),p+Vector2(9,-16),Color("c5c3b3"),5)
	if model.bracket_attached and not model.feed_clear() and model.travel>=.35:draw_circle(p-Vector2(0,12),7,Color("cb9b62"))
	box(Rect2(452,421,97,62),Color("515750"),3);text("附件托盘",Vector2(460,480),13)
