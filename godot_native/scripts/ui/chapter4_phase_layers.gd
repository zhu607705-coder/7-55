extends RefCounted
const Picker=preload("res://scripts/world_object_picker.gd")
## Source ChapterFourTemporalMazeScene phase props and ChapterFourClockMotion.
## All clocks here are local presentation time; no story state is written.
const Room=preload("res://scripts/games/chapter4_room204_model.gd")
const CoverMotion=preload("res://scripts/presentation/maintenance_cover_motion.gd")
var cover_motion:RefCounted=CoverMotion.new()
var source: Dictionary={}
var npcs: Dictionary={}
var alumni: Array=[]
var elapsed_ms: float=0
var phase_key: String=""
var state_owner: Dictionary={}
var repaired: bool=false
var repair_ms: float=900
var cover_open: bool=false
var oil_ms: float=9999
var clock_key: String=""
var clock_ms: float=0
func _init() -> void:
	source=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-three-floor-maze.layout.json"))
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/rpg/npcs/finale/finale_npc_manifest.json"))
	for entry in manifest.animations: npcs[entry.id]=entry
	alumni=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter4-native-source.json")).alumni
	npcs["chapter-four-front-desk-staff-idle"]={"file":"res://assets/rpg/npcs/library/front_desk_staff_2frame.png","frameWidth":96,"frameHeight":128,"frameCount":2,"fps":2,"loop":true}
func tick(delta: float,state: Dictionary) -> void:
	cover_motion.tick(delta,state)
	var c: Dictionary=state.get("chapter4",{}); var facts: Array=c.get("factIds",[])
	var key: String=str(c.get("floor",""))+":"+str(c.get("phase",""))+":"+str(c.get("timeState",""))
	var is_repaired: bool="cart_wheel_repaired" in facts; var is_open: bool="cart_wheel_cover_opened" in facts
	if not is_same(state,state_owner) or key!=phase_key:
		# An ordinary load replaces the owner even in the same phase. Restored
		# completed props are terminal, not a continuation of retired timing.
		state_owner=state
		phase_key=key; elapsed_ms=0; repair_ms=float(source.maintenanceRuntime.repairedPush.durationMs); oil_ms=9999; repaired=is_repaired; cover_open=is_open
	if is_repaired and not repaired: repair_ms=0
	if is_open and not cover_open: oil_ms=0
	repaired=is_repaired; cover_open=is_open
	var step: float=minf(delta,0.05)*1000
	elapsed_ms+=step; repair_ms+=step; oil_ms+=step
	var next_clock: String=clock_frame(state)+":"+str(c.get("worldTimeSeconds",0))+":"+str("hour_hand_installed" in facts)+":"+str(manual_minute(state))
	if next_clock!=clock_key: clock_ms=0; clock_key=next_clock
	clock_ms+=step
func maintenance_active(state: Dictionary) -> bool:
	var c: Dictionary=state.get("chapter4",{})
	return c.get("floor","")=="A1" and c.get("phase","")=="maintenance_repair" and c.get("timeState","")=="2245_maintenance"
func maintenance_sample(state: Dictionary) -> Dictionary:
	var m: Dictionary=source.maintenanceRuntime; var is_repaired: bool="cart_wheel_repaired" in state.get("chapter4",{}).get("factIds",[])
	var offset: Vector2=Vector2.ZERO; var alpha: float=0
	if is_repaired:
		var t: float=_sine(repair_ms/float(m.repairedPush.durationMs)); offset=(Room.point(m.repairedPush.to)-Room.point(m.repairedPush.from))*t
		alpha=minf(clampf(t/0.12,0,1),clampf((1-t)/0.15,0,1))
	else:
		var t: float=elapsed_ms-1100
		if t>=0:
			t=fmod(t,3360)
			var effort: float=_sine(t/240) if t<240 else (1.0 if t<320 else (1-_sine((t-320)/240) if t<560 else 0.0))
			offset=Vector2(-5*effort,0); alpha=clampf(effort*4,0,1)
	return {"offset":offset,"pushAlpha":alpha,"cart":Room.point(m.cleaningCart.position)+offset,"cleaner":Room.point(m.cleaner.position)+offset,"push":Room.point(m.repairedPush.from)+offset,"colliding":not is_repaired}
