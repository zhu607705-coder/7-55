extends Control
## Illustrated rehearsal records. Only accepted trials supply the live ink trace.
signal tracing_aligned
const Typography=preload("res://scripts/ui/native_typography.gd")
const Model=preload("res://scripts/games/theater_shadow_rehearsal_model.gd")
const Tracing=preload("res://scripts/presentation/theater_rehearsal_tracing.gd")
const INK=Color("45423B")
const FAINT=Color("AEA184")
const RED=Color("9A514A")
const PAGES=[
	[
		{"title":"卷一 · 展扇","caption":"一轴未移，翼缘已开","record":"初试只顾移扇，影虽近了旧痕，半边蝶翼仍瘦。批曰：位可移，扇亦可展。","experiment":"先留住底座，只拨外沿铜扣；看上下两端与外侧翼缘，哪一处先变。","question":"扇位与开合，各管哪一笔？"},
		{"title":"扇骨留白","caption":"墨记原形，朱记展开","record":"铜扣绕轴而行，扇骨逐片张开。翼缘向外舒展，上下两端却不随之长高。","experiment":"展扇时留意朱圈；若整片影都偏在一旁，再回看底座的位置。","question":"不要把偏位，当作未展。"},
		{"title":"覆看初试","caption":"朱线为旧痕，墨影为上回试演","record":"合影先看轴，再看上下，末看翼缘。三处各有缘故，莫将扇架一味推来推去。","experiment":"掩卷后只改一处，再点灯留影；翻回此页，比较墨影与朱线的差别。","question":"这一回，究竟是哪一笔未合？"}
	],
	[
		{"title":"卷二 · 远近","caption":"同一把扇，远近两影","record":"扇近灯，影反大；扇近幕，影反小。旧页旁写着：小扇也能投出大影。","experiment":"先不碰铜扣，只把扇架推近、拉远；看影的高与宽是否一同变化。","question":"影大，是扇大，还是离灯近？"},
		{"title":"莫混两法","caption":"远近改全形，开合改翼缘","record":"前后挪扇，整片影随之伸缩；收拢扇骨，只收翼缘。两者看似都能变窄，留下的痕却不同。","experiment":"先比较上下两端，再比较外缘。每次只动一件；看乱了，就撤回上一动。","question":"上下已合，外缘仍宽，该动哪里？"},
		{"title":"覆看远近","caption":"上回留影，仍照原样收在此页","record":"校远近时，先以影的上下两端为准；再试开合，勿让一处误差牵着另一处走。","experiment":"把上回墨影与朱线对看；回台上改变一项，再留下一次可比较的试演。","question":"哪一项改变了高，哪一项只改了宽？"}
	],
	[
		{"title":"卷三 · 借光","caption":"钉不动，可借它校灯","record":"双扇同偏，未必两人都站错。灯师在幕边钉一木钉，记影的两端，留作众影的参照。","experiment":"先看木钉：左右移灯，钉影换位；前后推灯，钉影也会变长变短。","question":"两扇同错时，先查共同的光。"},
		{"title":"侧幕余影","caption":"灯、扇、侧幕，共走一条光路","record":"灯位已定，幕上仍有宽黑一片。旧批圈住侧幕：它挡的光，不会因扇骨开合而散。","experiment":"将侧幕移出光路，再分看两扇。扇面本有大小，不必摆在同一远近。","question":"先辨谁在挡光，再辨谁的影未合。"},
		{"title":"合蝶余记","caption":"一盏灯下，各有其位","record":"以钉校灯，以空处辨遮挡，再分看两翼的位、形、开合。两扇不必齐行，合在幕上便是同一只蝶。","experiment":"掩卷后挑一处未合的痕试改；看见双翼一同变化，便回头检查灯。","question":"借同一束光，也各有自己的远近。"}
	]
]
var round_index:=0
var page_index:=0
var trial:Dictionary={}
var study:Dictionary={}
var tracing:Control

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	tracing=Tracing.new();tracing.name="LooseRehearsalTracing";add_child(tracing);tracing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tracing.aligned.connect(func():tracing_aligned.emit())
	_sync_tracing()

func show_page(round_id:int,page:int,last_trial:Dictionary,discovery:Dictionary={})->void:
	round_index=clampi(round_id,0,2);page_index=clampi(page,0,2)
	trial=last_trial.duplicate(true);study=discovery.duplicate(true);_sync_tracing();queue_redraw()

func _sync_tracing()->void:
	if not is_instance_valid(tracing):return
	tracing.visible=page_index<2 and not study.get("sealed",false)
	tracing.configure(round_index,study)
func cancel_drag()->void:
	if is_instance_valid(tracing):tracing.cancel_drag()
func handle_key(event:InputEventKey)->bool:
	return is_instance_valid(tracing) and tracing.is_visible_in_tree() and tracing.handle_key(event)
