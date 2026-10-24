extends RefCounted
const StampMotion=preload("res://scripts/presentation/library_stamp_motion.gd")
const Picker=preload("res://scripts/world_object_picker.gd")
const ObjectRebuild=preload("res://scripts/ui/library_object_rebuild.gd")
const PlayerMetrics=preload("res://scripts/player_metrics.gd")
const PrinterObject=preload("res://scripts/ui/library_printer_object.gd")
const SeatMotion=preload("res://scripts/presentation/library_seat_motion.gd")
## LibraryInteriorScene's source-pixel replacement layers and timed prop motion.
## Runtime-only presentation; reads persisted facts but never creates them.
var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/library-world-source.json"))
var art: Texture2D
var staff_art: Texture2D
var stamp_art: Texture2D
var rebuild: RefCounted=ObjectRebuild.new()
var printer: RefCounted=PrinterObject.new()
var seat: RefCounted=SeatMotion.new()
var clock_ms: float=0
var stamp_ms: float=-1
var scanning_ms: float=-1
var stamped: bool=false
var lost_stage: String="missing_report"
var font: Font=load("res://scripts/ui/native_typography.gd").body_font()
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
var reveal_serial: int=0
var cue_queue: Array=[]
var broadcast_index: int=0
var last_player:=Vector2.ZERO
var pass_from:=Vector2.ZERO

func sync(state: Dictionary,scene_changed: bool=false) -> void:
	seat.sync(state,scene_changed)
	var scene: String=str(state.get("native",{}).get("scene",""))
	if scene!="library_interior":
		if active: reveal_serial+=1
		printer.sync(state,false)
		active=false; initialized=false; shelf_animating=false; bag_animating=false; cue_queue.clear(); return
	active=true
	# The World is instantiated in Chapter 1. Generated Chapter 2 textures must
	# not be probed until their real content family is mounted. Failed attempts
	# remain retryable, rather than pinning one startup miss for the whole run.
	var content_ready: bool=not OS.has_feature("web")
	if not content_ready:
		var loop: MainLoop=Engine.get_main_loop()
		var delivery: Node=(loop as SceneTree).root.get_node_or_null("WebContent") if loop is SceneTree else null
		content_ready=delivery!=null and bool(delivery.call("ready_for_state",state))
	if content_ready:
		if art==null: art=load("res://assets/rpg/interiors/library_interior.png")
		if staff_art==null: staff_art=load("res://assets/rpg/npcs/library/front_desk_staff_2frame.png")
		if stamp_art==null: stamp_art=load("res://assets/rpg/props/library_front_desk_stamp_v01.png")
		rebuild.ensure_loaded()
	printer.sync(state,rebuild.ready,scene_changed)
	var p: Dictionary=state.get("ui",{}).get("libraryFinalsPuzzle",{})
	reduced=bool(state.get("native",{}).get("settings",{}).get("reduced_motion",false))
	if not initialized or scene_changed or not is_same(state,bound_state):
		reveal_serial+=1
		bound_state=state; initialized=true
		shelf_collected=bool(p.get("archivedRuleCollected",false)); bag_evicted=bool(p.get("backpackEvicted",false))
		shelf_offset=int(source.shelf.shiftPx) if shelf_collected else 0
		shelf_phase="complete" if shelf_collected else "idle"; shelf_frame=source.shelf.frames.size()-1 if shelf_collected else 0
		shelf_animating=false; bag_animating=false; shelf_ms=0; bag_ms=0; broadcast_index=0
		stamped=bool(p.get("nonPersonProofStamped",false)); stamp_ms=-1; clock_ms=0; lost_stage=str(p.get("lostFoundStage","missing_report")); scanning_ms=0 if lost_stage=="scanning" else -1
		cue_queue.clear(); return
	if not stamped and p.get("nonPersonProofStamped",false): stamp_ms=0; scanning_ms=-1
	if lost_stage!="scanning" and p.get("lostFoundStage","")=="scanning": scanning_ms=0
	stamped=bool(p.get("nonPersonProofStamped",false)); lost_stage=str(p.get("lostFoundStage","missing_report"))
	if not shelf_collected and p.get("archivedRuleCollected",false):
		reveal_serial+=1
		shelf_animating=true; shelf_ms=0; shelf_offset=0; shelf_frame=0; shelf_phase="shaking"
	if not bag_evicted and p.get("backpackEvicted",false):
		bag_animating=true; bag_ms=0; broadcast_index=0; pass_from=last_player
	shelf_collected=bool(p.get("archivedRuleCollected",false)); bag_evicted=bool(p.get("backpackEvicted",false))

