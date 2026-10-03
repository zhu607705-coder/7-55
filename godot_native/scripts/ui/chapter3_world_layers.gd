extends RefCounted
const Picker=preload("res://scripts/world_object_picker.gd")
## Source-sized Phaser actors and dynamic props. This renderer never writes story facts.
const Metrics=preload("res://scripts/player_metrics.gd")
const PromoTimeline=preload("res://scripts/presentation/c3_promo_timeline.gd")
const Bike=preload("res://scripts/presentation/c3_bike_world_view.gd")
var bike_view: RefCounted=Bike.new()
const Door=preload("res://scripts/presentation/interior_door_layer.gd")
var doors: RefCounted=Door.new()
var narrative_session: RefCounted
var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter3-world-source.json"))
var worlds: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json")).worlds
var theater_text: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter3-theater.content.json"))
var textures: Dictionary={}
var font: Font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
var clock_ms: float=0
var scene_id: String=""
var previous_state: Dictionary={}
var light_alpha: float=1
var shadow_alpha: float=0
var fade_from:=Vector2(1,0)
var fade_to:=Vector2(1,0)
var fade_ms: float=180
var admission_ms: float=INF
var pickup_ms: float=INF
var pickup_start:=Vector2.ZERO
var collected_programs: Array=[]
var program_flights: Array=[]
var last_carried: Array=[]
var occlusion_alphas: Dictionary={}
func texture(path: String) -> Texture2D:
	if not textures.has(path): textures[path]=load(path) if ResourceLoader.exists(path) else null
	return textures[path]
func asset(key: String) -> String: return str(source.assets.get(key,""))
func reduced(s: Dictionary) -> bool: return bool(s.native.get("settings",{}).get("reduced_motion",false))
func scene_npcs(s: Dictionary) -> bool: return s.canteenHunt.phase!="exit_blocking"
func sync(s: Dictionary,scene_changed: bool=false) -> void:
	var current: String=str(s.native.get("scene",""))
	if scene_changed or current!=scene_id or previous_state.is_empty():
		scene_id=current; occlusion_alphas.clear(); clock_ms=0; admission_ms=INF; pickup_ms=INF; program_flights=[]
		last_carried=s.canteenHunt.carriedTrayIds.duplicate(); collected_programs=s.theaterHunt.collectedProgramIds.duplicate()
		previous_state=s.duplicate(true)
		fade_to=Vector2(1,0) if s.native.mode=="light" else Vector2(0,1)
		if not scene_npcs(s): fade_to=Vector2.ZERO
		fade_from=fade_to; light_alpha=fade_to.x; shadow_alpha=fade_to.y; fade_ms=180
	var target: Vector2=(Vector2(1,0) if s.native.mode=="light" else Vector2(0,1)) if scene_npcs(s) else Vector2.ZERO
	if target!=fade_to:
		fade_from=Vector2(light_alpha,shadow_alpha); fade_to=target; fade_ms=0
	if reduced(s): light_alpha=target.x; shadow_alpha=target.y; fade_ms=180
	if not previous_state.theaterHunt.admitted and s.theaterHunt.admitted: admission_ms=0
	if s.canteenHunt.carriedTrayIds!=last_carried:
		if not s.canteenHunt.carriedTrayIds.is_empty():
			var id: String=str(s.canteenHunt.carriedTrayIds[0])
			var trays: Array=worlds.canteen_interior.constants.CANTEEN_TRAYS
			for i in range(trays.size()):
				if str(trays[i].id)==id and i<s.native.get("c3_tray_slots",[]).size():
					var point: Dictionary=s.native.c3_tray_slots[i]; pickup_start=Vector2(point.x,point.y); pickup_ms=0
		last_carried=s.canteenHunt.carriedTrayIds.duplicate()
	for entry: Dictionary in worlds.theater_interior.interactionTargets:
		if entry.get("kind")=="program" and s.theaterHunt.collectedProgramIds.has(entry.programId) and not collected_programs.has(entry.programId):
			program_flights.append({"id":entry.programId,"start":Vector2(entry.x,entry.y),"elapsed":0.0})
	collected_programs=s.theaterHunt.collectedProgramIds.duplicate()
	previous_state=s.duplicate(true)
