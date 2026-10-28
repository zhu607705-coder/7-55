extends SceneTree
const Layers=preload("res://scripts/ui/chapter4_world_layers.gd")
const Phase=preload("res://scripts/ui/chapter4_phase_layers.gd")
const Chapter=preload("res://scripts/chapters/chapter4.gd")
const Room=preload("res://scripts/games/chapter4_room204_model.gd")
var checks: int=0
var failures: int=0
class Surface extends Control:
	var layers: RefCounted
	var state: Dictionary
	var background:Texture2D
	func _draw() -> void:
		var mix_value:float=1.0 if state.chapter4.mode=="dark" else 0.0
		var context: Dictionary={"origin":Vector2.ZERO,"zoom":0.55,"player":Vector2(1000,716),"scene_id":"duan_yongping_temporal_maze","floor":state.chapter4.floor,"background":background,"mode_mix":mix_value}
		if background:draw_texture_rect(background,Rect2(Vector2.ZERO,Vector2(1672,941)*.55),false)
		draw_rect(Rect2(Vector2.ZERO,size),Color(.03,.15,.26,mix_value*.3))
		layers.draw_back(self,context,state); layers.draw_front(self,context,state)
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func fresh() -> Dictionary:
	var s: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":4,"scene":"duan_yongping_temporal_maze","page":"c4_device","mode":"light","player":{"x":1001,"y":214},"settings":{},"c4_context":"power"}
	s.chapter4.prologueSeen=true; s.chapter4.phase="maintenance_repair"; s.chapter4.timeState="2245_maintenance"; s.chapter4.worldTimeSeconds=81900; s.chapter4.guardMode="patrol"; s.chapter4.floor="A1"; s.chapter4.mode="light"; s.chapter4.factIds=["hour_hand_installed","maintenance_incident_linked"]
	return s
func plate_for(state:Dictionary)->Texture2D:
	var c:Dictionary=state.chapter4;var name:String=str(c.floor).to_lower()+"_"+str(c.timeState)
	if c.floor=="A3" and c.timeState=="1850_evening":name="a3_1850_reference"
	if c.floor=="A2" and c.timeState=="0754_blackout":name="a2_0754_chase"
	var path:String="res://assets/rpg/interiors/finale/chapter4-755/states/"+name+".png"
	if not ResourceLoader.exists(path):path="res://assets/rpg/interiors/finale/chapter4-755/base/"+str(c.floor).to_lower()+".png"
	return load(path)
func image_of(texture:Texture2D)->Image:
	var image:Image=texture.get_image()
	if image.is_compressed():image.decompress()
	return image
func luminance(color:Color)->float:return color.r*.2126+color.g*.7152+color.b*.0722
func wall_brightness(image:Image,frame:Rect2)->float:
	var total:float=0;var count:int=0
	for y in range(int(frame.position.y),int(frame.end.y),3):
		for x in [int(frame.position.x)-5,int(frame.end.x)+5]:total+=luminance(image.get_pixel(x,y));count+=1
	for x in range(int(frame.position.x),int(frame.end.x),3):
		for y in [int(frame.position.y)-5,int(frame.end.y)+5]:total+=luminance(image.get_pixel(x,y));count+=1
	return total/maxi(1,count)
