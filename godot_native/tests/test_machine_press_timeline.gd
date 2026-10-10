extends "res://tests/test_mixer_completion_continuity.gd"
## Deterministic machine press, fluid gates and controller boundaries. Scripted
## controls and sampled local clocks do not claim rendered FPS or physical CUA.
const Press=preload("res://scripts/presentation/drink_machine_press.gd")
const MachineMotion=preload("res://scripts/presentation/c3_mixer_motion.gd")

func drink_color(id: String,alpha: float=0.92) -> Color:
	var value: int=Session.COLORS[id]
	return Color((value>>16&255)/255.0,(value>>8&255)/255.0,(value&255)/255.0,alpha)

func sample(view: Control,progress: float) -> void:
	view.surface.motion.sample_pose(view.surface.motion.duration_ms*progress)
	view.surface._process(0)

func test_art() -> void:
	var atlas:=Image.new()
	var result: int=atlas.load_png_from_buffer(FileAccess.get_file_as_bytes(Press.ATLAS_PATH))
	check(result==OK and not atlas.is_empty(),"registered four-frame machine press PNG is readable")
	if result!=OK or atlas.is_empty(): return
	check(atlas.get_size()==Vector2i(2172,724) and atlas.get_format()==Image.FORMAT_RGBA8,"press artwork uses its original RGBA sheet dimensions")
	var unique: Dictionary={}
	for frame in range(4):
		var region: Rect2=Press.region(frame)
		check(Rect2(Vector2.ZERO,Vector2(atlas.get_size())).encloses(region),"registered press frame lies wholly inside the original sheet: "+str(frame))
		var cell: Image=atlas.get_region(Rect2i(region))
		unique[cell.get_data().hex_encode().sha256_text()]=true
		check(cell.get_used_rect().has_area(),"each press pose contains actual raster artwork: "+str(frame))
	check(unique.size()==4,"idle, depression, hold and release use four distinct raster regions")
	for point: Vector2i in [Vector2i(0,0),Vector2i(2171,0),Vector2i(0,723),Vector2i(2171,723)]:
		check(atlas.get_pixelv(point).a==0,"generated sheet has genuine transparent outer corners")
	check(Press.region(-1)==Press.region(0) and Press.region(4)==Press.region(3),"invalid atlas indices are safely bounded")

func test_accepted_press(reduced: bool,id: String) -> void:
	var view: Control=fresh(reduced)
	var motion: Node2D=view.surface.motion
	var order: Array=view.session.button_order.duplicate()
	var selected: int=order.find(id)
	var contact: Transform2D=motion.transform
	var nozzle: Transform2D=motion.nozzle.transform
	var button: Sprite2D=view.surface.press_buttons[selected]
	var button_transform: Transform2D=button.transform
	check(motion.press_frame()==0 and not motion.stream.visible and not motion.drip.visible,"idle machine is released and dry: "+id)
	check(order!=Session.RECIPE and view.surface.press_buttons.size()==3,"machine preserves three shuffled controller ingredient slots")
	check(button.texture==Press.ATLAS and (button.material as ShaderMaterial).get_shader_parameter("drink_color")==drink_color(id,1.0),"physical button tint matches its actual shuffled ingredient: "+id)
	press(view,id)
	var committed: Dictionary=s.duplicate(true)
	check(dispatched==["c3_mix:"+id] and s.canteenHunt.drinkMixSequence==[id] and not s.items[id],"physical press commits exactly its original controller action immediately: "+id)
	check(motion.duration_ms==(140.0 if reduced else 420.0),"ordinary accepted press retains original local duration")
	# The first 8% depresses the button. Fluid cannot start until 18%; release
	# at 68% stops continuous flow, and the last drop retires at 88%.
	for beat: Array in [[0.0,1],[0.079,1],[0.08,2],[0.179,2],[0.18,2],[0.4,2],[0.679,2],[0.68,3],[0.78,3],[0.879,3],[0.88,0],[1.0,0]]:
		var progress: float=beat[0]
		sample(view,progress)
		var expected_frame: int=(2 if progress<0.68 else 0) if reduced else int(beat[1])
		var label: String=id+"/"+str(reduced)+"/"+str(progress)
		check(motion.press_frame()==expected_frame and button.region_rect==Press.region(expected_frame),"selected physical button follows press/hold/release/idle frame: "+label)
		check(motion.stream.visible==(not reduced and progress>=0.18 and progress<0.68),"continuous flow obeys exact 18%-68% gate: "+label)
		check(motion.drip.visible==(not reduced and progress>=0.68 and progress<0.88),"last drop obeys exact 68%-88% gate: "+label)
		check(not motion.bottle.visible and motion.transform==contact and motion.nozzle.transform==nozzle and button.transform==button_transform,"machine, outlet and cup remain anchored without a flying bottle: "+label)
		check(s==committed and view.session.button_order==order,"sampled presentation cannot consume, reshuffle or rewrite a recipe: "+label)
		for index in range(3):
			if index!=selected:
				check(view.surface.press_buttons[index].visible and view.surface.press_buttons[index].region_rect==Press.region(0),"unselected machine button stays released: "+label)
		if motion.stream.visible:
			check(motion.stream.color==drink_color(id) and motion.liquid_parts[0].color==drink_color(id),"flow and actual glass layer share the selected source color: "+label)
			check((motion.stream.polygon[0]+motion.stream.polygon[1])/2==MachineMotion.NOZZLE_OUTLET,"continuous flow starts at the fixed physical nozzle")
		if motion.drip.visible:
			check(motion.drip.color==drink_color(id),"release drop keeps the selected source liquid color: "+label)
			if is_equal_approx(progress,0.68):check(motion.drip.position.is_equal_approx(MachineMotion.NOZZLE_OUTLET),"last drop begins at outlet exactly when continuous flow stops")
	# Sampling does not finish an operation; crossing the local clock does.
	motion._process(0.001);view.surface._process(0)
	check(not motion.playing and motion.press_frame()==0 and button.region_rect==Press.region(0) and button.modulate.a<0.3,"completed consumed button rebounds then dims without disappearing")
	check(s==committed and dispatched.size()==1 and motion.shown_sequence==[id],"completion retains exactly one source layer and no second action")
	view.free()

