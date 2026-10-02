extends RefCounted
const Picker=preload("res://scripts/world_object_picker.gd")
## LibraryInteriorScene's source-pixel replacement layers and timed prop motion.
## Runtime-only presentation; reads persisted facts but never creates them.
var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/library-world-source.json"))
var art: Texture2D=load("res://assets/rpg/interiors/library_interior.png")
var staff_art: Texture2D=load("res://assets/rpg/npcs/library/front_desk_staff_2frame.png")
var stamp_art: Texture2D=load("res://assets/rpg/props/library_front_desk_stamp_v01.png")
var clock_ms: float=0
var stamp_ms: float=-1
var scanning_ms: float=-1
var stamped: bool=false
var lost_stage: String="missing_report"
var font: Font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
var bound_state: Dictionary={}
var initialized: bool=false
var active: bool=false
var reduced: bool=false
var shelf_collected: bool=false
var bag_evicted: bool=false
var shelf_ms: float=0
var bag_ms: float=0
var shelf_animating: bool=false
var bag_animating: bool=false
var shelf_offset: int=0
var shelf_phase: String="idle"
var shelf_frame: int=0
var cue_queue: Array=[]
var broadcast_index: int=0
var note_collected: bool=false
var receipt_collected: bool=false
var receipt_ms: float=-1
var note_ms: float=-1
var last_player:=Vector2.ZERO
var pass_from:=Vector2.ZERO

func sync(state: Dictionary,scene_changed: bool=false) -> void:
	var scene: String=str(state.get("native",{}).get("scene",""))
	if scene!="library_interior":
		active=false; initialized=false; shelf_animating=false; bag_animating=false; cue_queue.clear(); return
	active=true
	var p: Dictionary=state.get("ui",{}).get("libraryFinalsPuzzle",{})
	reduced=bool(state.get("native",{}).get("settings",{}).get("reduced_motion",false))
	if not initialized or scene_changed or not is_same(state,bound_state):
		bound_state=state; initialized=true
		shelf_collected=bool(p.get("archivedRuleCollected",false)); bag_evicted=bool(p.get("backpackEvicted",false))
		shelf_offset=int(source.shelf.shiftPx) if shelf_collected else 0
		shelf_phase="complete" if shelf_collected else "idle"; shelf_frame=source.shelf.frames.size()-1 if shelf_collected else 0
		shelf_animating=false; bag_animating=false; shelf_ms=0; bag_ms=0; broadcast_index=0
		note_collected=bool(p.get("occupancyNoteCollected",false)); receipt_collected=bool(p.get("seatReceiptCollected",false)); receipt_ms=-1; note_ms=-1
		stamped=bool(p.get("nonPersonProofStamped",false)); stamp_ms=-1; clock_ms=0; lost_stage=str(p.get("lostFoundStage","missing_report")); scanning_ms=0 if lost_stage=="scanning" else -1
		cue_queue.clear(); return
	if not stamped and p.get("nonPersonProofStamped",false): stamp_ms=0; scanning_ms=-1
	if lost_stage!="scanning" and p.get("lostFoundStage","")=="scanning": scanning_ms=0
	stamped=bool(p.get("nonPersonProofStamped",false)); lost_stage=str(p.get("lostFoundStage","missing_report"))
	if not shelf_collected and p.get("archivedRuleCollected",false):
		shelf_animating=true; shelf_ms=0; shelf_offset=0; shelf_frame=0; shelf_phase="shaking"
	if not bag_evicted and p.get("backpackEvicted",false):
		bag_animating=true; bag_ms=0; broadcast_index=0; pass_from=last_player
	if not receipt_collected and p.get("seatReceiptCollected",false): receipt_ms=0
	if not note_collected and p.get("occupancyNoteCollected",false): note_ms=0
	shelf_collected=bool(p.get("archivedRuleCollected",false)); bag_evicted=bool(p.get("backpackEvicted",false))
	note_collected=bool(p.get("occupancyNoteCollected",false)); receipt_collected=bool(p.get("seatReceiptCollected",false))

