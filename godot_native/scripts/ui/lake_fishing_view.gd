extends Control
## Native presentation of the active source LakeFishingRitualVisual.
## Reads the existing model. Input, audio, results and saves stay in its host.
const Motion = preload("res://scripts/ui/lake_fishing_motion.gd")
const INK = Color("092f36")
const GOLD = Color("ffdd83")
const PALE = Color("e8f5cc")
const MINT = Color("76dfc9")
const RED = Color("f27f69")
var host: Control
var background: Texture2D
var angler: Texture2D
var angler_poses: Dictionary = {}
const ANGLER_GRIPS := {
	"rest": [Vector2(850,550),Vector2(961,535)],
	"pull": [Vector2(845,499),Vector2(925,434)],
	"release": [Vector2(1009,538),Vector2(1145,439)]
}
# Effective alpha>=8 bounds ignore sparse edge noise without editing source PNGs.
const ACTOR_REGIONS := {
	"fish": Rect2(120,416,1014,465),
	"swan": Rect2(106,212,1113,885),
	"creature": Rect2(15,147,1739,595)
}
const ACTOR_ANCHORS := {
	"fish": Vector2(646,269),
	"swan": Vector2(633,663),
	"creature": Vector2(1075,323)
}
var actor_textures: Dictionary = {}
var font: Font
var labels: Dictionary = {}
var reduced_motion := false
var visual_time := 0.0
var reaction_at := -10.0
var reaction_good := true
var seen_judgments: Dictionary = {}
var feedback := ""
var feedback_until := 0.0
var current_motion: Dictionary = {}

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	background = load("res://assets/rpg/qizhen_fishing/lake_fishing_cleanplate.png")
	angler = load("res://assets/rpg/qizhen_fishing/player_blue_fishing_skiff.png")
	angler_poses = {"pull":load("res://assets/rpg/qizhen_fishing/angler_pull.png"),"release":load("res://assets/rpg/qizhen_fishing/angler_release.png")}
	actor_textures = {
		"fish": load("res://assets/rpg/qizhen_fishing/target_fish.png"),
		"swan": load("res://assets/rpg/qizhen_fishing/distant_black_swan.png"),
		"creature": load("res://assets/rpg/qizhen_fishing/submerged_lake_creature.png")
	}
	# High-resolution source art is heavily minified at the original native size.
	# Actor-only mip filtering prevents noisy sparkle; the pixel lake/skiff stay unchanged.
	for key: String in actor_textures:
		var filtered := CanvasTexture.new()
		filtered.diffuse_texture = actor_textures[key]
		filtered.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		actor_textures[key] = filtered
	font = load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	var state := get_node_or_null("/root/State")
	if state: reduced_motion = bool(state.d.native.settings.get("reduced_motion",false))
	for key in ["title","target","phase","instruction","feedback","swan","tension","progress","guide","beat_action","next_beat","count_in","result","result_body","modal","modal_body"]:
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_override("font",font)
		# Source-palette edge keeps cues legible over both sky and water.
		label.add_theme_color_override("font_outline_color",INK)
		label.add_theme_constant_override("outline_size",1)
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
		label.add_theme_constant_override("outline_size",1)
		add_child(label)
		labels["beat"+str(i)] = label

