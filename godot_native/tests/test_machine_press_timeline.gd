extends "res://tests/test_mixer_completion_continuity.gd"
## Deterministic cup/lever contact, fluid gates and source-controller boundaries.
## Scripted controls and sampled local clocks do not claim rendered FPS or CUA.
const Press=preload("res://scripts/presentation/drink_machine_press.gd")
const Paddle=preload("res://scripts/presentation/drink_cup_paddle.gd")
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
	check(result==OK and not atlas.is_empty(),"original flavor-selector PNG remains readable")
	if result==OK and not atlas.is_empty():
		check(atlas.get_size()==Vector2i(2172,724) and atlas.get_format()==Image.FORMAT_RGBA8,"selectors preserve their original RGBA sheet")
		check(Rect2(Vector2.ZERO,Vector2(atlas.get_size())).encloses(Press.region(0)),"stationary selector uses a registered original raster region")
		check(atlas.get_region(Rect2i(Press.region(0))).get_used_rect().has_area(),"selector region contains actual raster artwork")
	var image:=Image.new()
	result=image.load_png_from_buffer(FileAccess.get_file_as_bytes(Paddle.PATH))
	check(result==OK and not image.is_empty(),"generated cup-actuated paddle PNG is readable")
	if result!=OK or image.is_empty():return
	check(image.get_size()==Vector2i(1254,1254) and image.get_format()==Image.FORMAT_RGBA8,"paddle preserves its genuine generated RGBA source dimensions")
	check(Paddle.REGION==Rect2(488,150,280,960) and Paddle.IMAGE_PIVOT==Vector2(627,240) and Paddle.IMAGE_CONTACT==Vector2(733,950),"paddle registration pins the original hinge and right contact pad")
	check(Rect2(Vector2.ZERO,Vector2(image.get_size())).encloses(Paddle.REGION) and Paddle.REGION.has_point(Paddle.IMAGE_PIVOT) and Paddle.REGION.has_point(Paddle.IMAGE_CONTACT),"registered raster contains both physical anchors")
	check(image.get_region(Rect2i(Paddle.REGION)).get_used_rect().has_area(),"moving paddle region contains real raster pixels")
	var metal: Color=image.get_pixelv(Vector2i(Paddle.IMAGE_CONTACT))
	check(metal.a>=0.95 and metal.r*0.2126+metal.g*0.7152+metal.b*0.0722>=0.2,"registered contact is on the visible metal rim rather than its dark shadow fringe")
	check(MachineMotion.PRESSED_ANGLE==0.22 and MachineMotion.REST_ANGLE==-0.42 and MachineMotion.PRESSED_ANGLE-MachineMotion.REST_ANGLE>0.6,"held lever visibly rotates through more than 0.6 radians from rest")
	for point: Vector2i in [Vector2i(0,0),Vector2i(1253,0),Vector2i(0,1253),Vector2i(1253,1253)]:
		check(image.get_pixelv(point).a==0,"generated paddle has transparent outer corners")
	var provenance: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/native/canteen_animation/drink_cup_paddle.provenance.json"))
	check(FileAccess.get_sha256(Paddle.PATH)==str(provenance.sha256),"registered paddle bytes match generated-art provenance")
	var registered: Array=provenance.registered_region
	check(Rect2(registered[0],registered[1],registered[2],registered[3])==Paddle.REGION and Vector2(provenance.hinge_center[0],provenance.hinge_center[1])==Paddle.IMAGE_PIVOT and Vector2(provenance.right_pad_contact[0],provenance.right_pad_contact[1])==Paddle.IMAGE_CONTACT,"provenance and runtime share the same visible-rim registration")
	var paddle: Sprite2D=Paddle.sprite()
	check(paddle.texture==Paddle.TEXTURE and paddle.region_rect==Paddle.REGION and paddle.scale.is_equal_approx(Vector2.ONE*(66.0/710.0)),"paddle renders the registered raster at uniform scale")
	check((paddle.position+(Paddle.IMAGE_PIVOT-Paddle.REGION.position)*paddle.scale).is_zero_approx(),"registered hinge maps exactly to the rigid sprite's local origin")
	check((paddle.position+(Paddle.IMAGE_CONTACT-Paddle.REGION.position)*paddle.scale).is_equal_approx(Paddle.CONTACT_LOCAL),"registered pad maps exactly to the physical contact solver")
	paddle.free()
	# Check the visible bright wall, excluding transparent fringe and dark outline.
	var glass: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/native/mixer/components.json")).components.glass
	var glass_image: Image=(load(glass.path) as Texture2D).get_image()
	var region: Array=glass.region
	var factor: float=150.0/float(region[3])
	for angle_step in range(65):
		var angle: float=-0.42+angle_step*0.01
		var contact: Vector2=MachineMotion.PADDLE_PIVOT+Paddle.CONTACT_LOCAL.rotated(angle)
		var row: int=roundi((contact.y+150.0)/factor)+int(region[1])
		var left_pixel: int=-1
		for x in range(int(region[0]),int(region[0])+int(region[2])/2):
			var pixel: Color=glass_image.get_pixel(x,row)
			var luminance: float=pixel.r*0.2126+pixel.g*0.7152+pixel.b*0.0722
			if pixel.a>=0.8 and luminance>=0.7:left_pixel=x;break
		var visible_wall: float=(left_pixel-float(region[0])-float(region[2])/2.0)*factor
		var overlap: float=MachineMotion.cup_wall_x(contact.y)-visible_wall
		check(left_pixel>=0 and overlap>=-0.25 and overlap<0.75,"contact touches the bright glass wall within 0.25px gap or 0.75px occlusion: "+str(angle))

