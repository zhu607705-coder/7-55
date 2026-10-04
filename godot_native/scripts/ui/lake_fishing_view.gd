extends Control
## Native presentation of the active source LakeFishingRitualVisual.
## Reads the existing model. Input, audio, results and saves stay in its host.
const INK = Color("092f36")
const GOLD = Color("ffdd83")
const PALE = Color("e8f5cc")
const MINT = Color("76dfc9")
const RED = Color("f27f69")
var host: Control
var background: Texture2D
var angler: Texture2D
var font: Font
var labels: Dictionary = {}
var reduced_motion := false
var visual_time := 0.0
var reaction_at := -10.0
var reaction_good := true
var seen_judgments: Dictionary = {}
var feedback := ""
var feedback_until := 0.0

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	background = load("res://assets/rpg/qizhen_fishing/qizhen_fishing_dawn_environment.png")
	angler = load("res://assets/rpg/qizhen_fishing/player_blue_fishing_skiff.png")
	font = load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	var state := get_node_or_null("/root/State")
	if state: reduced_motion = bool(state.d.native.settings.get("reduced_motion",false))
	for key in ["title","target","phase","instruction","feedback","swan","tension","guide","beat_action","next_beat","count_in","result","result_body","modal","modal_body"]:
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_override("font",font)
		# Source-palette edge keeps cues legible over both sky and water.
		label.add_theme_color_override("font_outline_color",INK)
		label.add_theme_constant_override("outline_size",4)
		label.add_theme_color_override("font_color",PALE)
		add_child(label)
		labels[key] = label
	for i in range(4):
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font",font)
		# Source-palette edge keeps cues legible over both sky and water.
		label.add_theme_color_override("font_outline_color",INK)
		label.add_theme_constant_override("outline_size",4)
		add_child(label)
		labels["beat"+str(i)] = label

func reset_view() -> void:
	visual_time = 0
	reaction_at = -10
	feedback_until = 0
	feedback = ""
	seen_judgments.clear()

func advance_view(delta: float) -> void:
	if not is_instance_valid(host) or host.model==null: return
	if not host.paused and (host.running or host.sent): visual_time += delta
	for note: Dictionary in host.model.notes:
		if str(note.judgment).is_empty() or seen_judgments.has(note.index): continue
		seen_judgments[note.index] = true
		reaction_at = visual_time
		reaction_good = note.judgment!="miss"
		feedback = "漂亮！把湖拽近了一截" if note.judgment=="perfect" else ("这一钩脱了，跟住鱼影！" if note.judgment=="miss" else "稳住，再收一截")
		feedback_until = visual_time+.8
	_layout_labels()
	queue_redraw()

func _label(key: String,text: String,rect: Rect2,point_size: int,color: Color=PALE,shown: bool=true) -> void:
	var label: Label = labels[key]
	label.visible = shown
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size",point_size)
	label.add_theme_color_override("font_color",color)