func tracing_geometry()->Dictionary:
	if not is_instance_valid(tracing) or not tracing.visible:return {}
	var origin:Vector2=tracing.global_position+tracing.origin()
	var paper:Rect2=Rect2(origin+tracing.sheet*tracing.fit(),tracing.EXTENT*tracing.fit())
	var target:Rect2=Rect2(origin+tracing.TARGET*tracing.fit(),tracing.EXTENT*tracing.fit())
	return {"sheet":[paper.position.x,paper.position.y,paper.size.x,paper.size.y],"target":[target.position.x,target.position.y,target.size.x,target.size.y],"ready":tracing.evidence_ready,"sealed":tracing.sealed}

static func page_text(round_id:int,page:int,last_trial:Dictionary,discovery:Dictionary={})->String:
	var note:Dictionary=PAGES[clampi(round_id,0,2)][clampi(page,0,2)]
	var text:String="[b]%s[/b]\n\n[color=#9A514A]旧记[/color]  %s\n\n[color=#9A514A]试看[/color]  %s\n\n%s"%[note.title,note.record,note.experiment,note.question]
	if not discovery.get("sealed",false):
		var clues:Array=["纸上同一道扇轴旁，留着两笔不同的翼缘。断去的半页，似乎也拓自这把扇。","门前留了两张大小不同的扇影，扇骨的数目却一根不少。页边的脚印被擦去了。","两翼分站两边，一枚木钉始终未挪。旧印一处错开，一处长短不齐。"]
		var instruction:String="册边夹着空试纸。点灯可以留影；留住别处，只改一处，才看得出两影之间发生了什么。"
		if discovery.get("ready",false):instruction="两次试演已留下可相照的影拓。将散页覆回旧印，让三处断笔接续。"
		elif round_id==2 and not discovery.get("pairs",{}).is_empty():instruction="已有一对影拓，另一处断痕仍未续上。错位与长短，是否来自同一种拨动？"
		text="[b]%s[/b]\n\n%s\n\n[color=#9A514A]页边小记[/color]\n%s"%[["扇骨残页","门前残页","同灯残页"][clampi(round_id,0,2)],clues[clampi(round_id,0,2)],instruction]
		if page==2:text="[b]试演留痕[/b]\n\n朱线是幕上的旧痕，墨影是上一次点灯留下的。\n\n掩卷后试着只改一处，再看这道影。"
	if page==2:
		var result:String="尚未留影。掩卷后点灯，才会记下本次试演。" if last_trial.is_empty() else ("上回试演，已与旧痕相合。" if str(last_trial.get("failure","")).is_empty() else "上回试演："+Model.failure_text(str(last_trial.failure)))
		text+="\n\n[color=#9A514A]今试[/color]  "+result
	return text

func _label(at:Vector2,text:String,color:Color=INK,pixels:int=17)->void:
	draw_string(Typography.body_font(),at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)

func _arrow(a:Vector2,b:Vector2,color:Color=RED)->void:
	draw_line(a,b,color,1.5)
	var back:Vector2=(a-b).normalized()*7
	draw_line(b,b+back.rotated(.48),color,1.5);draw_line(b,b+back.rotated(-.48),color,1.5)

func _fan(at:Vector2,radius:float,spread:float,color:Color=INK)->void:
	var points:=PackedVector2Array([at])
	for rib:int in range(9):
		var angle:float=deg_to_rad(-90.0+(float(rib)/8.0-.5)*116.0*spread)
		var end:Vector2=at+Vector2(cos(angle),sin(angle))*radius
		points.append(end);draw_line(at,end,Color(color,.55),1)
	points.append(at);draw_polyline(points,color,1.8)
	draw_circle(at,3,color)

func _wing(at:Vector2,radius:float,side:int,spread:float,color:Color,outline:bool)->void:
	var points:=PackedVector2Array()
	for p:Vector2 in [Vector2(0,-.1),Vector2(.12,-.72),Vector2(.44,-1.10),Vector2(.85,-.98),Vector2(1,-.64),Vector2(.90,-.29),Vector2(.55,-.01),Vector2(.48,.09),Vector2(.83,.28),Vector2(.80,.60),Vector2(.55,.92),Vector2(.25,1.04),Vector2(.10,.81),Vector2(0,.14)]:points.append(at+Vector2(p.x*side*spread,p.y)*radius)
	var paper:=Rect2(20,48,320,158)
	for piece:PackedVector2Array in Geometry2D.intersect_polygons(points,PackedVector2Array([paper.position,Vector2(paper.end.x,paper.position.y),paper.end,Vector2(paper.position.x,paper.end.y)])):
		if outline:piece.append(piece[0]);draw_polyline(piece,color,1.5)
		else:draw_colored_polygon(piece,color)