func tick(delta: float,s: Dictionary) -> void:
	sync(s)
	var dt: float=clampf(delta,0,.1)*1000
	clock_ms+=dt; admission_ms+=dt; pickup_ms+=dt; fade_ms=minf(180,fade_ms+dt)
	var blend: float=(1-cos(fade_ms/180*PI))/2
	light_alpha=lerpf(fade_from.x,fade_to.x,blend); shadow_alpha=lerpf(fade_from.y,fade_to.y,blend)
	for flight: Dictionary in program_flights: flight.elapsed+=dt
	program_flights=program_flights.filter(func(f:Dictionary)->bool:return float(f.elapsed)<(120 if reduced(s) else 420))
	doors.tick(delta,s,narrative_session)
func _npc_frame(pair: int,fps: float,delay: float,s: Dictionary) -> int:
	if reduced(s) or clock_ms<fmod(delay,540): return pair*2
	var t: float=fmod(clock_ms-fmod(delay,540),2000/fps+delay)
	return pair*2+(1 if t>=1000/fps else 0)
func _npc(id: String,key: String,p: Vector2,pair: int,depth: float,fps: float,delay: float,s: Dictionary) -> Dictionary:
	return {"id":id,"kind":"sprite","asset":asset(key),"point":p,"scale":Metrics.DISPLAY_SCALE,"frameSize":Vector2(96,128),"frame":_npc_frame(pair,fps,delay,s),"anchor":Vector2(.5,1),"alpha":light_alpha,"depth":depth}
func promo_pose(s: Dictionary) -> Dictionary:
	if narrative_session==null or narrative_session.sequence_id!="canteen_promo" or narrative_session.status not in ["issued","playing","complete"]: return {}
	return PromoTimeline.snapshot(maxf(0,narrative_session.elapsed_ms-float(narrative_session.spec.get("timelineStartMs",0))),reduced(s))