func collisions(state: Dictionary) -> Array:
	var out: Array=[]
	if maintenance_active(state):
		var sample: Dictionary=maintenance_sample(state)
		if sample.colliding:
			for obj in [source.maintenanceRuntime.cleaningCart,source.maintenanceRuntime.cleaner]:
				var bounds: Rect2=Room.rect(obj.footBounds); bounds.position+=Vector2(sample.offset); out.append(bounds)
	if recovery_active(state): out.append(Room.rect(source.finalChaseRuntime.room202Door.barrierBounds))
	return out
func recovery_active(state: Dictionary) -> bool:
	var c: Dictionary=state.get("chapter4",{})
	return c.get("floor","")=="A2" and c.get("phase","")=="final_minute_recovery"
func clock_frame(state: Dictionary) -> String:
	var c: Dictionary=state.get("chapter4",{}); var facts: Array=c.get("factIds",[])
	if c.get("timeState","")=="0755_morning": return "0755_complete"
	if c.get("timeState","")=="0754_blackout": return "0754_calibrated"
	if c.get("phase","")=="maintenance_repair" and c.get("timeState","")=="2245_maintenance": return "gear_running" if "clock_gear_repaired" in facts else "gear_stuttering"
	if "hour_hand_installed" in facts: return "1850_hour_hand_restored" if c.get("timeState","")=="1850_evening" else "2245_complete"
	return "1225_missing_hour_hand" if c.get("timeState","")=="1225_bakery" else "2245_missing_hour_hand"
func manual_minute(state: Dictionary) -> bool:
	var c: Dictionary=state.get("chapter4",{}); var facts: Array=c.get("factIds",[])
	return (c.get("phase","")=="maintenance_repair" and c.get("timeState","")=="2245_maintenance" and "clock_gear_repaired" in facts) or (c.get("phase","")=="return_to_clock" and state.get("items",{}).get("finalMinute",false))
func draw_back(owner: RefCounted,canvas: CanvasItem,context: Dictionary,state: Dictionary) -> void:
	var c: Dictionary=state.chapter4
	if c.floor=="A1":
		_draw_clock(owner,canvas,context,state)
		if c.phase in ["blackout_light_grid","final_chase"]:
			owner._world(canvas,context)
			for i in range(source.lightGridRuntime.visualRegions.size()):
				var region: Dictionary=source.lightGridRuntime.visualRegions[i]; var lit: bool=(int(c.lightGrid.mask)&(1<<i))!=0
				canvas.draw_rect(Room.rect(region.bounds),Color("020711",0.08 if lit else 0.7))
			canvas.draw_set_transform(Vector2.ZERO)
	_draw_objects(owner,canvas,context,state,false)
func draw_front(owner: RefCounted,canvas: CanvasItem,context: Dictionary,state: Dictionary) -> void:
	_draw_objects(owner,canvas,context,state,true)
