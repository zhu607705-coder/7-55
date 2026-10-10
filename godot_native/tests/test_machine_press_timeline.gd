extends "res://tests/test_mixer_completion_continuity.gd"
## Deterministic three-outlet depth mechanics and original controller oracles.
## Pixel registration uses the actual PNGs. Scripted samples do not claim CUA/FPS.
const MachineMotion=preload("res://scripts/presentation/c3_mixer_motion.gd")
const Rig=preload("res://scripts/presentation/drink_fountain_rig.gd")
const PHASES=[0.14,0.26,0.36,0.38,0.66,0.76,0.88,0.96]
var glass_image: Image
var glass_region: Rect2
var mouth_source_left: int=-1
var mouth_source_right: int=-1

func drink_color(id: String,alpha: float=0.92) -> Color:
	var value: int=Session.COLORS[id]
	return Color((value>>16&255)/255.0,(value>>8&255)/255.0,(value&255)/255.0,alpha)

func sample(view: Control,progress: float) -> void:
	view.surface.motion.sample_pose(view.surface.motion.duration_ms*progress)
	view.surface._process(0)

func phase_samples() -> Array[float]:
	var values: Array[float]=[0.0,0.07,0.20,0.31,0.50,0.71,0.82,0.92,1.0]
	for boundary: float in PHASES:
		values.append(boundary-0.00001);values.append(boundary);values.append(boundary+0.00001)
	values.sort();return values

func luminance(pixel: Color) -> float:
	return pixel.r*0.2126+pixel.g*0.7152+pixel.b*0.0722

func project_pixel(point: Vector2,angle: float) -> Vector2:
	# Independent horizontal-axis 3D rotation followed by the authored projection.
	var q: Vector2=(point-Rig.IMAGE_HINGE)*Rig.PADDLE_SCALE
	var depth: float=q.y*sin(angle)
	return Vector2(q.x-0.22*depth,q.y*cos(angle)+0.4*depth)

func signed_clearance(motion: Node2D) -> float:
	return motion.cup_depth-(346.0/557.0*120.0/2.0)-44.4*sin(motion.rig.angles[motion.selected_slot])

func front_pose(motion: Node2D) -> bool:
	return is_equal_approx(motion.cup_depth,120.0) and is_equal_approx(motion.glass_root.scale.x,120.0/150.0)

func all_rest(motion: Node2D) -> bool:
	return motion.rig.angles.all(func(angle):return is_equal_approx(angle,0.55))