func test_accepted_press(reduced: bool,id: String) -> void:
	var view: Control=fresh(reduced)
	var motion: Node2D=view.surface.motion
	var order: Array=view.session.button_order.duplicate()
	var selected: int=order.find(id)
	var assembly: Transform2D=motion.transform
	var nozzle: Transform2D=motion.nozzle.transform
	var hinge: Vector2=motion.paddle_root.position
	var paddle_transform: Transform2D=motion.paddle.transform
	var button: Sprite2D=view.surface.press_buttons[selected]
	var button_transform: Transform2D=button.transform
	check(motion.glass_root.position==Vector2(68,0) and is_equal_approx(motion.paddle_root.rotation,MachineMotion.REST_ANGLE) and not motion.stream.visible and not motion.drip.visible,"idle cup waits clear of the resting paddle: "+id)
	check(order!=Session.RECIPE and view.surface.press_buttons.size()==3,"machine preserves three shuffled controller ingredient slots")
	check(button.texture==Press.ATLAS and (button.material as ShaderMaterial).get_shader_parameter("drink_color")==drink_color(id,1.0),"selector tint matches its actual shuffled ingredient: "+id)
	press(view,id)
	var committed: Dictionary=s.duplicate(true)
	check(dispatched==["c3_mix:"+id] and s.canteenHunt.drinkMixSequence==[id] and not s.items[id],"cup presentation follows exactly one immediately committed controller action: "+id)
	check(motion.duration_ms==(140.0 if reduced else 1050.0),"ordinary push uses 1050 local ms, or 140 reduced-motion ms")
	# Sample all phase boundaries and both sides of the exact fluid gates.
	for progress: float in [0.0,0.08,0.1599,0.16,0.22,0.2799,0.28,0.2999,0.30,0.4,0.6499,0.65,0.70,0.7599,0.76,0.82,0.8799,0.88,0.9599,0.96,1.0]:
		sample(view,progress)
		var label: String=id+"/"+str(reduced)+"/"+str(progress)
		check(motion.press_frame()==0 and button.region_rect==Press.region(0),"top selector never impersonates the under-nozzle pressure lever: "+label)
		check(motion.stream.visible==(not reduced and progress>=0.30 and progress<0.65),"continuous flow obeys the exact contacted 30%-65% gate: "+label)
		check(motion.drip.visible==(not reduced and progress>=0.65 and progress<0.76),"last drop obeys the exact 65%-76% gate: "+label)
		check(not motion.bottle.visible and motion.transform==assembly and motion.nozzle.transform==nozzle and motion.paddle_root.position==hinge and motion.paddle.transform==paddle_transform and button.transform==button_transform,"assembly, nozzle, hinge and raster registration remain fixed: "+label)
		check(motion.glass_root.scale==Vector2.ONE and motion.cup_shadow.position==motion.glass_root.position,"cup moves rigidly with its own contact shadow: "+label)
		check(s==committed and view.session.button_order==order,"presentation sampling cannot consume, reshuffle or rewrite a recipe: "+label)
		for selector: Sprite2D in view.surface.press_buttons:
			check(selector.visible and selector.region_rect==Press.region(0),"every flavor selector stays mounted and released: "+label)
		if reduced:
			check(motion.glass_root.position==Vector2(68,0) and is_equal_approx(motion.paddle_root.rotation,MachineMotion.REST_ANGLE),"reduced motion suppresses cup translation and lever rotation: "+label)
		else:
			if progress<0.16:check(is_equal_approx(motion.paddle_root.rotation,MachineMotion.REST_ANGLE) and motion.cup_contact_error()>0,"cup approaches before touching or moving the lever: "+label)
			if progress>=0.16 and progress<=0.65:
				var pad: Vector2=motion.paddle_root.position+Paddle.CONTACT_LOCAL.rotated(motion.paddle_root.rotation)
				var wall_x: float=motion.glass_root.position.x-37.8+clampf(pad.y-motion.glass_root.position.y,-150.0,0.0)*7.0/150.0
				check(absf(pad.x-wall_x)<0.0001 and motion.cup_contact_error()<0.0001,"registered cup wall remains in exact rigid-paddle contact through push and flow: "+label)
				check(pad.y>=motion.glass_root.position.y-150.0 and pad.y<=motion.glass_root.position.y,"registered contact lies within the glass wall height")
			if progress>=0.28 and progress<=0.76:check(is_equal_approx(motion.paddle_root.rotation,MachineMotion.PRESSED_ANGLE),"lever stays fully pressed through flow and the falling final drop")
			if progress>=0.88:check(is_equal_approx(motion.paddle_root.rotation,MachineMotion.REST_ANGLE),"lever returns to its exact resting angle before cup return finishes")
			if progress>=0.96:check(motion.glass_root.position==Vector2(68,0),"final cup returns to its original home")
		if motion.stream.visible:
			check(motion.stream.color==drink_color(id) and motion.liquid_parts[0].color==drink_color(id),"flow and actual glass layer share the selected source color: "+label)
			check((motion.stream.polygon[0]+motion.stream.polygon[1])/2==MachineMotion.NOZZLE_OUTLET,"continuous flow starts at the fixed physical nozzle")
		if motion.drip.visible:
			check(motion.drip.color==drink_color(id),"last drop keeps the selected source liquid color: "+label)
			if is_equal_approx(progress,0.65):check(motion.drip.position.is_equal_approx(MachineMotion.NOZZLE_OUTLET),"last drop starts at the outlet as continuous flow stops")
			check(absf(motion.drip.position.x-motion.glass_root.position.x)<46,"withdrawing cup mouth remains below the last drop")
	# Sampling the end pose does not finish the operation; the local clock does.
	var final_cup: Vector2=motion.glass_root.position
	MixerTiming.finish_current(motion);view.surface._process(0)
	check(not motion.playing and motion.glass_root.position==final_cup and button.region_rect==Press.region(0) and button.modulate.a<0.3,"completed cup remains continuous as its consumed selector dims")
	check(s==committed and dispatched.size()==1 and motion.shown_sequence==[id],"completion retains exactly one source layer and no second action")
	view.free()