func tick(delta: float,state: Dictionary) -> void:
	sync(state)
	if not active or not is_finite(delta) or delta<=0: return
	var ms: float=minf(delta,0.05)*1000
	clock_ms+=ms
	if scanning_ms>=0: scanning_ms+=ms
	if stamp_ms>=0:
		stamp_ms+=ms
		if stamp_ms>=(3 if reduced else 810): stamp_ms=-1; clock_ms=0
	if receipt_ms>=0:
		receipt_ms+=ms
		if receipt_ms>=1020: receipt_ms=-1
	if note_ms>=0:
		note_ms+=ms
		if note_ms>=420: note_ms=-1
	if shelf_animating:
		shelf_ms+=ms
		if reduced:
			if shelf_ms>=140: shelf_offset=int(source.shelf.shiftPx); shelf_phase="paper"; shelf_frame=source.shelf.frames.size()-1
		else:
			var at: float=0
			for i in range(source.shelf.frames.size()):
				var row: Dictionary=source.shelf.frames[i]; at+=float(row.durationMs)
				# Source delayedCall applies each frame AFTER its own duration.
				if shelf_ms>=at: shelf_offset=int(row.offsetPx); shelf_phase=str(row.phase); shelf_frame=i
			if shelf_ms>=paper_start_ms(): shelf_phase="paper"; shelf_offset=int(source.shelf.shiftPx)
		if shelf_ms>=shelf_total_ms():
			shelf_animating=false; shelf_phase="complete"; shelf_offset=int(source.shelf.shiftPx)
			cue_queue.append({"id":"library_archived_rule_reveal_completed","payload":{"itemId":"archivedLeaveRule"}})
	if bag_animating:
		bag_ms+=ms
		var lines: Array=["书包：主人马上回来。","玩家：什么时候？","书包：三分钟。","系统：它三天前也是这么说的。"]
		while broadcast_index<lines.size() and bag_ms>=broadcast_index*720:
			cue_queue.append({"id":"library_backpack_broadcast_line","payload":{"text":lines[broadcast_index],"index":broadcast_index}}); broadcast_index+=1
		if bag_ms>=bag_total_ms(): bag_animating=false

func paper_start_ms() -> float: return 140.0 if reduced else float(source.shelf.totalMs)+110.0
func shelf_total_ms() -> float: return paper_start_ms()+(120+20+100 if reduced else 240+220+220)
func bag_shake_ms() -> float: return float(source.backpackTimeline.shakeDurationMs)*2*(int(source.backpackTimeline.shakeRepeat)+1)
func bag_total_ms() -> float: return bag_shake_ms()+float(source.backpackTimeline.waitMs)+float(source.backpackTimeline.transferMs)
func blocks_movement() -> bool: return active and shelf_animating
func backpack_eviction_active() -> bool: return active and bag_animating
func take_cues() -> Array:
	var out: Array=cue_queue.duplicate(true); cue_queue.clear(); return out
func collision_rect() -> Dictionary:
	return {"id":"north_display_shelf","left":502+mini(0,shelf_offset),"top":108,"right":625+maxi(0,shelf_offset),"bottom":234}
func adjusted_collisions(static_collisions: Array,state: Dictionary) -> Array:
	sync(state)
	var out: Array=static_collisions.duplicate(true)
	if not active: return out
	for i in range(out.size()):
		if out[i] is Dictionary and out[i].get("id","")=="north_display_shelf": out[i]=collision_rect()
	return out
func replace_collision(obstacle: Dictionary) -> Dictionary:
	return collision_rect() if active and obstacle.get("id","")=="north_display_shelf" else obstacle
func _stepped(value: float) -> float:
	# Phaser.Math.Easing.Stepped defaults to one step.
	return 0.0 if value<=0 else 1.0
func backpack_pose() -> Dictionary:
	var position:=Vector2(float(source.backpack.x),float(source.backpack.y)); var alpha: float=1
	if bag_animating:
		if bag_ms<bag_shake_ms():
			var phase: float=fposmod(bag_ms,140)/70
			position.x+=7*(phase if phase<=1 else 2-phase)
		elif bag_ms>=bag_shake_ms()+float(source.backpackTimeline.waitMs):
			var ratio: float=_stepped((bag_ms-bag_shake_ms()-float(source.backpackTimeline.waitMs))/float(source.backpackTimeline.transferMs))
			position=position.lerp(Vector2(334,634),ratio); alpha=1-ratio
	return {"position":position,"alpha":alpha,"visible":bag_animating,"scale":float(source.backpack.scale),"angle":float(source.backpack.angle),"depth":float(source.backpack.depth)}