func test_art() -> void:
	for role: String in ["body","paddle"]:
		var path: String=Rig.BODY_PATH if role=="body" else Rig.PADDLE_PATH
		var image:=Image.new()
		var result: int=image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
		check(result==OK and not image.is_empty(),"generated "+role+" PNG is readable")
		if result!=OK or image.is_empty():continue
		check(image.get_size()==Vector2i(1536,1024) and image.get_format()==Image.FORMAT_RGBA8,"genuine generated RGBA source dimensions: "+role)
		var provenance: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path.replace(".png",".provenance.json")))
		check(FileAccess.get_sha256(path)==str(provenance.sha256),"generated source bytes match provenance: "+role)
		for corner: Vector2i in [Vector2i.ZERO,Vector2i(1535,0),Vector2i(0,1023),Vector2i(1535,1023)]:
			check(image.get_pixelv(corner).a<0.02,"generated art has transparent outer corners: "+role)
		if role=="paddle":
			check(Rect2(Vector2.ZERO,Vector2(image.get_size())).encloses(Rig.PADDLE_REGION) and Rig.PADDLE_REGION.has_point(Rig.IMAGE_HINGE) and Rig.PADDLE_REGION.has_point(Rig.IMAGE_CONTACT),"paddle region contains registered hinge and broad-face contact")
			check(image.get_pixelv(Vector2i(Rig.IMAGE_CONTACT)).a>=0.95,"rear cup wall contacts actual opaque pad face, never transparent fringe")
			var row: int=int(Rig.IMAGE_CONTACT.y)
			var left: int=-1;var right: int=-1
			for x in range(int(Rig.PADDLE_REGION.position.x),int(Rig.PADDLE_REGION.end.x)):
				var pixel: Color=image.get_pixel(x,row)
				if pixel.a>=0.95 and luminance(pixel)>=0.4:
					if left<0:left=x
					right=x
			check(left>=0 and left<Rig.IMAGE_CONTACT.x-200 and right>Rig.IMAGE_CONTACT.x+200,"actual bright side borders enclose the broad-face contact with visible pad width")
			check(image.get_pixel(768,535).a>=0.95 and luminance(image.get_pixel(768,535))>0.7,"registered moving region includes the generated bright upper pad rim")
		else:
			for index in range(3):
				var selector: Rect2=Rig.SELECTOR_REGIONS[index]
				check(image.get_pixelv(Vector2i(selector.get_center())).a>=0.95,"each selector is registered to actual cabinet pixels")
				var outlet: Vector2=Vector2(Rig.OUTLET_X[index],Rig.OUTLET_Y)/Rig.BODY_SCALE+Rig.SOURCE_ORIGIN
				check(image.get_pixelv(Vector2i(outlet)).a>=0.95,"each fixed outlet anchor lies on its generated nozzle assembly")
	check(is_equal_approx(Rig.CUP_RADIUS,346.0/557.0*120.0/2.0),"physical cup radius derives from original glass aspect and uniform 120px height")
	var glass: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/native/mixer/components.json")).components.glass
	check(FileAccess.get_sha256(glass.path)=="1947dd5c871bcabd38f019ea5650fff62088ccd28f6ac78b9aeedec0d1dc5715","original glass PNG is preserved byte-for-byte")
	glass_image=(load(glass.path) as Texture2D).get_image()
	glass_region=Rect2(glass.region[0],glass.region[1],glass.region[2],glass.region[3])
	check(glass_region==Rect2(595,229,346,557) and glass_image.get_pixel(768,500).a<0.08,"original glass region and genuine clear center stay unchanged")
	for x in range(int(glass_region.position.x),int(glass_region.end.x)):
		var pixel: Color=glass_image.get_pixel(x,259) # Visible original upper-rim row.
		if pixel.a>=0.8 and luminance(pixel)>=0.7:
			if mouth_source_left<0:mouth_source_left=x
			mouth_source_right=x
	check(mouth_source_left>=0 and mouth_source_right-mouth_source_left>300,"actual bright upper rim establishes a measurable glass opening")
	var rig:=Rig.new();root.add_child(rig)
	check(rig.selectors.size()==3 and rig.nozzles.size()==3 and rig.pivots.size()==3 and rig.paddles.size()==3,"three physical outlets each own one selector, fixed hinge and textured paddle")
	for index in range(3):
		var paddle: Polygon2D=rig.paddles[index]
		check(paddle.texture==Rig.PADDLE and paddle.get_parent()==rig.pivots[index],"each paddle renders genuine raster artwork at its own hinge")
		for angle: float in [0.55,0.31,0.0,-0.12]:
			rig.set_angle(index,angle)
			check(paddle.rotation==0 and rig.pivots[index].rotation==0,"forward paddle motion never uses image-plane rotation")
			for point in range(4):check(paddle.polygon[point].is_equal_approx(project_pixel(paddle.uv[point],angle)),"raster corner follows independent horizontal-axis projection")
			check(rig.projected_contact(index).is_equal_approx(rig.pivots[index].position+project_pixel(Rig.IMAGE_CONTACT,angle)),"physical pad center shares actual UV projection")
	rig.free()

func check_raster_overlap(motion: Node2D,label: String) -> void:
	# A depth contact is behind the clear cup face. Verify it is bracketed by
	# measured bright glass walls rather than equating it with a side-wall hit.
	var pad: Vector2=motion.rig.pivots[motion.selected_slot].position+project_pixel(Rig.IMAGE_CONTACT,motion.rig.angles[motion.selected_slot])
	var local: Vector2=(pad-motion.glass_root.position)/motion.glass_root.scale
	var factor: float=150.0/glass_region.size.y
	var source_row: int=roundi(glass_region.position.y+(local.y+150.0)/factor)
	check(source_row>=glass_region.position.y and source_row<glass_region.end.y,"projected pad contact lies within actual glass height: "+label)
	if source_row<glass_region.position.y or source_row>=glass_region.end.y:return
	var left: int=-1;var right: int=-1
	for x in range(int(glass_region.position.x),int(glass_region.end.x)):
		var pixel: Color=glass_image.get_pixel(x,source_row)
		if pixel.a>=0.8 and luminance(pixel)>=0.7:
			if left<0:left=x
			right=x
	var pixel_x: float=glass_region.position.x+glass_region.size.x/2+local.x/factor
	check(left>=0 and right>left and pixel_x>left and pixel_x<right,"projected rear-wall contact is inside the measured bright glass silhouette: "+label)