func _draw_trial()->void:
	draw_rect(Rect2(20,48,320,158),FAINT,false,1)
	for target:Dictionary in Model.LEVELS[round_index].targets:_wing(Vector2(180+float(target.center)*26,128),float(target.radius)*56,int(target.side),float(target.spread),RED,true)
	if trial.is_empty():
		_label(Vector2(96,234),"此页候你留影",FAINT)
		return
	for shadow:Dictionary in trial.get("projections",[]):
		if shadow.kind=="fan":_wing(Vector2(180+float(shadow.center)*26,128),float(shadow.radius)*56,int(shadow.side),float(shadow.spread),Color(INK,.55),false)
		elif shadow.kind=="screen":
			var shape:=Rect2(180+(float(shadow.center)-float(shadow.radius))*26,56,float(shadow.radius)*52,142).intersection(Rect2(20,48,320,158))
			if shape.has_area():draw_rect(shape,Color(INK,.34))
	if not trial.get("witness",{}).is_empty():
		var target_x:float=180.0+float(trial.witnessTarget)*26.0
		var cast_x:float=clampf(180.0+float(trial.witness.center)*26.0,23,337)
		for y:float in [62,102]:draw_line(Vector2(target_x-6,y),Vector2(target_x+6,y),RED,1.5)
		draw_line(Vector2(cast_x,102-20*float(trial.witness.magnification)),Vector2(cast_x,102),INK,3)
	# Trace is the last accepted try, never an unearned live answer or a timer.
	_label(Vector2(100,234),"上回试演留痕",RED)

func _draw()->void:
	if size.x<=0 or size.y<=0:return
	if page_index<2 and not study.get("sealed",false):return
	var fit:float=minf(size.x/360.0,size.y/270.0)
	draw_set_transform((size-Vector2(360,270)*fit)/2,0,Vector2.ONE*fit)
	_label(Vector2(16,24),["展扇图","远近图","借光图"][round_index] if study.get("sealed",false) else "试演影拓",RED,20)
	_label(Vector2(16,45),str(PAGES[round_index][page_index].caption) if study.get("sealed",false) else "朱线为旧痕，墨影为上回试演",FAINT,14)
	if page_index==2:_draw_trial()
	elif round_index==0:
		_fan(Vector2(180,186),100,.34,FAINT);_fan(Vector2(180,186),100,1.0,INK)
		var grip:=Vector2(265,133)
		draw_arc(grip,13,0,TAU,28,RED,1.6)
		_arrow(Vector2(210,69),Vector2(265,106));_label(Vector2(225,68),"展",RED)
		draw_line(Vector2(145,201),Vector2(215,201),INK,3)
		_label(Vector2(133,232),"底座留住",FAINT)
		if page_index==1:
			draw_line(Vector2(67,87),Vector2(67,186),FAINT,1)
			for y:float in [87,186]:draw_line(Vector2(61,y),Vector2(73,y),RED,2)
			_label(Vector2(16,128),"高",RED)
	elif round_index==1:
		if page_index==0:
			var source:=Vector2(35,201)
			draw_circle(source,8,INK);draw_line(Vector2(310,55),Vector2(310,207),INK,2)
			_fan(Vector2(124,189),48,.8,INK);_fan(Vector2(236,189),48,.8,FAINT)
			_arrow(Vector2(153,208),Vector2(208,208));_label(Vector2(12,234),"灯",INK);_label(Vector2(296,234),"幕",INK)
			for end:Vector2 in [Vector2(310,55),Vector2(310,207)]:draw_line(source,end,Color(RED,.65),1)
			_label(Vector2(93,85),"近灯影大",RED)
		else:
			_fan(Vector2(107,180),85,.75,INK);_fan(Vector2(107,180),57,.75,FAINT)
			_fan(Vector2(264,180),85,.35,FAINT);_fan(Vector2(264,180),85,.9,INK)
			_arrow(Vector2(55,216),Vector2(136,216));_label(Vector2(65,243),"远近",RED)
			draw_arc(Vector2(264,180),95,deg_to_rad(-142),deg_to_rad(-38),24,RED,1.5);_label(Vector2(244,243),"开合",RED)
	else:
		if page_index==0:
			draw_line(Vector2(76,192),Vector2(76,124),INK,5);draw_circle(Vector2(76,124),5,INK)
			_label(Vector2(43,231),"木钉不动",FAINT)
			draw_rect(Rect2(188,52,135,152),FAINT,false,1)
			draw_line(Vector2(237,185),Vector2(237,95),INK,5)
			draw_line(Vector2(287,185),Vector2(287,66),Color(INK,.3),5)
			for y:float in [95,185]:draw_line(Vector2(224,y),Vector2(250,y),RED,2)
			_arrow(Vector2(282,215),Vector2(237,215));_label(Vector2(197,244),"影合两端刻线",RED)
		else:
			draw_circle(Vector2(35,179),9,INK);_fan(Vector2(127,179),64,.8)
			draw_rect(Rect2(206,94,42,93),Color(INK,.5));draw_rect(Rect2(300,46,20,156),Color(INK,.7))
			for end:Vector2 in [Vector2(300,46),Vector2(300,202)]:draw_line(Vector2(35,179),end,Color(RED,.6),1)
			_arrow(Vector2(228,207),Vector2(271,226));_label(Vector2(193,250),"移开遮光物",RED)
	draw_line(Vector2(16,261),Vector2(344,261),FAINT,1)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
