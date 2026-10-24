extends Control
## Evidence is an inspectable artefact; it neither evaluates nor writes progress.
const Type=preload("res://scripts/ui/native_typography.gd")
const INK=Color("424b49")
const FADED=Color("8b8877")
const RED=Color("99574b")
var puzzle_id:=""
var source:Dictionary={}
static func caption(id:String)->String:
	return {"duty_board":"纸边的红印透到了背面。", "archive_index":"三件遗留物夹在抽屉边。", "media_alignment":"比较同一画面的三个位置。", "positioning_calibration":"旧压痕与试压纸都留在工位。", "power_topology":"两端的线束保留着同一批绕线痕。", "evacuation_route":"脚印在转角处换了方向。"}.get(id,"")
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size=Vector2(0,342);size_flags_horizontal=Control.SIZE_EXPAND_FILL
	resized.connect(queue_redraw)
func words(at:Vector2,text:String,points:int=16,ink:Color=INK)->void:draw_string(Type.body_font(),at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,points,ink)
func line(a:Vector2,b:Vector2,ink:Color=INK,width:float=2)->void:draw_line(a,b,ink,width)
func door(at:Vector2,scale:float=1,ink:Color=INK)->void:
	draw_rect(Rect2(at,Vector2(28,42)*scale),ink,false,2);line(at+Vector2(14,0)*scale,at+Vector2(14,42)*scale,ink)
func _draw()->void:
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE*(size.x/344.0))
	draw_rect(Rect2(0,0,344,342),Color("e8dec4"));draw_rect(Rect2(7,7,330,328),FADED,false,1)
	match puzzle_id:
		"archive_index":
			words(Vector2(20,30),"归档袋上的残签",17)
			draw_rect(Rect2(23,45,298,66),Color("c9bb99"))
			words(Vector2(38,72),"冲印  94 / 11",22);words(Vector2(38,98),"末两位沿用底片齿孔号",12,FADED)
			for x:int in range(28,320,22):draw_rect(Rect2(x,47,8,6),INK)
			words(Vector2(20,137),"夹页剖面",16)
			for i:int in 3:
				var y:float=151+i*37
				line(Vector2(37,y),Vector2(160,y));line(Vector2(37,y),Vector2(37,y+30))
				if i==0:draw_circle(Vector2(107,y+16),9,RED);line(Vector2(107,y+16),Vector2(143,y+16),RED)
			line(Vector2(30,265),Vector2(165,265));words(Vector2(40,282),"地面",13,FADED)
			words(Vector2(186,140),"胶片边角",16)
			draw_rect(Rect2(182,152,139,139),INK,false,2);door(Vector2(205,213),1.35)
			for y:int in [168,187]:
				line(Vector2(199,y),Vector2(301,y));line(Vector2(294,y-6),Vector2(301,y));line(Vector2(294,y+6),Vector2(301,y))
			words(Vector2(203,280),"←  出入口  →",13)
		"duty_board":
			words(Vector2(20,31),"签到夹里的一角",18)
			for i:int in 2:
				var r:=Rect2(48+i*90,64+i*79,173,95)
				draw_rect(Rect2(r.position+Vector2(3,4),r.size),FADED);draw_rect(r,Color("f1e7ce"))
				line(r.position+Vector2(102,0),r.position+Vector2(102,95),RED,3)
				words(r.position+Vector2(14,44),"墨迹" if i==0 else "透印",17)
			words(Vector2(22,282),"纸背透出的印，左右相反。",16)
			words(Vector2(22,309),"夹口与夹尾也留着红泥。",16)
		"media_alignment":
			words(Vector2(20,30),"三处取景残角",18)
			for i:int in 3:
				var at:=Vector2(32,59+i*87)
				draw_rect(Rect2(at,Vector2(277,68)),FADED,false)
				if i==0:door(at+Vector2(23,13))
				elif i==1:
					for n:int in 4:line(at+Vector2(18+n*10,53-n*10),at+Vector2(45+n*10,53-n*10))
				else:
					for n:int in 3:draw_rect(Rect2(at+Vector2(15+n*20,17),Vector2(14,23)),INK,false)
				words(at+Vector2(110,37),["门框缺口", "梯沿斜纹", "中幅落款"][i],17)
				line(at+Vector2(100,48),at+Vector2(254,48),FADED)
		"positioning_calibration":
			words(Vector2(20,31),"留存试压纸",18)
			for i:int in 3:
				var center:=Vector2(66+i*104,113)
				draw_rect(Rect2(center-Vector2(41,54),Vector2(83,121)),Color("d5d1ba"))
				var end:float=4.4 if i==0 else TAU
				draw_arc(center,23,0,end,32,INK,2 if i<2 else 6)
				if i==2:
					for n:int in 5:line(center+Vector2(23,0).rotated(n*1.2),center+Vector2(33,0).rotated(n*1.2),INK)
				words(center+Vector2(-27,80),["未透", "成形", "破边"][i],17)
			words(Vector2(22,241),"压头弹簧 / 留存成形行程",16)
			line(Vector2(45,262),Vector2(297,262),FADED)
			for i:int in 5:line(Vector2(45+i*63,256),Vector2(45+i*63,272),FADED)
			var pressure:int=int(source.registration.calibration.pressure)
			line(Vector2(45,285),Vector2(45+pressure*63,285),RED,4)
			words(Vector2(22,319),"比较行程，再试压；观察纸边。",15)
		"power_topology":
			words(Vector2(20,30),"线束抽样 / 接头留痕",18)
			var pairs:Array=[["大厅","西廊"],["后区","教室"],["东廊","大厅"],["西廊","后区"],["教室","东廊"]]
			for i:int in pairs.size():
				var y:float=67+i*51
				words(Vector2(22,y),pairs[i][0],15);words(Vector2(247,y),pairs[i][1],15)
				for x:int in [99,193]:
					line(Vector2(x-10,y-6),Vector2(x+39,y-6),INK,3)
					for j:int in i+1:line(Vector2(x+j*6,y-14),Vector2(x+j*6,y+2),RED,2)
		"evacuation_route":
			words(Vector2(20,31),"夜间鞋底拓片",18)
			var order:Array=[3,0,2,1]
			for i:int in 4:
				var n:int=order[i];var at:=Vector2(28,64+i*63)
				words(at+Vector2(60,20),["202 门外", "东侧墙边", "核心转角", "主梯黄线"][n],17)
				var dir:float=[0.0,0.0,PI/2,PI][n]
				var toe:=at+Vector2(20,12)+Vector2(0,-11).rotated(dir)
				draw_circle(toe,8,INK);line(toe,toe+Vector2(0,19).rotated(dir),INK,9)
				for j:int in 3:line(at+Vector2(165+j*14,13),at+Vector2(172+j*14,22),FADED)
	draw_set_transform(Vector2.ZERO)