func check_pose(view: Control,progress: float,label: String) -> void:
	var motion: Node2D=view.surface.motion
	var selected: int=motion.selected_slot
	check(motion.rig.nozzles.size()==3 and motion.nozzle==motion.rig.nozzles[selected],"selected liquid uses exactly its corresponding fixed outlet: "+label)
	check(motion.stream.visible==(not motion.reduced and progress>=0.38 and progress<0.66),"continuous flow obeys exact contacted 38%-66% gate: "+label)
	check(motion.drip.visible==(not motion.reduced and progress>=0.66 and progress<0.76),"last drop obeys exact 66%-76% gate: "+label)
	check(not motion.bottle.visible and motion.press_frame()==0,"no bottle pour or top-selector press substitutes for cup actuation: "+label)
	var expected_scale: float=(120.0/150.0)*(0.93+0.07*motion.cup_depth/120.0)
	check(motion.glass_root.rotation==0 and motion.glass_root.scale.is_equal_approx(Vector2.ONE*expected_scale),"original glass changes only uniform depth scale: "+label)
	check(motion.cup_shadow.position==motion.glass_root.position and motion.cup_shadow.scale==motion.glass_root.scale,"cup shadow follows the original glass depth pose: "+label)
	check(motion.glass_root.position.is_equal_approx(Vector2(motion.cup_lateral-0.22*motion.cup_depth,-60+0.4*motion.cup_depth)),"cup uses consistent forward/back projection: "+label)
	var source_foot: Vector2=Rig.SOURCE_ORIGIN+motion.glass_root.position/Rig.BODY_SCALE
	var actual_tray:=PackedVector2Array([Vector2(446,660),Vector2(1135,678),Vector2(1113,788),Vector2(271,767)])
	check(Geometry2D.is_point_in_polygon(source_foot,actual_tray),"cup remains supported by actual generated tray pixels through transfer and depth cycle: "+label)
	for slot in range(3):
		check(motion.rig.nozzles[slot].position==Vector2(Rig.OUTLET_X[slot],Rig.OUTLET_Y) and motion.rig.pivots[slot].position==Vector2(Rig.OUTLET_X[slot],Rig.HINGE_Y),"all nozzle anchors and hinge positions remain fixed: "+label)
		check(motion.rig.paddles[slot].rotation==0 and motion.rig.pivots[slot].rotation==0,"none of the three levers swings sideways in 2D: "+label)
		check(view.surface.press_buttons[slot].visible and view.surface.press_buttons[slot].region_rect==Rig.SELECTOR_REGIONS[slot],"every actual ingredient selector remains mounted: "+label)
		if slot!=selected:check(is_equal_approx(motion.rig.angles[slot],0.55),"unselected paddle remains fully released: "+label)
	if motion.reduced:
		check(front_pose(motion) and all_rest(motion),"reduced motion suppresses cup translation, scaling and lever motion: "+label)
	else:
		check(signed_clearance(motion)>=-0.0001 and is_equal_approx(motion.depth_clearance(),signed_clearance(motion)),"independent signed depth check prevents paddle penetration: "+label)
		if progress<=0.14:check(front_pose(motion),"lateral outlet transfer happens only fully in front: "+label)
		if progress>=0.14:check(is_equal_approx(motion.cup_lateral,Rig.OUTLET_X[selected]),"approach, press and return stay at selected outlet X: "+label)
		if progress<0.26:check(all_rest(motion),"cup approaches before it can move any paddle: "+label)
		if progress>=0.26 and progress<=0.66:
			check(absf(signed_clearance(motion))<0.0001 and motion.depth_contact_error()<0.0001,"rear cup wall maintains physical depth contact through press and flow: "+label)
			check_raster_overlap(motion,label)
		if progress>=0.36 and progress<=0.76:check(is_equal_approx(motion.rig.angles[selected],-0.12),"paddle stays pressed until the final drop ends: "+label)
		if progress>=0.88:check(all_rest(motion),"paddle returns fully forward before cup withdrawal finishes: "+label)
		if progress>=0.96:check(front_pose(motion),"cup reaches fully front position before the next outlet transfer: "+label)
	if motion.stream.visible or motion.drip.visible:
		var radius: float=glass_region.size.x/glass_region.size.y*120.0/2.0
		check(motion.cup_depth-radius<=0.0 and motion.cup_depth+radius>=0.0,"fixed nozzle depth zero remains within cup opening during stream and last drop: "+label)
		var raster_factor: float=150.0/glass_region.size.y*motion.glass_root.scale.x
		var center_pixel: float=glass_region.position.x+glass_region.size.x/2.0
		var mouth_left: float=motion.glass_root.position.x+(mouth_source_left-center_pixel)*raster_factor
		var mouth_right: float=motion.glass_root.position.x+(mouth_source_right-center_pixel)*raster_factor
		check(motion.nozzle.position.x>mouth_left and motion.nozzle.position.x<mouth_right,"stream/drop outlet X lies inside measured original rim at uniform depth scale: "+label)
	if motion.stream.visible:
		var outlet: Vector2=(motion.stream.polygon[0]+motion.stream.polygon[1])/2
		check(outlet.is_equal_approx(motion.rig.nozzles[selected].position) and motion.stream.color==drink_color(motion.item_id),"sole stream starts at selected physical nozzle with its actual ingredient color: "+label)
		for other in range(3):
			if other!=selected:check(outlet.distance_to(motion.rig.nozzles[other].position)>80,"unselected outlets cannot emit the active liquid: "+label)
	if motion.drip.visible:
		check(motion.drip.color==drink_color(motion.item_id) and is_equal_approx(motion.drip.position.x,motion.nozzle.position.x),"last drop keeps selected outlet and ingredient: "+label)
		if absf(progress-0.66)<0.000000001:check(motion.drip.position.is_equal_approx(motion.nozzle.position),"last drop starts at outlet exactly when continuous flow stops")
		check(absf(motion.drip.position.x-motion.glass_root.position.x)<46*motion.glass_root.scale.x,"withdrawing original cup remains beneath final drop")