func honor_lighting(holder:Surface,layers:RefCounted)->void:
	var phase:RefCounted=layers.phases;var chapter:RefCounted=Chapter.new()
	for floor_id:String in ["A1","A2","A3"]:
		for time_id:String in ["2245_opening","1850_evening","2245_maintenance","0754_blackout","1225_bakery","0755_morning"]:
			var previous_tints:Dictionary={}
			for mode:String in ["light","dark"]:
				var s:Dictionary=fresh();s.chapter4.floor=floor_id;s.chapter4.timeState=time_id;s.chapter4.mode=mode;s.native.mode=mode;s.chapter4.phase="blackout_light_grid" if floor_id=="A1" and time_id=="0754_blackout" else "room204_restore"
				var before:Dictionary=s.duplicate(true);var plate:Texture2D=plate_for(s);var image:Image=image_of(plate)
				var context:Dictionary={"background":plate,"mode_mix":1.0 if mode=="dark" else 0.0}
				var figures:Array=phase.honor_figures(s)
				check(figures.size()==(13 if floor_id=="A1" else 7 if floor_id=="A3" else 0),"Lighting preserves source portrait consumers "+floor_id+" "+time_id+" "+mode)
				for person:Dictionary in figures:
					var tint:Color=phase.portrait_tint(layers,context,s,person)
					if time_id in ["1225_bakery","0755_morning"]:check(tint==Color.WHITE,"Daylight portrait material stays unchanged "+str(person.id))
					else:
						var photo:Image=image_of(layers.texture(person.portraitUrl));var samples:Array[float]=[]
						for y in range(0,photo.get_height(),maxi(1,photo.get_height()/13)):
							for x in range(0,photo.get_width(),maxi(1,photo.get_width()/13)):
								var color:Color=photo.get_pixel(x,y)
								if color.a>=.5:samples.append(luminance(color*tint))
						samples.sort()
						check(not samples.is_empty() and samples[int((samples.size()-1)*.9)]<=wall_brightness(image,Room.rect(person.frameBounds))*1.25+.006,"Night face highlights stay within nearby wall illumination "+floor_id+" "+time_id+" "+mode+" "+str(person.id))
					if mode=="light":previous_tints[person.id]=tint
					else:check(previous_tints[person.id]==tint,"Reality mode cannot give a portrait an independent light "+str(person.id))
				# Exercise the real depth passes, including mode and blackout masks.
				holder.state=s;holder.background=plate;holder.queue_redraw();await process_frame;await process_frame
				check(s==before,"Portrait shading never changes story or collision state")
				if time_id=="1850_evening":
					var targets:Array=chapter.targets("duan_yongping_temporal_maze",s)
					for person:Dictionary in figures:
						check(targets.any(func(target):return target.action=="c4_bio_"+str(person.id) and not target.has("mode")),"Space biography retains its authored target in both modes "+str(person.id))
						var response:Dictionary=chapter.dispatch(s,"c4_bio_"+str(person.id))
						check(response.get("page","")=="c4_bio" and s.chapter4==before.chapter4,"Biography remains readable without changing progression")
