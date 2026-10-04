extends RefCounted
## Measured screen-space status only. No input, simulation or story ownership.
const Compact=preload("res://scripts/ui/compact_overlay_layout.gd")

static func wrap_phrases(font: Font,text: String,width: float,font_size: int) -> String:
	var lines: Array[String]=[]
	var line: String=""
	for phrase: String in text.split(" · "):
		var candidate: String=phrase if line.is_empty() else line+" · "+phrase
		if not line.is_empty() and font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width:
			lines.append(line);line=phrase
		else: line=candidate
	lines.append(line)
	return "\n".join(lines)

static func layout(font: Font,extent: Vector2,display_scale: float,header_height: float,status: String,alert: String="",progress: String="") -> Dictionary:
	var scale: float=maxf(.01,display_scale)
	var short: bool=extent.y*scale<400
	var font_size: int=Compact.font_size(14 if short else 15,14,scale)
	var margin: float=(8.0 if short else 12.0)/scale
	var padding: float=(5.0 if short else 8.0)/scale
	var gap: float=(3.0 if short else 5.0)/scale
	var available: float=maxf(1,extent.x-margin*2-padding*2)
	var texts: Array[String]=[status]
	if not alert.is_empty():
		var full: String=" · ".join([status,alert,progress])
		var status_progress: String=" · ".join([status,progress])
		if font.get_string_size(full,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x<=available:
			texts=[full]
		elif font.get_string_size(status_progress,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x<=available:
			texts=[status_progress,alert]
		else: texts=[status,alert,progress]
	var width: float=0
	for text: String in texts: width=maxf(width,minf(available,font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x))
	var top: float=header_height+6.0/scale
	var y: float=top+padding
	var rows: Array=[]
	for text: String in texts:
		var display_text: String=wrap_phrases(font,text,width,font_size)
		var measured: Vector2=font.get_multiline_string_size(display_text,HORIZONTAL_ALIGNMENT_LEFT,width,font_size)
		var rect:=Rect2(margin+padding,y,width,maxf(font.get_height(font_size),measured.y))
		rows.append({"text":text,"display_text":display_text,"rect":rect})
		y=rect.end.y+gap
	var bar:=Rect2()
	if not alert.is_empty():
		bar=Rect2(margin+padding,y,width,(5.0 if short else 6.0)/scale)
		y=bar.end.y+gap
	var panel:=Rect2(margin,top,width+padding*2,y-gap+padding-top)
	return {"panel":panel,"rows":rows,"risk_bar":bar,"font_size":font_size,"scale":scale,"short":short}

static func draw(canvas: CanvasItem,font: Font,metrics: Dictionary,warning: bool,alpha: float,risk_ratio: float=-1,critical: bool=false,pressured: bool=false) -> void:
	var scale: float=metrics.scale
	canvas.draw_rect(metrics.panel,Color("071723",.9*alpha))
	canvas.draw_rect(metrics.panel,Color("b9e5ef",.6*alpha),false,1.0/scale)
	var text_color: Color=Color("ffaaa0") if warning else Color("fff2b6")
	text_color.a=alpha
	for row: Dictionary in metrics.rows:
		canvas.draw_multiline_string(font,row.rect.position+Vector2(0,font.get_ascent(metrics.font_size)),row.display_text,HORIZONTAL_ALIGNMENT_LEFT,row.rect.size.x,metrics.font_size,-1,text_color)
	if risk_ratio<0 or metrics.risk_bar.size==Vector2.ZERO: return
	canvas.draw_rect(metrics.risk_bar,Color("213744",.94*alpha))
	var risk: Color=Color("ff665a") if critical else (Color("ffc857") if pressured else Color("77d6e8"))
	risk.a=alpha
	canvas.draw_rect(Rect2(metrics.risk_bar.position,Vector2(metrics.risk_bar.size.x*maxf(.035,clampf(risk_ratio,0,1)),metrics.risk_bar.size.y)),risk)