func test_accepted_press(reduced: bool,id: String) -> void:
	var view: Control=fresh(reduced)
	var motion: Node2D=view.surface.motion
	var order: Array=view.session.button_order.duplicate()
	var selected: int=order.find(id)
	var assembly: Transform2D=motion.transform
	var body: Transform2D=motion.rig.body.transform
	var glass_art: Transform2D=motion.glass_sprite.transform
	var idle_position: Vector2=motion.glass_root.position
	check(front_pose(motion) and all_rest(motion) and not motion.stream.visible and not motion.drip.visible,"idle cup waits fully in front of all three paddles")
	check(order!=Session.RECIPE and motion.slot_ids==order,"outlets preserve actual shuffled controller ingredient slots")
	var button: Sprite2D=view.surface.press_buttons[selected]
	var tint: Color=drink_color(id,1.0)
	check(button.texture==Rig.BODY and is_equal_approx(button.modulate.r,tint.r*2.6) and is_equal_approx(button.modulate.g,tint.g*2.6) and is_equal_approx(button.modulate.b,tint.b*2.6),"actual source color tints the corresponding neutral selector")
	press(view,id)
	var committed: Dictionary=s.duplicate(true)
	check(dispatched==["c3_mix:"+id] and s.canteenHunt.drinkMixSequence==[id] and not s.items[id],"cup follows one immediately committed controller action: "+id)
	check(motion.selected_slot==selected and motion.slot_ids[selected]==id,"selected physical outlet maps actual shuffled ingredient, never answer order")
	check(motion.duration_ms==(140.0 if reduced else 1050.0),"ordinary cycle keeps exact normal and reduced local durations")
	for progress: float in phase_samples():
		sample(view,progress);check_pose(view,progress,id+"/"+str(reduced)+"/"+str(progress))
		check(motion.transform==assembly and motion.rig.body.transform==body and motion.glass_sprite.transform==glass_art,"cabinet and original glass raster registrations never move independently")
		check(s==committed and view.session.button_order==order,"pose sampling cannot consume, reshuffle or rewrite recipe")
		if reduced:check(motion.glass_root.position==idle_position,"reduced cycle never translates even to a different outlet")
	var end: Vector2=motion.glass_root.position
	MixerTiming.finish_current(motion);view.surface._process(0)
	check(not motion.playing and motion.glass_root.position==end and front_pose(motion) and button.modulate.a<0.3,"completion preserves front pose and dims consumed selector")
	check(s==committed and dispatched.size()==1 and motion.shown_sequence==[id],"completion retains actual source layer without replay")
	view.free()

