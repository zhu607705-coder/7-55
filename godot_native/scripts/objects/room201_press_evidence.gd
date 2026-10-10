extends Node2D
## Physical wear and earned imprints sit above generated image moving layers.
var view:Control
func _process(_delta:float)->void:queue_redraw()
func _label(at:Vector2,text:String,pixels:=27,color:=Color("f0d6a0"))->void:
	draw_string(view.get_theme_default_font(),at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(pixels,ceili(14/maxf(.01,view.fit))),color)
func _wear(at:Vector2,radius:float,bright:=false)->void:
	var ink:=Color("dac693") if bright else Color("968462")
	draw_arc(at+Vector2(1,2),radius,.25,2.95,26,Color("342a20"),4,true)
	draw_arc(at,radius,3.4,6.1,26,ink,2.5,true)
	draw_arc(at+Vector2(1,1),radius-4,.45,2.7,22,Color("594832"),2,true)
func _draw()->void:
	if view==null:return
	var source:Dictionary=view.Model.source().registration.calibration
	var target:Vector2=view.center+Vector2(float(source.horizontal),float(source.vertical))*22
	var contacts:Array=view.CONTACTS
	var sheet_at:Vector2=view.art.parts.TransparentClockSheet.position
	var embossed:bool=view.completed and (view.motion!="press" or view.motion_time>=.51 or view.reduced)
	for local:Vector2 in contacts:
		var scar:Vector2=target+local*view.carriage_art_scale()
		_wear(scar,22*view.carriage_art_scale(),true)
		if embossed:
			var stamp:Vector2=sheet_at+local*view.carriage_art_scale()
			draw_arc(stamp,17*view.carriage_art_scale(),0,TAU,32,Color("e5f2d5"),3,true)
	if view.dent and view.checkpoint.inserted and not embossed and (view.motion!="press" or view.motion_time>=.51 or view.reduced):
		var at:Vector2=sheet_at+Vector2(26,43)
		draw_arc(at,18,.2,2.6,18,Color("424848"),3,true)
		draw_arc(at+Vector2(1,-1),18,.2,2.6,18,Color("b8c9c0"),1.5,true)
	var gauge_scale:float=.90 if view.narrow else 1.0
	var pressure:float=view._visual_calibration().z
	for i:int in range(5):
		var at:Vector2=view.lever_pivot+Vector2(-1,90+i*28)*gauge_scale
		var worn:bool=i==int(source.pressure)
		draw_line(at-Vector2(7,0),at+Vector2(7,0),Color("e5d7b0") if worn else Color("775e36"),5 if worn else 2,true)
		if worn:draw_line(at+Vector2(-7,3),at+Vector2(7,3),Color("453b2c"),2,true)
	var needle:Vector2=view.lever_pivot+Vector2(-24,90+pressure*28)*gauge_scale
	draw_colored_polygon(PackedVector2Array([needle+Vector2(-9,-6),needle+Vector2(5,0),needle+Vector2(-9,6)]),Color("cfaa63"))
	var handles:Array=view.rail_handles()
	if not view.completed:
		_label(handles[0].point+Vector2(-28,109) if view.narrow else handles[0].point+Vector2(-47,123),"横移")
		_label(handles[1].point+Vector2(-28,111),"纵移")
		_label(view.wheel+Vector2(-80,201) if view.narrow else view.wheel+Vector2(-86,247),"转手轮 · 蓄压")
		_label(Vector2(555,292) if view.narrow else Vector2(1235,88),"拉下压杆")
	if not view.checkpoint.inserted:
		_label(view.loose_center+Vector2(-115,171),"拖进卡槽 / 点一下" if view.plate_available else "原件还没到工位",25)
	elif view.completed:
		_label(Vector2(83,1290) if view.narrow else Vector2(519,985),"三枚压印，齐了。原件带回 A1",26,Color("d4e9c2"))
	if view.motion=="press" and view.motion_time>=.36 and view.motion_time<=.81 and not view.press_outcome.is_empty():
		_label(view.center+Vector2(-47,192),"咔哒。" if view.press_outcome=="success" else "梆！",42)
