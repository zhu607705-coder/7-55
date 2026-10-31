extends "res://campuses/future_learning_center/scripts/puzzles/collab_view.gd"
const AssemblyModel=preload("res://campuses/future_learning_center/scripts/puzzles/assembly_model.gd")
var bracket_drag:=false
const BRACKET_TRAY:=Vector2(500,451)
func _init()->void:
	model=AssemblyModel.new();apparatus_title="整机复验";apparatus_goal="分开能用的附件，装在一起也要重新验证。"
	hints=["分开测试时没有的接触，在组合后出现在哪里？","只卸下一个附件比较送料，再装回比较，其他条件不动。","对照分体记录的活动范围与当前接触点，核对装配版本。"]
func bracket_position()->Vector2:
	return visuals.object_at("Bracket",logical_bracket_position()) if visuals!=null else logical_bracket_position()
func logical_bracket_position()->Vector2:
	return projected(model.rotate_point(Vector2(model.bracket_x,65))) if model.bracket_attached else BRACKET_TRAY
func _press(at:Vector2)->void:
	var exact:bool=visuals!=null and visuals.hit("Bracket",at)
	var padded:bool=at.distance_to(bracket_position())<32 and physical_pick(at).is_empty()
	if not model.running and not model.paused and (exact or padded):
		bracket_drag=true;selected=-1;pressed_at=at;pointer=at;grab_offset=bracket_position()-at;action="";return
	super._press(at)
func _release(at:Vector2)->void:
	if bracket_drag:
		pointer=at;_sync_visuals(0)
		bracket_drag=false
		at+=grab_offset;grab_offset=Vector2.ZERO
		if Rect2(452,414,97,75).has_point(at):model.set_bracket(model.bracket_x,false);feedback="支架卸下，挡片也失去支撑。"
		else:
			var local:=Vector2(at.x-CENTER.x,(at.y-CENTER.y)/.66).rotated(-model.quarter_turn*PI/2)
			if absf(local.y-65)<40 and model.set_bracket(clampf(local.x,-138,138)):feedback="支架已换位，重新观察当前整机。"
		_sync_visuals(0);queue_redraw();return
	super._release(at)
func _cancel_pointer()->void:
	bracket_drag=false;super._cancel_pointer()
func _draw_generated_extra()->void:
	text("附件托盘" if model.bracket_attached else "支撑已卸下",Vector2(555,468),13,Color("253e46"))
	if bracket_drag:ApparatusStyle.target(self,Rect2(452,414,97,75),true)
	var footprint:Rect2=model.bracket_rect()
	var bracket_stop:float=(210.0-footprint.end.y-18.0)/210.0
	var contact:bool=model.bracket_attached and footprint.intersects(Rect2(-18,0,36,210)) and model.travel>=bracket_stop-.001
	var show_footprint:=contact
	if bracket_drag:
		var at:=pointer+grab_offset
		var local:=Vector2(at.x-CENTER.x,(at.y-CENTER.y)/.66).rotated(-model.quarter_turn*PI/2)
		show_footprint=absf(local.y-65)<40
		footprint.position.x+=clampf(local.x,-138,138)-model.bracket_x
	if show_footprint:
		# This explicitly labelled clearance feedback is not a replacement prop.
		var corners:=PackedVector2Array()
		for local:Vector2 in [footprint.position,Vector2(footprint.end.x,footprint.position.y),footprint.end,Vector2(footprint.position.x,footprint.end.y)]:corners.append(projected(model.rotate_point(local)))
		for i:int in 4:draw_dashed_line(corners[i],corners[(i+1)%4],Color("986a36"),1.5,4)
		text("支架占用范围",projected(model.rotate_point(footprint.get_center()))+Vector2(20,22),13,Color("253e46"))
	if contact:draw_circle(projected(model.rotate_point(Vector2(0,model.bracket_rect().end.y))),5,Color("cb9b62"))