func paper_pose() -> Dictionary:
	var position:=Vector2(514,152); var alpha: float=0.45 if reduced else 0.18
	var glow_alpha: float=0.12 if reduced else 0.04
	var glow_position:=Vector2(514,152)
	if shelf_animating and shelf_ms>=paper_start_ms():
		var elapsed: float=shelf_ms-paper_start_ms()
		var reveal: float=120 if reduced else 240
		var hold: float=20 if reduced else 220
		var fade: float=100 if reduced else 220
		var blend: float=_stepped(elapsed/reveal)
		position=position.lerp(Vector2(494,152 if reduced else 158),blend); alpha=lerpf(alpha,1,blend)
		if elapsed>=reveal+hold:
			var out: float=_stepped((elapsed-reveal-hold)/fade); position.y-=16*out; alpha=1-out
		var glow_progress: float=clampf(elapsed/100,0,1) if reduced else fposmod(elapsed,440)/220
		if glow_progress>1: glow_progress=2-glow_progress
		glow_position=glow_position.lerp(Vector2(494,152),glow_progress)
		glow_alpha=lerpf(0.12 if reduced else 0.04,0.2 if reduced else 0.42,glow_progress)
		if elapsed>reveal+hold: glow_position.y=(152 if reduced else 158)-16; glow_alpha=0
	return {"position":position,"alpha":alpha,"glowAlpha":glow_alpha,"glowPosition":glow_position,"visible":shelf_animating}
func debug_snapshot() -> Dictionary:
	return {"active":active,"shelfPhase":shelf_phase,"shelfFrame":shelf_frame,"shelfOffset":shelf_offset,"shelfAnimating":shelf_animating,"shelfMs":shelf_ms,"shelfTotalMs":shelf_total_ms(),"shelfCollision":collision_rect(),"backpack":backpack_pose(),"backpackClearPatch":bag_evicted,"backpackMs":bag_ms,"backpackTotalMs":bag_total_ms(),"paper":paper_pose(),"receiptMs":receipt_ms,"staff":staff_pose(),"stampMs":stamp_ms}

func owns_pick_target(id: String) -> bool:
	return id in ["front_desk","identity_machine","library_shelf_755","occupancy_note"]

func _context(canvas: CanvasItem,context: Dictionary) -> void:
	canvas.draw_set_transform(context.get("origin",Vector2.ZERO),0,Vector2.ONE*float(context.get("zoom",1)))
func _in_pass(depth: float,context: Dictionary,front: bool) -> bool:
	return (depth>Vector2(context.get("player",Vector2.ZERO)).y+float(source.playerDepthOffset))==front
func draw_back(canvas: CanvasItem,context: Dictionary,state: Dictionary) -> void:
	if context.get("scene_id","")!="library_interior": return
	sync(state); last_player=context.get("player",Vector2.ZERO); _context(canvas,context)
	# Both patches stay in the background; neither can occlude the actor.
	var bounds: Dictionary=source.shelf.bounds
	canvas.draw_texture_rect_region(art,Rect2(bounds.left,bounds.top,bounds.width,bounds.height),Rect2(bounds.left,source.shelfFloorSourceTop,bounds.width,bounds.height))
	if bag_evicted:
		var p: Dictionary=source.backpackClearPatchSource
		canvas.draw_texture_rect_region(art,Rect2(1255-float(p.width)/2,407-float(p.height)/2,p.width,p.height),Rect2(p.left,p.top,p.width,p.height))
	canvas.draw_set_transform(Vector2.ZERO)
	_draw_depth_pass(canvas,context,state,false)
func draw_front(canvas: CanvasItem,context: Dictionary,state: Dictionary) -> void:
	if context.get("scene_id","")!="library_interior": return
	_draw_depth_pass(canvas,context,state,true)
