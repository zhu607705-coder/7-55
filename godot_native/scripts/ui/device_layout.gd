extends RefCounted
## Fullscreen device chrome uses logical viewport units, never OS screen pixels/DPR.
## Text, targets and spacing grow together; short mobile layouts reflow without
## shrinking text below the readable baseline. PhoneShell keeps its own 430x860.
static func scale_for(area:Vector2)->float:
	if area.x<600:return clampf(area.x/430.0,1.0,1.2)
	return clampf(minf(area.x/1280.0,area.y/720.0),1.0,2.5)
static func font_size(area:Vector2,base:int)->int:return roundi(base*scale_for(area))
static func panel(panel:Control,area:Rect2,insets:Vector4)->Rect2:
	var s:float=scale_for(area.size)
	var margin:float=16*s
	var safe:=Rect2(Vector2(insets.x+margin,insets.y+margin),area.size-Vector2(insets.x+insets.z+margin*2,insets.y+insets.w+margin*2))
	var short_view:bool=area.size.y<540
	panel.header.position=safe.position;panel.header.size=Vector2(safe.size.x,52*s)
	panel.title.add_theme_font_size_override("font_size",roundi((22 if area.size.x<600 else 28)*s))
	panel.close_button.add_theme_font_size_override("font_size",roundi(18*s))
	panel.close_button.custom_minimum_size=Vector2(108,52)*s
	panel.hint.add_theme_font_size_override("font_size",roundi(18*s))
	panel.feedback.add_theme_font_size_override("font_size",roundi(18*s))
	panel.hint.position=safe.position+Vector2(0,62*s)
	panel.hint.size=Vector2(safe.size.x,(46 if short_view else 68)*s)
	panel.feedback.position=Vector2(safe.position.x,safe.end.y-48*s)
	panel.feedback.size=Vector2(safe.size.x,48*s)
	panel.view.position=Vector2.ZERO;panel.view.size=area.size
	var top:float=panel.hint.position.y+panel.hint.size.y+8*s
	panel.view.layout_scene(Rect2(Vector2(safe.position.x,top),Vector2(safe.size.x,maxf(80,panel.feedback.position.y-top-8*s))))
	return safe