func _depth(context: Dictionary,y: float,front: bool) -> bool: return (y>Vector2(context.get("player",Vector2.ZERO)).y)==front
func _draw_objects(owner: RefCounted,canvas: CanvasItem,context: Dictionary,state: Dictionary,front: bool) -> void:
	var c: Dictionary=state.chapter4
	_draw_people(owner,canvas,context,state,front)
	if maintenance_active(state): _draw_maintenance(owner,canvas,context,state,front)
	if c.floor=="A1" and c.phase in ["blackout_light_grid","final_chase"] and _depth(context,float(source.lightGridRuntime.panel.visibleBoxBounds.y)+4,front):
		var frame: String="closed"
		if not c.lightGrid.locked and state.get("native",{}).get("page","")=="c4_device" and state.native.get("c4_context","")=="power": frame="open_powered" if int(c.lightGrid.mask)==6 else "open_partial"
		var bounds: Rect2=Room.rect(source.lightGridRuntime.panel.visibleBoxBounds)
		# Source explicitly sets the power panel origin to (1,0), overriding its atlas pivot.
		_draw_origin_frame(owner,canvas,context,"chapter4_power_panel_states",frame,Vector2(bounds.end.x,bounds.position.y),Vector2(1,0),0.11)
	if c.floor=="A1" and c.phase=="morning_checkin":
		for target in source.morningCheckinRuntime.targetEntities:
			var bounds: Rect2=Room.rect(target.installationBounds)
			if _depth(context,bounds.end.y+6,front):
				owner._world(canvas,context)
				var accepted: bool=bool(c.checkinCardAccepted) if target.targetId=="a1_campus_card_reader" else bool(c.checkinPaperAccepted)
				Picker.record(canvas,[str(target.targetId)],bounds)
				_draw_checkin(canvas,bounds,target.targetId=="a1_campus_card_reader",accepted)
				owner._text(canvas,Vector2(bounds.get_center().x,bounds.position.y-8),"校园卡" if target.targetId=="a1_campus_card_reader" else "纸条",8,Color("f7f1dc")); canvas.draw_set_transform(Vector2.ZERO)
		for student in [{"p":Vector2(582,700),"id":"student_phone_glance","flip":false},{"p":Vector2(1078,704),"id":"student_adjust_bag","flip":true},{"p":Vector2(1110,570),"id":"student_idle","flip":true}]:
			if _depth(context,student.p.y,front): _npc(owner,canvas,context,student.id,student.p,0.65,elapsed_ms,student.flip)
	if recovery_active(state):
		var barrier: Rect2=Room.rect(source.finalChaseRuntime.room202Door.barrierBounds)
		if _depth(context,barrier.end.y+3,front):
			owner._world(canvas,context); canvas.draw_rect(barrier,Color("17202b",0.94)); canvas.draw_rect(barrier,Color("82a9bd",0.9),false,2)
			owner._text(canvas,Vector2(barrier.get_center().x,barrier.position.y-8),"门禁已落锁",12,Color("d9edf2")); canvas.draw_set_transform(Vector2.ZERO)
		var minute: Dictionary=source.finalMinuteRuntime
		if not state.items.finalMinute and "final_minute_recovered" not in c.factIds and _depth(context,float(minute.pivot.y)+6,front): owner.draw_frame(canvas,context,minute.texture,minute.frame,Room.point(minute.pivot),0,float(minute.uniformScale))
func _draw_maintenance(owner: RefCounted,canvas: CanvasItem,context: Dictionary,state: Dictionary,front: bool) -> void:
	var m: Dictionary=source.maintenanceRuntime; var sample: Dictionary=maintenance_sample(state); var facts: Array=state.chapter4.factIds
	if _depth(context,sample.cart.y,front): _npc(owner,canvas,context,m.cleaningCart.texture,sample.cart,float(m.cleaningCart.uniformScale),elapsed_ms)
	if _depth(context,sample.cleaner.y+1,front): _npc(owner,canvas,context,m.cleaner.animationId,sample.cleaner,float(m.cleaner.uniformScale),elapsed_ms,false,1-float(sample.pushAlpha))
	if _depth(context,sample.push.y+2,front) and float(sample.pushAlpha)>0:
		_npc(owner,canvas,context,m.repairedPush.animationId,sample.push,float(m.cleaner.uniformScale),elapsed_ms,bool(m.repairedPush.flipX),float(sample.pushAlpha),Room.rect(m.repairedPush.visibleCharacterCrop))
	var wheel: Rect2=Room.rect(m.targetEntities[0].installationBounds)
	if "cart_wheel_repaired" not in facts and _depth(context,wheel.end.y+6,front):
		_draw_wheel_cover(owner,canvas,context,state,sample)
	if oil_ms<1100 and "cart_wheel_cover_opened" in facts:
		var t: float=_sine(oil_ms/320) if oil_ms<320 else (1.0 if oil_ms<780 else 1-_sine((oil_ms-780)/320))
		for target in m.targetEntities:
			if target.targetId=="a1_cleaning_cart_oil_bottle" and _depth(context,float(target.pivot.y)+18,front): owner.draw_frame(canvas,context,"chapter4_story_items",target.frame,Room.point(target.pivot)+Vector2(0,-14*t),0,float(target.uniformScale),Color(1,1,1,t))