func test_phase_continuity() -> void:
	var view: Control=fresh();press(view,"blackCoffee")
	var motion: Node2D=view.surface.motion
	for boundary: float in [0.16,0.28,0.30,0.65,0.76,0.88,0.96]:
		sample(view,boundary-0.00001)
		var before: Vector2=motion.glass_root.position
		var angle: float=motion.paddle_root.rotation
		sample(view,boundary);var at: Vector2=motion.glass_root.position
		sample(view,boundary+0.00001)
		check(before.distance_to(at)<0.01 and at.distance_to(motion.glass_root.position)<0.01 and absf(angle-motion.paddle_root.rotation)<0.0001,"cup and rigid paddle remain continuous across phase "+str(boundary))
	var previous_x: float=68.0
	for tick in range(101):
		var progress: float=tick/100.0;sample(view,progress)
		if progress<=0.28:check(motion.glass_root.position.x<=previous_x+0.0001,"cup approaches and pushes monotonically without a snap")
		if progress>=0.65:check(motion.glass_root.position.x>=previous_x-0.0001,"cup withdraws monotonically after flow shuts off")
		if motion.stream.visible:check(progress>=0.30 and progress<0.65 and motion.cup_contact_error()<0.0001,"dense samples never show flow before contact or after withdrawal")
		previous_x=motion.glass_root.position.x
	view.free()