func reset_view() -> void:
	visual_time = 0
	reaction_at = -10
	feedback_until = 0
	feedback = ""
	seen_judgments.clear()
	current_motion.clear()

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
	var short := h<420
	var ending: bool = host.sent or m.phase in ["failed","completed"]
	var modal: bool = not host.running or host.paused
	var header := header_rect()
	var stage_text: String = {"casting":"01 · 瞄准抛竿","count_in":"02 · 四拍预备","fighting":"03 · 跟拍遛鱼"}.get(m.stage,"")
	_label("title","启真湖拒绝被钓",Rect2(header.position+Vector2(16,6),Vector2(header.size.x-32,26)),18)
	_label("target","这一竿 · "+str(host.config.get("title","")),Rect2(header.position+Vector2(16,34),Vector2(header.size.x*.56-16,22)),13,Color("c2d0b3"))
	_label("phase",stage_text,Rect2(header.position+Vector2(header.size.x*.56,34),Vector2(header.size.x*.44-16,22)),13,GOLD,not ending)
	var holding: bool = m.controls.has("hook")
	var instruction := "蓄到绿色区 · 松手抛竿" if holding else "左右对准鱼影 · 按住蓄力"
	if str(m.cue).begins_with("抛偏") or str(m.cue).begins_with("太轻") or str(m.cue).begins_with("太重"): instruction = m.cue
	_label("instruction",instruction,instruction_rect().grow(-4),14,Color("fff0c2"),m.stage=="casting" and not modal and not ending)
	_label("feedback",feedback,Rect2(18,h*.60-18,w-36,36),16,GOLD if reaction_good else Color("ffb195"),visual_time<feedback_until and not ending and not host.paused)
	var swan_text := "嘎！松手！" if m.rushing_at(m.elapsed) else "现在，起鱼！"
	_label("swan",swan_text,Rect2(w*.82-72,h*.39-55,140,26),13,Color("efe0aa"),not ending and not modal and not short and (m.rushing_at(m.elapsed) or m.lift_ready()))
	var meter := meter_plate_rect()
	_label("tension","抛竿力度" if m.stage=="casting" else "张力 %d%%"%roundi(m.tension),Rect2(meter.position+Vector2(16,3),Vector2(116,23)),13,PALE,not ending and not modal)
	_label("progress","收竿 %d / %d"%[m.judged,m.notes.size()],Rect2(meter.position+Vector2(meter.size.x-138,3),Vector2(122,23)),12,Color("bac8a6"),not ending and not modal)
	_label("guide",guide_text(),Rect2(8,h-25,w-16,21),12,Color("d5ddbb"),not ending and not modal)
	var rhythm: Vector2 = m.rhythm_position(m.elapsed)
	var beat_y: float = rhythm_y()
	var music_visible: bool = m.stage!="casting" and not ending and not modal
	var spacing: float = rhythm_spacing()
	var commands := ["按住稳线","松开放线","按住收线","松开起鱼"]
	_label("beat_action","听四拍，准备开始" if m.stage=="count_in" else commands[int(rhythm.x)],Rect2(w/2-180,beat_y-42,360,25),16,GOLD,music_visible)
	_label("next_beat",m.rhythm_name+" · %d BPM  下一拍："%roundi(60/m.beat_sec)+commands[(int(rhythm.x)+1)%4],Rect2(12,beat_y+33,w-24,21),12,Color("bfd0b4"),music_visible and m.stage=="fighting" and not short)
	for i in range(4):
		_label("beat"+str(i),["按住","松开","按住","松开"][i],Rect2(w/2+(i-1.5)*spacing-28,beat_y+9,56,21),12,GOLD if i==int(rhythm.x) else Color("9daf99"),music_visible)
	var count_in: int = maxi(1,4-int((m.elapsed-m.cast_at)/m.beat_sec))
	_label("count_in","预备 %d"%count_in,Rect2(12,h*.43,w-24,42),24,GOLD,m.stage=="count_in" and not modal)
	var result_text := "这一口，湖认输了" if host.sent else "这次，湖把你钓走了"
	var result_body: String = str(host.config.get("title",""))+"浮上来了\n%s · 收获 %d / %d"%[str(m.final_result.get("grade","")),m.final_result.get("notes_hit",0),m.notes.size()] if host.sent else host._fishing_hint()
	var panel := modal_rect()
	_label("result",result_text,Rect2(panel.position+Vector2(16,12),Vector2(panel.size.x-32,32)),20,GOLD,ending)
	_label("result_body",result_body,Rect2(panel.position+Vector2(20,48),Vector2(panel.size.x-40,64)),15,PALE,ending)
	_label("modal","已暂停" if host.paused else "准备好了吗？",Rect2(panel.position+Vector2(16,12),Vector2(panel.size.x-32,32)),20,PALE,modal and not ending)
	var instructions := "先对准鱼影，按住水面蓄力\n拖动控线 · 松手抛竿" if host.fishing_controls_enabled else "A / D 控线，空格蓄力再松开\n也可直接按住水面拖动"
	_label("modal_body","继续后从同一时刻恢复" if host.paused else instructions,Rect2(panel.position+Vector2(20,48),Vector2(panel.size.x-40,58)),15,MINT,modal and not ending)

func header_rect() -> Rect2:
	var width := minf(size.x-28,480)
	return Rect2((size.x-width)/2,10,width,64)

func guide_height() -> float:
	return 25.0

func meter_plate_rect() -> Rect2:
	var width := minf(size.x-32,400 if size.y<420 else 480)
	var left := size.x-width-28 if size.y<420 else (size.x-width)/2
	return Rect2(left,size.y-83,width,51)