func cover_geometry(state:Dictionary,now_ms:=-1)->Dictionary:
	var cart:Dictionary=source.maintenanceRuntime.cleaningCart
	var frame:Dictionary=cart.wheelRegion.sourceFrameSize
	var region:Rect2=Room.rect(cart.wheelRegion.bounds)
	var scale_value:float=cart.uniformScale
	var pose:Dictionary=cover_motion.sample(state,now_ms)
	pose["pivot"]=maintenance_sample(state).cart+(Vector2(region.position.x,region.get_center().y)-Vector2(float(frame.width)*.5,float(frame.height)))*scale_value
	pose["source_region"]=Rect2(region.position.x,region.position.y+9,region.size.x,16)
	pose["local_rect"]=Rect2(Vector2(-region.size.x*.08,-8),Vector2(region.size.x,16))
	pose["scale"]=scale_value
	return pose
func _draw_wheel_cover(owner:RefCounted,canvas:CanvasItem,context:Dictionary,state:Dictionary,_cart_sample:Dictionary)->void:
	var pose:=cover_geometry(state)
	var art:Texture2D=owner.texture(str(npcs.cleaning_cart.file).replace("src/assets/","res://assets/"))
	if art==null:return
	var zoom:float=context.zoom
	canvas.draw_set_transform(Vector2(context.origin)+Vector2(pose.pivot)*zoom,deg_to_rad(float(pose.angle_degrees)),Vector2.ONE*float(pose.scale)*zoom)
	# Retain the original cart's painted frame/wheel material, rather than a
	# translucent placeholder rectangle. Source pixels keep uniform scale.
	canvas.draw_texture_rect_region(art,pose.local_rect,pose.source_region)
	canvas.draw_rect(pose.local_rect,Color("34352f"),false,.9)
	canvas.draw_circle(Vector2.ZERO,1.3,Color("a0a398"))
	canvas.draw_set_transform(Vector2.ZERO)
func _npc(owner: RefCounted,canvas: CanvasItem,context: Dictionary,id: String,p: Vector2,scale_value: float,time_ms: float,flip: bool=false,alpha: float=1,crop: Rect2=Rect2()) -> void:
	if alpha<=0: return
	var def: Dictionary=npcs[id]; var art: Texture2D=owner.texture(str(def.file).replace("src/assets/","res://assets/"))
	if not art: return
	var frame: int=int(time_ms*float(def.fps)/1000)
	frame=frame%int(def.frameCount) if def.loop else mini(frame,int(def.frameCount)-1)
	var full: Vector2=Vector2(def.frameWidth,def.frameHeight); var columns: int=maxi(1,int(art.get_width()/full.x)); var region: Rect2=crop if crop.has_area() else Rect2(Vector2.ZERO,full)
	var target: Rect2=Rect2(region.position-full*Vector2(0.5,1),region.size)
	region.position+=Vector2((frame%columns)*full.x,int(frame/columns)*full.y)
	canvas.draw_set_transform(Vector2(context.origin)+p*float(context.zoom),0,Vector2(-1 if flip else 1,1)*scale_value*float(context.zoom))
	canvas.draw_texture_rect_region(art,target,region,Color(1,1,1,alpha)); canvas.draw_set_transform(Vector2.ZERO)
func _draw_origin_frame(owner: RefCounted,canvas: CanvasItem,context: Dictionary,sheet: String,id: String,p: Vector2,origin: Vector2,scale_value: float) -> void:
	var data: Dictionary=Room.data().sheets[sheet]; var frame: Dictionary=data.frames[id]; var art: Texture2D=owner.texture(data.path)
	if not art: return
	var cell: Rect2=Room.rect(frame.sourceRect); var trim: Rect2=Room.rect(frame.sourceTrim)
	canvas.draw_set_transform(Vector2(context.origin)+p*float(context.zoom),0,Vector2.ONE*scale_value*float(context.zoom))
	canvas.draw_texture_rect_region(art,Rect2(trim.position-cell.position-cell.size*origin,trim.size),trim); canvas.draw_set_transform(Vector2.ZERO)