func test_rejected_press(reduced: bool) -> void:
	var view: Control=fresh(reduced)
	s.items.blackCoffee=false;view.refresh()
	var before: Dictionary=s.duplicate(true)
	press(view,"blackCoffee")
	for progress: float in [0.0,0.16,0.30,0.4,0.65,0.76,0.88,1.0]:
		sample(view,progress)
		check(view.surface.motion.press_frame()==0 and not view.surface.motion.stream.visible and not view.surface.motion.drip.visible and view.surface.motion.glass_root.position==Vector2(68,0) and is_equal_approx(view.surface.motion.paddle_root.rotation,MachineMotion.REST_ANGLE),"missing ingredient cannot move the cup, press the lever or dispense at "+str(progress))
	check(dispatched.is_empty() and s==before and view.surface.motion.observed_accepts==0,"missing selector feedback cannot fake an accepted action")
	check(feedback==[str(view.session.drinks.ingredientMissing)],"missing selector retains the original feedback")
	view.free()

func test_cancel_and_queue() -> void:
	for progress: float in [0.08,0.22,0.4,0.70,0.82,0.94]:
		var view: Control=fresh();press(view,"blackCoffee");sample(view,progress)
		var committed: Dictionary=s.duplicate(true)
		view.dismiss();view.surface._process(0)
		check(not view.surface.motion.playing and not view.surface.motion.stream.visible and not view.surface.motion.drip.visible and view.surface.motion.press_frame()==0,"dismiss immediately cancels approach, contact, flow, drop, rebound or return: "+str(progress))
		check(s==committed and closes==["dismissed"],"dismiss preserves the already accepted controller transaction")
		view.setup(func() -> Dictionary:return s,dispatch,Callable(),random(18))
		check(view.surface.motion.glass_root.position==Vector2(68,0) and is_equal_approx(view.surface.motion.paddle_root.rotation,MachineMotion.REST_ANGLE) and not view.surface.is_pouring() and view.surface.motion.shown_sequence==["blackCoffee"],"reopen reconstructs partial glass at home with a dry released lever")
		view.free()
	for reduced: bool in [false,true]:
		for recipe: Array in [Session.RECIPE,["lemonTea","blackCoffee","sparklingWater"]]:
			var view: Control=fresh(reduced);complete(view,recipe)
			var committed: Dictionary=s.duplicate(true)
			check(s.canteenHunt.drinkMixAttemptCount==1 and dispatched.size()==3 and view.surface.pending_pours.size()==2,"rapid input immediately commits one attempt and queues only accepted cup pushes")
			for index in range(3):
				var motion: Node2D=view.surface.motion
				var expected_return: Vector2=Vector2(68,0) if reduced or index==2 else motion.cup_return
				if not reduced and index<2:
					var rest_contact: Vector2=motion.paddle_contact()
					var clear_x: float=rest_contact.x-(-37.8+rest_contact.y*7.0/150.0)
					check(expected_return.x>clear_x and expected_return.x<68.0 and expected_return.y==0.0,"intermediate cup return stays nearer than home while clearing the resting paddle")
				check(motion.cup_start==motion.glass_root.position,"next accepted push starts at the cup's actual handoff position")
				if not reduced:
					var previous_x: float=motion.glass_root.position.x
					for tick in range(101):
						var progress: float=tick/100.0;sample(view,progress)
						var pad: Vector2=motion.paddle_contact()
						var clearance: float=motion.glass_root.position.x-37.8+(pad.y-motion.glass_root.position.y)*7.0/150.0-pad.x
						check(clearance>=-0.001,"queued approach and rebound never penetrate the cup wall: "+str(index)+"/"+str(progress))
						if progress<=0.28:check(motion.glass_root.position.x<=previous_x+0.0001,"every queued cup approaches and pushes monotonically from its actual handoff")
						if progress>=0.65:check(motion.glass_root.position.x>=previous_x-0.0001,"every queued cup withdraws monotonically while clearing the rebounding lever")
						previous_x=motion.glass_root.position.x
					for boundary: float in [0.76,0.88,0.96]:
						sample(view,boundary-0.00001);var cup_before: Vector2=motion.glass_root.position
						sample(view,boundary+0.00001)
						check(cup_before.distance_to(motion.glass_root.position)<0.01,"queued rebound and staged return remain continuous at "+str(boundary))
				sample(view,0.4)
				check(motion.item_id==recipe[index] and motion.press_frame()==0,"queued cup presentation follows the accepted ingredient with stationary selectors")
				check(not motion.stream.visible if reduced else motion.stream.visible and motion.stream.color==drink_color(recipe[index]),"queued flow follows input order rather than solution order")
				check(motion.duration_ms==((220.0 if reduced else 1350.0) if index==2 else (140.0 if reduced else 1050.0)),"queue retains exact ordinary and terminal local durations")
				sample(view,1.0)
				check(motion.glass_root.position==expected_return,"queued ingredients use their clear staged return; final and reduced cups use home")
				var end: Vector2=motion.glass_root.position
				MixerTiming.finish_current(motion)
				check(motion.glass_root.position==end,"completion-to-next-cup handoff is position-continuous")
				check(s==committed and dispatched.size()==3,"queue transitions cannot replay controller actions")
			check(not view.surface.is_pouring() and view.surface.motion.shown_sequence==recipe and s==committed,"queue retains actual layers and committed good/bad result")
			view.free()
	# A late accepted action must not retarget a cup already withdrawing.
	var view: Control=fresh();press(view,"blackCoffee");sample(view,0.82)
	var before: Vector2=view.surface.motion.glass_root.position
	press(view,"sparklingWater")
	check(view.surface.motion.glass_root.position==before and view.surface.motion.cup_return==Vector2(68,0),"late queued input never moves the current return target")
	sample(view,1.0);MixerTiming.finish_current(view.surface.motion)
	check(view.surface.motion.cup_start==Vector2(68,0) and view.surface.motion.glass_root.position==Vector2(68,0),"late queued push inherits the completed home position without a teleport")
	view.free()

func run() -> void:
	var original_time_scale: float=Engine.time_scale
	check(MachineMotion.PLAYBACK_RATE==0.75,"cup-actuated machine retains the requested local 0.75 playback rate")
	test_art()
	for reduced: bool in [false,true]:
		for id: String in Session.RECIPE:test_accepted_press(reduced,id)
		test_rejected_press(reduced)
	test_phase_continuity();test_cancel_and_queue()
	var view: Control=fresh();press(view,"blackCoffee")
	view.surface.motion._process(0.2)
	check(is_equal_approx(view.surface.motion.elapsed_ms,150.0),"200ms of real delta advances the machine by 150ms of local time")
	view.surface.motion._process(-1)
	check(is_equal_approx(view.surface.motion.elapsed_ms,150.0),"negative delta cannot rewind cup contact or flow")
	view.free()
	check(Engine.time_scale==original_time_scale,"physical machine never changes global engine time scale")
	print("Machine cup/lever timeline: ",checks," checks, ",errors," failures")
	quit(1 if errors else 0)