func meter_y() -> float:
	return meter_plate_rect().position.y+30

func guide_text() -> String:
	if host.fishing_controls_enabled:
		return "按住水面蓄力 · 拖动控线 · 松手抛竿" if host.model.stage=="casting" else "拖动跟住鱼影 · 按住收线 / 松开提竿"
	return "A / D 控线 · 空格按住 / 松开 · 可拖动水面"

func instruction_rect() -> Rect2:
	var width := minf(size.x-36,390)
	return Rect2((size.x-width)/2,84,width,38)

func rhythm_y() -> float:
	return 128.0 if size.y<420 else 133.0

func rhythm_spacing() -> float:
	return minf(76,(size.x-96)/3.0)

func modal_rect() -> Rect2:
	var width := minf(size.x-32,470)
	return Rect2((size.x-width)/2,78 if size.y<420 else size.y*.30,width,177 if size.y<420 else 220)

func start_rect() -> Rect2:
	var panel := modal_rect()
	return Rect2(size.x/2-88,panel.end.y-62,176,44)

func _draw() -> void:
	if not is_instance_valid(host) or host.model==null or size.x<=0 or size.y<=0: return
	var m: RefCounted = host.model
	var w: float = size.x
	var h: float = size.y
	var portrait := w<600
	var t: float = 0 if reduced_motion else visual_time
	var ending: bool = host.sent or m.phase in ["failed","completed"]
	var active: bool = host.running and not host.paused and not ending
	if background:
		var factor: float = maxf(w/background.get_width(),h/background.get_height())
		var rendered: Vector2 = background.get_size()*factor
		draw_texture_rect(background,Rect2((size-rendered)/2,rendered),false)
	else: draw_rect(Rect2(Vector2.ZERO,size),Color("164f53"))
	# The exact existing model anchors own fish/float positions. Surface layers
	# only occlude their artwork; none can advance a judgment or reward.
	var water_y: float = h*.56
	var fish_x: float = w*.5+m.fish_x()*w*.29
	var hook_x: float = w*.5+m.line_x*w*.29
	var creature_pos := Vector2(fish_x*.35+w*.33,water_y+h*.16)
	var creature_scale: float = .68 if portrait else 1.16
	_draw_creature(creature_pos,creature_scale,t,m.controls.has("hook"),float(m.judged)/maxi(1,m.notes.size()))
	if not host.paused or current_motion.is_empty(): current_motion = Motion.sample(m,reduced_motion)
	var fish_scale: float = .84 if portrait else 1
	var fish_color: Color = Color("a69f62") if m.lift_ready() else (Color("685e48") if m.rushing_at(m.elapsed) else Color("254c42"))
	_draw_fish(Vector2(fish_x,water_y),fish_scale,t,fish_color,current_motion)
	_water_veil(Rect2(Vector2(fish_x,water_y)-Vector2(41,23)*fish_scale,Vector2(68,47)*fish_scale),.28)
	# Reflections pass above submerged objects and below surface actors.
	for i in range(38):
		var x: float = fmod(i*97.31+sin(t*.4+i)*9,w)
		var y: float = h*.39+fmod(i*43.7,h*.39)
		draw_line(Vector2(x,y),Vector2(x+5+i%15,y),Color(GOLD if i%3==0 else MINT,.10+sin(t+i)*.035),1)
	_ring(Vector2(fish_x,water_y+4),Vector2(80,23)*fish_scale,Color(GOLD if m.lift_ready() else MINT,.65 if m.aligned() else .22),1)
	_draw_resistance(Vector2(fish_x,water_y),fish_scale,current_motion)
	_draw_swan(Vector2(w*.82+sin(t*.5)*10,h*.39),.67 if portrait else .85,t,m.rushing_at(m.elapsed))
	if m.stage=="casting":
		draw_line(Vector2(hook_x-11,water_y),Vector2(hook_x+11,water_y),Color(PALE,.65))
		draw_line(Vector2(hook_x,water_y-10),Vector2(hook_x,water_y+10),Color(PALE,.65))
	var tip := _draw_angler(Vector2(w*(.26 if portrait else .16),h*.82),.73 if portrait else 1,t,m.line_x,m.tension,m.controls.has("hook"),not ending)
	_draw_fishing_line(tip,Vector2(hook_x,water_y+9),m.tension,current_motion)
	_draw_float(Vector2(hook_x,water_y+9),m.aligned(),t)
	_draw_splash(Vector2(hook_x,water_y+10),visual_time-reaction_at,reaction_good)
	if m.lift_ready() and m.stage=="fighting":
		_ring(Vector2(fish_x,water_y+4),Vector2(89,27)*fish_scale,Color(GOLD,.45+.2*sin(t*5)),1)
	# Compact code-owned HUD draws last, with no artwork baked into the plate.
	_hud_plate(header_rect())
	if active:
		if m.stage=="casting": _hud_plate(instruction_rect(),.87)
		else: _draw_rhythm(m)
		_draw_meter(m)
	if ending or not host.running or host.paused:
		# Keep the lake visible around a bounded, readable dialog.
		draw_rect(Rect2(Vector2.ZERO,size),Color(INK,.24))
		_hud_plate(modal_rect(),.96)
		if host.sent: _draw_catch(Vector2(w/2,modal_rect().position.y-35+sin(t*3)*2),str(host.config.get("spotId","fish")))