func test_rejected_press(reduced: bool) -> void:
	var view: Control=fresh(reduced)
	s.items.blackCoffee=false;view.refresh()
	var before: Dictionary=s.duplicate(true)
	press(view,"blackCoffee")
	for progress: float in [0.0,0.18,0.4,0.68,0.8,1.0]:
		sample(view,progress)
		check(view.surface.motion.press_frame()==0 and not view.surface.motion.stream.visible and not view.surface.motion.drip.visible,"missing ingredient never depresses or dispenses at "+str(progress))
	check(dispatched.is_empty() and s==before and view.surface.motion.observed_accepts==0,"missing button feedback cannot fake an accepted action")
	check(feedback==[str(view.session.drinks.ingredientMissing)],"missing machine button retains the original feedback")
	view.free()

func test_cancel_and_queue() -> void:
	for progress: float in [0.04,0.4,0.78]:
		var view: Control=fresh();press(view,"blackCoffee");sample(view,progress)
		var committed: Dictionary=s.duplicate(true)
		view.dismiss();view.surface._process(0)
		check(not view.surface.motion.playing and not view.surface.motion.stream.visible and not view.surface.motion.drip.visible and view.surface.motion.press_frame()==0,"dismiss immediately stops press, flow or final drop: "+str(progress))
		check(s==committed and closes==["dismissed"],"dismiss preserves the already accepted controller transaction")
		view.setup(func() -> Dictionary:return s,dispatch,Callable(),random(18))
		check(view.surface.motion.press_frame()==0 and not view.surface.is_pouring() and view.surface.motion.shown_sequence==["blackCoffee"],"reopen reconstructs partial glass with dry released buttons")
		view.free()
	for recipe: Array in [Session.RECIPE,["lemonTea","blackCoffee","sparklingWater"]]:
		var view: Control=fresh();complete(view,recipe)
		var committed: Dictionary=s.duplicate(true)
		var order: Array=view.surface.source_slots.map(func(slot):return slot.id)
		check(s.canteenHunt.drinkMixAttemptCount==1 and dispatched.size()==3 and view.surface.pending_pours.size()==2,"rapid machine input commits one attempt and queues only its accepted visual presses")
		for index in range(3):
			sample(view,0.4)
			var selected: int=order.find(recipe[index])
			check(view.surface.motion.item_id==recipe[index] and view.surface.press_buttons[selected].region_rect==Press.region(2),"queued presentation depresses the actual next accepted ingredient")
			check(view.surface.motion.stream.color==drink_color(recipe[index]),"queued machine flow follows input order rather than solution order")
			check(view.surface.motion.duration_ms==(600.0 if index==2 else 420.0),"queue retains ordinary and terminal local durations")
			view.surface.motion._process(1.0)
		check(not view.surface.is_pouring() and view.surface.motion.shown_sequence==recipe and s==committed,"queued press completion retains actual layers and committed good/bad result")
		view.free()

func run() -> void:
	var original_time_scale: float=Engine.time_scale
	check(MachineMotion.PLAYBACK_RATE==0.75,"machine press retains the requested local 0.75 playback rate")
	test_art()
	for reduced: bool in [false,true]:
		for id: String in Session.RECIPE:test_accepted_press(reduced,id)
		test_rejected_press(reduced)
	test_cancel_and_queue()
	var view: Control=fresh();press(view,"blackCoffee")
	view.surface.motion._process(0.2)
	check(is_equal_approx(view.surface.motion.elapsed_ms,150.0),"200ms of real delta advances the machine by 150ms of local time")
	view.surface.motion._process(-1)
	check(is_equal_approx(view.surface.motion.elapsed_ms,150.0),"negative delta cannot rewind physical pressure or flow")
	view.free()
	check(Engine.time_scale==original_time_scale,"physical machine never changes global engine time scale")
	print("Machine press timeline: ",checks," checks, ",errors," failures")
	quit(1 if errors else 0)