func entries(s: Dictionary) -> Array:
	var result: Array=[]
	if scene_id=="canteen_interior":
		var c: Dictionary=source.constants
		var promo_live: Dictionary=promo_pose(s)
		if light_alpha>0:
			for i in range(c.CANTEEN_COUNTER_NPC_X.size()):
				var x: float=c.CANTEEN_COUNTER_NPC_X[i]
				result.append(_npc("counter_"+str(i),"canteenCounterAuntiesSheetUrl",Vector2(x,c.CANTEEN_COUNTER_NPC_Y),i,300,1.7+i*.08,260+i*83,s))
				for row in range(c.CANTEEN_QUEUE_NPC_Y.size()):
					var index: int=i*3+row
					var y: float=c.CANTEEN_QUEUE_NPC_Y[row]+(float(promo_live.queueOffsets[row]) if i==2 and not promo_live.is_empty() else 36 if i==2 and s.canteenHunt.queueGapOpened else 0)
					if i==2 and row==0 and promo_live.get("turnVisible",false):
						result.append({"id":"queue_turn","kind":"sprite","asset":asset("canteenQueueStudentTurnUrl"),"point":Vector2(x,y),"scale":Metrics.DISPLAY_SCALE,"anchor":Vector2(.5,1),"depth":y+122}); continue
					result.append(_npc("queue_"+str(index),"canteenQueueStudentsSheetUrl",Vector2(x,y),index,y+120,1.35+(index%4)*.1,180+((i*3+row)*137)%520,s))
			for group: Array in [["CANTEEN_SEATED_NPC_PLACEMENTS","canteenSeatedStudentsSheetUrl"],["CANTEEN_SEATED_EXTRA_NPC_PLACEMENTS","canteenSeatedStudentsExtraSheetUrl"]]:
				for i in range(c[group[0]].size()):
					var p: Dictionary=c[group[0]][i]; var extra: bool=str(group[0]).contains("EXTRA")
					result.append(_npc(str(group[0])+str(i),group[1],Vector2(p.x,p.y),p.framePair,p.y+120,1.5+(i%3)*.13 if extra else 1.45+(i%4)*.12,310+(i*173)%620 if extra else 220+(i*149)%640,s))
			var return_p: Dictionary=c.CANTEEN_RETURN_NPC_POSITION
			result.append(_npc("return_worker","canteenReturnAuntieSheetUrl",Vector2(return_p.x,return_p.y),0,return_p.y+120,1.65,390,s))
		if shadow_alpha>0:
			var sequence: Array=[0,0,1,0,0,0,2]
			var index: int=mini(6,int(fmod(clock_ms,1780)/(1000.0/7))) if not reduced(s) else 0
			result.append({"id":"shadow_worker","kind":"sprite","asset":asset("canteenShadowAuntieSheetUrl"),"point":Vector2(c.CANTEEN_COUNTER_NPC_X[2],c.CANTEEN_COUNTER_NPC_Y),"scale":Metrics.DISPLAY_SCALE,"frameSize":Vector2(96,128),"frame":sequence[index],"anchor":Vector2(.5,1),"alpha":shadow_alpha,"depth":310})
		var counter: Dictionary=c.CANTEEN_COUNTER_FRONT_CROP
		result.append({"id":"counter_front","kind":"crop","asset":asset("canteenInteriorMapUrl"),"rect":_bounds(counter),"depth":counter.depth})
		for i in range(c.CANTEEN_SEATED_TABLE_CROPS.size()):
			var crop: Dictionary=c.CANTEEN_SEATED_TABLE_CROPS[i]
			result.append({"id":"table_front_"+str(i),"kind":"crop","asset":asset("canteenInteriorMapUrl"),"rect":_bounds(crop),"depth":crop.bottom+120})
		var side: bool=s.canteenHunt.active and s.canteenHunt.phase in c.CANTEEN_SIDE_GAME_PHASES
		if side and s.canteenHunt.entryPaperEscaped:
			var promo: Dictionary=worlds.canteen_interior.constants.CANTEEN_PROMO_BOARD
			var active: bool=s.canteenHunt.promoDrinkPlaced and s.canteenHunt.queueGapOpened
			if promo_live.is_empty():
				result.append({"id":"promo_active" if active else "promo_empty","kind":"sprite","asset":asset("canteenPromoBoardActiveUrl" if active else "canteenPromoBoardEmptyUrl"),"point":Vector2(promo.x,promo.y),"scale":.5,"depth":1700 if active else 1698})
				if active: result.append({"id":"promo_bubbles","kind":"sprite","asset":asset("canteenPromoFxSheetUrl"),"point":Vector2(promo.x-15,promo.y+2),"scale":.56,"frameSize":Vector2(48,48),"frame":int(clock_ms/(1000.0/6))%3,"depth":1704})
			else:
				if promo_live.emptyVisible: result.append({"id":"promo_empty","kind":"sprite","asset":asset("canteenPromoBoardEmptyUrl"),"point":Vector2(promo.x,promo.y),"scale":.5,"alpha":promo_live.emptyAlpha,"depth":1698})
				if promo_live.insertVisible: result.append({"id":"promo_insert","kind":"sprite","asset":asset("canteenPromoDrinkInsertSheetUrl"),"point":Vector2(promo.x-14,promo.y+8),"scale":1.2,"frameSize":Vector2(48,64),"frame":promo_live.insertFrame,"depth":1703})
				if promo_live.activeVisible: result.append({"id":"promo_active","kind":"sprite","asset":asset("canteenPromoBoardActiveUrl"),"point":Vector2(promo.x,promo.y),"scale":promo_live.activeScale,"alpha":promo_live.activeAlpha,"depth":1700})
				if promo_live.bubblesVisible: result.append({"id":"promo_bubbles","kind":"sprite","asset":asset("canteenPromoFxSheetUrl"),"point":Vector2(promo.x-15,promo.y+2),"scale":.56,"frameSize":Vector2(48,48),"frame":promo_live.bubblesFrame,"depth":1704})
				if promo_live.glowAlpha>0: result.append({"id":"promo_glow","kind":"glow","point":Vector2(promo.x,promo.y),"size":Vector2(158,108)*float(promo_live.glowScale),"alpha":promo_live.glowAlpha,"depth":1699})
				for row in range(3):
					var prompt: Dictionary=promo_live.prompts[row]
					if prompt.visible: result.append({"id":"queue_prompt_"+str(row),"kind":"sprite","asset":asset("canteenPromoFxSheetUrl"),"point":Vector2(c.CANTEEN_COUNTER_NPC_X[2],c.CANTEEN_QUEUE_NPC_Y[row]+float(prompt.dy)),"scale":.55,"frameSize":Vector2(48,48),"frame":prompt.frame,"alpha":prompt.alpha,"depth":c.CANTEEN_QUEUE_NPC_Y[row]+128})
			if not s.canteenHunt.carriedTrayIds.is_empty() and (narrative_session==null or narrative_session.status not in ["issued","playing","complete"]):
				var player: Vector2=_player(s); var duration: float=100 if reduced(s) else 360
				var target: Vector2=player-Vector2(0,48)
				if pickup_ms<duration:
					var ratio: float=pickup_ms/duration; var ease: float=2.70158*ratio*ratio*ratio-1.70158*ratio*ratio
					result.append({"id":"tray_pickup","kind":"tray","point":pickup_start.lerp(target,ease),"scale":lerpf(.75,.58,ease),"depth":2300})
				else: result.append({"id":"carried_tray","kind":"tray","point":target,"scale":.75,"depth":player.y+163})
	elif scene_id=="theater_interior":
		var t: Dictionary=s.theaterHunt; var dark: bool=s.native.mode=="dark"
		var offset: float=worlds.theater_interior.constants.THEATER_TICKET_FIXTURE_OFFSET_Y
		var scan: bool=admission_ms<(160 if reduced(s) else 900)
		var bob: float=0 if reduced(s) else _yoyo(clock_ms,1350)
		result.append({"id":"ticket_inspector","kind":"sprite","asset":asset("ticketInspectorScanUrl" if scan else "ticketInspectorIdleUrl"),"point":Vector2(753,681+offset-16-bob),"scale":.75,"depth":832+offset})
		result.append({"id":"ticket_reader","kind":"reader","point":Vector2(907,690+offset),"admitted":t.admitted,"depth":839+offset})
		for target: Dictionary in worlds.theater_interior.interactionTargets:
			if target.kind=="program" and t.phase=="program_search" and not t.collectedProgramIds.has(target.programId):
				result.append({"id":"program_"+str(target.programId),"kind":"sprite","asset":asset("program"+str(target.programId).capitalize()+"Url"),"point":Vector2(target.x,target.y),"size":Vector2(48,48),"depth":target.y+40,"glow":dark})
		for flight: Dictionary in program_flights:
			var p: float=clampf(flight.elapsed/(120 if reduced(s) else 420),0,1)
			var ease: float=2.70158*p*p*p-1.70158*p*p
			result.append({"id":"program_flight_"+str(flight.id),"kind":"sprite","asset":asset("program"+str(flight.id).capitalize()+"Url"),"point":flight.start.lerp(_player(s)-Vector2(0,50),ease),"size":Vector2(48,48)*lerpf(1,.35,ease),"alpha":1-ease,"depth":2300})
		if dark and t.phase=="prop_setup" and not t.propGhostRead:
			var alpha: float=1 if reduced(s) else lerpf(.58,.9,_yoyo(clock_ms,760))
			result.append({"id":"prop_ghost","kind":"sprite","asset":asset("propBoxGhostUrl"),"point":Vector2(294,165),"scale":.78,"alpha":alpha,"depth":1603})
			result.append({"id":"manager_ghost","kind":"sprite","asset":asset("stageManagerGhostIdleUrl" if reduced(s) or int(clock_ms/720)%2==0 else "stageManagerGhostPointUrl"),"point":Vector2(500,166),"scale":.7,"alpha":alpha,"depth":1604})
			result.append({"id":"prop_clue","kind":"text","point":Vector2(310,108),"text":theater_text.prop.ghost+"\n"+theater_text.prop.managerHint,"width":280.0,"fontSize":12,"depth":1603})
		if dark and t.phase=="spotlight_ready": result.append({"id":"paper_future_path","kind":"sprite","asset":asset("paperFuturePathUrl"),"point":Vector2(835,180),"scale":.78,"depth":2101})
		if t.phase in ["spotlight_ready","spotlight_hunt","reversal"]:
			var p: float=_yoyo(clock_ms,760)
			result.append({"id":"stage_paper","kind":"sprite","asset":asset("paperResidualUrl" if dark else "paperFluorescentUrl" if t.paperDusted else "paperFlightUrl"),"point":Vector2(835,180+7*p),"angle":lerpf(-4,4,p),"scale":1.0,"depth":2100})
		if dark and t.phase=="entry_ticket" and not t.posterCleaned: result.append({"id":"poster_half","kind":"poster","point":Vector2(282,731),"depth":1603})
		if not dark and t.phase=="entry_ticket" and t.cc98TicketCommissionPhase=="delivered" and not s.items.theaterTicketHalfB and not s.items.temporaryTheaterTicket:
			result.append({"id":"kiosk_receipt","kind":"text","point":Vector2(1146,715),"text":theater_text.ticket.codeVisible,"width":350.0,"fontSize":13,"depth":1603})
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.depth)<float(b.depth))
	return result