func tick(delta: float,state: Dictionary) -> void:
	sync(state)
	if not active or not is_finite(delta) or delta<=0: return
	var ms: float=minf(delta,0.05)*1000
	printer.advance(ms/1000.0)
	seat.advance(ms/1000.0)
	clock_ms+=ms
	if scanning_ms>=0: scanning_ms+=ms
	if stamp_ms>=0:
		stamp_ms+=ms
		if stamp_ms>=(StampMotion.REDUCED_MS if reduced else StampMotion.TOTAL_MS): stamp_ms=-1; clock_ms=0
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
			finish_shelf_reveal(state,reveal_serial)
	if bag_animating:
		bag_ms+=ms
		var lines: Array=["书包：主人马上回来。","玩家：什么时候？","书包：三分钟。","系统：它三天前也是这么说的。"]
		while broadcast_index<lines.size() and bag_ms>=broadcast_index*720:
			cue_queue.append({"id":"library_backpack_broadcast_line","payload":{"text":lines[broadcast_index],"index":broadcast_index}}); broadcast_index+=1
		if bag_ms>=bag_total_ms(): bag_animating=false

func paper_start_ms() -> float: return 140.0 if reduced else float(source.shelf.totalMs)+110.0
func shelf_total_ms() -> float: return paper_start_ms()+(120+20+100 if reduced else 240+220+220)
func owns_shelf_reveal(state: Dictionary,serial: int) -> bool:
	return active and initialized and is_same(state,bound_state) and serial==reveal_serial and str(state.get("native",{}).get("scene",""))=="library_interior" and bool(state.get("ui",{}).get("libraryFinalsPuzzle",{}).get("archivedRuleCollected",false))
func _settle_shelf_reveal() -> void:
	shelf_animating=false; shelf_phase="complete"; shelf_offset=int(source.shelf.shiftPx)
	shelf_frame=source.shelf.frames.size()-1; shelf_ms=shelf_total_ms()
func finish_shelf_reveal(state: Dictionary,serial: int) -> bool:
	# Presentation completion never acquires, consumes, reads or saves an item.
	if not owns_shelf_reveal(state,serial) or not shelf_animating: return false
	_settle_shelf_reveal()
	cue_queue.append({"id":"library_archived_rule_reveal_completed","payload":{"itemId":"archivedLeaveRule","revealSerial":reveal_serial}})
	return true
func cancel_shelf_reveal(state: Dictionary,serial: int) -> void:
	if not is_same(state,bound_state) or serial!=reveal_serial: return
	# The controller has already committed the acquisition. Leaving its reveal
	# keeps the earned final pose and invalidates any queued old completion.
	if shelf_collected: _settle_shelf_reveal()
	reveal_serial+=1
	cue_queue=cue_queue.filter(func(event: Dictionary): return event.get("id","")!="library_archived_rule_reveal_completed")
