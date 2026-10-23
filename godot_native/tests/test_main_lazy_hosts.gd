extends SceneTree
## Real Main lifecycle; validate_native supplies an isolated user profile.
var state: Node
var shell: Control
var checks := 0
var failures := 0
var idle_snapshots := 0

func _initialize() -> void: run.call_deferred()
func frames(count: int=4) -> void:
	for i in count: await process_frame
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("MAIN LAZY HOSTS: "+label)
func install(value: Dictionary) -> void:
	state.d=value; state.story_reset.emit(); shell._refresh(); await frames()
func counted_runtime() -> Dictionary:
	idle_snapshots += 1
	return shell._read_runtime_state()

func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated test profile")
	if failures: quit(1); return
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	root.size=Vector2i(1440,900)
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames()
	shell.set_process(false)
	check(shell.library_story_host==null and shell.c3_scene_host==null and shell.c3_narrative_host==null,"Chapter 1 creates none of the three later story hosts")
	check(shell.later_phone_builder==null,"Chapter 1 does not construct later phone pages")
	check(is_instance_valid(shell.audio_director) and shell.audio_director.is_processing(),"early chapter sound director remains live")
	check(is_instance_valid(shell.home_charging_host),"early charging interaction remains available")
	state.open_page("photos"); await frames()
	check(shell.later_phone_builder==null,"ordinary early photos do not load recovered-photo builder")
	var library_state: Dictionary=state.initial()
	library_state.native.chapter=2; library_state.native.scene="library_interior"; library_state.native.page="library_022_dialogue"
	library_state.runtimeMode="rpg"; library_state.rpgScene="library_interior"
	library_state.ui.libraryFinalsPhase="evidence_gathering"
	await install(library_state)
	check(is_instance_valid(shell.library_story_host) and shell.library_story_host.is_processing(),"library ownership activates its story host")
	check(shell.c3_scene_host==null and shell.c3_narrative_host==null,"library evidence does not eagerly create C3 hosts")
	var library: Control=shell.library_story_host
	library_state=state.d.duplicate(true)
	library_state.ui.libraryFinalsPhase="seat_recovered"; library_state.ui.libraryFinalsPuzzle.playerSeated=true; library_state.rpgCheckpoint="library_seat_022"
	await install(library_state)
	check(state.d.native.chapter==2 and is_instance_valid(shell.c3_scene_host),"Chapter 2 library exit admits its pending C3 opening")
	check(shell.c3_scene_host.current!=null and shell.c3_scene_host.current.valid(state.d),"pending opening attaches to the real authoritative state")
	var scene_host: Control=shell.c3_scene_host
	scene_host.set_process(false); scene_host._skip(); scene_host._advance(); await frames()
	check(state.d.native.chapter==3 and state.d.native.scene=="campus_bootstrap","ordinary opening completion reaches Chapter 3 campus")
	check(not library.is_processing() and not scene_host.is_processing(),"completed library and opening stop outside their content")
	state.begin_checkpoint("c3-canteen-entry"); shell._refresh(); await frames()
	check(shell.c3_scene_host==scene_host and scene_host.is_processing(),"canteen reuses and activates the existing scene host")
	check(is_instance_valid(shell.c3_narrative_host) and shell.c3_narrative_host.is_processing(),"canteen activates the shared C3 narrative host")
	var narrative: Control=shell.c3_narrative_host
	check(shell.later_phone_builder==null,"entering the world alone does not construct phone evidence pages")
	var initial_state: Dictionary=state.initial()
	await install(initial_state)
	for host: Control in [library,scene_host,narrative]:
		check(not host.is_processing() and host.current==null,"reset stops and clears each used story host")
		host.runtime_reader=counted_runtime
	await frames(8)
	check(idle_snapshots==0,"Chapter 1 returns perform zero snapshots through dormant hosts")
	check(shell.library_story_host==library and shell.c3_scene_host==scene_host and shell.c3_narrative_host==narrative,"reset keeps loaded hosts reusable")
	state.begin_checkpoint("c3-theater-code"); shell._refresh(); await frames()
	check(shell.c3_narrative_host==narrative and narrative.is_processing(),"theater reactivates the same narrative host")
	check(not scene_host.is_processing() and not library.is_processing(),"theater leaves unrelated library and canteen-opening hosts stopped")
	state.open_page("c3_journal"); await frames()
	check(shell.later_phone_builder!=null,"first actual journal entry constructs later phone builder")
	var later: RefCounted=shell.later_phone_builder
	await install(state.initial())
	state.open_page("c3_journal"); await frames()
	check(shell.later_phone_builder==later,"later phone builder is reused across a reset and revisit")
	await shell.shutdown(); shell.queue_free(); await frames()
	print("Main lazy hosts: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