func canteen_occlusion(cover: Dictionary, player: Vector2, is_reduced: bool) -> Dictionary:
	# CanteenInteriorScene.updateOcclusion uses the actual foot body, not the
	# sprite anchor. It softens intersecting foreground instead of losing the actor.
	var bounds:=_bounds(cover)
	var player_bounds: Rect2=Metrics.visual_rect(player)
	var foot_y: float=Metrics.foot_rect(player).end.y
	var behind: bool=player_bounds.end.x>bounds.position.x and player_bounds.position.x<bounds.end.x and foot_y<float(cover.get("sortY",bounds.end.y))-1
	var overlaps: bool=behind and player_bounds.intersects(bounds)
	var target_alpha: float=.52 if overlaps else 1.0
	var id: String=str(cover.get("id",""))
	var alpha: float=target_alpha if is_reduced else lerpf(float(occlusion_alphas.get(id,1.0)),target_alpha,.18)
	occlusion_alphas[id]=alpha
	return {"visible":behind,"alpha":alpha,"softened":overlaps}

func draw_landmarks(canvas: CanvasItem,context: Dictionary,s: Dictionary) -> void:
	bike_view.draw_hint(canvas,context,s)
	# Small presentation repair for an existing authored mixer hotspot that was
	# otherwise indistinguishable from the five ordering kiosks in the base plate.
	# No recipe/color clue, collision, availability, or transaction change.
	if scene_id!="canteen_interior" or not s.canteenHunt.active or not s.canteenHunt.entryPaperEscaped or s.canteenHunt.promoDrinkPlaced or s.canteenHunt.phase not in source.constants.CANTEEN_SIDE_GAME_PHASES: return
	var station: Dictionary=worlds.canteen_interior.constants.CANTEEN_MIX_STATION
	var point:=Vector2(station.x,station.y)
	var origin: Vector2=context.origin; var z: float=context.zoom
	canvas.draw_set_transform(origin+point*z,0,Vector2.ONE*z)
	canvas.draw_rect(Rect2(-57,-46,114,97),Color("18333a"))
	canvas.draw_rect(Rect2(-57,-46,114,97),Color("8e7754"),false,3)
	canvas.draw_rect(Rect2(-26,-32,52,54),Color("b9e6ee",.16))
	canvas.draw_polyline(PackedVector2Array([Vector2(-27,-34),Vector2(-23,24),Vector2(23,24),Vector2(27,-34)]),Color("b9e6ee"),3)
	canvas.draw_line(Vector2(7,11),Vector2(19,-42),Color("d9caa9"),3)
	canvas.draw_rect(Rect2(-55,27,110,22),Color("8e7754"))
	canvas.draw_string(font,Vector2(-36,43),"混合台",HORIZONTAL_ALIGNMENT_CENTER,72,16,Color("fff2d8"))
	canvas.draw_set_transform(Vector2.ZERO)
	if canvas.has_method("register_object_bounds"): canvas.register_object_bounds(["canteen-mixer"],Rect2(point+Vector2(-57,-46),Vector2(114,97)))

