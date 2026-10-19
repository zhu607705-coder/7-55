extends RefCounted
const Picker=preload("res://scripts/world_object_picker.gd")
## Source-pixel furniture, residuals and bakery machinery. No progression writes.
const Room = preload("res://scripts/games/chapter4_room204_model.gd")
const PhaseLayers = preload("res://scripts/ui/chapter4_phase_layers.gd")
var phases: RefCounted=PhaseLayers.new()
static var presentation: Dictionary={}
var source_font: Font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
var textures: Dictionary={}
var source: Dictionary={}
var clock_ms: float=0
var bakery_ms: float=0
var conveyor_ms: float=0
var bakery_key: String=""
var placement_signature: String=""
var last_entities: Dictionary={}
var moves: Dictionary={}
var floor_id: String=""
var native_prop: Node2D
func _sync_native_prop(state: Dictionary) -> void:
	if is_instance_valid(native_prop): native_prop.sync(state,native_prop.world.scene_id)
func _native_owns(id: String) -> bool:
	return is_instance_valid(native_prop) and native_prop.owns_entity(id)
func _init() -> void:
	source=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-three-floor-maze.layout.json"))
func texture(path: String) -> Texture2D:
	if not textures.has(path): textures[path]=load(path) if ResourceLoader.exists(path) else null
	return textures[path]
func tick(delta: float,state: Dictionary) -> void:
	phases.tick(delta,state)
	clock_ms+=minf(delta,0.05)*1000
	var bakery_phase: String=str(state.get("chapter4",{}).get("phase",""))
	if bakery_phase!=bakery_key: bakery_ms=0; conveyor_ms=0; bakery_key=bakery_phase
	var stop_time: float=float(presentation.get("elapsedMs",0))
	if not (presentation.get("kind","")=="bakery_stop" and stop_time>=360) and (bakery_phase!="bakery_hour_hand" or "bakery_hour_hand_exposed" not in state.get("chapter4",{}).get("factIds",[])):
		bakery_ms+=minf(delta,0.05)*1000
		conveyor_ms+=minf(delta,0.05)*1000*(0.45 if presentation.get("kind","")=="bakery_stop" and stop_time>=120 else 1.0)
	var current: Dictionary={}; var c: Dictionary=state.get("chapter4",{}); var signature: String=JSON.stringify(c.get("room204Placements",[]))
	for e in Room.entities(state): current[e.kind+":"+e.id]=e
	if floor_id==c.get("floor","") and not placement_signature.is_empty() and signature!=placement_signature:
		for id in current:
			if last_entities.has(id) and current[id].position!=last_entities[id].position:
				moves[id]={"from":last_entities[id].position,"angle":last_entities[id].angle,"start":clock_ms}
	last_entities=current; placement_signature=signature; floor_id=c.get("floor","")
	for id in moves.keys():
		if clock_ms-float(moves[id].start)>=480: moves.erase(id)
func owns_pick_target(id: String) -> bool:
	return id.begins_with("a1_hall_clock") or id in ["a1_front_desk_attendant","a2_elevator_attendant","a3_reference_teacher","a1_bakery_inspection_lamp","a1_bakery_hour_hand_pickup","a1_noticeboard_paper","a1_campus_card_reader","a1_attendance_paper_slot"] or not phases.alumni.filter(func(person):return str(person.targetId)==id).is_empty()

func register_frame(canvas: CanvasItem,ids: Array,sheet_id: String,frame_id: String,pos: Vector2,angle: float,scale_value: float) -> void:
	var sheet: Dictionary=Room.data().sheets[sheet_id]; var frame: Dictionary=sheet.frames[frame_id]
	var src: Rect2=Room.rect(frame.sourceTrim)
	Picker.record(canvas,ids,{"rect":Rect2(src.position-Room.point(frame.pivot),src.size),"texture":texture(sheet.path),"source":src,"transform":Transform2D(deg_to_rad(angle),Vector2.ONE*scale_value,0,pos)})

func _active(context: Dictionary,state: Dictionary) -> bool:
	return context.get("scene_id","")=="duan_yongping_temporal_maze" and state.has("chapter4")

func bakery_foreground_below_player(cover: Dictionary,state: Dictionary) -> bool:
	# The source player is at PLAYER_TOP_DEPTH (9900). These normal bakery
	# crops stay at PLAYER_DEPTH_BASE + baseline (4387/4449), below that player.
	# Reveal walls and the entrance have separate source rules; do not alter them.
	var c: Dictionary=state.get("chapter4",{})
	return c.get("floor","")=="A1" and c.get("phase","") in ["bakery_hour_hand","morning_checkin"] and str(cover.get("id","")) in ["a1_foreground_018","a1_midday_queue_front"]