func _hud_plate(rect: Rect2,opacity: float=.93) -> void:
	_round(rect.grow(2),Color("071f25",.38),9)
	_round(rect,Color("123b3b",opacity),7,Color("b9b37a",.82))
	_round(rect.grow(-4),Color(0,0,0,0),4,Color("719381",.3))
	for corner: Vector2 in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
		var dir := Vector2(1 if corner.x==rect.position.x else -1,1 if corner.y==rect.position.y else -1)
		draw_line(corner+dir*Vector2(8,3),corner+dir*Vector2(15,3),Color("dbcc8f",.85))
		draw_line(corner+dir*Vector2(3,8),corner+dir*Vector2(3,15),Color("dbcc8f",.85))

func _draw_rhythm(m: RefCounted) -> void:
	var rhythm: Vector2 = m.rhythm_position(m.elapsed)
	var y: float = rhythm_y()
	var spacing: float = rhythm_spacing()
	var width := minf(size.x-28,430)
	_hud_plate(Rect2((size.x-width)/2,y-47,width,81 if size.y<420 else 104),.91)
	var first := size.x/2-1.5*spacing
	draw_line(Vector2(first,y),Vector2(first+spacing*3,y),Color("809d83",.55),1)
	var cursor: float = first+minf(3,rhythm.x+rhythm.y)*spacing
	draw_line(Vector2(first,y),Vector2(cursor,y),Color(GOLD,.78),2)
	for i in range(4):
		var current := i==int(rhythm.x)
		var center := Vector2(size.x/2+(i-1.5)*spacing,y)
		draw_circle(center,8,Color("0b2c32"))
		draw_arc(center,8,0,TAU,28,Color(GOLD if current else Color("84997b"),1 if current else .8),1.5)
		if current:
			draw_circle(center,4,GOLD)
			var pulse: float = 0 if reduced_motion else exp(-rhythm.y*8)
			draw_arc(center,11+(1-pulse)*3,0,TAU,28,Color(GOLD,pulse*.42))

func _draw_meter(m: RefCounted) -> void:
	var rect := meter_plate_rect()
	_hud_plate(rect,.91)
	var x: float = rect.position.x+20
	var width: float = rect.size.x-40
	var value: float = m.cast_power() if m.stage=="casting" else m.tension/100
	_round(Rect2(x,meter_y(),width,9),Color("08252c"),3,Color("79927b",.65))
	if m.stage=="casting": draw_rect(Rect2(x+width*.3,meter_y()+1,width*.6,7),Color(MINT,.27))
	var meter_color: Color = (MINT if value>=.3 and value<=.9 else GOLD) if m.stage=="casting" else (RED if value>=.8 else GOLD)
	if value>0:
		_round(Rect2(x+1,meter_y()+1,maxf(2,(width-2)*minf(value,1)),7),Color(meter_color,.92),2)
		draw_line(Vector2(x+width*minf(value,1),meter_y()-2),Vector2(x+width*minf(value,1),meter_y()+11),PALE,1)

func _water_veil(rect: Rect2,opacity: float) -> void:
	if not background: return
	var factor: float = maxf(size.x/background.get_width(),size.y/background.get_height())
	var origin: Vector2 = (size-background.get_size()*factor)/2
	var clipped := rect.intersection(Rect2(Vector2.ZERO,size))
	# Same screen-aligned lake texels add natural reflection detail and depth.
	draw_texture_rect_region(background,clipped,Rect2((clipped.position-origin)/factor,clipped.size/factor),Color(1,1,1,opacity))