func adjusted_collisions(base: Array,s: Dictionary) -> Array:
	var out: Array=base.filter(func(box: Dictionary)->bool:return not str(box.get("id","")).begins_with("c3_dynamic_"))
	if scene_id=="canteen_interior" and scene_npcs(s) and s.native.mode=="light":
		var c: Dictionary=source.constants
		var promo_live: Dictionary=promo_pose(s)
		for col in range(c.CANTEEN_COUNTER_NPC_X.size()):
			for row in range(c.CANTEEN_QUEUE_NPC_Y.size()):
				if col==2 and not promo_live.is_empty() and not promo_live.queueCollidable[row]: continue
				var p:=Vector2(c.CANTEEN_COUNTER_NPC_X[col],c.CANTEEN_QUEUE_NPC_Y[row]+(float(promo_live.queueOffsets[row]) if col==2 and not promo_live.is_empty() else 36 if col==2 and s.canteenHunt.queueGapOpened else 0))
				out.append(_foot("queue_"+str(col*3+row),p))
		out.append(_foot("return_worker",Vector2(c.CANTEEN_RETURN_NPC_POSITION.x,c.CANTEEN_RETURN_NPC_POSITION.y)))
	elif scene_id=="theater_interior":
		for box: Dictionary in source.constants.THEATER_TICKET_FIXTURE_COLLISION_RECTS:
			var entry: Dictionary=box.duplicate(); entry.id="c3_dynamic_"+str(box.id); out.append(entry)
		if not s.theaterHunt.admitted:
			var entry: Dictionary=worlds.theater_interior.constants.THEATER_GATE_BLOCKER.duplicate(); entry.id="c3_dynamic_admission_gate"; out.append(entry)
	return out