func _draw_clock(owner: RefCounted,canvas: CanvasItem,context: Dictionary,state: Dictionary) -> void:
	var c: Dictionary=state.chapter4; var registration: Dictionary=source.finalClockRuntime.visualRegistration; var p: Vector2=Room.point(registration.axis); var radius: float=registration.statePlateFaceRadius
	var frame: String=clock_frame(state)
	if owner.presentation.get("kind","")=="hall_clock_inspection":
		var stamp: float=owner.presentation.get("elapsedMs",0); frame="gear_stuttering" if stamp>=1700 and stamp<3200 else "2245_missing_hour_hand"
	owner.draw_frame(canvas,context,"chapter4_clock_states",frame,p,0,float(registration.uniformScale))
	owner.draw_frame(canvas,context,"chapter4_clock_states","blank_face",p,0,float(registration.uniformScale))
	owner._world(canvas,context)
	var running: bool="clock_gear_repaired" in c.factIds; var manual: bool=manual_minute(state); var elapsed: float=clock_ms/1000
	var time: float=float(c.worldTimeSeconds)+(elapsed if running and not manual else 0.0)
	var recoil: float=0.0 if running else sin(minf(1,fmod(elapsed,1.4)/0.46)*PI)*0.07
	var gearing: float=elapsed*0.8 if running and not manual else recoil*3
	canvas.draw_rect(Rect2(p+Vector2(-13,radius*0.4-8),Vector2(26,14)),Color("463d2d",0.13))
	for gear in [{"p":p+Vector2(-6,radius*0.4-1),"r":5.0,"a":gearing},{"p":p+Vector2(5,radius*0.4-1),"r":6.0,"a":-gearing*5/6}]:
		canvas.draw_arc(gear.p,gear.r*0.72,0,TAU,32,Color("997038",0.9),1.1)
		for i in range(10):
			var unit: Vector2=Vector2.from_angle(float(gear.a)+i*PI/5); canvas.draw_line(gear.p+unit*gear.r*0.62,gear.p+unit*gear.r,Color("997038",0.9),1.1)
		canvas.draw_circle(gear.p,1,Color("654b2c"))
	if "hour_hand_installed" in c.factIds: _hand(canvas,p,fmod(time,43200)/43200*TAU,radius*0.49,3.2,Color("26312c"))
	if not manual: _hand(canvas,p,fmod(time,3600)/3600*TAU+recoil,radius*0.77,2.2,Color("38423a"))
	else:
		var angle_value: float=float(owner.presentation.get("angle",source.finalClockRuntime.initialAngleDegrees)) if owner.presentation.get("kind","")=="clock_drag" else float(source.finalClockRuntime.initialAngleDegrees)
		var end: Vector2=p+Vector2.from_angle(deg_to_rad(angle_value))*float(source.finalClockRuntime.minuteHandRadius); end=end.round()
		canvas.draw_line(p,end,Color("d8edf0",0.96),3); canvas.draw_circle(end,8,Color("f2d47b",0.92)); canvas.draw_arc(end,8,0,TAU,32,Color("f7f1dc",0.98),2)
	if running and not manual:
		var unit: Vector2=Vector2.from_angle(fmod(floor(time),60)/60*TAU-PI/2); canvas.draw_line(p-unit*radius*0.18,p+unit*radius*0.83,Color("aa4932"),1)
	for target: Dictionary in (canvas.get("targets") if canvas.has_method("_pick_target") else []):
		if str(target.get("id","")).begins_with("a1_hall_clock"):
			var b: Array=target.bounds
			Picker.record(canvas,[str(target.id)],Rect2(b[0],b[1],b[2],b[3]))
	canvas.draw_circle(p,3,Color("785128")); canvas.draw_circle(p-Vector2(0.5,0.5),1.7,Color("e0b569")); canvas.draw_set_transform(Vector2.ZERO)
func _hand(canvas: CanvasItem,p: Vector2,angle: float,length: float,width: float,color: Color) -> void:
	var end: Vector2=p+Vector2(sin(angle),-cos(angle))*length
	canvas.draw_line(p+Vector2.ONE,end+Vector2.ONE,Color("191e19",0.3),width+1); canvas.draw_line(p,end,color,width)