func run() -> void:
	var s: Dictionary=fresh(); var original: Dictionary=s.duplicate(true); var layers: RefCounted=Layers.new(); var phase: RefCounted=layers.phases
	phase.tick(0,s)
	check(phase.collisions(s)==[Rect2(1089,700,51,16),Rect2(1150,708,20,16)],"Maintenance cart and cleaner use exact source foot rectangles")
	phase.elapsed_ms=1340
	check(phase.maintenance_sample(s).offset==Vector2(-5,0) and phase.maintenance_sample(s).pushAlpha==1.0,"Failed push reaches original five-pixel effort at 240ms")
	phase.elapsed_ms=1660
	check(phase.maintenance_sample(s).offset==Vector2.ZERO,"Failed push returns cart after source 560ms cycle")
	phase.tick(0,s); s.chapter4.factIds.append("cart_wheel_cover_opened"); phase.tick(0,s)
	check(phase.oil_ms==0,"Opening wheel cover launches source oil reveal once")
	s.chapter4.factIds.append("cart_wheel_repaired"); s.chapter4.factIds.append("clock_gear_repaired"); phase.tick(0,s)
	check(phase.collisions(s).is_empty(),"Repair disables cart and cleaner blocking bodies immediately")
	check(phase.maintenance_sample(s).cart==Vector2(1115,716),"Live repair begins at source cart position")
	for i in 9: phase.tick(0.05,s)
	check(phase.maintenance_sample(s).cart.is_equal_approx(Vector2(1082,716)),"Source 900ms sine roll is halfway at 450ms")
	for i in 9: phase.tick(0.05,s)
	check(phase.maintenance_sample(s).cart==Vector2(1049,716) and phase.maintenance_sample(s).pushAlpha==0.0,"Source repaired cart settles 66px west without a baked duplicate")
	var reloaded: RefCounted=Phase.new(); reloaded.tick(0,s)
	check(reloaded.maintenance_sample(s).cart==Vector2(1049,716),"Reload restores completed maintenance push rather than replaying it")
	check(phase.clock_frame(s)=="gear_running" and phase.manual_minute(s),"Repaired clock exposes source manual minute endpoint")
	s.chapter4.floor="A2"; s.chapter4.phase="final_minute_recovery"; s.chapter4.timeState="0754_blackout"
	check(phase.collisions(s)==[Rect2(1298,341,110,29)],"Room202 door uses exact source recovery barrier")
	s.chapter4.phase="return_to_clock"; check(phase.collisions(s).is_empty(),"Recovered minute reopens Room202 exit")
	s.chapter4.floor="A1"; s.items.finalMinute=true
	check(phase.clock_frame(s)=="0754_calibrated" and phase.manual_minute(s),"Return route keeps 07:54 clock plus physical insertion endpoint")
	s.chapter4.phase="morning_checkin"; s.chapter4.timeState="0755_morning"
	check(phase.clock_frame(s)=="0755_complete" and not phase.manual_minute(s),"Morning restoration removes manual endpoint")
	for sheet in ["chapter4_clock_states","chapter4_power_panel_states"]:
		check(Room.data().sheets.has(sheet) and ResourceLoader.exists(Room.data().sheets[sheet].path),"Original dynamic atlas is bundled: "+sheet)
	check(phase.honor_figures(s).size()==13,"A1 source honor wall has all13 original portrait consumers")
	s.chapter4.floor="A3"; s.chapter4.phase="room204_restore"
	check(phase.honor_figures(s).size()==7,"A3 source honor wall has all7 original portrait consumers")
	var yang:Dictionary=phase.honor_figures(s).filter(func(person):return person.id=="yang_wei")[0]
	check(Room.rect(yang.frameBounds).position==Vector2(1034,72) and Room.rect(yang.frameBounds).end.y<=142,"Yang Wei is mounted on the clear north wall, outside the walking corridor")
	check(phase.honor_floor_repairs(s).size()==1 and Room.rect(yang.floorRepair.bounds).encloses(Rect2(526,627,73,99)),"The old baked corridor frame and its edges receive a floor repair")
	check(Room.rect(yang.floorRepair.bounds).size==Room.rect(yang.floorRepair.sourceBounds).size,"Floor restoration uses an undistorted same-size source crop")
	check(phase.support_people(s).size()==1 and phase.support_people(s)[0].npcId=="a3_reference_teacher","A3 reference teacher renders in the authored phase")
	check(phase.alumni.all(func(person): return ResourceLoader.exists(person.portraitUrl)),"All20 source-backed honor portraits are present")
	var chapter: RefCounted=Chapter.new(); s=fresh(); s.chapter4.phase="room204_restore"; s.chapter4.timeState="1850_evening"
	var unchanged: Dictionary=s.duplicate(true); var conversation: Dictionary=chapter.dispatch(s,"c4_front_desk")
	check(conversation.message==chapter._dialogue("frontDesk.classrooms_none") and s==unchanged,"Front desk preserves original context dialogue without writing a story fact")
	s.chapter4.factIds.append("classroom_104_chalk_residual_observed")
	check(chapter._front_desk_dialogue(s.chapter4)=="frontDesk.classroom_104_done","Front desk dialogue tracks independent classroom observation")
	s=fresh(); var answer: Dictionary={"wheel_sound":"latch","clock_jam":"gear_offset","oil_trace":"oil_shortage"}
	chapter.dispatch(s,"c4_diagnose",answer); chapter.dispatch(s,"c4_cart_cover"); chapter.dispatch(s,"c4_cart_oil"); chapter.dispatch(s,"c4_diagnose",answer)
	check(not s.items.shortPryBar and not s.items.universalLubricatingOil,"Repeated diagnosis cannot regenerate consumed final-use tools")
	s=fresh(); s.chapter4.phase="blackout_light_grid"; s.chapter4.timeState="0754_blackout"; s.chapter4.lightGrid={"mask":6,"locked":false}; chapter.dispatch(s,"c4_toggle_hall")
	check(s.chapter4.lightGrid.mask==6,"Blackout phase name cannot replace minute-theft prerequisite")
	s=fresh(); s.chapter4.phase="final_chase"; s.chapter4.timeState="0754_blackout"; s.chapter4.floor="A2"; s.chapter4.chaseStairwellStage="complete"; s.chapter4.factIds=["light_grid_locked","powered_route_confirmed","room202_endpoint_inferred"]
	var result: Dictionary=chapter.dispatch(s,"c4_reach202")
	check(result.has("teleport") and Vector2(result.teleport[0],result.teleport[1])==Vector2(1453,306) and s.rpgCheckpoint=="c4_a2_room202","Reaching202 atomically restores safe interior spawn and checkpoint")
	s=fresh(); s.chapter4.phase="opening_paper_caught"; s.chapter4.timeState="2245_opening"; s.chapter4.factIds=["external_time_rejected"]
	result=chapter.dispatch(s,"c4_clock")
	check(result.has("world_effect") and result.world_effect.durationMs==4700,"Clock inspection keeps original timed in-world handoff")
	chapter.dispatch(s,"c4_clock_inspected",{"session":result.world_effect.session,"elapsedMs":4699,"acknowledged":true}); check("hall_clock_inspected" not in s.chapter4.factIds,"Inspection cannot bypass 4700ms source sequence")
	chapter.dispatch(s,"c4_clock_inspected",{"session":result.world_effect.session,"elapsedMs":4700,"acknowledged":true}); check("hall_clock_inspected" in s.chapter4.factIds,"Inspection commits at authored boundary")
	# Execute real Godot CanvasItem draw commands for every phase and transition.
	var holder: Surface=Surface.new(); holder.size=Vector2(960,540); holder.layers=layers; holder.state=fresh(); root.add_child(holder)
	for sample in [["maintenance_repair","A1","2245_maintenance",[]],["maintenance_repair","A1","2245_maintenance",["cart_wheel_cover_opened"]],["maintenance_repair","A1","2245_maintenance",["cart_wheel_repaired","clock_gear_repaired"]],["blackout_light_grid","A1","0754_blackout",[]],["final_chase","A1","0754_blackout",[]],["morning_checkin","A1","0755_morning",[]],["final_minute_recovery","A2","0754_blackout",[]],["room204_restore","A3","1850_evening",[]]]:
		holder.state.chapter4.phase=sample[0]; holder.state.chapter4.floor=sample[1]; holder.state.chapter4.timeState=sample[2]; holder.state.chapter4.factIds=sample[3]
		var before: Dictionary=holder.state.duplicate(true); layers.tick(0.016,holder.state); holder.queue_redraw(); await process_frame; await process_frame
		check(holder.state==before,"Presentation never writes story state: "+sample[0]+str(sample[3]))
	holder.queue_free(); await process_frame
	var honor_holder:Surface=Surface.new();honor_holder.size=Vector2(960,540);honor_holder.layers=layers;honor_holder.state=fresh();root.add_child(honor_holder)
	await honor_lighting(honor_holder,layers)
	honor_holder.queue_free();await process_frame
	check(original==fresh(),"Pure initial snapshot remains unchanged")
	print("CHAPTER4_PHASE_WORLD_TESTS ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
