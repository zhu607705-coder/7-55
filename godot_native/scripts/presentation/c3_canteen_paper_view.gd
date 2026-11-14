extends Control
const Paper=preload("res://scripts/presentation/c3_paper_art.gd")
const Overlay=preload("res://scripts/ui/world_overlay_layout.gd")
var session: RefCounted
var world: Control
var font: Font
var ghosts: Array=[]
var last_frame: int=-1
var ghost_session_id: int=0
var ghost_elapsed_ms: float=0.0
var tail_lines: Array=[]
var tail_ms: float=0.0
var tail_reduced: bool=false
var display_scale: float=1.0
func narrow_text() -> bool:
	return is_instance_valid(world) and world.size.x*display_scale<620
func text_layout(text: String,point: Vector2,width: float,factor: float,is_tail: bool=false) -> Dictionary:
	# Coordinates remain in the unmodified 960x540 world. Only the HUD text
	# compensates for the actual SubViewport display scale.
	var physical_scale: float=maxf(.1,display_scale)
	var unit:=Overlay.ui_units(world.size,physical_scale)
	var font_size: int=maxi(15 if is_tail else int(13*factor),ceili(Overlay.BODY_PX*unit))
	var padding: float=8*unit
	var max_width: float=world.size.x-24*unit
	var natural_width: float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x+padding*2
	var box_width: float=minf(max_width,maxf(width,natural_width))
	var lines: Array[String]=[]
	var line: String=""
	for character: String in text:
		if not line.is_empty() and font.get_string_size(line+character,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>box_width-padding*2:
			lines.append(line); line=""
		line+=character
	if not line.is_empty(): lines.append(line)
	var line_height: float=font.get_height(font_size)
	var box_height: float=line_height*lines.size()+padding*2
	var rect:=Rect2(point-Vector2(box_width/2,box_height/2),Vector2(box_width,box_height))
	var edge: float=6*unit
	rect.position.x=clampf(rect.position.x,edge,world.size.x-edge-rect.size.x)
	rect.position.y=world.size.y-box_height-10*unit if is_tail and narrow_text() else clampf(rect.position.y,edge,world.size.y-edge-rect.size.y)
	return {"rect":rect,"fontSize":font_size,"lines":lines,"lineHeight":line_height,"padding":padding,"unit":unit}
func _draw_readable(text: String,point: Vector2,width: float,factor: float,alpha: float,is_tail: bool=false) -> void:
	var layout: Dictionary=text_layout(text,point,width,factor,is_tail)
	var rect: Rect2=layout.rect
	draw_rect(rect,Color("102633",.94*alpha) if is_tail else Color("fff6df",.97*alpha))
	if not is_tail:
		draw_rect(rect,Color("243947",alpha),false,layout.unit)
		var tip:=minf(9*float(layout.unit),world.size.y-rect.end.y)
		var base:=Vector2(rect.position.x+rect.size.x*.3,rect.end.y)
		draw_colored_polygon(PackedVector2Array([base,base+Vector2(tip,0),base+Vector2(tip*.3,tip)]),Color("fff6df",alpha))
	for i in range(layout.lines.size()):
		var baseline:=rect.position+Vector2(layout.padding,layout.padding+font.get_ascent(layout.fontSize)+i*layout.lineHeight)
		draw_string(font,baseline,layout.lines[i],HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-layout.padding*2,layout.fontSize,Color("f5fbff",alpha) if is_tail else Color("172932",alpha))
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	font=preload("res://scripts/ui/native_typography.gd").body_font()
func tick(delta_ms: float) -> void:
	var elapsed_delta: float=maxf(0,delta_ms) if is_finite(delta_ms) else 0.0
	if session!=null and session.kind=="canteen":
		if session.status=="cancelled":
			ghosts.clear(); last_frame=-1
			queue_redraw(); return
		var elapsed: float=session.elapsed_ms
		if ghost_session_id!=session.get_instance_id() or elapsed<ghost_elapsed_ms:
			# New arrival/retry cannot inherit old sprites or a previous timer phase.
			ghosts.clear(); last_frame=-1; ghost_elapsed_ms=0
			ghost_session_id=session.get_instance_id()
		elapsed_delta=maxf(0,elapsed-ghost_elapsed_ms)
		if session.paused: elapsed_delta=0
		for ghost: Dictionary in ghosts: ghost.age+=elapsed_delta
		ghosts=ghosts.filter(func(g: Dictionary)->bool:return g.age<g.duration)
		if not session.paused and elapsed>=session.route_start_ms:
			var interval: float=120.0 if session.reduced_motion else 78.0
			var frame: int=int((elapsed-session.route_start_ms)/interval)
			# Source increments its timer before testing the even frame. Frame0
			# at route start is not an emission. Preserve crossed timer callbacks.
			for step: int in range(maxi(1,last_frame+1),frame+1):
				var at: float=session.route_start_ms+step*interval
				var duration: float=90.0 if session.reduced_motion else 220.0
				if step%2==0 and at<session.escape_end_ms and elapsed-at<duration:
					var ghost:=_route_ghost(at,step%4)
					ghost.age=elapsed-at; ghost.duration=duration
					ghosts.append(ghost)
			last_frame=frame
		ghost_elapsed_ms=elapsed
	else:
		for ghost: Dictionary in ghosts: ghost.age+=elapsed_delta
		ghosts=ghosts.filter(func(g: Dictionary)->bool:return g.age<g.duration)
	if not tail_lines.is_empty():
		tail_ms+=elapsed_delta
		if tail_ms>=tail_lines.size()*1600: tail_lines=[]
	queue_redraw()

func _route_ghost(at: float,frame: int) -> Dictionary:
	# Read the existing authored route at the timer boundary. Never rewind or
	# write the controller-issued session to sample a presentation sprite.
	var point: Vector2=session.trigger_paper
	var angle: float=-6.0
	for segment: Dictionary in session.route:
		if at<float(segment.startMs)+float(segment.durationMs):
			var progress: float=session._ease(clampf((at-float(segment.startMs))/float(segment.durationMs),0,1),segment.ease)
			point=point.lerp(segment.point,progress); angle=lerpf(angle,float(segment.angle),progress)
			break
		point=segment.point; angle=float(segment.angle)
	return {"point":point,"angle":angle,"frame":frame,"scale":0.82,"age":0.0,"duration":0.0}

func ghost_pose(ghost: Dictionary) -> Dictionary:
	var progress: float=clampf(ghost.age/ghost.duration,0,1)
	return {"point":ghost.point,"angle":ghost.angle,"frame":ghost.frame,"scale":float(ghost.scale)*lerpf(1,0.82,progress),"alpha":0.24*(1-progress),"tint":Color("bdefff")}
func _screen(p: Vector2) -> Vector2: return world.world_to_view(p)
func _draw() -> void:
	if not is_instance_valid(world) or world.scene_id!="canteen_interior": return
	for ghost: Dictionary in ghosts:
		var pose: Dictionary=ghost_pose(ghost)
		Paper.draw(self,_screen(pose.point),world.zoom*pose.scale,pose.angle,pose.frame,pose.alpha,false,Transform2D.IDENTITY,Vector2.ONE,pose.tint)
	if session!=null:
		var pose: Dictionary=session.paper_pose()
		if pose.visible: Paper.draw(self,_screen(pose.point),world.zoom*float(pose.scale),pose.angle,pose.frame)
		for prompt: Dictionary in session.speech_bubbles():
			_bubble(prompt.text,_screen(prompt.point),float(prompt.width)*world.zoom*float(prompt.scale),world.zoom*float(prompt.scale),prompt.alpha)
		var alarm: Dictionary=session.alarm_pose()
		if not alarm.is_empty(): _bubble("!",_screen(alarm.point),26*world.zoom,world.zoom,alarm.alpha)
	if not tail_lines.is_empty():
		var index: int=mini(int(tail_ms/1600),tail_lines.size()-1)
		var t: float=fposmod(tail_ms,1600)
		var fade: float=70 if tail_reduced else 120
		var hold: float=1600-(190 if tail_reduced else 280)
		var alpha: float=minf(clampf(t/fade,0,1),clampf((fade*2+hold-t)/fade,0,1))
		_draw_readable(str(tail_lines[index]),Vector2(world.size.x/2,world.size.y-107),0,1,alpha,true)
func _bubble(text: String,point: Vector2,width: float,factor: float,alpha: float=1.0) -> void:
	_draw_readable(text,point,width,factor,alpha)
func reset() -> void:
	session=null; ghosts=[]; tail_lines=[]; tail_ms=0; last_frame=-1; ghost_session_id=0; ghost_elapsed_ms=0; queue_redraw()