func _draw_float(p: Vector2,aligned: bool,t: float) -> void:
	var bob: float = sin(t*2.7)*.7
	p.y+=bob
	_ring(p+Vector2(0,10),Vector2(34+sin(t*2)*3,7),Color(PALE,.48))
	_ring(p+Vector2(0,10),Vector2(51,11),Color(GOLD,.20))
	draw_line(p+Vector2(0,-19),p+Vector2(0,-10),Color("e2d9b0"),1)
	_round(Rect2(p+Vector2(-4,-10),Vector2(8,20)),Color("153d3c"),2)
	_round(Rect2(p+Vector2(-3,-10),Vector2(6,10)),Color("c95e43") if aligned else Color("9a6e58"),2)
	draw_rect(Rect2(p+Vector2(-3,0),Vector2(6,8)),Color("ddd6ad"))
	draw_line(p+Vector2(-2,-8),p+Vector2(-2,6),Color("fff0c7",.8),1)
	_water_veil(Rect2(p+Vector2(-5,7),Vector2(10,6)),.55)
	draw_line(p+Vector2(-8,10),p+Vector2(8,10),Color("dcd9ac",.68))

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

func _actor_rect(key: String,center: Vector2,width: float) -> Rect2:
	var region: Rect2 = ACTOR_REGIONS[key]
	var factor: float = width/region.size.x
	return Rect2(center-Vector2(ACTOR_ANCHORS[key])*factor,region.size*factor)

func _draw_actor(key: String,center: Vector2,width: float,tint: Color=Color.WHITE) -> Rect2:
	var rect := _actor_rect(key,center,width)
	var texture: Texture2D = actor_textures.get(key)
	if texture: draw_texture_rect_region(texture,rect,ACTOR_REGIONS[key],tint)
	return rect

func _draw_fish(p: Vector2,s: float,_t: float,color: Color,motion: Dictionary={}) -> void:
	var tint := Color(.9,.98,.94,.96)
	if color==GOLD or color==Color("a69f62"): tint=Color(1,1,.82,1)
	elif color==Color("685e48"): tint=Color(1,.86,.79,.96)
	if motion.is_empty():
		_draw_actor("fish",p,62*s,tint)
		return
	var texture: Texture2D=actor_textures.get("fish")
	if not texture:return
	var source: Rect2=ACTOR_REGIONS.fish
	# Twenty-four connected textured strips retain original pixels while the tail
	# and body bend independently. No whole-image rotate/translate surrogate.
	for i in range(24):
		var x0: float=i/24.0
		var x1: float=(i+1)/24.0
		var corners: Array[Vector2]=[Vector2(x0,0),Vector2(x1,0),Vector2(x1,1),Vector2(x0,1)]
		var points:=PackedVector2Array()
		var uvs:=PackedVector2Array()
		for uv: Vector2 in corners:
			points.append(p+Motion.fish_point(uv,62*s,motion))
			uvs.append((source.position+uv*source.size)/texture.get_size())
		draw_polygon(points,PackedColorArray([tint]),uvs,texture)

func _draw_resistance(p: Vector2,s: float,motion: Dictionary) -> void:
	# Force and actual line load have distinct owners: the rush beat supplies
	# the thrust, while measured tension constrains the fish and sharpens its wake.
	if bool(motion.reduced):return
	var energy: float=float(motion.fish_force)*float(motion.stress)
	if energy<.05:return
	var tail: Vector2=p+Motion.fish_point(Vector2(.04,.61),62*s,motion)
	_ring(tail+Vector2(-10,5)*s,Vector2(20+energy*22,5+energy*6)*s,Color(PALE,energy*.65),1.2)
	for i in range(3):
		var origin:=tail+Vector2(-12-i*6,(i-1)*3)*s
		draw_line(origin,origin+Vector2(-3-energy*6,-energy*(i-1))*s,Color(MINT,energy*.55),1.2,true)

func _draw_creature(p: Vector2,s: float,t: float,pulling: bool,progress: float) -> void:
	var breathe: float=sin(t*1.6)*3
	var rise: float=progress*20
	var rect := _draw_actor("creature",p+Vector2(0,breathe-rise),390*s,Color(1,1,1,.68))
	# Reflection texels remain above the complete moving sprite, including tail.
	_water_veil(rect.grow(2),.46)
	# Retain the original held-state visual; it has no input or reward authority.
	if pulling:
		draw_polyline(PackedVector2Array([p+Vector2(124*s,-rise),p+Vector2(143*s,-64*s-rise),p+Vector2(184*s,-76*s-rise)]),Color(GOLD,.4))
		_ellipse(p+Vector2(185*s,-79*s-rise),Vector2(24,6)*s,Color(Color("dec18a"),.8))

