extends "res://tests/test_canteen_defense_resume.gd"
var chase_starts:=0
func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("Bike chase reentry checks require an isolated test user directory")
		quit(2);return
	state=root.get_node("State");state.developer_mode=true
	imported=state.initial();imported.native.chapter=3;imported.native.page="phone_home";imported.native.scene="campus_bootstrap"
	imported.runtimeMode="rpg";imported.rpgScene="campus_bootstrap";imported.canteenHunt.active=true
	imported.canteenHunt.phase="chase_ready";imported.canteenHunt.bikePaid=true;imported.canteenHunt.bikeLockCleaned=true
	imported.wallet.cashCents=0;imported.items.greaseTissue=true;imported.items.cafeteriaWages=false
	state.action_completed.connect(func(id,_before,_after,_result):
		if id=="c3_chase":chase_starts+=1
	)
	defense_fixture();await new_main(Vector2i(1440,900))
	shell._show_world_mobile();await frames()
	check(not is_instance_valid(shell.active_game) and chase_starts==0,"paid chase_ready retains existing bike Start flow")
	check(state.get_targets("campus_bootstrap").any(func(target):return target.id=="bike"),"paid bike remains available before first Start")
	for cycle in range(2):
		imported.canteenHunt.phase="chasing";defense_fixture();var count:=chase_starts
		await new_main(Vector2i(1440,900))
		check(is_instance_valid(shell.active_game) and shell.active_game.mode=="chase" and chase_starts==count+1,"fresh source chasing phase restores exactly one chase")
		var game: Control=shell.active_game;await tap(game.start_button);game._process(.1);await tap(game.pause_button)
		root.size=Vector2i(430,860);shell.size=Vector2(430,860);shell._layout();shell._refresh();shell._resume_world_activity();await frames()
		check(shell.active_game==game and game.paused and chase_starts==count+1,"resize refresh and Return cannot replace paused chase")
		await tap(game.exit_button);count=chase_starts
		for i in range(4):shell._process(.1);shell._refresh();await frames(1)
		check(not is_instance_valid(shell.active_game) and chase_starts==count,"explicit Exit remains exited")
		shell._show_journal();await frames();await click(shell.find_child("JournalResume",true,false));await frames(4)
		check(is_instance_valid(shell.active_game) and chase_starts==count+1,"ordinary Tasks Return restores interrupted paid chase")
		check(state.d.wallet.cashCents==0 and state.d.items.greaseTissue and not state.d.items.cafeteriaWages and state.d.canteenHunt.bikePaid,"reentry never pays again or alters retained items")
		await tap(shell.active_game.exit_button)
	var count:=chase_starts
	# Compact startup restores the persisted surface, just like desktop. Exercise
	# the ordinary save reader rather than deriving that choice from page/width.
	for saved_mode: String in ["rpg","phone"]:
		await close_main();defense_fixture();state.d.runtimeMode=saved_mode
		state.developer_mode=false
		var saved: bool=state.save_game()
		state.d=state.initial()
		var restored: bool=state.load_game()
		state.developer_mode=true
		check(saved and restored and state.d.runtimeMode==saved_mode and state.d.native.scene=="campus_bootstrap" and state.d.canteenHunt.phase=="chasing","ordinary compact save/load preserves explicit "+saved_mode+" surface and chasing checkpoint")
		count=chase_starts;await new_main(Vector2i(430,860))
		if saved_mode=="rpg":
			check(is_instance_valid(shell.active_game) and shell.active_game.mode=="chase" and shell.mobile_world and not shell.phone.visible and chase_starts==count+1,"portrait RPG reload restores exactly one saved chase")
			check(state.d.wallet.cashCents==0 and state.d.items.greaseTissue and not state.d.items.cafeteriaWages and state.d.canteenHunt.bikePaid,"portrait RPG reload retains payment and story items")
			if is_instance_valid(shell.active_game):await tap(shell.active_game.exit_button)
		else:
			check(not is_instance_valid(shell.active_game) and shell.phone.visible and not shell.mobile_world and chase_starts==count,"portrait explicit phone reload waits for scene Return")
	var return_facts: Dictionary={"scene":state.d.native.scene,"phase":state.d.canteenHunt.phase,"paid":state.d.canteenHunt.bikePaid,"items":JSON.stringify(state.d.items),"wallet":JSON.stringify(state.d.wallet)}
	shell._show_journal();await frames();await click(shell.find_child("JournalResume",true,false));await frames(4)
	check(is_instance_valid(shell.active_game) and chase_starts==count+1,"portrait Tasks Return restores source chasing owner")
	check(state.d.runtimeMode=="rpg","portrait Tasks Return persists the explicit RPG destination")
	check(state.d.native.scene==return_facts.scene and state.d.canteenHunt.phase==return_facts.phase and state.d.canteenHunt.bikePaid==return_facts.paid and JSON.stringify(state.d.items)==return_facts.items and JSON.stringify(state.d.wallet)==return_facts.wallet,"portrait Tasks Return retains scene phase payment wallet and every item")
	await tap(shell.active_game.exit_button)
	var exported: String="user://bike-chase-reentry.json";check(state.export_save(exported)==OK,"normal save exports chasing state")
	for cycle in range(2):
		count=chase_starts;var result: Dictionary=state.import_save(exported);await frames(8)
		check(result.ok and is_instance_valid(shell.active_game) and chase_starts==count+1,"ordinary save import installs exactly one valid chasing owner")
		check(state.d.canteenHunt.phase=="chasing" and state.d.wallet.cashCents==0,"save restore preserves phase and payment")
		await tap(shell.active_game.exit_button);state.developer_mode=true
	count=chase_starts;state.d.canteenHunt.bikePaid=false;shell._show_world_mobile();await frames()
	check(not is_instance_valid(shell.active_game) and chase_starts==count,"unpaid inconsistent phase cannot bypass bike payment")
	state.d.canteenHunt.bikePaid=true;state.d.canteenHunt.chaseCompleted=true;shell._show_world_mobile();await frames()
	check(not is_instance_valid(shell.active_game) and chase_starts==count,"completed chase cannot reopen")
	state.d.canteenHunt.chaseCompleted=false;state.d.native.scene="canteen_interior";shell._show_world_mobile();await frames()
	check(not is_instance_valid(shell.active_game) and chase_starts==count,"other world cannot admit campus chase")
	state.d.native.scene="campus_bootstrap";shell._show_settings();shell._show_world_mobile();await frames()
	check(not is_instance_valid(shell.active_game) and chase_starts==count,"existing modal retains input ownership")
	shell._close_modal()
	# Shared host keeps each activity on its explicitly supported layout path.
	for mode: String in ["rhythm","kayak"]:
		shell._open_game({"type":mode,"phase":"boarding","goal":4,"spotId":"locker_key"});await frames()
		if mode=="rhythm":
			check(shell._activity_owns_scene() and shell.active_game.size==shell.size and shell.active_game.scale==Vector2.ONE,"fishing owns one unscaled full-scene activity surface")
			check(shell.active_game.fishing_view.visible and shell.active_game.fishing_view.size.y>=shell.size.y*.6,"fishing keeps its restored source field at a readable physical size")
		else:
			check(not shell._activity_owns_scene() and shell.active_game.size==Vector2(960,540),"kayak retains its existing layout path")
		shell.active_game.cancel_game();await frames()
	await close_main()
	print("BIKE_CHASE_REENTRY: ",checks," checks; ",failures," failures; starts=",chase_starts)
	quit(1 if failures else 0)