func _layout_labels() -> void:
	if labels.is_empty() or host.model==null: return
	var m: RefCounted = host.model
	var w: float = size.x
	var h: float = size.y
	var portrait := w<600
	var short := h<420
	var ending: bool = host.sent or m.phase in ["failed","completed"]
	var modal: bool = not host.running or host.paused
	var stage_text: String = {"casting":"01 / 瞄准抛竿","count_in":"02 / 四拍预备","fighting":"03 / 跟拍遛鱼"}.get(m.stage,"")
	_label("title","启真湖拒绝被钓",Rect2(12,4,w*.55-24,30) if short else Rect2(12,8,w-24,32),20 if short else 22)
	_label("target","这一竿 · "+str(host.config.get("title","")),Rect2(w*.55,6,w*.45-12,27) if short else Rect2(12,42,w-24,27),16,Color("b7d9c7"))
	_label("phase",stage_text,Rect2(w*.55,34,w*.45-12,26) if short else Rect2(12,70,w-24,28),16,GOLD,not ending)
	var holding: bool = m.controls.has("hook")
	var instruction := "蓄到绿色区 · 松手抛竿" if holding else "左右对准鱼影 · 按住蓄力"
	if str(m.cue).begins_with("抛偏") or str(m.cue).begins_with("太轻") or str(m.cue).begins_with("太重"): instruction = m.cue
	_label("instruction",instruction,instruction_rect(),17,Color("fff0c2"),m.stage=="casting" and not modal)
	_label("feedback",feedback,Rect2(18,h*.60-22,w-36,48),19,GOLD if reaction_good else Color("ffb195"),visual_time<feedback_until and not ending and not host.paused)
	var swan_text := "嘎！松手！" if m.rushing_at(m.elapsed) else ("现在，起鱼！" if m.lift_ready() else "它也在钓你。")
	_label("swan",swan_text,Rect2(w*.82-85,h*.39-65,160,30),14,Color("d2e7c2"),not ending and not modal and not short)
	_label("tension","抛竿力度" if m.stage=="casting" else "张力 %d%%"%roundi(m.tension),Rect2(12,meter_y()-28,w-24,25),15,PALE,not ending and not modal)
	_label("guide",guide_text(),Rect2(12,h-guide_height()-4,w-24,guide_height()),15 if portrait else 16,PALE,not ending and not modal)
	var rhythm: Vector2 = m.rhythm_position(m.elapsed)
	var beat_y: float = 227 if portrait else h-137
	if short: beat_y = 130
	var music_visible: bool = m.stage!="casting" and not ending and not modal
	var track: float = w*.5 if portrait else w*.65
	var spacing: float = minf(75,(w-70)/3.0) if portrait else 106
	var commands := ["按住稳线","松开放线","按住收线","松开起鱼"]
	_label("beat_action","听四拍，准备开始" if m.stage=="count_in" else commands[int(rhythm.x)],Rect2(track-minf(w-24,430)/2,beat_y-65,minf(w-24,430),32),20,GOLD,music_visible)
	_label("next_beat",m.rhythm_name+" · %d BPM  下一拍："%roundi(60/m.beat_sec)+commands[(int(rhythm.x)+1)%4],Rect2(12,beat_y-33,w-24,28),14,Color("b5d0bf"),music_visible and m.stage=="fighting" and not short)
	for i in range(4):
		_label("beat"+str(i),["按住","松开","按住","松开"][i],Rect2(track+(i-1.5)*spacing-35,beat_y+12,70,25),14,GOLD if i==int(rhythm.x) else Color("9ebfb1"),music_visible)
	var count_in: int = maxi(1,4-int((m.elapsed-m.cast_at)/m.beat_sec))
	_label("count_in","预备 %d"%count_in,Rect2(w*.4,158,w*.5,36) if short else Rect2(12,h*.43,w-24,48),26 if short else 32,GOLD,m.stage=="count_in" and not modal)
	var result_text := "这一口，湖认输了" if host.sent else "这次，湖把你钓走了"
	var result_body: String = str(host.config.get("title",""))+"浮上来了\n%s · 收获 %d / %d"%[str(m.final_result.get("grade","")),m.final_result.get("notes_hit",0),m.notes.size()] if host.sent else host._fishing_hint()
	_label("result",result_text,Rect2(22,62,w-44,34) if short else Rect2(22,h*.36,w-44,42),23,GOLD,ending)
	_label("result_body",result_body,Rect2(30,104,w-60,52) if short else Rect2(30,h*.45,w-60,86),17,PALE,ending)
	_label("modal","已暂停" if host.paused else "准备好了吗？",Rect2(24,62,w-48,34) if short else Rect2(24,h*.35,w-48,38),24,PALE,modal and not ending)
	_label("modal_body","继续后从同一时刻恢复" if host.paused else ("先对准鱼影，按住蓄力再松手\n可用下方按键，也可在水面拖动" if host.fishing_controls_enabled else "A / D 控线，空格蓄力再松开\n也可直接按住水面拖动"),Rect2(24,104,w-48,48) if short else Rect2(24,h*.42,w-48,64),17,MINT,modal and not ending)

func guide_height() -> float:
	return 46.0 if size.x<600 and not host.fishing_controls_enabled else 28.0

func meter_y() -> float:
	return size.y-guide_height()-28.0

func guide_text() -> String:
	if host.fishing_controls_enabled: return ("按住蓄力 / 松开抛竿" if host.model.stage=="casting" else "按住收线 / 松开提竿")+" · 可拖动水面"
	if size.x<600: return "A / D 控线 · 空格按住 / 松开\n可在水面拖动 · Esc 暂停"
	return "A / D 控线 · 空格按住 / 松开 · 鼠标可在水面拖动"

