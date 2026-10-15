extends SceneTree
const Layers=preload("res://scripts/ui/chapter3_world_layers.gd")
const Chapter=preload("res://scripts/chapters/chapter3.gd")
var checks: int=0
var errors: int=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: errors+=1; push_error(label)
func initial(scene: String="canteen_interior") -> Dictionary:
	var s: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":3,"scene":scene,"page":"c3_canteen","mode":"light","player":{"x":1466,"y":608},"settings":{},"c3_tray_slots":[]}
	s.canteenHunt.active=true; s.canteenHunt.phase="tray_search"; s.canteenHunt.entryPaperEscaped=true
	s.theaterHunt.active=true; s.theaterHunt.phase="entry_ticket"
	return s
func entry(list: Array,id: String) -> Dictionary:
	for row: Dictionary in list:
		if row.id==id: return row
	return {}
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s: Dictionary=initial(); var layer:=Layers.new(); layer.sync(s,true)
	var before: String=JSON.stringify(s)
	var entries: Array=layer.entries(s)
	var npcs: Array=entries.filter(func(e:Dictionary)->bool:return str(e.get("asset","")).contains("/npcs/canteen/"))
	check(npcs.size()==31,"four workers+twelve queue+fourteen seated+return worker are all visible")
	for npc: Dictionary in npcs:
		check(npc.frameSize==Vector2(96,128) and npc.scale==.65 and npc.anchor==Vector2(.5,1),"shared source frame/scale/anchor "+str(npc.id))
		check(layer.texture(npc.asset)!=null,"original asset loads "+str(npc.id))
	check(entry(entries,"return_worker").point==Vector2(1515,610),"return worker original visible source anchor")
	check(entry(entries,"promo_empty").point==Vector2(1232,130) and entry(entries,"promo_empty").scale==.5,"source empty promo board size and anchor")
	check(entries.filter(func(e:Dictionary)->bool:return e.kind=="crop").size()==8,"original counter plus seven occupied-table crops")
	var collisions: Array=layer.adjusted_collisions([],s)
	check(collisions.size()==13,"only twelve queue and return-worker colliders")
	for box: Dictionary in collisions: check(box.right-box.left==19.5 and box.bottom-box.top==14.625,"source fixed NPC foot rectangle")
	check(layer.adjusted_collisions(collisions,s).size()==13,"dynamic colliders do not accumulate across ticks")
	var queue: Dictionary=entry(entries,"queue_6"); check(queue.point==Vector2(790,246),"unshifted third queue source point")
	s.canteenHunt.queueGapOpened=true; s.canteenHunt.promoDrinkPlaced=true; layer.tick(.01,s); entries=layer.entries(s)
	check(entry(entries,"queue_6").point==Vector2(790,282),"opened queue shifts exactly36 sourcepixels")
	check(entry(entries,"promo_active").scale==.5 and entry(entries,"promo_bubbles").frameSize==Vector2(48,48),"active board and cropped source bubble sheet")
	check(entry(entries,"promo_bubbles").point==Vector2(1217,132) and entry(entries,"promo_bubbles").scale==.56,"source bubble offset and scale")
	var frame_before: int=entry(entries,"promo_bubbles").frame
	for _i in range(2): layer.tick(.1,s)
	check(entry(layer.entries(s),"promo_bubbles").frame!=frame_before,"source six-fps bubble loop animates")
	s.canteenHunt.carriedTrayIds=["tray_blue_01"]; layer.sync(s); layer.pickup_ms=500; entries=layer.entries(s)
	check(entry(entries,"carried_tray").point==Vector2(1466,560) and entry(entries,"carried_tray").scale==.75,"carried tray follows player with original48px offset")
	s.native.mode="dark"; layer.sync(s)
	check(layer.adjusted_collisions([],s).is_empty(),"light NPC collisions disable immediately on dark switch")
	for _i in range(2): layer.tick(.1,s)
	entries=layer.entries(s)
	check(entries.filter(func(e:Dictionary)->bool:return str(e.get("asset","")).contains("/npcs/canteen/")).size()==1 and not entry(entries,"shadow_worker").is_empty(),"dark mode replaces all ordinary people with original shadow auntie")
	s.canteenHunt.phase="exit_blocking"; layer.tick(.1,s); layer.tick(.1,s)
	check(layer.entries(s).filter(func(e:Dictionary)->bool:return str(e.get("asset","")).contains("/npcs/canteen/")).is_empty(),"defense hides scene NPCs instead of drawing duplicate actors")
	# Renderer never invents progress or changes source state dictionaries.
	s=initial(); layer.sync(s,true); before=JSON.stringify(s)
	layer.tick(.1,s); layer.entries(s); layer.adjusted_collisions([],s)
	check(JSON.stringify(s)==before,"renderer is non-authoritative")
	# Source theater geometry, phase-only programs, ticket reader and dark evidence.
	s=initial("theater_interior"); layer.sync(s,true); entries=layer.entries(s)
	check(entry(entries,"ticket_inspector").point==Vector2(753,707) and entry(entries,"ticket_inspector").scale==.75,"inspector uses source42px fixture offset once")
	check(entry(entries,"ticket_reader").point==Vector2(907,732),"reader procedural visual source point")
	check(entries.filter(func(e:Dictionary)->bool:return str(e.id).begins_with("program_")).is_empty(),"program scraps are not shown before admission")
	collisions=layer.adjusted_collisions([],s)
	check(collisions.size()==3 and collisions[0].top==633 and collisions[1].top==650,"original unshifted fixture collisions plus admission gate")
	s.theaterHunt.admitted=true; s.theaterHunt.phase="program_search"; layer.sync(s); entries=layer.entries(s)
	check(entry(entries,"ticket_inspector").asset.ends_with("ticket_inspector_scan_front.png"),"successful admission swaps original scan sprite")
	check(layer.adjusted_collisions([],s).size()==2,"admission removes only source gate barrier")
	check(entries.filter(func(e:Dictionary)->bool:return str(e.id).begins_with("program_")).size()==3,"three source program pieces available only program_search")
	for id: String in ["opening","spotlight","finale"]:
		check(entry(entries,"program_"+id).size==Vector2(48,48) and not entry(entries,"program_"+id).glow,"source48px program art and light visibility")
	s.native.mode="dark"; layer.sync(s); entries=layer.entries(s)
	check(entry(entries,"program_opening").glow,"dark program glow is visible")
	s.theaterHunt.collectedProgramIds=["opening"]; layer.sync(s); entries=layer.entries(s)
	check(entry(entries,"program_opening").is_empty() and not entry(entries,"program_flight_opening").is_empty(),"collection removes ground scrap and creates source physical flight")
	s.theaterHunt.phase="prop_setup"; layer.sync(s); entries=layer.entries(s)
	check(entry(entries,"manager_ghost").point==Vector2(500,166) and entry(entries,"manager_ghost").scale==.7,"original manager ghost source transform")
	check(entry(entries,"prop_ghost").point==Vector2(294,165) and entry(entries,"prop_ghost").scale==.78,"original prop ghost source transform")
	check(entry(entries,"prop_clue").text==layer.theater_text.prop.ghost+"\n"+layer.theater_text.prop.managerHint,"source clue strings unchanged")
	s.theaterHunt.propGhostRead=true; layer.sync(s)
	check(entry(layer.entries(s),"manager_ghost").is_empty(),"acknowledged ghost clue no longer shows future instruction")
	s.theaterHunt.phase="spotlight_ready"; s.theaterHunt.paperDusted=true; layer.sync(s); entries=layer.entries(s)
	check(entry(entries,"stage_paper").asset.ends_with("paper_residual.png") and not entry(entries,"paper_future_path").is_empty(),"dark residual texture takes precedence over fluorescent state")
	s.native.mode="light"; layer.sync(s)
	check(entry(layer.entries(s),"stage_paper").asset.ends_with("paper_fluorescent.png"),"light stage uses existing fluorescent paper")
	s=initial("theater_interior"); s.theaterHunt.cc98TicketCommissionPhase="delivered"; layer.sync(s,true)
	check(not entry(layer.entries(s),"kiosk_receipt").is_empty(),"delivered receipt code is explicitly light-only")
	s.native.mode="dark"; layer.sync(s)
	check(entry(layer.entries(s),"kiosk_receipt").is_empty(),"dark does not leak the light kiosk clue")
	# Controller targets now align with visible original people, source phase and exact prose.
	s=initial(); var chapter:=Chapter.new(); var definitions: Array=chapter.definitions("canteen_interior",s)
	var auntie: Dictionary=chapter.get_definition("canteen_interior","auntie",s)
	check(auntie.x==1515 and auntie.y==610 and auntie.stand=={"x":1466,"y":608} and auntie.proximity==64,"visible return-worker interaction uses exact source stand and radius")
	var chats: Array=definitions.filter(func(e:Dictionary)->bool:return e.get("kind")=="npc")
	check(chats.size()==11,"all original six queue/four seated/one counter dialogue definitions retained")
	for npc: Dictionary in chats:
		var expected: String=""
		if str(npc.id).begins_with("initial-queue-npc-"): expected=layer.source.constants.CANTEEN_QUEUE_NPC_DIALOGUE[int(str(npc.id).get_slice("-",3))]
		elif str(npc.id).begins_with("initial-seated-npc-"): expected=layer.source.constants.CANTEEN_SEATED_NPC_DIALOGUE[int(str(npc.id).get_slice("-",3))]
		else: expected=layer.source.constants.CANTEEN_COUNTER_NPC_DIALOGUE
		check(npc.dialogue==expected,"verbatim optional NPC source prose "+str(npc.id))
	var eligible: Array=chapter.targets("canteen_interior",s).filter(func(e:Dictionary)->bool:return str(e.id).begins_with("initial-"))
	check(eligible.size()>=5,"initial optional conversations are actually reachable")
	var choice: Dictionary=chapter.get_definition("canteen_interior",eligible[0].id,s)
	s.native.player=choice.get("stand",{"x":choice.x,"y":choice.y})
	chapter.dispatch(s,"c3_target:"+str(choice.id))
	var story: RefCounted=chapter.narrative_session(s)
	check(story!=null and story.lines[0].text==choice.dialogue,"actual optional NPC interaction issues original timed narrative")
	check(not s.canteenHunt.trayTaskStarted,"optional chatter never substitutes the auntie's task")
	s=initial("theater_interior"); chapter=Chapter.new()
	check(not chapter.targets("theater_interior",s).any(func(t:Dictionary)->bool:return str(t.id).begins_with("theater_program_")),"no future program interaction marker in lobby")
	check(layer.handles_target({"id":"theater_program_opening"},s),"dynamic layer suppresses duplicate generic target icon")
	print("Chapter 3 world layers: %d checks, %d failures" % [checks,errors]); quit(0 if errors==0 else 1)