func draw_back(canvas: CanvasItem,context: Dictionary,state: Dictionary) -> void:
	if not _active(context,state): return
	draw_before_furniture(canvas,context,state,false)
	_draw_furniture(canvas,context,state,false)
	draw_after_furniture(canvas,context,state,false)
func draw_front(canvas: CanvasItem,context: Dictionary,state: Dictionary) -> void:
	if not _active(context,state): return
	draw_before_furniture(canvas,context,state,true)
	_draw_furniture(canvas,context,state,true)
	draw_after_furniture(canvas,context,state,true)
func draw_before_furniture(canvas: CanvasItem,context: Dictionary,state: Dictionary,front: bool) -> void:
	if front:
		if not _active(context,state): return
		phases.draw_front(self,canvas,context,state)
		_draw_bakery_people(canvas,context,state,true)
	else:
		if not _active(context,state): return
		var c: Dictionary=state.chapter4
		phases.draw_back(self,canvas,context,state)
		if Room.presentation(state)=="interactive" and (c.mode=="dark" or presentation.get("kind","")=="projection"):
			var l: Dictionary=Room.data().layout
			for i in range(l.initialPiecePairs.size()):
				draw_frame(canvas,context,"chapter4_room204_residual",l.initialPiecePairs[i].residualFrame,Room.point(l.slotTargets[i].center),0,0.25,Color(0.47,0.875,1,0.88))
		_draw_bakery_people(canvas,context,state,false)
func draw_after_furniture(canvas: CanvasItem,context: Dictionary,state: Dictionary,front: bool) -> void:
	if not _active(context,state): return
	var c: Dictionary=state.chapter4
	if front:
		if presentation.get("kind","")=="projection" and state.chapter4.floor=="A2" and Vector2(context.get("player",Vector2.ZERO)).y<475: draw_projection(canvas,context,float(presentation.get("elapsedMs",0)))
		if state.chapter4.floor=="A1":
			_draw_bakery(canvas,context,state,true)
			if state.chapter4.phase=="opening_handoff" and "opening_paper_at_noticeboard" in state.chapter4.factIds:
				for a in source.floors[0].anchors:
					if a.id=="a1_noticeboard_paper":
						var r: Rect2=Room.rect(a.bounds)
						register_frame(canvas,["a1_noticeboard_paper"],"chapter4_story_items","sign_in_record_paper",Vector2(r.get_center().x,r.end.y),0,0.18)
						draw_frame(canvas,context,"chapter4_story_items","sign_in_record_paper",Vector2(r.get_center().x,r.end.y),0,0.18)
	else:
		if c.floor=="A1": _draw_bakery(canvas,context,state,false)
		if presentation.get("kind","")=="projection" and c.floor=="A2" and Vector2(context.get("player",Vector2.ZERO)).y>=475: draw_projection(canvas,context,float(presentation.get("elapsedMs",0)))
func _draw_furniture(canvas: CanvasItem,context: Dictionary,state: Dictionary,front: bool,segment: int=0) -> void:
	var player: Vector2=context.get("player",Vector2.ZERO)
	var after_native:=false
	for e in Room.entities(state):
		var pos: Vector2=e.position; var angle: float=e.angle; var id: String=e.kind+":"+e.id
		if _native_owns(id): after_native=true;continue
		if segment==1 and after_native: continue
		if segment==2 and not after_native: continue
		if moves.has(id):
			var t: float=clampf((clock_ms-float(moves[id].start))/480.0,0,1); t=1-pow(1-t,3)
			pos=Vector2(moves[id].from).lerp(pos,t); angle=lerpf(float(moves[id].angle),angle,t)
		if (pos.y+1>player.y)!=front: continue
		draw_frame(canvas,context,"chapter4_room204_furniture",e.frame,pos,angle,0.25)
func draw_frame(canvas: CanvasItem,context: Dictionary,sheet_id: String,frame_id: String,pos: Vector2,angle: float,scale_value: float,tint: Color=Color.WHITE) -> void:
	var sheet: Dictionary=Room.data().sheets[sheet_id]; var frame: Dictionary=sheet.frames[frame_id]; var art: Texture2D=texture(sheet.path)
	if not art: return
	var src: Rect2=Room.rect(frame.sourceTrim); var pivot: Vector2=Room.point(frame.pivot); var origin: Vector2=context.get("origin",Vector2.ZERO); var zoom: float=context.get("zoom",1.0)
	canvas.draw_set_transform(origin+pos*zoom,deg_to_rad(angle),Vector2.ONE*scale_value*zoom)
	canvas.draw_texture_rect_region(art,Rect2(src.position-pivot,src.size),src,tint)
	canvas.draw_set_transform(Vector2.ZERO)
