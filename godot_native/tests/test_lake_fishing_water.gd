extends SceneTree
## Native presentation fixtures and source-input replays; no campaign rewards.
const Model=preload("res://scripts/games/rhythm_fishing_model.gd")
const Motion=preload("res://scripts/ui/lake_fishing_motion.gd")
const Water=preload("res://scripts/ui/lake_fishing_water.gd")
var checks:=0
var failures:=0
const SAFE=Rect2(10,200,410,360)
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FISHING WATER: "+label)
func observe(w: RefCounted,m: RefCounted,dt: float=1.0/60.0,paused: bool=false,reduced: bool=false,safe: Rect2=SAFE,blocked: Array[Rect2]=[]) -> void:
	var motion: Dictionary=Motion.sample(m,reduced)
	w.observe(dt,m,Motion.depth_sample(m,motion),motion,paused,reduced,Vector2(220,380),safe,blocked)
func snapshot(m: RefCounted) -> String:
	var values: Dictionary={}
	for property: Dictionary in m.get_property_list():
		if int(property.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE:values[property.name]=m.get(property.name)
	return JSON.stringify(values)
func fixture() -> RefCounted:
	var m:=Model.new();m.configure("locker_key",Model.load_chart("locker_key"))
	m.phase="running";m.stage="fighting";m.cast_at=0;m.elapsed=4*m.beat_sec
	return m
func test_lifecycle() -> void:
	var m=fixture();var w:=Water.new();observe(w,m)
	check(w.splashes.is_empty() and w.drops.is_empty(),"attachment cannot replay old bite or success")
	for index in range(6):m.notes[index].judgment="great"
	observe(w,m)
	check(w.emitted.retrieval==1 and w.drops.size()==2,"real successful-note progress triggers one shallow retrieval and two lens drops")
	for i in range(6):observe(w,m,0)
	check(w.emitted.retrieval==1 and w.drops.size()==2,"repeated rendering of one judgment cannot duplicate effects")
	observe(w,m,.1)
	var state:=JSON.stringify([w.clock,w.splashes,w.drops,w.emitted,w.lens_samples()])
	m.neutral()
	for i in range(8):observe(w,m,1,true)
	check(JSON.stringify([w.clock,w.splashes,w.drops,w.emitted,w.lens_samples()])==state,"pause and input neutralization freeze positions, ages and events")
	var before: Array[Vector4]=w.lens_samples();observe(w,m,.35)
	check(w.lens_samples()[0].y>before[0].y,"camera droplet hangs briefly then slides down")
	for drop: Dictionary in w.drops:check(Water.clear_path(Water.drop_bounds(drop),SAFE,[]),"whole droplet path stays in safe lake area")
	observe(w,m,2)
	check(w.drops.is_empty() and w.splashes.is_empty(),"all water expires without another gameplay event")
	m.notes[6].judgment="good";observe(w,m)
	check(w.drops.size()>0,"next real retrieval can emit again")
	observe(w,m,.01,false,true)
	check(w.drops.is_empty(),"reduced motion immediately removes lens motion")
	for splash: Dictionary in w.splashes:check(splash.still,"reduced motion also stops already active spray")
	m.notes[7].judgment="perfect";observe(w,m,.01,false,true)
	check(w.splashes[-1].still and w.drops.is_empty(),"reduced motion retains only a stationary short ripple")
	m.phase="completed";m.final_result={"passed":true};observe(w,m,.01,false,true)
	check(w.emitted.catch==1,"successful completion produces one catch event")
	for i in range(20):observe(w,m,.01,false,true)
	check(w.emitted.catch==1,"terminal frame repeats do not duplicate catch")
	m.phase="failed";observe(w,m)
	check(w.drops.is_empty() and w.splashes.is_empty(),"failure clears success water immediately")
	w.reset();check(w.clock==0 and w.drops.is_empty() and w.splashes.is_empty() and w.emitted.catch==0,"explicit retry resets every pool and event latch")
	m=fixture();observe(w,m);m.notes[0].judgment="miss";observe(w,m)
	check(w.emitted.retrieval==0 and w.emitted.catch==0 and w.drops.is_empty(),"misses cannot create a successful retrieval or lens splash")
	m.phase="completed";m.final_result={"passed":false};observe(w,m)
	check(w.emitted.catch==0 and w.splashes.is_empty(),"failed completion does not look like a catch")
	m=fixture();w.reset();observe(w,m)
	m.elapsed+=m.phrase_time(5.3);m.tension=90;observe(w,m)
	check(w.emitted.struggle==0 and w.drops.is_empty(),"deep high tension does not throw camera spray")
	for i in range(6):m.notes[i].judgment="good"
	m.elapsed+=m.phrase_time(4);observe(w,m)
	check(w.emitted.struggle==1,"a shallow loaded thrust creates one local struggle splash")
	var amount: int=w.emitted.struggle
	for i in range(5):observe(w,m,0)
	check(w.emitted.struggle==amount,"same thrust is deduplicated by phrase")
	m.elapsed=0;observe(w,m)
	check(w.splashes.is_empty() and w.drops.is_empty() and w.clock==0,"rewound model time clears old attempt water")

func test_source_replay(id: String,fps: int) -> void:
	var trace: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/rhythm_"+id+".json"))
	check(Model.validate_result(trace,id),"checked-in source trace validates: "+id)
	var m:=Model.new();m.configure(id,Model.load_chart(id));var w:=Water.new();var cursor:=0
	observe(w,m,0)
	var max_drops:=0;var max_splashes:=0;var intact:=true
	var ticks: int=ceili((float(trace.finishedAtSec)+.2)*fps)
	for tick in range(ticks+1):
		var at: float=float(tick)/fps
		while cursor<trace.inputs.size() and float(trace.inputs[cursor].timeSec)<=at:
			var input: Dictionary=trace.inputs[cursor];m.advance_to(float(input.timeSec))
			match str(input.type):
				"press":m.press(str(input.action))
				"release":m.release(str(input.action))
				"neutral":m.neutral()
			cursor+=1
		m.advance_to(at)
		var before:=snapshot(m);observe(w,m,1.0/fps)
		intact=intact and snapshot(m)==before
		max_drops=maxi(max_drops,w.drops.size());max_splashes=maxi(max_splashes,w.splashes.size())
	check(intact,"water never changes model, trace or rewards: "+id+" @"+str(fps))
	check(m.phase=="completed" and m.final_result.get("passed",false),"unchanged native model completes source input trace")
	check(w.emitted.bite==1 and w.emitted.catch==1 and w.emitted.retrieval>=1 and w.emitted.struggle>=1,"real source stages produce bite, shallow struggle, retrieval and one catch")
	check(max_drops<=4 and max_splashes<=3,"fixed pools remain bounded across source replay")
	print("WATER_REPLAY ",id," fps=",fps," events=",w.emitted," max_drops=",max_drops," max_splashes=",max_splashes)

func run() -> void:
	test_lifecycle()
	for id: String in ["locker_key","net_frame","fish","paper"]:
		for fps in [20,60]:test_source_replay(id,fps)
	root.get_node("State").developer_mode=true
	for extent: Vector2i in [Vector2i(1180,812),Vector2i(430,860),Vector2i(844,390)]:
		root.size=extent
		var host: Control=load("res://scripts/ui/minigame_host.gd").new();root.add_child(host);await process_frame
		host.setup({"type":"rhythm","chartId":"locker_key","spotId":"locker_key","session_id":"water-test"})
		host.configure_activity_layout(Vector2(extent),extent.x<1100);host.begin();host.set_process(false)
		var view: Control=host.fishing_view
		host.model=fixture();view.advance_view(0)
		for i in range(6):host.model.notes[i].judgment="good"
		view.advance_view(.016);view.advance_view(.08)
		check(view.water_lens.mouse_filter==Control.MOUSE_FILTER_IGNORE,"lens never owns pointer input")
		check(view.water.drops.size()>0,"actual viewport provides a readable safe lens band: "+str(extent))
		for drop: Dictionary in view.water.drops:check(view.water_safe_rect().encloses(Water.drop_bounds(drop)),"lens lifetime cannot cross header, rhythm or tension panels")
		host.toggle_pause();var clock: float=view.water.clock;view.advance_view(2)
		check(view.water.clock==clock and not view.water_lens.visible,"pause freezes water and keeps modal unobscured")
		host.toggle_pause();view.advance_view(.01)
		check(view.water.clock>clock,"resume advances the same water age")
		host.model.phase="completed";host.model.final_result={"passed":true};host.sent=true;host.running=false;view.advance_view(.01)
		for drop: Dictionary in view.water.drops:check(not Water.drop_bounds(drop).intersects(view.modal_rect().grow(6)),"terminal dialog is protected for the entire droplet path")
		host.restart();host.set_process(false)
		check(view.water.drops.is_empty() and view.water.splashes.is_empty() and not view.water_lens.visible,"real retry clears pools and shader visibility")
		host.begin();host.set_process(false)
		host.model=fixture();view.advance_view(0)
		for i in range(6):host.model.notes[i].judgment="good"
		view.advance_view(.016)
		check(not view.water.drops.is_empty(),"failure fixture starts with visible water")
		host.model.phase="failed";host._check_terminal();view.advance_view(.01)
		check(not host.running and view.water.drops.is_empty() and view.water.splashes.is_empty() and not view.water_lens.visible,"real stopped failure host still clears all water")
		host.queue_free();await process_frame
	print("LAKE_FISHING_WATER: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
