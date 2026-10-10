extends "res://tests/test_canteen_mixer.gd"
## Deterministic presentation timing + untouched source transactions. Local
## fixture and scripted Control signals, not a full campaign or physical CUA.
func fresh(reduced: bool=false) -> Control:
	s=initial();s.native.settings.reduced_motion=reduced
	dispatched.clear();closes.clear();feedback.clear()
	var view: Control=panel();view.set_process(false);view.surface.motion.set_process(false)
	return view
func complete(view: Control,recipe: Array=Session.RECIPE) -> void:
	for id: String in recipe: press(view,id)
func drain_pours(view: Control) -> void:
	for beat in range(3): MixerTiming.finish_current(view.surface.motion)
func run() -> void:
	for reduced in [false,true]:
		for recipe: Array in [Session.RECIPE,["lemonTea","blackCoffee","sparklingWater"]]:
			var view: Control=fresh(reduced)
			var order: Array=view.session.button_order.duplicate()
			var contact: Vector2=view.surface.motion.position
			complete(view,recipe)
			var committed: Dictionary=s.duplicate(true)
			check(dispatched.size()==3 and s.canteenHunt.drinkMixAttemptCount==1 and s.canteenHunt.drinkMixSequence.is_empty(),"rapid third input commits exactly one original transaction before visual completion")
			check(s.items.dailySpecialSparklingWater==(recipe==Session.RECIPE) and s.items.badDrink!=(recipe==Session.RECIPE),"original good/bad reward already available")
			check(view.slots.all(func(slot):return slot.disabled and slot.get_theme_stylebox("disabled") is StyleBoxEmpty),"terminal input lock remains visually transparent over original selectors")
			check(view.finishing and not view.session.active and view.visible and closes.is_empty(),"source session closed; only cancellable presentation remains")
			check(view.surface.motion.item_id==recipe[0] and view.surface.pending_pours.size()==2,"rapid input queues accepted cup pushes rather than hard-cutting it")
			view.slots[0].pressed.emit();view.refresh()
			check(dispatched.size()==3 and s==committed,"stale or repeated terminal input cannot spend or grant twice")
			view._process(10)
			check(view.visible and view.modulate.a==1 and view.finish_elapsed_ms==0,"return waits for queued physical pours without changing committed state")
			for index in range(3):
				check(view.surface.motion.item_id==recipe[index],"accepted pours preserve actual input order")
				check(view.surface.motion.position==contact,"machine origin remains fixed throughout every cup push")
				MixerTiming.finish_current(view.surface.motion)
			check(not view.surface.is_pouring() and view.surface.motion.shown_sequence==recipe,"full three-layer glass remains after the final cup return")
			check(view.surface.source_slots.map(func(slot):return slot.id)==order,"retained selector order never changes during completion")
			view.configure_layout(Vector2(390,844),true)
			check(view.prompt_label.text=="调配中…","layout refresh keeps finishing instruction instead of asking for another ingredient")
			check(view.surface.motion.shown_sequence==recipe and s==committed,"resize retains completed cup and cannot replay transaction")
			view.set_feedback("stale external feedback")
			var settle: float=0 if reduced else view.SETTLE_MS
			var hold: float=160 if reduced else view.RESULT_MS
			var fade: float=100 if reduced else view.RETURN_MS
			view._process((settle+1)/1000/view.MixerMotion.PLAYBACK_RATE)
			check(view.feedback_label.text==view.finish_message and not view.finish_message.is_empty(),"controller result appears only after pour and settling")
			view._process((hold+fade/2-1)/1000/view.MixerMotion.PLAYBACK_RATE)
			check(view.modulate.a>0 and view.modulate.a<1 and view.visible,"native panel returns continuously to retained world")
			view._process((fade/2+1)/1000/view.MixerMotion.PLAYBACK_RATE)
			check(closes==["attempt_complete"] and not view.visible and not view.blocks_world_input(),"completion emits one close and releases input automatically")
			view._process(1);view.dismiss();view.refresh()
			check(s==committed and closes.size()==1,"settle, fade and late callbacks never modify reward or emit a second close")
			view.free()
	# Escape at every completion phase is immediate and preserves the already
	# committed reward. New open gets a fresh source lifetime with no stale tail.
	for phase in ["pour","settle","result","fade"]:
		var view: Control=fresh();complete(view);var committed: Dictionary=s.duplicate(true)
		if phase!="pour":drain_pours(view)
		if phase=="result":view._process(.15/view.MixerMotion.PLAYBACK_RATE)
		if phase=="fade":view._process(.55/view.MixerMotion.PLAYBACK_RATE)
		var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;view._input(escape)
		check(not view.visible and closes==["dismissed"] and view.surface.pending_pours.is_empty() and not view.surface.motion.playing,"Escape cancels optional "+phase+" immediately")
		check(s==committed,"Escape preserves committed "+phase+" inventory and attempt")
		view.setup(func() -> Dictionary:return s,dispatch,Callable(),random(18))
		check(view.visible and not view.finishing and view.modulate.a==1 and view.model.layers.is_empty(),"reopen has no old completion ghost: "+phase)
		view.free()
	for change in ["replacement","scene","attempt","teardown"]:
		var view: Control=fresh();complete(view);var committed: Dictionary=s.duplicate(true)
		if change=="replacement":s=s.duplicate(true)
		elif change=="scene":s.native.scene="campus_bootstrap"
		elif change=="attempt":s.canteenHunt.drinkMixAttemptCount+=1
		elif change=="teardown":view.free()
		if change!="teardown":
			view.refresh()
			check(not view.visible and closes==["context_changed"] and view.surface.pending_pours.is_empty(),"new context cancels stale tail: "+change)
			view.free()
		check(s.items==committed.items,"interruption cannot alter final inventory: "+change)
	# A synchronous signal listener may load/route while State.act is returning.
	for change in ["replacement","scene","dismiss"]:
		var dispatch_view: Control=fresh()
		dispatch_view.dispatch=func(action: String,value: Variant) -> Dictionary:
			var result: Dictionary=dispatch(action,value)
			if change=="replacement":s=s.duplicate(true)
			elif change=="scene":s.native.scene="campus_bootstrap"
			else:dispatch_view.dismiss()
			return result
		press(dispatch_view,"blackCoffee")
		check(not dispatch_view.visible and not dispatch_view.surface.is_pouring(),"dispatch-time "+change+" cannot revive stale presentation")
		check(dispatched.size()==1 and s.canteenHunt.drinkMixSequence==["blackCoffee"] and not s.items.blackCoffee,"dispatch-time "+change+" preserves sole accepted transaction")
		dispatch_view.free()
	# Missing click must not restart or replace a valid in-flight cup push.
	var view: Control=fresh();press(view,"blackCoffee")
	view.surface.motion._process(.1);var elapsed: float=view.surface.motion.elapsed_ms
	press(view,"blackCoffee")
	check(view.surface.motion.elapsed_ms==elapsed and not view.surface.motion.denied and dispatched.size()==1,"missing double-click leaves accepted pour continuous")
	view.free()
	print("Mixer completion continuity: ",checks," checks, ",errors," failures")
	quit(1 if errors else 0)
