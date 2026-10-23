extends RefCounted
## Selected prose rests on the bottom safe edge; mobile uses the safe width.
## Uses the selected fonts for both painting and measurement. No state or input.
const Selected=preload("res://scripts/ui/selected_ui_theme.gd")
static func _height(text:String,width:float,role:String,px:int)->float:
	if text.is_empty():return 0
	var face:=Selected.font("dialogue",role)
	var natural:float=face.get_height(px)
	var measured:float=face.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,maxf(1,width),px).y
	var rows:int=maxi(1,roundi(measured/maxf(1,natural)))
	var spacing:int=roundi(float(px)*float(Selected.role("dialogue",role).leading)-natural)
	return ceilf(measured+spacing*(rows-1))
static func metrics(region:Rect2,display_scale:float,speaker:String,text:String,prompt:String,text_scale:float=1.0)->Dictionary:
	var scale:float=maxf(.01,display_scale)
	var gap:float=8/scale
	var padding:float=8/scale
	var width:float=region.size.x*(.57 if region.size.x*scale>=600 else 1.0)
	var inner:float=maxf(1,width-padding*2)
	var heading_px:int=maxi(1,ceili(Selected.size("dialogue","heading")*text_scale/scale))
	var body_px:int=maxi(1,ceili(Selected.size("dialogue","body")*text_scale/scale))
	var tip_px:int=maxi(1,ceili(Selected.size("dialogue","tip")*text_scale/scale))
	var heading_height:float=_height(speaker,inner,"heading",heading_px)
	var tip_height:float=_height(prompt,inner,"tip",tip_px)
	var body_y:float=padding+heading_height+(gap if heading_height>0 else 0)
	var footer:float=padding+(tip_height+gap if tip_height>0 else 0)
	var body_height:float=_height(text,inner,"body",body_px)
	var visible_height:float=minf(body_height,maxf(1,region.size.y-body_y-footer))
	var overflow:bool=visible_height<body_height
	if overflow:body_height=_height(text,maxf(1,inner-14/scale),"body",body_px)
	var height:float=minf(region.size.y,body_y+visible_height+footer)
	return {"panel":Rect2(region.end.x-width,region.end.y-height,width,height),"speaker":Rect2(padding,padding,inner,heading_height),"body":Rect2(padding,body_y,inner,body_height),"body_viewport":Rect2(padding,body_y,inner,visible_height),"prompt":Rect2(padding,body_y+visible_height+(gap if tip_height>0 else 0),inner,tip_height),"speaker_font":heading_px,"body_font":body_px,"prompt_font":tip_px,"body_overflow":overflow}
static func apply_role(label:Label,role:String,px:int)->void:
	Selected.apply_label(label,"dialogue",role)
	label.add_theme_font_size_override("font_size",px)
	label.add_theme_constant_override("line_spacing",roundi(float(px)*float(Selected.role("dialogue",role).leading)-Selected.font("dialogue",role).get_height(px)))