func owns_pick_target(target: Dictionary,_state: Dictionary) -> bool:
	var id: String=str(target.get("id",""))
	return (scene_id=="campus_bootstrap" and id=="bike") or scene_id in ["canteen_interior","theater_interior"] and (id.begins_with("initial-") or id.begins_with("theater_program_") or id in ["auntie","canteen-promo-board","theater_ticket_gate"])

func _pick_ids(entry: Dictionary,targets: Array) -> Array:
	var id: String=str(entry.id)
	if id.begins_with("program_") and not id.begins_with("program_flight_"): return ["theater_"+id]
	if id in ["promo_empty","promo_active","promo_insert","promo_bubbles"]: return ["canteen-promo-board"]
	if id=="ticket_reader": return ["theater_ticket_gate"]
	if id=="prop_ghost": return ["theater_prop_box"]
	if id=="return_worker": return ["auntie"]
	var result: Array=[]
	for target: Dictionary in targets:
		var target_id: String=str(target.get("id",""))
		if not target_id.begins_with("initial-"): continue
		var point:=Vector2(float(target.position[0]),float(target.position[1]))
		if target_id.begins_with("initial-seated-"): point.y+=30
		if point.is_equal_approx(entry.get("point",Vector2.INF)): result.append(target_id)
	return result

func handles_target(target: Dictionary,_s: Dictionary) -> bool: return str(target.get("id","")).begins_with("theater_program_")
func _foot(id: String,p: Vector2) -> Dictionary: return {"id":"c3_dynamic_"+id,"left":p.x-Metrics.FOOT_SIZE.x/2,"right":p.x+Metrics.FOOT_SIZE.x/2,"top":p.y-Metrics.FOOT_SIZE.y,"bottom":p.y}
func _bounds(r: Dictionary) -> Rect2: return Rect2(r.left,r.top,r.right-r.left,r.bottom-r.top)
func _player(s: Dictionary) -> Vector2:
	var p: Dictionary=s.native.get("player",{}); return Vector2(float(p.get("x",0)),float(p.get("y",0)))
func _yoyo(ms: float,duration: float) -> float:
	var p: float=fmod(ms/duration,2); return (1-cos(p*PI))/2
func draw_back(canvas: CanvasItem,context: Dictionary,s: Dictionary) -> void:
	bike_view.draw(canvas,context,s,false)
	doors.draw_back(canvas,context,s)
	_draw_partition(canvas,context,s,false)
func draw_front(canvas: CanvasItem,context: Dictionary,s: Dictionary) -> void:
	bike_view.draw(canvas,context,s,true)
	_draw_partition(canvas,context,s,true)
	doors.draw_front(canvas,context,s)
func _draw_partition(canvas: CanvasItem,context: Dictionary,s: Dictionary,front: bool) -> void:
	if scene_id not in ["canteen_interior","theater_interior"]: return
	var depth: float=context.player.y+(159 if scene_id=="canteen_interior" else 120)
	for entry: Dictionary in entries(s):
		if (float(entry.depth)>depth)==front: _draw_entry(canvas,context,entry)