func bag_shake_ms() -> float: return float(source.backpackTimeline.shakeDurationMs)*2*(int(source.backpackTimeline.shakeRepeat)+1)
func bag_total_ms() -> float: return bag_shake_ms()+float(source.backpackTimeline.waitMs)+float(source.backpackTimeline.transferMs)
func stamp_animation_active(state: Dictionary) -> bool:
	# A replaced save or another scene cannot retain an old presentation wait.
	return active and initialized and is_same(state,bound_state) and str(state.get("native",{}).get("scene",""))=="library_interior" and stamp_ms>=0
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
	var angle: float=float(source.backpack.angle)
	if not bag_evicted and rebuild.ready:
		var inspect: Dictionary=seat.bag_pose()
		position+=Vector2(inspect.offset); angle+=float(inspect.angle)
	if bag_animating:
		if bag_ms<bag_shake_ms():
			var phase: float=fposmod(bag_ms,140)/70
			position.x+=7*(phase if phase<=1 else 2-phase)
		elif bag_ms>=bag_shake_ms()+float(source.backpackTimeline.waitMs):
			var ratio: float=_stepped((bag_ms-bag_shake_ms()-float(source.backpackTimeline.waitMs))/float(source.backpackTimeline.transferMs))
			position=position.lerp(Vector2(334,634),ratio); alpha=1-ratio
	var generated: bool=rebuild.ready
	return {"position":position,"alpha":alpha,"visible":bag_animating or (generated and not bag_evicted),"scale":float(source.backpack.scale),"angle":angle,"depth":float(rebuild.layout.objects.backpack.depth) if generated else float(source.backpack.depth)}
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
	return {"active":active,"shelfPhase":shelf_phase,"shelfFrame":shelf_frame,"shelfOffset":shelf_offset,"shelfAnimating":shelf_animating,"shelfMs":shelf_ms,"shelfTotalMs":shelf_total_ms(),"shelfCollision":collision_rect(),"backpack":backpack_pose(),"backpackClearPatch":bag_evicted,"backpackMs":bag_ms,"backpackTotalMs":bag_total_ms(),"paper":paper_pose(),"receiptMs":seat.receipt_ms,"note":seat.note_pose(),"receipt":seat.receipt_pose(),"staff":staff_pose(),"stampMs":stamp_ms,"stamp":stamp_pose(),"objectRebuild":rebuild.snapshot(),"printer":printer.snapshot()}

func owns_pick_target(id: String) -> bool:
	return id in ["front_desk","identity_machine","library_shelf_755","occupancy_note"] or (rebuild.ready and id in ["catalog_terminal","printer","backpack","bag_photo","backpack_pass"])

func _context(canvas: CanvasItem,context: Dictionary) -> void:
	canvas.draw_set_transform(context.get("origin",Vector2.ZERO),0,Vector2.ONE*float(context.get("zoom",1)))
func _in_pass(depth: float,context: Dictionary,front: bool) -> bool:
	return (depth>Vector2(context.get("player",Vector2.ZERO)).y+float(source.playerDepthOffset))==front
func _floor_depth(baseline: float) -> float:
	return baseline+float(source.playerDepthOffset)-PlayerMetrics.foot_rect(Vector2.ZERO).position.y