func instruction_rect() -> Rect2:
	return Rect2(18,70,size.x-36,42) if size.y<420 else Rect2(18,126,size.x-36,50)

func start_rect() -> Rect2:
	return Rect2(Vector2(size.x/2-100,166 if size.y<420 else size.y*.58),Vector2(200,48))

func _draw() -> void:
	if not is_instance_valid(host) or host.model==null or size.x<=0 or size.y<=0: return
	var m: RefCounted = host.model
	var w: float = size.x
	var h: float = size.y
	var portrait := w<600
	var t: float = 0 if reduced_motion else visual_time
	var ending: bool = host.sent or m.phase in ["failed","completed"]
	if background:
		var factor: float = maxf(w/background.get_width(),h/background.get_height())
		var rendered: Vector2 = background.get_size()*factor
		draw_texture_rect(background,Rect2((size-rendered)/2,rendered),false)
	else: draw_rect(Rect2(Vector2.ZERO,size),Color("164f53"))
	draw_rect(Rect2(0,0,w,80 if h<420 else 122),Color(INK,.88))
	if m.stage=="casting" and host.running and not host.paused and not ending:
		_round(instruction_rect(),Color(INK,.9),5)
	draw_rect(Rect2(0,meter_y()-33,w,h-meter_y()+33),Color(INK,.78))
	draw_line(Vector2(20,80 if h<420 else 122),Vector2(w-20,80 if h<420 else 122),Color(GOLD,.38))
	for i in range(38):
		var x: float = fmod(i*97.31+sin(t*.4+i)*9,w)
		var y: float = h*.39+fmod(i*43.7,h*.39)
		draw_line(Vector2(x,y),Vector2(x+5+i%15,y),Color(GOLD if i%3==0 else MINT,.12+sin(t+i)*.06),2 if i%3==0 else 1)
	var water_y: float = h*.56
	var fish_x: float = w*.5+m.fish_x()*w*.29
	var hook_x: float = w*.5+m.line_x*w*.29
	_draw_creature(Vector2(fish_x*.35+w*.33,water_y+h*.16),.68 if portrait else 1.16,t,m.controls.has("hook"),float(m.judged)/maxi(1,m.notes.size()))
	_draw_swan(Vector2(w*.82+sin(t*.5)*10,h*.39),.67 if portrait else .85,t,m.rushing_at(m.elapsed))
	var fish_scale: float = .84 if portrait else 1
	var fish_color: Color = GOLD if m.lift_ready() else (Color("bc6650") if m.rushing_at(m.elapsed) else Color("184941"))
	_ellipse(Vector2(fish_x,water_y),Vector2(108,46)*fish_scale,Color(GOLD if m.lift_ready() else RED if m.rushing_at(m.elapsed) else MINT,.2+(sin(t*5)*.5+.5)*.1 if m.lift_ready() else .1))
	_draw_fish(Vector2(fish_x,water_y),fish_scale,t,fish_color)
	_ring(Vector2(fish_x,water_y+4),Vector2(80,25)*fish_scale,Color(GOLD if m.lift_ready() else MINT,.8 if m.aligned() else .3),2)
	if m.stage=="casting":
		draw_line(Vector2(hook_x-15,water_y),Vector2(hook_x+15,water_y),Color(PALE,.8))
		draw_line(Vector2(hook_x,water_y-13),Vector2(hook_x,water_y+13),Color(PALE,.8))
	var tip := _draw_angler(Vector2(w*(.26 if portrait else .16),h*.82),.73 if portrait else 1,t,m.line_x,m.tension,m.controls.has("hook"),not ending)
	_draw_fishing_line(tip,Vector2(hook_x,water_y+9),m.tension,m.rushing_at(m.elapsed),t)
	_ellipse(Vector2(hook_x,water_y+20),Vector2(24,7),Color(Color("062b30"),.45))
	_round(Rect2(hook_x-4,water_y+1,8,22),Color("f7e7b8"),3)
	_round(Rect2(hook_x-4,water_y+1,8,11),Color("e86543") if m.aligned() else Color("7e7570"),3)
	draw_line(Vector2(hook_x,water_y-4),Vector2(hook_x,water_y+1),Color("2a3932"))
	_draw_splash(Vector2(hook_x,water_y+10),visual_time-reaction_at,reaction_good)
	if m.lift_ready() and m.stage=="fighting":
		for i in range(6):
			var a: float = i*PI/3+t
			draw_rect(Rect2(fish_x+cos(a)*54-2,water_y+sin(a)*25-2,4,4),Color(GOLD,.8))
	if m.stage!="casting" and not ending and host.running and not host.paused:
		var rhythm: Vector2 = m.rhythm_position(m.elapsed)
		var track: float = w*.5 if portrait else w*.65
		var spacing: float = minf(75,(w-70)/3) if portrait else 106
		var beat_y: float = 227 if portrait else h-137
		if h<420: beat_y=130
		var first: float = track-1.5*spacing
		draw_line(Vector2(first,beat_y),Vector2(track+1.5*spacing,beat_y),Color(MINT,.25),2)
		var cursor: float = first+minf(3,rhythm.x+rhythm.y)*spacing
		draw_line(Vector2(first,beat_y),Vector2(cursor,beat_y),Color(GOLD,.72),2)
		draw_circle(Vector2(cursor,beat_y),3,PALE)
		for i in range(4):
			var pulse: float = exp(-rhythm.y*8)
			var center := Vector2(track+(i-1.5)*spacing,beat_y)
			draw_circle(center,5+pulse*2 if i==int(rhythm.x) else 4,GOLD if i==int(rhythm.x) else Color("375e56"))
			if i==int(rhythm.x): draw_arc(center,9+(1-pulse)*5,0,TAU,36,Color(GOLD,pulse*.7))
	var meter_x: float = 36 if portrait else w*.35
	var meter_width: float = w-72 if portrait else w*.36
	var value: float = m.cast_power() if m.stage=="casting" else m.tension/100
	_round(Rect2(meter_x,meter_y(),meter_width,12),Color(Color("051f28"),.9),4)
	if m.stage=="casting": draw_rect(Rect2(meter_x+meter_width*.3,meter_y(),meter_width*.6,12),Color(MINT,.4))
	var meter_color: Color = (MINT if value>=.3 and value<=.9 else GOLD) if m.stage=="casting" else (RED if value>=.8 else GOLD)
	_round(Rect2(meter_x,meter_y()+2,maxf(3,meter_width*minf(value,1)),8),Color(meter_color,.95),3)
	for i in range(m.notes.size()):
		var judgment: String = m.notes[i].judgment
		draw_circle(Vector2((w*.275 if h<420 else w/2)+(i-(m.notes.size()-1)/2.0)*16,48 if h<420 else 108),3.3,Color("436b61") if judgment.is_empty() else RED if judgment=="miss" else GOLD)
	if ending:
		draw_rect(Rect2(Vector2.ZERO,size),Color(Color("062b32"),.86))
		_round(Rect2(16,50,w-32,178) if h<420 else Rect2(w*.08,h*.27,w*.84,h*.49),Color(0,0,0,0),12,Color(GOLD,.55))
		if host.sent: _draw_catch(Vector2(w/2,h*.22+sin(t*3)*2),str(host.config.get("spotId","fish")))
	elif not host.running or host.paused:
		_round(Rect2(16,50,w-32,178) if h<420 else Rect2(16,h*.28,w-32,h*.43),Color(Color("062b32"),.93),8,Color(GOLD,.6))