func _draw_entry(canvas: CanvasItem,context: Dictionary,entry: Dictionary) -> void:
	var z: float=context.zoom; var origin: Vector2=context.origin
	if entry.kind=="crop":
		var tex: Texture2D=texture(entry.asset)
		if tex!=null: canvas.draw_texture_rect_region(tex,Rect2(origin+entry.rect.position*z,entry.rect.size*z),entry.rect)
		return
	var point: Vector2=entry.point; var scale_value: float=float(entry.get("scale",1))
	canvas.draw_set_transform(origin+point*z,deg_to_rad(float(entry.get("angle",0))),Vector2.ONE*z*scale_value)
	if entry.kind=="sprite":
		var tex: Texture2D=texture(entry.asset)
		if tex!=null:
			var region:=Rect2(Vector2.ZERO,tex.get_size())
			if entry.has("frameSize"):
				var columns: int=maxi(1,int(tex.get_width()/entry.frameSize.x)); var frame: int=int(entry.frame)
				region=Rect2(Vector2((frame%columns)*entry.frameSize.x,int(frame/columns)*entry.frameSize.y),entry.frameSize)
			var size_value: Vector2=entry.get("size",region.size)
			if entry.get("glow",false):
				var pulse: float=_yoyo(clock_ms,820)
				canvas.draw_circle(Vector2.ZERO,26*lerpf(.82,1.18,pulse),Color("2aaeff",.16)); canvas.draw_arc(Vector2.ZERO,26*lerpf(.82,1.18,pulse),0,TAU,32,Color("83e4ff",lerpf(.3,.9,pulse)),4)
			if float(entry.get("alpha",1))>0.05:
				var ids: Array=_pick_ids(entry,(canvas.get("targets") if canvas.has_method("_pick_target") else []))
				# These surfaces use the exact current frame, pivot, scale and rotation.
				Picker.record(canvas,ids,{"rect":Rect2(-size_value*entry.get("anchor",Vector2(.5,.5)),size_value),"texture":tex,"source":region,"transform":Transform2D(deg_to_rad(float(entry.get("angle",0))),Vector2.ONE*scale_value,0,point)})
			canvas.draw_texture_rect_region(tex,Rect2(-size_value*entry.get("anchor",Vector2(.5,.5)),size_value),region,Color(1,1,1,clampf(float(entry.get("alpha",1)),0,1)))
	elif entry.kind=="glow":
		canvas.draw_rect(Rect2(-entry.size/2,entry.size),Color("9af4ff",entry.alpha))
	elif entry.kind=="tray":
		canvas.draw_style_box(_rounded(Color("9eabad"),Color("59686d"),3),Rect2(-11,-7,22,13)); canvas.draw_style_box(_rounded(Color("e7ece9"),Color.TRANSPARENT,2),Rect2(-9,-5,18,9))
	elif entry.kind=="reader":
		Picker.record(canvas,["theater_ticket_gate"],Rect2(point+Vector2(-11,-13),Vector2(22,42)))
		Picker.record(canvas,["theater_ticket_gate"],Rect2(point+Vector2(-17,-30.5),Vector2(34,25)))
		canvas.draw_rect(Rect2(-11,-13,22,42),Color("263443")); canvas.draw_rect(Rect2(-11,-13,22,42),Color("101820"),false,3)
		canvas.draw_rect(Rect2(-17,-30.5,34,25),Color("182431")); canvas.draw_rect(Rect2(-17,-30.5,34,25),Color("090f18"),false,3)
		canvas.draw_rect(Rect2(-10,-24,20,8),Color("64e58d") if entry.admitted else Color("58d7f2",lerpf(.55,1,_yoyo(clock_ms,760))))
		canvas.draw_rect(Rect2(-11,-11.5,22,3),Color("d8bd72",.92)); canvas.draw_string(font,Vector2(-9,12),"验票",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("e8d9b9"))
	elif entry.kind=="poster":
		canvas.draw_rect(Rect2(-20,-12,40,24),Color("88e8ff",.15)); canvas.draw_rect(Rect2(-20,-12,40,24),Color("88e8ff",.95),false,3); canvas.draw_string(font,Vector2(-5,6),"A",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("c8f7ff"))
	elif entry.kind=="text":
		var width: float=entry.width; var height: float=font.get_multiline_string_size(entry.text,HORIZONTAL_ALIGNMENT_CENTER,width,int(entry.fontSize)).y+10
		canvas.draw_rect(Rect2(-width/2-8,-height/2,width+16,height),Color("091126",.9))
		canvas.draw_multiline_string(font,Vector2(-width/2,-height/2+5+font.get_ascent(int(entry.fontSize))),entry.text,HORIZONTAL_ALIGNMENT_CENTER,width,int(entry.fontSize),-1,Color("9eeaff"))
	canvas.draw_set_transform(Vector2.ZERO)
func _rounded(fill: Color,border: Color,radius: int) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new(); style.bg_color=fill; style.border_color=border; style.set_border_width_all(1 if border.a>0 else 0); style.set_corner_radius_all(radius); return style