func draw_back(canvas: CanvasItem,context: Dictionary,state: Dictionary) -> void:
	if context.get("scene_id","")!="library_interior": return
	seat.bind_view(canvas)
	sync(state); last_player=context.get("player",Vector2.ZERO); _context(canvas,context)
	if rebuild.ready:
		# The world normally uses the clean plate directly, preserving its wash
		# and floor-route draw order. Standalone layer previews may supply no base.
		if context.get("background")!=rebuild.clean_plate:
			canvas.draw_texture_rect(rebuild.clean_plate,Rect2(Vector2.ZERO,rebuild.clean_plate.get_size()),false)
		if shelf_collected: _draw_mechanism(canvas)
	else:
		# Original-source fallback is explicit in debug_snapshot. It is retained
		# only while the complete generated asset set is unavailable.
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
	if rebuild.ready:
		_draw_static_foreground(canvas,context,front)
		for id: String in ["catalog_terminal","printer"]:
			if _in_pass(_floor_depth(float(rebuild.layout.objects[id].baselineY)),context,front):
				if id=="printer": printer.draw(canvas,rebuild.geometry(id,rebuild.bounds(id)),rebuild.layout.objects[id].targets)
				else: _draw_generated_object(canvas,id,rebuild.bounds(id))
			for component: Dictionary in rebuild.layout.objects[id].get("components",[]):
				if _in_pass(_floor_depth(float(component.baselineY)),context,front):
					var geometry: Dictionary=rebuild.component_geometry(id,component)
					Picker.record(canvas,component.targets,geometry)
					canvas.draw_texture_rect_region(geometry.texture,geometry.rect,geometry.source)
	# Original clocks and the shared player.y+120 depth contract are retained.
	if _in_pass(float(source.shelfDepth),context,front): _draw_shelf(canvas,state)
	if not rebuild.ready and _in_pass(float(source.mechanismDepth),context,front) and shelf_collected: _draw_mechanism(canvas)
	if _in_pass(float(source.paperDepth),context,front): _draw_shelf_paper(canvas)
	if _in_pass(548,context,front): _draw_seat_status(canvas)
	canvas.draw_set_transform(Vector2.ZERO)
	var bag: Dictionary=backpack_pose()
	if bag.visible and _in_pass(float(bag.depth),context,front): _draw_backpack(canvas,context,bag)
	var note: Dictionary=seat.note_pose()
	if _in_pass(602,context,front) and note.visible:
		if note.alpha>0.05: Picker.record(canvas,["occupancy_note"] if not seat.note_collected else [],SeatMotion.paper_geometry(note))
		_draw_seat_paper(canvas,context,note,"纸条",Color("e9dcae"))
	if _in_pass(625,context,front): _draw_receipt(canvas,context)
	_draw_front_desk(canvas,context,front)
	if front and bag_animating and bag_ms<620:
		var ratio: float=_stepped(bag_ms/620); var at: Vector2=(pass_from+Vector2(0,-18)).lerp(Vector2(1255,373),ratio)
		canvas.draw_set_transform(Vector2(context.get("origin",Vector2.ZERO))+at*float(context.get("zoom",1)),TAU*ratio,Vector2.ONE*float(context.get("zoom",1)))
		canvas.draw_rect(Rect2(-30,-16,60,32),Color("2f8a59")); canvas.draw_string(font,Vector2(-22,6),"PASS",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f6f1dc")); canvas.draw_set_transform(Vector2.ZERO)
func _draw_shelf(canvas: CanvasItem,state: Dictionary) -> void:
	if rebuild.ready:
		var area: Rect2=rebuild.bounds("north_display_shelf")
		area.position.x+=shelf_offset
		_draw_generated_object(canvas,"north_display_shelf",area)
	else:
		_draw_original_shelf(canvas)
	var known: bool=state.get("ui",{}).get("libraryFinalsPuzzle",{}).get("callNumberCollected",false) or shelf_collected
	var center:=Vector2(563.5+shelf_offset,248)
	canvas.draw_rect(Rect2(center-Vector2(28,9),Vector2(56,18)),Color("e8d9b8"))
	canvas.draw_string(font,center+Vector2(-23,4),"I247.55" if known else "I247.??",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("18231f"))

func _draw_original_shelf(canvas: CanvasItem) -> void:
	var vertices:=PackedVector2Array(); var uv:=PackedVector2Array()
	for point: Array in source.shelf.outline:
		vertices.append(Vector2(float(point[0])+shelf_offset,float(point[1])))
		uv.append(Vector2(float(point[0])/art.get_width(),float(point[1])/art.get_height()))
	Picker.record(canvas,["library_shelf_755"],{"polygon":vertices})
	canvas.draw_polygon(vertices,PackedColorArray([Color.WHITE]),uv,art)

func _draw_generated_object(canvas: CanvasItem,id: String,area: Rect2) -> void:
	for geometry: Dictionary in rebuild.pieces(id,area):
		Picker.record(canvas,rebuild.layout.objects[id].targets,geometry)
		canvas.draw_texture_rect_region(geometry.texture,geometry.rect,geometry.source)

func _draw_static_foreground(canvas: CanvasItem,context: Dictionary,front: bool) -> void:
	# Same-source shelf faces now occlude an actor walking behind them.
	# Their original collision rectangles remain the sole solid geometry.
	if not front: return
	for row: Dictionary in rebuild.layout.staticForeground:
		if PlayerMetrics.foot_rect(Vector2(context.get("player",Vector2.ZERO))).position.y>=float(row.baselineY): continue
		var r: Array=row.rect
		var area:=Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3]))
		canvas.draw_texture_rect_region(rebuild.clean_plate,area,area)
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
	if rebuild.ready:
		var texture: Texture2D=rebuild.textures.backpack
		var scale_value: float=float(rebuild.layout.objects.backpack.scale)
		var area:=Rect2(-texture.get_size()*scale_value/2,texture.get_size()*scale_value)
		var geometry: Dictionary=rebuild.geometry("backpack",area)
		var transform:=Transform2D(deg_to_rad(float(pose.angle)),Vector2(pose.position))
		geometry.transform=transform
		if not bag_evicted: Picker.record(canvas,rebuild.layout.objects.backpack.targets,geometry)
		canvas.draw_set_transform(origin+Vector2(pose.position)*z,deg_to_rad(float(pose.angle)),Vector2.ONE*z)
		canvas.draw_texture_rect_region(texture,geometry.rect,geometry.source,Color(1,1,1,float(pose.alpha)))
		canvas.draw_set_transform(Vector2.ZERO)
		return
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