func collisions(state: Dictionary) -> Array:
	_sync_native_prop(state)
	var out: Array=[]
	for e: Dictionary in Room.entities(state):
		if _native_owns(e.kind+":"+e.id): out.append(native_prop.footprint_bounds(e.kind+":"+e.id))
		else: out.append(Room.entity_collision(e))
	out.append_array(phases.collisions(state))
	var c: Dictionary=state.get("chapter4",{})
	if c.get("floor","")=="A1" and c.get("phase","")=="bakery_hour_hand" and c.get("timeState","")=="1225_bakery":
		var foot: Dictionary=source.playerFootBoxContract.worldFootBox
		for i in range(source.bakeryRuntime.crowd.routes.size()):
			var actor: Dictionary=_crowd_sample(source.bakeryRuntime.crowd.routes[i],i)
			var center_offset: Vector2=Vector2(0,(float(source.playerFootBoxContract.sourceFootBox.y)+float(source.playerFootBoxContract.sourceFootBox.height)/2-128)*0.65)
			out.append(Rect2(Vector2(actor.position)+center_offset-Vector2(float(foot.width),float(foot.height))/2,Vector2(float(foot.width),float(foot.height))))
	return out
func pick_drag(worldpos: Vector2,state: Dictionary) -> Dictionary:
	_sync_native_prop(state)
	if not Room.group_available(state): return {}
	var entities: Array=Room.entities(state); entities.reverse()
	for e in entities:
		if e.kind not in ["chair","table"]: continue
		var frame: Dictionary=Room.data().sheets.chapter4_room204_furniture.frames[e.frame]
		var local: Vector2=(worldpos-Vector2(e.position)).rotated(-deg_to_rad(float(e.angle)))/0.25+Room.point(frame.pivot)
		if _native_owns(e.kind+":"+e.id):
			if not native_prop.contains_source_point(worldpos,e.kind+":"+e.id): continue
		elif not Room.rect(frame.sourceRect).has_point(local): continue
		for group in Room.data().groups:
			for mapping in group.mappings:
				var match_piece: bool=mapping.pieceId==e.id
				if e.kind=="table":
					for table in Room.data().layout.discussionTables:
						if table.id==e.id and mapping.pieceId in table.pieceIds: match_piece=true
				if match_piece and not Room.group_complete(group,state.chapter4.room204Placements): return {"kind":"chapter4_room204_group","groupId":group.id,"orientation":"up","floor":"A2","phase":"room204_restore","source":[worldpos.x,worldpos.y]}
	return {}
func resolve_drag(payload: Dictionary,worldpos: Vector2,state: Dictionary) -> Dictionary:
	if not Room.group_available(state) or payload.get("kind","")!="chapter4_room204_group" or payload.get("floor","")!="A2" or payload.get("phase","")!="room204_restore": return {}
	for group in Room.data().groups:
		if Room.rect(group.targetBounds).has_point(worldpos): return {"action":"c4_group_"+str(payload.get("groupId","")),"value":{"groupId":payload.get("groupId",""),"targetGroupId":group.id,"orientation":payload.get("orientation",""),"drop":[worldpos.x,worldpos.y]}}
	return {}