func _ellipse(center: Vector2,dimensions: Vector2,color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(40): points.append(center+Vector2(cos(i*TAU/40),sin(i*TAU/40))*dimensions*.5)
	draw_colored_polygon(points,color)

func _ring(center: Vector2,dimensions: Vector2,color: Color,width: float=1) -> void:
	var points := PackedVector2Array()
	for i in range(41): points.append(center+Vector2(cos(i*TAU/40),sin(i*TAU/40))*dimensions*.5)
	draw_polyline(points,color,width,true)

func _triangle(a: Vector2,b: Vector2,c: Vector2,color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([a,b,c]),color)

func _round(rect: Rect2,color: Color,radius: int,border: Color=Color(0,0,0,0)) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color=color;box.corner_radius_top_left=radius;box.corner_radius_top_right=radius
	box.corner_radius_bottom_left=radius;box.corner_radius_bottom_right=radius
	box.border_color=border;box.set_border_width_all(1 if border.a>0 else 0)
	draw_style_box(box,rect)

func _draw_fish(p: Vector2,s: float,t: float,color: Color) -> void:
	_ellipse(p,Vector2(48,20)*s,Color(color,.95))
	_triangle(p+Vector2(-19,0)*s,p+Vector2(-37*s,-13*s+sin(t*7)*3),p+Vector2(-37*s,13*s+sin(t*7)*3),Color(color,.95))
	_triangle(p+Vector2(-2,-8)*s,p+Vector2(2,-19)*s,p+Vector2(13,-7)*s,Color(color,.95))
	_ellipse(p+Vector2(3,4)*s,Vector2(30,6)*s,Color(Color("eecb87"),.5))
	draw_circle(p+Vector2(16,-3)*s,2*s,GOLD)
	draw_line(p+Vector2(9,-6)*s,p+Vector2(6,5)*s,Color(INK,.7))

func _draw_creature(p: Vector2,s: float,t: float,pulling: bool,progress: float) -> void:
	var breathe: float=sin(t*1.6)*3
	var rise: float=progress*20
	_ellipse(p+Vector2(0,15*s),Vector2(340,76)*s,Color(Color("062d36"),.2))
	_ellipse(p+Vector2(0,breathe-rise),Vector2(285,87)*s,Color(Color("174d4b"),.42))
	_ellipse(p+Vector2(-7*s,-13*s+breathe-rise),Vector2(228,42)*s,Color(Color("29695b"),.32))
	_triangle(p+Vector2(-120*s,-rise),p+Vector2(-193*s,-48*s+sin(t*2)*8),p+Vector2(-177*s,56*s),Color(Color("0b3b3e"),.4))
	for row in range(4):
		for i in range(14):
			if absf(i-7)*.12+absf(row-2)*.18>1.04: continue
			var at:=p+Vector2((i-7)*16*s+(row%2)*8*s,(row-2)*14*s+breathe-rise)
			draw_arc(at,7*s,.2,PI-.2,10,Color(Color("6da787"),.15))
	var eye:=p+Vector2(102*s,-17*s+breathe-rise)
	_ellipse(eye,Vector2(33,24)*s,Color(Color("163d39"),.8))
	_ellipse(eye+Vector2(3*s,0),Vector2(17,14)*s,Color(GOLD,.72))
	_ellipse(eye+Vector2(5*s,0),Vector2(4,13)*s,INK)
	draw_arc(p+Vector2(111*s,8*s-rise),24*s,-.2,1.2,20,Color(Color("8eb493"),.28),2)
	draw_polyline(PackedVector2Array([p+Vector2(126*s,12*s-rise),p+Vector2(165*s,17*s+sin(t)*5-rise),p+Vector2(193*s,2*s-rise)]),Color(PALE,.28))
	if pulling:
		draw_polyline(PackedVector2Array([p+Vector2(124*s,-rise),p+Vector2(143*s,-64*s-rise),p+Vector2(184*s,-76*s-rise)]),Color(GOLD,.4))
		_ellipse(p+Vector2(185*s,-79*s-rise),Vector2(24,6)*s,Color(Color("dec18a"),.8))

func _draw_swan(p: Vector2,s: float,t: float,rush: bool) -> void:
	var bob: float=sin(t*2)*2
	_ellipse(p+Vector2(0,14*s),Vector2(82,14)*s,Color(Color("092f34"),.25))
	_ellipse(p+Vector2(0,bob),Vector2(62,28)*s,Color("10242b"))
	_triangle(p+Vector2(-22*s,0),p+Vector2(-40,-12)*s,p+Vector2(-34,8)*s,Color("10242b"))
	draw_polyline(PackedVector2Array([p+Vector2(19*s,-3*s+bob),p+Vector2(30*s,-17*s+bob),p+Vector2(27*s,-36*s+bob),p+Vector2(19*s,-43*s+bob)]),Color("10242b"),10*s,true)
	_ellipse(p+Vector2(19*s,-43*s+bob),Vector2(18,14)*s,Color("152b31"))
	_triangle(p+Vector2(14*s,-45*s+bob),p+Vector2(s,-40*s+bob),p+Vector2(14*s,-38*s+bob),Color("cf5b36"))
	draw_circle(p+Vector2(17*s,-46*s+bob),1.2*s,Color("ffe8bc"))
	for i in range(6): draw_arc(p+Vector2((-9+i*5)*s,-2*s),11*s,.1,2,15,Color(Color("547273"),.8))
	if rush:
		draw_line(p+Vector2(-35,-28)*s,p+Vector2(-42,-33)*s,Color(GOLD,.65),2)
		draw_line(p+Vector2(-29,-35)*s,p+Vector2(-32,-42)*s,Color(GOLD,.65),2)
	_ring(p+Vector2(0,15*s),Vector2(79*s+sin(t*3)*5,14*s),Color(PALE,.35))

func _draw_angler(p: Vector2,s: float,t: float,lean: float,tension: float,held: bool,shown: bool) -> Vector2:
	var bob: float=sin(t*1.8)*2
	var target_width: float=224*s
	var dimensions: Vector2=angler.get_size()*(target_width/angler.get_width())
	var origin:=p+Vector2(0,25*s+bob)
	var angle: float=deg_to_rad(lean*1.2+(-.6 if held else 0))
	_ellipse(p+Vector2(0,26*s),Vector2(target_width,20*s),Color(Color("082e35"),.3))
	if shown:
		draw_set_transform(origin,angle)
		draw_texture_rect(angler,Rect2(Vector2(-dimensions.x/2,-dimensions.y),dimensions),false)
		draw_set_transform(Vector2.ZERO)
	var hand: Vector2=origin+Vector2(target_width*.121,-dimensions.y*.465).rotated(angle)
	var tip:=hand+Vector2((88+lean*10)*s,-(83-tension*.27)*s)
	draw_polyline(PackedVector2Array([hand+Vector2(-9,10)*s,hand,hand+Vector2(35,-45)*s,tip+Vector2(-24,-6)*s,tip]),Color("314e46"),4*s,true)
	draw_line(hand,hand+Vector2(35,-45)*s,Color(GOLD,.7))
	draw_circle(hand+Vector2(-6,12)*s,6*s,Color("a79c74"))
	draw_circle(hand+Vector2(-6,12)*s,3*s,Color("294239"))
	return tip

func _draw_fishing_line(a: Vector2,b: Vector2,tension: float,rush: bool,t: float) -> void:
	var points:=PackedVector2Array()
	for i in range(25):
		var u: float=i/24.0
		points.append(a.lerp(b,u)+Vector2(sin(u*PI)*sin(t*20)*(3 if rush else .5),sin(u*PI)*(1-tension/100)*46))
	draw_polyline(points,Color(INK,.35),3,true)
	draw_polyline(points,Color(RED if tension>80 else Color("ffe5a9"),.95),1.2,true)

func _draw_splash(p: Vector2,seconds: float,good: bool) -> void:
	if seconds<0 or seconds>.75: return
	var amount: float=seconds/.75
	_ring(p,Vector2(20+amount*105,7+amount*31),Color(GOLD if good else MINT,(1-amount)*.75),2)
	for i in range(9):
		var a: float=i/9.0*TAU
		draw_circle(p+Vector2(cos(a)*amount*55,sin(a)*amount*18-sin(amount*PI)*22),2.4-amount,Color(PALE if good else MINT,1-amount))

func _draw_catch(p: Vector2,kind: String) -> void:
	if kind in ["fish","lake"]: _draw_fish(p,1.7,0,GOLD)
	elif kind=="locker_key":
		draw_arc(p+Vector2(-11,0),10,0,TAU,32,GOLD,4)
		draw_line(p,p+Vector2(31,0),GOLD,4)
		draw_line(p+Vector2(20,0),p+Vector2(20,11),GOLD,4)
		draw_line(p+Vector2(29,0),p+Vector2(29,8),GOLD,4)
	elif kind=="net_frame":
		_ring(p,Vector2(56,38),GOLD,4)
		draw_line(p+Vector2(0,20),p+Vector2(0,43),GOLD,4)
		for i in range(-2,3):
			draw_line(p+Vector2(i*9,-15),p+Vector2(i*9,15),Color(GOLD,.5))
			draw_line(p+Vector2(-23,i*6),p+Vector2(23,i*6),Color(GOLD,.5))
	else:
		_round(Rect2(p-Vector2(22,27),Vector2(44,54)),GOLD,3)
		_round(Rect2(p+Vector2(8,-30),Vector2(9,20)),Color(0,0,0,0),4,Color("9aac9b"))
		for i in range(4): draw_line(p+Vector2(-13,-12+i*9),p+Vector2(12,-12+i*9),Color(INK,.5),2)