func test_phase_continuity() -> void:
	var view: Control=fresh();press(view,"blackCoffee")
	var motion: Node2D=view.surface.motion
	for boundary: float in PHASES:
		sample(view,boundary-0.00001);var before: Vector2=motion.glass_root.position;var angle: float=motion.rig.angles[motion.selected_slot];var scale_before: Vector2=motion.glass_root.scale
		sample(view,boundary+0.00001)
		check(before.distance_to(motion.glass_root.position)<0.02 and absf(angle-motion.rig.angles[motion.selected_slot])<0.0001 and scale_before.distance_to(motion.glass_root.scale)<0.0001,"depth pose remains continuous across phase "+str(boundary))
	var previous_depth: float=120.0;var previous_lateral: float=motion.cup_start_lateral
	for tick in range(1001):
		var progress: float=tick/1000.0;sample(view,progress)
		check(signed_clearance(motion)>=-0.0001,"dense samples never penetrate paddle")
		if not is_equal_approx(motion.cup_lateral,previous_lateral):check(front_pose(motion),"every lateral change happens fully in front")
		if progress>=0.14 and progress<=0.36:check(motion.cup_depth<=previous_depth+0.0001,"cup approaches and pushes monotonically away from viewer")
		if progress>=0.66:check(motion.cup_depth>=previous_depth-0.0001,"cup withdraws monotonically toward viewer after flow stops")
		if motion.stream.visible:check(progress>=0.38 and progress<0.66 and absf(signed_clearance(motion))<0.0001,"dense samples never flow outside contacted hold")
		previous_depth=motion.cup_depth;previous_lateral=motion.cup_lateral
	view.free()

func test_rejected_press(reduced: bool) -> void:
	var view: Control=fresh(reduced);s.items.blackCoffee=false;view.refresh()
	var before: Dictionary=s.duplicate(true);var pose: Vector2=view.surface.motion.glass_root.position
	press(view,"blackCoffee")
	for progress: float in phase_samples():
		sample(view,progress)
		var motion: Node2D=view.surface.motion
		check(front_pose(motion) and all_rest(motion) and motion.glass_root.position==pose and not motion.stream.visible and not motion.drip.visible,"missing ingredient cannot transfer, push or dispense")
	check(dispatched.is_empty() and s==before and view.surface.motion.observed_accepts==0,"missing selector cannot fake accepted action")
	check(feedback==[str(view.session.drinks.ingredientMissing)],"missing selector retains original feedback")
	view.free()