func _world(canvas: CanvasItem,context: Dictionary) -> void: canvas.draw_set_transform(context.get("origin",Vector2.ZERO),0,Vector2.ONE*float(context.get("zoom",1.0)))
func _draw_bakery(canvas: CanvasItem,context: Dictionary,state: Dictionary,front: bool) -> void:
	var c: Dictionary=state.chapter4
	if c.phase not in ["bakery_hour_hand","morning_checkin"]: return
	# Original belt/lamp/item layers use the counter surface depth, always
	# below chapterFourPlayerDepth(). Keep their original art and animation.
	if front: return
	var b: Dictionary=source.bakeryRuntime
	var stopped: bool="bakery_hour_hand_exposed" in c.factIds or c.phase!="bakery_hour_hand"
	var t: float=float(presentation.get("elapsedMs",0))
	var stop_active: bool=presentation.get("kind","")=="bakery_stop"
	if stop_active and t>=360: stopped=true
	var motion: float=conveyor_ms
	_world(canvas,context)
	var belt: Rect2=Room.rect(b.conveyorVisual.beltBounds); var rail: Rect2=Room.rect(b.conveyorVisual.frontRailBounds)
	canvas.draw_rect(Rect2(belt.position-Vector2(4,1),belt.size+Vector2(8,8)),Color(0.067,0.078,0.09,0.72)); canvas.draw_rect(belt,Color("354247"))
	var shift: float=fmod(motion/float(b.conveyorVisual.motionCycleMs)*18,18)
	for index in range(-1,11):
		var x: float=belt.position.x+index*18+shift
		if x>=belt.position.x and x<=belt.end.x: canvas.draw_line(Vector2(x,belt.position.y),Vector2(x,belt.end.y),Color("76817f"),2)
	for offset in [22,78,134]:
		var p: Vector2=Vector2(belt.position.x+fmod(float(offset)+motion/(float(b.conveyorVisual.motionCycleMs)*5)*belt.size.x,belt.size.x),belt.get_center().y)
		canvas.draw_rect(Rect2(p+Vector2(-12.5,-5),Vector2(25,12)),Color("4c3724")); canvas.draw_rect(Rect2(p+Vector2(-12.5,-5),Vector2(25,12)),Color("c9a566"),false,1)
		for dx in [-6,0,6]: canvas.draw_circle(p+Vector2(dx,-1),3,Color("e5ad5d") if dx==0 else Color("d99d51"))
	canvas.draw_rect(Rect2(belt.position-Vector2(5,3),Vector2(belt.size.x+10,4)),Color("b6aaa0")); canvas.draw_rect(rail,Color("8f8378")); canvas.draw_rect(rail,Color("382f2a"),false,1)
	for x in [belt.position.x,belt.end.x]: canvas.draw_circle(Vector2(x,belt.get_center().y),6,Color("4a5558")); canvas.draw_arc(Vector2(x,belt.get_center().y),6,0,TAU,20,Color("b6aaa0"),2)
	for dx in [-34,-24]:
		var p: Vector2=Vector2(rail.end.x+dx,rail.get_center().y); canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-3,-2),p+Vector2(-3,2),p+Vector2(3,0)]),Color("dcc47a"))
	canvas.draw_circle(Vector2(rail.end.x-9,rail.get_center().y),2.5,Color("d49c46") if stopped else Color("83d38b"))
	if not stopped:
		var x: float=belt.position.x+6+fmod(motion/1040.0,1)*(belt.size.x-12); canvas.draw_rect(Rect2(Vector2(x-1.5,belt.position.y+2.5),Vector2(3,belt.size.y-5)),Color(0.92,0.97,1,0.64))
	var lamp: Rect2=Room.rect(b.targetEntities[0].installationBounds)
	Picker.record(canvas,["a1_bakery_inspection_lamp"],lamp)
	var lit: bool="bakery_conveyor_lamp_inspected" in c.factIds
	canvas.draw_rect(lamp,Color("ffd66b",0.72) if lit else Color("4d4330",0.34)); canvas.draw_rect(lamp,Color("fff1a8",0.92) if lit else Color("907b53",0.92),false,2)
	canvas.draw_set_transform(Vector2.ZERO)
	if ("bakery_hour_hand_exposed" in c.factIds or (stop_active and t>=520)) and "bakery_hour_hand_collected" not in c.factIds:
		register_frame(canvas,["a1_bakery_hour_hand_pickup"],"chapter4_story_items","old_clock_hour_hand",Vector2(294,345),0,0.1)
		draw_frame(canvas,context,"chapter4_story_items","old_clock_hour_hand",Vector2(294,345),0,0.1)
		_world(canvas,context)
		var glint: float=(1-cos(fmod(clock_ms/520,2)*PI))/2
		canvas.draw_circle(Vector2(305,331.5),9*lerpf(0.82,1.22,glint),Color("fff3a8",lerpf(0.18,0.92,glint)*0.2))
		canvas.draw_arc(Vector2(305,331.5),9*lerpf(0.82,1.22,glint),0,TAU,24,Color("fff3a8",lerpf(0.18,0.92,glint)*0.9),2)
		canvas.draw_set_transform(Vector2.ZERO)
