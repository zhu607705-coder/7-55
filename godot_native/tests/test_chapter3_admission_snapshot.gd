extends SceneTree
## The animation layer observes admission; it must not retain the complete save,
## alias live state, invent a gate event on load, or restart an accepted effect.
const Layers=preload("res://scripts/ui/chapter3_world_layers.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("ADMISSION SNAPSHOT: "+label)
func initial(scene:String="theater_interior",admitted:bool=false)->Dictionary:
	var s:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":3,"scene":scene,"page":"phone_home","mode":"light","player":{"x":665,"y":790},"settings":{"reduced_motion":false},"c3_tray_slots":[]}
	s.canteenHunt.active=true;s.canteenHunt.phase="tray_search";s.canteenHunt.entryPaperEscaped=true
	s.theaterHunt.active=true;s.theaterHunt.admitted=admitted
	s.theaterHunt.phase="program_search" if admitted else "entry_ticket"
	return s
func snapshot(layer:RefCounted,s:Dictionary,label:String)->void:
	check(layer.previous_state.keys()==["theaterHunt"],label+" snapshots only the used domain")
	check(layer.previous_state.theaterHunt.keys()==["admitted"],label+" snapshots only the used fact")
	check(layer.previous_state.theaterHunt.admitted==s.theaterHunt.admitted,label+" observes current admission")
func sync_without_write(layer:RefCounted,s:Dictionary,label:String,scene_changed:bool=false)->void:
	var before:String=JSON.stringify(s)
	layer.sync(s,scene_changed)
	check(JSON.stringify(s)==before,label+" does not mutate controller state")
	snapshot(layer,s,label)
func run()->void:
	for admitted:bool in [false,true]:
		for direct_tick:bool in [false,true]:
			var s:Dictionary=initial("theater_interior",admitted)
			var layer:=Layers.new()
			check(layer.previous_state.is_empty(),"uninitialized snapshot is empty")
			var before:String=JSON.stringify(s)
			if direct_tick:layer.tick(.016,s)
			else:layer.sync(s)
			check(is_inf(layer.admission_ms),"first sync/tick of existing admission never fabricates a new admission")
			check(JSON.stringify(s)==before,"first sync/tick is non-authoritative")
			snapshot(layer,s,"first observation")
	var s:Dictionary=initial()
	var layer:=Layers.new()
	sync_without_write(layer,s,"initial false")
	s.theaterHunt.admitted=true;s.theaterHunt.phase="program_search"
	check(not layer.previous_state.theaterHunt.admitted,"live mutation cannot alias the saved admission observation")
	sync_without_write(layer,s,"earned false-to-true")
	check(layer.admission_ms==0,"false-to-true starts effect exactly once")
	layer.tick(.016,s)
	check(is_equal_approx(layer.admission_ms,16),"first tick advances the existing effect")
	sync_without_write(layer,s,"repeat true")
	check(is_equal_approx(layer.admission_ms,16),"repeated true does not restart effect")
	layer.tick(.016,s)
	check(is_equal_approx(layer.admission_ms,32),"subsequent tick advances rather than restarting")
	# A replacement save in the same scene behaves like the old detached copy.
	var replacement:Dictionary=s.duplicate(true)
	replacement.phoneBattery.percent=1;replacement.brightness=37
	sync_without_write(layer,replacement,"same-scene save replacement true")
	check(is_equal_approx(layer.admission_ms,32),"unrelated save facts and equal admission do not restart")
	replacement.theaterHunt.admitted=false
	check(layer.previous_state.theaterHunt.admitted,"replacement rollback does not retroactively mutate snapshot")
	sync_without_write(layer,replacement,"state rollback false")
	check(is_equal_approx(layer.admission_ms,32),"true-to-false alone is not a new admission effect")
	replacement.theaterHunt.admitted=true
	sync_without_write(layer,replacement,"readmitted after rollback")
	check(layer.admission_ms==0,"false-to-true after rollback remains observable")
	# Explicit refresh and actual departures reset, even if the new saved state
	# already has admission. They must never replay the gate scan on loading.
	for destination:String in ["dorm_hub","qizhen_lake","theater_interior"]:
		var loaded:Dictionary=initial(destination,true)
		layer.admission_ms=81
		sync_without_write(layer,loaded,"implicit scene switch "+destination)
		check(is_inf(layer.admission_ms),"scene switch resets admission presentation without synthesizing an edge")
		layer.admission_ms=57
		sync_without_write(layer,loaded,"explicit same-scene reload "+destination,true)
		check(is_inf(layer.admission_ms),"explicit reload resets admission presentation without replay")
		loaded.theaterHunt.admitted=false;layer.sync(loaded)
		loaded.theaterHunt.admitted=true;layer.sync(loaded)
		check(layer.admission_ms==0,"later false-to-true remains detectable after "+destination+" reset")
	# Shared domains needed by neighboring effects remain independently tracked.
	s=initial();layer=Layers.new();layer.sync(s)
	s.theaterHunt.admitted=true;s.theaterHunt.phase="program_search";layer.sync(s)
	s.theaterHunt.collectedProgramIds=["opening"];layer.sync(s)
	check(layer.program_flights.size()==1,"existing collected-program edge still emits one flight")
	layer.tick(.016,s);var flight_elapsed:float=layer.program_flights[0].elapsed
	s.phoneBattery.percent=0;layer.sync(s)
	check(layer.program_flights.size()==1 and is_equal_approx(layer.program_flights[0].elapsed,flight_elapsed),"unrelated mutation does not restart or duplicate program flight")
	var detached:Dictionary=layer.previous_state
	detached.theaterHunt.admitted=false
	check(s.theaterHunt.admitted,"snapshot mutation cannot write into controller state")
	print("Chapter 3 admission snapshot: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