func _draw_depth_pass(canvas: CanvasItem,context: Dictionary,state: Dictionary,front: bool) -> void:
	_context(canvas,context)
	# Native uses the original Phaser depths, including player.y+120.
	if _in_pass(float(source.shelfDepth),context,front): _draw_shelf(canvas,state)
	if _in_pass(float(source.mechanismDepth),context,front) and shelf_collected: _draw_mechanism(canvas)
	if _in_pass(float(source.paperDepth),context,front): _draw_shelf_paper(canvas)
	if _in_pass(548,context,front): _draw_seat_status(canvas)
	canvas.draw_set_transform(Vector2.ZERO)
	var bag: Dictionary=backpack_pose()
	if bag.visible and _in_pass(float(bag.depth),context,front): _draw_backpack(canvas,context,bag)
	var p: Dictionary=state.get("ui",{}).get("libraryFinalsPuzzle",{})
	if _in_pass(602,context,front) and ((p.get("backpackInspected",false) and not note_collected) or note_ms>=0):
		if note_ms<0: Picker.record(canvas,["occupancy_note"],Rect2(1261,407,42,30))
		_draw_paper(canvas,context,Vector2(1282,422-(48*_stepped(note_ms/420) if note_ms>=0 else 0)),"纸条",Color("e9dcae"),1-_stepped(note_ms/420) if note_ms>=0 else 1)
	if _in_pass(625,context,front) and receipt_ms>=0:
		_draw_paper(canvas,context,Vector2(1300+100*_stepped(receipt_ms/520),421),"022",Color("f1ead8"),1,6*_stepped(receipt_ms/520))
	_draw_front_desk(canvas,context,front)
	if front and bag_animating and bag_ms<620:
		var ratio: float=_stepped(bag_ms/620); var at: Vector2=(pass_from+Vector2(0,-18)).lerp(Vector2(1255,373),ratio)
		canvas.draw_set_transform(Vector2(context.get("origin",Vector2.ZERO))+at*float(context.get("zoom",1)),TAU*ratio,Vector2.ONE*float(context.get("zoom",1)))
		canvas.draw_rect(Rect2(-30,-16,60,32),Color("2f8a59")); canvas.draw_string(font,Vector2(-22,6),"PASS",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f6f1dc")); canvas.draw_set_transform(Vector2.ZERO)
func _draw_shelf(canvas: CanvasItem,state: Dictionary) -> void:
	var vertices:=PackedVector2Array(); var uv:=PackedVector2Array()
	for point: Array in source.shelf.outline:
		vertices.append(Vector2(float(point[0])+shelf_offset,float(point[1])))
		uv.append(Vector2(float(point[0])/art.get_width(),float(point[1])/art.get_height()))
	Picker.record(canvas,["library_shelf_755"],{"polygon":vertices})
	canvas.draw_polygon(vertices,PackedColorArray([Color.WHITE]),uv,art)
	var known: bool=state.get("ui",{}).get("libraryFinalsPuzzle",{}).get("callNumberCollected",false) or shelf_collected
	var center:=Vector2(563.5+shelf_offset,248)
	canvas.draw_rect(Rect2(center-Vector2(28,9),Vector2(56,18)),Color("e8d9b8"))
	canvas.draw_string(font,center+Vector2(-23,4),"I247.55" if known else "I247.??",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("18231f"))
func _draw_mechanism(canvas: CanvasItem) -> void:
	var alpha: float=clampf(0.18+maxi(0,shelf_offset)/16.0*0.82,0.18,1)
	var center:=Vector2(563.5,171.5)
	for y in [-48,48]:
		var r:=Rect2(center+Vector2(-61.5,y-2.5),Vector2(123,5)); canvas.draw_rect(r,Color("4a3525",alpha)); canvas.draw_rect(r,Color("241a14",alpha),false,2)
	var recess:=Rect2(center+Vector2(-55.5,-53),Vector2(17,46)); canvas.draw_rect(recess,Color("171612",alpha*0.94)); canvas.draw_rect(recess,Color("7d6337",alpha*0.9),false,2)
	for y in [-46,46]: canvas.draw_rect(Rect2(center+Vector2(-49,y-2),Vector2(4,4)),Color("d2ae54",alpha))
func _draw_shelf_paper(canvas: CanvasItem) -> void:
	var pose: Dictionary=paper_pose()
	if not pose.visible: return
	canvas.draw_circle(pose.glowPosition,22,Color("f0df9b",pose.glowAlpha))
	_paper_local(canvas,pose.position,"旧规",Color("e7d8ab"),pose.alpha)
func _draw_seat_status(canvas: CanvasItem) -> void:
	var pulse: float=1
	if bag_animating and bag_ms<840:
		var progress: float=fposmod(bag_ms,280)/140; pulse=1+0.25*_stepped(progress if progress<=1 else 2-progress)
	var color: Color=Color("e1b953") if bag_animating else Color("55c98c") if bag_evicted else Color("e65c57")
	canvas.draw_circle(Vector2(1252,322),6*pulse,color); canvas.draw_arc(Vector2(1252,322),6*pulse,0,TAU,24,Color("24342f"),2)
	canvas.draw_string(font,Vector2(1270,327),"022 · 转移中" if bag_animating else "022 · 空闲" if bag_evicted else "022 · 占用",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("8ce1b4") if bag_evicted and not bag_animating else Color("f0d56a"))
func _draw_backpack(canvas: CanvasItem,context: Dictionary,pose: Dictionary) -> void:
	var z: float=float(context.get("zoom",1)); var origin: Vector2=context.get("origin",Vector2.ZERO)
	var base:=Transform2D(deg_to_rad(float(pose.angle)),Vector2(pose.position)); var base_scale: float=float(pose.scale)
	for part: Dictionary in source.backpack.parts:
		var local:=Vector2(float(part.x),float(part.y))*base_scale
		var at: Vector2=base*local
		canvas.draw_set_transform(origin+at*z,deg_to_rad(float(pose.angle)+float(part.angle)),Vector2.ONE*base_scale*z)
		var rect:=Rect2(-Vector2(float(part.width),float(part.height))/2,Vector2(float(part.width),float(part.height)))
		var color:=Color.hex(int(part.color)*256+255); color.a=float(part.alpha)*float(pose.alpha)
		if part.type=="ellipse":
			var points:=PackedVector2Array()
			for i in range(32): points.append(Vector2(cos(i*TAU/32)*rect.size.x/2,sin(i*TAU/32)*rect.size.y/2))
			canvas.draw_colored_polygon(points,color)
		else: canvas.draw_rect(rect,color)
		if part.has("stroke"):
			var stroke:=Color.hex(int(part.stroke.color)*256+255); stroke.a=float(part.stroke.alpha)*float(pose.alpha)
			canvas.draw_rect(rect,stroke,false,float(part.stroke.width))
	canvas.draw_set_transform(Vector2.ZERO)
func _paper_local(canvas: CanvasItem,at: Vector2,text: String,color: Color,alpha: float) -> void:
	color.a=alpha; canvas.draw_rect(Rect2(at-Vector2(21,15),Vector2(42,30)),color); canvas.draw_rect(Rect2(at-Vector2(21,15),Vector2(42,30)),Color("42372a",alpha),false,3)
	canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(10,-14),at+Vector2(20,-14),at+Vector2(20,-4)]),Color("c5b48b",alpha))
	canvas.draw_string(font,at+Vector2(-10,5),text,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("40372c",alpha))