func draw_projection(canvas: CanvasItem,context: Dictionary,elapsed: float) -> void:
	var b: Rect2=Room.rect(Room.data().layout.projectionHandshake.screenBounds); var center: Vector2=b.get_center(); var stable: bool=elapsed>=360; var misaligned: bool=elapsed>=120 and not stable
	if misaligned: center.x+=3
	_world(canvas,context)
	canvas.draw_rect(Rect2(center-b.size/2-Vector2(8,6),b.size+Vector2(16,12)),Color(0.31,0.86,1,0.14)); canvas.draw_rect(Rect2(center-b.size/2,b.size),Color(0.027,0.094,0.153,0.94)); canvas.draw_rect(Rect2(center-b.size/2,b.size),Color("ff8d82") if misaligned else Color("7ce9ff"),false,2)
	_text(canvas,center+Vector2(0,-15),"记录叠合",9,Color("8fe8ff"))
	var values: Array=["18:44","18:50","6s/8s","A3"]; var xs: Array=[-38,-13,15,39]; var colors: Array=["d8d4bd","79ddf1","f0b85f","d9b45f"]
	for i in range(4):
		var p: Vector2=center+Vector2(float(xs[i])+(i-1.5)*2 if misaligned else float(xs[i]),-3 if stable else -2+(i%2)*5)
		_text(canvas,p+Vector2(0,3),values[i],7,Color(colors[i],0.9 if stable else 0.62))
	if stable:
		for points in [[Vector2(-14,10),Vector2(-14,1),Vector2(2,1),Vector2(2,10)],[Vector2(10,10),Vector2(10,3),Vector2(20,3)]]:
			var path: PackedVector2Array=[]
			for p in points: path.append(center+p)
			canvas.draw_polyline(path,Color("8fe8ff"),1)
	_text(canvas,center+Vector2(0,23),Room.data().layout.projectionHandshake.stableText if stable else ("边缘偏移" if misaligned else "边缘未重合"),8,Color("f7f1dc"))
	canvas.draw_set_transform(Vector2.ZERO)
func _text(canvas: CanvasItem,p: Vector2,text: String,size: int,color: Color) -> void:
	var font: Font=source_font; var width: float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	canvas.draw_string(font,p-Vector2(width/2,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func _crowd_sample(route: Dictionary,index: int) -> Dictionary:
	var from: Vector2=Room.point(route.from); var to: Vector2=Room.point(route.to); var duration: float=roundf(from.distance_to(to)/float(route.speed)*1000); var pause: float=route.endpointPauseMs; var t: float=fmod(bakery_ms,2*(duration+pause)); var reverse: bool=t>=duration+pause
	var local: float=t-(duration+pause if reverse else 0); var p: Vector2=to.lerp(from,clampf(local/duration,0,1)) if reverse else from.lerp(to,clampf(local/duration,0,1)); var animation: String="student_walk"; var frame: int=(index*3+int(bakery_ms/125))%8
	if local>=duration:
		animation="student_idle"; frame=0
	if local>=duration and local-duration<maxf(180,minf(360,pause-40)):
		animation="student_phone_glance" if (index+(0 if reverse else 1))%2==0 else "student_adjust_bag"
		frame=mini(1,int((local-duration)/(1000.0/(3 if animation=="student_phone_glance" else 4))))
	return {"position":p,"animation":animation,"frame":frame,"flip":(to.x>from.x)!=reverse}
func _draw_bakery_people(canvas: CanvasItem,context: Dictionary,state: Dictionary,front: bool) -> void:
	var c: Dictionary=state.get("chapter4",{})
	if c.get("floor","")!="A1" or front: return
	var b: Dictionary=source.bakeryRuntime; var zoom: float=context.get("zoom",1.0); var origin: Vector2=context.get("origin",Vector2.ZERO)
	if c.get("phase","") in b.baker.activePhases:
		var art: Texture2D=texture(b.baker.textureFile.replace("src/assets/","res://assets/")); var p: Vector2=Room.point(b.baker.position)
		if art:
			var frame: int=6+mini(1,int(fmod(bakery_ms,2000.0/1.8+260)/(1000.0/1.8)))
			canvas.draw_texture_rect_region(art,Rect2(origin+(p-Vector2(48,128)*0.52)*zoom,Vector2(96,80)*0.52*zoom),Rect2(frame*96,0,96,80))
	if c.get("phase","")!="bakery_hour_hand" or c.get("timeState","")!="1225_bakery": return
	for i in range(b.crowd.routes.size()):
		var actor: Dictionary=_crowd_sample(b.crowd.routes[i],i)
		var suffix: String="8frame" if actor.animation=="student_walk" else "1frame" if actor.animation=="student_idle" else "2frame"
		var art: Texture2D=texture("res://assets/rpg/npcs/finale/"+actor.animation+"_"+suffix+".png")
		if not art: continue
		canvas.draw_set_transform(origin+Vector2(actor.position)*zoom,0,Vector2(-1 if actor.flip else 1,1)*0.65*zoom)
		canvas.draw_texture_rect_region(art,Rect2(-48,-128,96,128),Rect2(actor.frame*96,0,96,128)); canvas.draw_set_transform(Vector2.ZERO)