func _draw_seat_paper(canvas: CanvasItem,context: Dictionary,pose: Dictionary,label: String,color: Color) -> void:
	var z: float=context.get("zoom",1.0)
	var origin: Vector2=context.get("origin",Vector2.ZERO)
	canvas.draw_set_transform(origin+Vector2(pose.position)*z,deg_to_rad(float(pose.angle)),Vector2.ONE*z)
	var outline: PackedVector2Array=SeatMotion.paper_outline(pose)
	var shadow:=PackedVector2Array()
	for point: Vector2 in outline: shadow.append(point+Vector2(1,2))
	canvas.draw_colored_polygon(shadow,Color("493c28",0.32*float(pose.alpha)))
	color.a=float(pose.alpha); canvas.draw_colored_polygon(outline,color)
	var edge:=outline.duplicate(); edge.append(edge[0])
	canvas.draw_polyline(edge,Color("70654e",float(pose.alpha)),1)
	if pose.width>=28:
		var right: float=float(pose.width)/2; var top: float=-float(pose.height)/2
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(right-7,top),Vector2(right,top+7),Vector2(right-7,top+7)]),Color("c5b48b",float(pose.alpha)))
		canvas.draw_line(Vector2(0,top-float(pose.bend)),Vector2(0,-top-float(pose.bend)),Color("b2a382",0.35*float(pose.alpha)),1)
		canvas.draw_string(font,Vector2(-10,5-float(pose.bend)/2),label,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("40372c",float(pose.alpha)))
	canvas.draw_set_transform(Vector2.ZERO)

func _draw_receipt(canvas: CanvasItem,context: Dictionary) -> void:
	_context(canvas,context)
	# The table's physical seam remains after acquisition; no hover decoration.
	canvas.draw_line(SeatMotion.GAP_AT+Vector2(-13,3),SeatMotion.GAP_AT+Vector2(13,3),Color("514332"),2)
	canvas.draw_set_transform(Vector2.ZERO)
	var pose: Dictionary=seat.receipt_pose()
	if not pose.visible: return
	if pose.arrowAlpha>0:
		_context(canvas,context)
		var at: Vector2=pose.arrowPosition
		var arrow:=PackedVector2Array()
		for point: Vector2 in [Vector2(-16,-3),Vector2(3,-3),Vector2(3,-7),Vector2(13,0),Vector2(3,7),Vector2(3,3),Vector2(-16,3)]: arrow.append(at+point)
		canvas.draw_colored_polygon(arrow,Color("e3bd65",float(pose.arrowAlpha)))
		arrow.append(arrow[0]); canvas.draw_polyline(arrow,Color("4b3d27",float(pose.arrowAlpha)),1)
		canvas.draw_set_transform(Vector2.ZERO)
	_draw_seat_paper(canvas,context,pose,"022",Color("f1ead8"))