func _draw_paper(canvas: CanvasItem,context: Dictionary,at: Vector2,text: String,color: Color,alpha: float,angle: float=0) -> void:
	canvas.draw_set_transform(Vector2(context.get("origin",Vector2.ZERO))+at*float(context.get("zoom",1)),deg_to_rad(angle),Vector2.ONE*float(context.get("zoom",1)))
	_paper_local(canvas,Vector2.ZERO,text,color,alpha); canvas.draw_set_transform(Vector2.ZERO)

func staff_pose() -> Dictionary:
	var frame: int=0; var y: float=632
	if lost_stage=="scanning" or stamp_ms>=0: frame=1
	elif not reduced:
		var idle_ms: float=fposmod(clock_ms,6000.0/1.8+900)
		frame=int(source.frontDesk.idleFrames[mini(5,int(idle_ms/(1000.0/1.8)))])
	if not reduced:
		if scanning_ms>=0 and scanning_ms<480:
			var step: float=fposmod(scanning_ms,240)/120; y+=3*_stepped(step if step<=1 else 2-step)
		if stamp_ms>=110 and stamp_ms<330:
			var step: float=fposmod(stamp_ms-110,110)/55; y+=4*_stepped(step if step<=1 else 2-step)
	return {"frame":frame,"position":Vector2(334,y),"scale":float(source.frontDesk.scale),"depth":float(source.frontDesk.staffDepth)}