func _sine(t: float) -> float: return (1-cos(clampf(t,0,1)*PI))/2
func _draw_checkin(canvas: CanvasItem,bounds: Rect2,card: bool,accepted: bool) -> void:
	var x: float=bounds.position.x; var y: float=bounds.position.y; var w: float=bounds.size.x; var h: float=bounds.size.y; var status: Color=Color("7ee79a") if accepted else Color("75e6ff")
	if card:
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(x+3,y),Vector2(x+w-3,y),Vector2(x+w,y+4),Vector2(x+w-2,y+h),Vector2(x+2,y+h),Vector2(x,y+4)]),Color("07131c",0.98))
		canvas.draw_rect(Rect2(x+2,y+3,w-4,h-5),Color("9eafaa",0.96),false,1)
		for row in [[6,5,w-12,8,Color("badfdc")],[7,6,w-14,2,Color("1a6271",0.85)],[7,9,w-14,1,Color(status,0.95)],[7,h-7,w-14,2,Color("0b0908")],[w-7,h-5,3,2,status],[5,h-5,2,2,Color("9aa9a9",0.9)],[9,h-4,6,1,Color("e8f2e9")]]: canvas.draw_rect(Rect2(x+row[0],y+row[1],row[2],row[3]),row[4])
	else:
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(x+3,y+3),Vector2(x+w-3,y+3),Vector2(x+w,y+7),Vector2(x+w-2,y+h),Vector2(x+2,y+h),Vector2(x,y+7)]),Color("261c13",0.99))
		canvas.draw_rect(Rect2(x+2,y+6,w-4,h-8),Color("94d7a1",0.98) if accepted else Color("c89a55",0.98),false,1)
		for row in [[8,0,w-16,9,Color("f0e4c8")],[10,2,w-20,1,Color("c1b090")],[10,5,w-23,1,Color("c1b090")],[5,11,w-10,4,Color("080707")],[7,12,w-14,1,Color("705032")],[w-8,h-6,3,3,status],[6,h-5,w-18,2,Color("c8b27a",0.92)],[3,7,1,1,Color("e0c68c")],[w-4,7,1,1,Color("e0c68c")]]: canvas.draw_rect(Rect2(x+row[0],y+row[1],row[2],row[3]),row[4])

func honor_figures(state: Dictionary) -> Array:
	return alumni.filter(func(person): return str(state.get("chapter4",{}).get("floor",""))=="A"+str(int(person.floor)))
func support_people(state: Dictionary) -> Array:
	var c: Dictionary=state.get("chapter4",{}); var out: Array=[]
	for entry in [source.frontDeskRuntime]+source.supportNpcRuntimes:
		if c.get("floor","")==entry.storyFloor and c.get("phase","") in entry.activePhases: out.append(entry)
	return out
func _draw_people(owner: RefCounted,canvas: CanvasItem,context: Dictionary,state: Dictionary,front: bool) -> void:
	for person in honor_figures(state):
		if not _depth(context,162 if int(person.floor)==1 else 842,front): continue
		var frame: Rect2=Room.rect(person.frameBounds); var image_bounds: Rect2=Room.rect(person.imageBounds)
		Picker.record(canvas,[str(person.targetId)],frame)
		owner._world(canvas,context)
		if person.get("drawRuntimeFrame",false): canvas.draw_rect(frame,Color("281f18")); canvas.draw_rect(frame,Color("b8964d"),false,3)
		canvas.draw_rect(image_bounds,Color("17191d")); canvas.draw_set_transform(Vector2.ZERO)
		var portrait: Texture2D=owner.texture(person.portraitUrl)
		if portrait:
			# Keep the original image undistorted within the source matte bounds.
			var dimensions: Vector2=portrait.get_size(); dimensions*=minf(image_bounds.size.x/dimensions.x,image_bounds.size.y/dimensions.y)
			canvas.draw_texture_rect(portrait,Rect2(Vector2(context.origin)+(image_bounds.get_center()-dimensions/2)*float(context.zoom),dimensions*float(context.zoom)),false)
	for person in support_people(state):
		var p: Vector2=Room.point(person.position)
		if _depth(context,p.y,front):
			var def: Dictionary=npcs[person.animation]; var full:=Vector2(def.frameWidth,def.frameHeight); var dimensions:=full*float(person.uniformScale)
			var tex: Texture2D=owner.texture(str(def.file).replace("src/assets/","res://assets/"))
			if tex!=null:
				var index: int=int(elapsed_ms*float(def.fps)/1000)%int(def.frameCount)
				var columns: int=maxi(1,int(tex.get_width()/full.x))
				Picker.record(canvas,[str(person.interactionAnchorId)],{"rect":Rect2(p-dimensions*Vector2(.5,1),dimensions),"texture":tex,"source":Rect2(Vector2((index%columns)*full.x,int(index/columns)*full.y),full)})
			_npc(owner,canvas,context,person.animation,p,float(person.uniformScale),elapsed_ms)