func _draw_swan(p: Vector2,s: float,t: float,rush: bool) -> void:
	var bob: float=sin(t*2)*2
	_ellipse(p+Vector2(0,14*s),Vector2(82,14)*s,Color(Color("092f34"),.25))
	var rect := _draw_actor("swan",p+Vector2(0,bob),82*s)
	_water_veil(Rect2(rect.position.x,rect.end.y-3*s,rect.size.x,5*s),.32)
	if rush:
		draw_line(p+Vector2(-35,-28)*s,p+Vector2(-42,-33)*s,Color(GOLD,.65),2)
		draw_line(p+Vector2(-29,-35)*s,p+Vector2(-32,-42)*s,Color(GOLD,.65),2)
	_ring(p+Vector2(0,15*s),Vector2(79*s+sin(t*3)*5,14*s),Color(PALE,.35))

func _draw_angler(p: Vector2,s: float,_t: float,lean: float,_tension: float,_held: bool,shown: bool) -> Vector2:
	var target_width: float=224*s
	var dimensions: Vector2=angler.get_size()*(target_width/angler.get_width())
	var origin:=p+Vector2(0,25*s)
	var key: String=Motion.angler_pose(current_motion)
	var pose_texture: Texture2D=angler_poses.get(key,angler)
	var posture: Dictionary=current_motion.duplicate()
	# The elbow silhouettes are authored keyframes. Only a small extra upper-body
	# brace remains procedural, to show continuously changing measured tension.
	if key!="rest":posture.human_lean*=.35
	_ellipse(p+Vector2(0,26*s),Vector2(target_width,20*s),Color(Color("082e35"),.3))
	if shown:
		# Only use generated artwork above y=610. The original lower-body/boat
		# pixels are authoritative, even if a generator redraws them slightly.
		var seam: float=610.0/1016.0
		var rows: Array[float]=[seam,.60]
		for i in range(33):rows.append(i/32.0)
		rows.sort()
		for i in range(rows.size()-1):
			var y0: float=rows[i]
			var y1: float=rows[i+1]
			if is_equal_approx(y0,y1):continue
			var texture: Texture2D=pose_texture if y1<=seam else angler
			var uvs:=PackedVector2Array([Vector2(0,y0),Vector2(1,y0),Vector2(1,y1),Vector2(0,y1)])
			var points:=PackedVector2Array()
			for uv: Vector2 in uvs:points.append(origin+Motion.angler_point(uv,dimensions,posture))
			draw_polygon(points,PackedColorArray([Color.WHITE]),uvs,texture)
	var grip: Array=ANGLER_GRIPS[key]
	var near_hand: Vector2=origin+Motion.angler_point(grip[0]/angler.get_size(),dimensions,posture)
	var far_hand: Vector2=origin+Motion.angler_point(grip[1]/angler.get_size(),dimensions,posture)
	var direction: Vector2=(far_hand-near_hand).normalized() if key!="rest" else Vector2(.64,-.77)
	var rod: PackedVector2Array=Motion.rod_points(far_hand,s,lean,current_motion,direction)
	var butt: Vector2=near_hand-direction*7*s if key!="rest" else far_hand+Vector2(-9,10)*s
	draw_line(butt,far_hand,Color("3d3027"),4*s,true)
	draw_line(butt,far_hand,Color("ba9860",.95),1*s,true)
	draw_polyline(rod,Color("3d3027"),3*s,true)
	draw_polyline(rod,Color("ba9860",.95),1*s,true)
	for index in [8,16,24,31]:draw_circle(rod[index],1.7*s,Color("e2c88c"))
	var reel:=near_hand+Vector2(3,6)*s if key!="rest" else far_hand+Vector2(-6,12)*s
	draw_circle(reel,5*s,Color("a79c74"))
	draw_circle(reel,2.5*s,Color("294239"))
	return rod[-1]

func _draw_fishing_line(a: Vector2,b: Vector2,tension: float,motion: Dictionary) -> void:
	var points: PackedVector2Array=Motion.line_points(a,b,motion)
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