func staff_pose() -> Dictionary:
	var frame: int=0; var y: float=632
	if lost_stage=="scanning" or stamp_ms>=0: frame=1
	elif not reduced:
		var idle_ms: float=fposmod(clock_ms,6000.0/1.8+900)
		frame=int(source.frontDesk.idleFrames[mini(5,int(idle_ms/(1000.0/1.8)))])
	if not reduced:
		if scanning_ms>=0 and scanning_ms<480:
			var step: float=fposmod(scanning_ms,240)/120; y+=3*StampMotion.smooth(step if step<=1 else 2-step)
		if stamp_ms>=0:
			# The whole authored frame leans once with load; no sprite stretching.
			y+=1.2*float(stamp_pose().pressure)
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
	var pose: Dictionary=stamp_pose()
	# Quiet physical guides use the existing desk's brass / timber palette.
	canvas.draw_line(at+Vector2(-101,8),at+Vector2(3,8),Color("a38e60"),1)
	canvas.draw_line(at+Vector2(-101,40),at+Vector2(3,40),Color("6c593b"),2)
	canvas.draw_line(at+Vector2(-101,41),at+Vector2(3,41),Color("ba9d63"),1)
	if pose.visible:
		_draw_service_paper(canvas,at,pose)
		if not reduced and lost_stage=="scanning" and scanning_ms>=StampMotion.RECEIVE_MS and scanning_ms<1240:
			var scan: float=StampMotion.smooth(fposmod(scanning_ms-StampMotion.RECEIVE_MS,500)/500)
			canvas.draw_line(at+Vector2(pose.paper.x-20,12+scan*24),at+Vector2(pose.paper.x+20,12+scan*24),Color("e1b953",0.55),1)
	# Foot shadow tightens toward contact. Draw the original uniformly scaled
	# stamp AFTER the paper, so the foot visibly presses and occludes its mark.
	var gap: float=maxf(0,float(pose.contact.y)-float(pose.stampBottom.y))
	var shadow: float=(1-clampf(gap/24.0,0,1))*0.35
	canvas.draw_line(at+Vector2(-44,27),at+Vector2(-26,27),Color(0.17,0.11,0.06,shadow),2)
	canvas.draw_texture_rect(stamp_art,Rect2(at+pose.stampRect.position,pose.stampRect.size),false)

func stamp_pose() -> Dictionary:
	return StampMotion.sample(stamp_ms,scanning_ms if lost_stage=="scanning" else -1,reduced)

func _draw_service_paper(canvas: CanvasItem,at: Vector2,pose: Dictionary) -> void:
	var alpha: float=pose.alpha
	var corners:=PackedVector2Array()
	for local: Vector2 in [Vector2(-23,-14),Vector2(0,-14),Vector2(23,-14),Vector2(23,14),Vector2(0,14),Vector2(-23,14)]:
		corners.append(at+StampMotion.paper_point(local,pose))
	var shadow:=PackedVector2Array()
	for point: Vector2 in corners: shadow.append(point+Vector2(0,1.2))
	canvas.draw_colored_polygon(shadow,Color("493c28",0.3*alpha))
	canvas.draw_colored_polygon(corners,Color("f2ead5",alpha))
	var outline:=corners.duplicate(); outline.append(outline[0])
	canvas.draw_polyline(outline,Color("6b685b",alpha),1)
	# Fine ruled strokes follow the same local paper deformation as its edge.
	for row: int in range(2):
		var points:=PackedVector2Array()
		for col: int in range(7): points.append(at+StampMotion.paper_point(Vector2(-17+col*4,-8+row*5),pose))
		canvas.draw_polyline(points,Color("87928c",(0.8-row*0.15)*alpha),1)
	if pose.ink>0:
		var mark: Vector2=at+Vector2(pose.mark)+Vector2(0,pose.pressure*0.8)
		var ink:=Color("ae4037",alpha*pose.ink)
		canvas.draw_rect(Rect2(mark-Vector2(10,5),Vector2(20,10)),ink,false,0.8)
		canvas.draw_string(font,mark+Vector2(-9,2.8),"非本人",HORIZONTAL_ALIGNMENT_LEFT,-1,6,ink)