func test_cancel_resize_and_queue() -> void:
	for progress: float in [0.07,0.20,0.31,0.50,0.71,0.82,0.92]:
		var view: Control=fresh();press(view,"blackCoffee");sample(view,progress)
		var committed: Dictionary=s.duplicate(true);var motion: Node2D=view.surface.motion
		var pose: Vector2=motion.glass_root.position;var depth: float=motion.cup_depth;var angle: float=motion.rig.angles[motion.selected_slot]
		for dims: Vector2 in [Vector2(390,844),Vector2(844,390),Vector2(960,540)]:
			view.configure_layout(dims,dims!=Vector2(960,540))
			check(motion.glass_root.position==pose and motion.cup_depth==depth and motion.rig.angles[motion.selected_slot]==angle and s==committed,"resize preserves local depth/contact pose and immediate source transaction")
			check(view.art_board.encloses(view.surface.machine_bounds),"full three-outlet rig fits resized panel")
		view.dismiss();view.surface._process(0)
		check(not motion.playing and not motion.stream.visible and not motion.drip.visible and all_rest(motion) and front_pose(motion),"dismiss cancels every phase and releases all paddles")
		check(s==committed and closes==["dismissed"],"dismiss preserves accepted transaction")
		view.setup(func() -> Dictionary:return s,dispatch,Callable(),random(18))
		check(front_pose(motion) and all_rest(motion) and not view.surface.is_pouring() and motion.shown_sequence==["blackCoffee"],"reopen reconstructs source glass fully front without old motion")
		view.free()
	for reduced: bool in [false,true]:
		for recipe: Array in [Session.RECIPE,["lemonTea","blackCoffee","sparklingWater"]]:
			var view: Control=fresh(reduced);var order: Array=view.session.button_order.duplicate();complete(view,recipe)
			var committed: Dictionary=s.duplicate(true)
			check(s.canteenHunt.drinkMixAttemptCount==1 and dispatched.size()==3 and view.surface.pending_pours.size()==2,"rapid input commits attempt immediately and queues only accepted presentations")
			for index in range(3):
				var motion: Node2D=view.surface.motion
				check(front_pose(motion) and motion.cup_start_lateral==motion.cup_lateral,"next accepted push inherits actual fully-front handoff")
				check(motion.selected_slot==order.find(recipe[index]),"queue follows actual selected shuffled outlet, including wrong recipe")
				for tick in range(101):
					var progress: float=tick/100.0;sample(view,progress)
					check_pose(view,progress,str(index)+"/"+str(progress))
				check(motion.duration_ms==((220.0 if reduced else 1350.0) if index==2 else (140.0 if reduced else 1050.0)),"ordinary and terminal queue durations remain exact")
				var end: Vector2=motion.glass_root.position;MixerTiming.finish_current(motion)
				check(front_pose(motion) and motion.glass_root.position==end,"completion-to-next transfer has no cup teleport")
				check(s==committed and dispatched.size()==3,"queue cannot replay controller actions")
			check(not view.surface.is_pouring() and view.surface.motion.shown_sequence==recipe and s==committed,"queue retains actual layers and committed good/bad result")
			view.free()
	var view: Control=fresh();press(view,"blackCoffee");sample(view,0.82)
	var pose: Vector2=view.surface.motion.glass_root.position;var depth: float=view.surface.motion.cup_depth
	press(view,"sparklingWater")
	check(view.surface.motion.glass_root.position==pose and view.surface.motion.cup_depth==depth,"late queued input never retargets current withdrawal")
	sample(view,1.0);pose=view.surface.motion.glass_root.position;MixerTiming.finish_current(view.surface.motion)
	check(front_pose(view.surface.motion) and view.surface.motion.glass_root.position==pose,"late queued push starts only from completed front pose")
	view.free()

func test_shuffle_mapping() -> void:
	var seen: Dictionary={}
	for seed_value in range(80):
		var view: Control=fresh();view.dismiss();dispatched.clear();closes.clear();view.setup(func() -> Dictionary:return s,dispatch,Callable(),random(seed_value))
		var order: Array=view.session.button_order.duplicate()
		if seen.has(str(order)):view.free();continue
		seen[str(order)]=true
		check(not s.canteenHunt.drinkShelfRead and order!=Session.RECIPE,"unread shelf never exposes recipe via outlet order")
		for id: String in order:
			press(view,id);sample(view,0.5)
			check(view.surface.motion.selected_slot==order.find(id) and view.surface.motion.item_id==id and view.surface.motion.stream.color==drink_color(id),"every shuffled slot dispenses its actual input ingredient")
			MixerTiming.finish_current(view.surface.motion)
		view.free()
	check(seen.size()==5,"all five source-allowed non-answer shuffle orders exercised")

func run() -> void:
	var original_time_scale: float=Engine.time_scale
	check(MachineMotion.PLAYBACK_RATE==0.75,"machine retains exact local 0.75 playback rate")
	check([MachineMotion.TRANSFER_END,MachineMotion.CONTACT_BEGIN,MachineMotion.PRESS_END,MachineMotion.FLOW_BEGIN,MachineMotion.FLOW_END,MachineMotion.DRIP_END,MachineMotion.REBOUND_END,MachineMotion.RETURN_END]==PHASES,"authored depth cycle has exact transfer/contact/flow/withdraw/rebound gates")
	test_art()
	for reduced: bool in [false,true]:
		for id: String in Session.RECIPE:test_accepted_press(reduced,id)
		test_rejected_press(reduced)
	test_phase_continuity();test_cancel_resize_and_queue();test_shuffle_mapping()
	var view: Control=fresh();press(view,"blackCoffee");view.surface.motion._process(0.2)
	check(is_equal_approx(view.surface.motion.elapsed_ms,150.0),"200 real ms advances 150 local ms")
	view.surface.motion._process(-1);check(is_equal_approx(view.surface.motion.elapsed_ms,150.0),"negative delta cannot rewind depth mechanics")
	view.free();check(Engine.time_scale==original_time_scale,"physical presentation never changes global engine clock")
	print("Three-outlet cup depth timeline: ",checks," checks, ",errors," failures")
	quit(1 if errors else 0)