func _draw_front_desk(canvas: CanvasItem,context: Dictionary,front: bool) -> void:
	_context(canvas,context)
	var pose: Dictionary=staff_pose(); var scale_value: float=pose.scale
	if _in_pass(float(source.frontDesk.staffDepth),context,front):
		Picker.record(canvas,["front_desk"],{"rect":Rect2(Vector2(pose.position)-Vector2(48,128)*scale_value,Vector2(96,128)*scale_value),"texture":staff_art,"source":Rect2(int(pose.frame)*96,0,96,128)})
		canvas.draw_texture_rect_region(staff_art,Rect2(Vector2(pose.position)-Vector2(48,128)*scale_value,Vector2(96,128)*scale_value),Rect2(int(pose.frame)*96,0,96,128))
	if _in_pass(float(source.frontDesk.counterDepth),context,front):
		var b: Dictionary=source.frontDesk.counterBounds; var region:=Rect2(b.left,b.top,b.width,b.height)
		Picker.record(canvas,["front_desk"],region)
		canvas.draw_texture_rect_region(art,region,region)
	if _in_pass(float(source.frontDesk.serviceDepth),context,front): _draw_stamp_service(canvas)
	if _in_pass(810,context,front):
		canvas.draw_rect(Rect2(243,669,144,26),Color("23332f",0.93))
		canvas.draw_string(font,Vector2(251,687),"信息台 / 失物招领",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f2e5c6"))
	canvas.draw_set_transform(Vector2.ZERO)
func _draw_stamp_service(canvas: CanvasItem) -> void:
	var at:=Vector2(334,594)
	# Original LibraryInteriorScene's service zone: (0,8), 116×86.
	# Active scan and ordinary service are affordances of this same object.
	Picker.record(canvas,["identity_machine","front_desk"],Rect2(at+Vector2(-58,-35),Vector2(116,86)))
	Picker.record(canvas,["identity_machine","front_desk"],Rect2(at+Vector2(5,-51),Vector2(92,22)))
	var indicator: Color=Color("5ed68d") if lost_stage=="stamped" else Color("e1b953") if lost_stage in ["ready","scanning"] else Color("c96a5e")
	var status: String={"missing_report":"等待报告","ready":"递交报告","scanning":"人工核验","stamped":"已盖章"}.get(lost_stage,"")
	canvas.draw_rect(Rect2(at+Vector2(5,-51),Vector2(92,22)),Color("173b35",0.92)); canvas.draw_rect(Rect2(at+Vector2(5,-51),Vector2(92,22)),Color("7fa89b",0.9),false,2)
	canvas.draw_circle(at+Vector2(14,-40),4,indicator)
	canvas.draw_string(font,at+Vector2(35,-36),status,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("bdebc9") if lost_stage=="stamped" else Color("f1b3ad") if lost_stage=="missing_report" else Color("f7e6a6"))
	var labels: Array=["图","座","物"]
	for i in range(3):
		var x: float=28+i*22; var color: Color=Color("5ed68d") if lost_stage=="stamped" else Color("e1b953") if lost_stage=="ready" or (lost_stage=="scanning" and i<2) else Color("c96a5e")
		if lost_stage=="missing_report": color.a=0.72
		canvas.draw_circle(at+Vector2(x,-21),3,color); canvas.draw_string(font,at+Vector2(x-3.5,-9),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("c6d1ca"))
	var press: bool=stamp_ms>=0 and (reduced or (stamp_ms>0 and stamp_ms<=250))
	var stamp_y: float=28 if press else 14
	canvas.draw_texture_rect(stamp_art,Rect2(at+Vector2(-49,stamp_y-20),Vector2(28,40)),false)
	if lost_stage=="scanning" or stamp_ms>=0:
		var x: float=-20 if reduced or scanning_ms>0 or stamp_ms>=0 else -78
		var alpha: float=0 if stamp_ms>(2 if reduced else 390) else 1
		var paper:=Rect2(at+Vector2(x-23,10),Vector2(46,28))
		canvas.draw_rect(paper,Color("f2ead5",alpha)); canvas.draw_rect(paper,Color("5a625d",alpha),false,2)
		canvas.draw_rect(Rect2(at+Vector2(x-17.5,16),Vector2(25,2)),Color("87928c",0.9*alpha)); canvas.draw_rect(Rect2(at+Vector2(x-17.5,22),Vector2(19,2)),Color("87928c",0.7*alpha))
		if stamp_ms>=(0 if reduced else 110): canvas.draw_string(font,at+Vector2(x-10,32),"非本人",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("b43f3f",alpha))
		if not reduced and lost_stage=="scanning" and scanning_ms>=240 and scanning_ms<1240:
			var forward: bool=int((scanning_ms-240)/250)%2==0
			canvas.draw_rect(Rect2(at+Vector2(-43,34.5 if forward else 9.5),Vector2(46,3)),Color("e1b953",0.28 if forward else 0.95))
