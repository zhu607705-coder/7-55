extends Control
## Source App.tsx queue/recovery + LibraryStoryOverlay playback. Controller owns facts.
const View=preload("res://scripts/presentation/library_story_view.gd")
var read_state: Callable
var provider: Callable
var dispatch: Callable
var cue: Callable
var runtime_reader: Callable
var current: RefCounted
var view: Control
var completion_sent: bool=false
func setup(state_reader: Callable,session_provider: Callable,action_sink: Callable,cue_sink: Callable=Callable(),runtime_state_reader: Callable=Callable()) -> void:
	read_state=state_reader; provider=session_provider; dispatch=action_sink; cue=cue_sink; runtime_reader=runtime_state_reader
	process_priority=60; mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view=View.new(); add_child(view); view.advance.connect(_advance)
func blocks_input() -> bool:
	return current!=null and current.status in ["issued","playing","complete"]
func _focused() -> bool:
	if not runtime_reader.is_valid(): return true
	return bool(runtime_reader.call().get("native",{}).get("host",{}).get("focused",true))
func _process(delta: float) -> void:
	if is_visible_in_tree(): tick(delta*1000,_focused())
func tick(delta_ms: float,focused: bool=true) -> void:
	if not read_state.is_valid() or not provider.is_valid(): return
	var s: Dictionary=read_state.call()
	if current!=null and (not current.valid(s) or current.status=="cancelled"): reset()
	var issued: RefCounted=provider.call(minf(delta_ms,100) if focused else 0)
	if current==null and issued!=null and issued.attach(s,self):
		current=issued; completion_sent=false; view.session=current; view.move_to_front(); move_to_front()
	if current==null: view.session=null; view.tick(); return
	current.frame(s,delta_ms,self,focused); view.tick(); _flush_cues()
	if current.status=="complete" and not completion_sent:
		completion_sent=true
		var finished: RefCounted=current
		dispatch.call("lib_story_complete",finished)
		if finished.status=="consumed":
			if cue.is_valid(): cue.call("library_story_finished",{"sequenceId":finished.sequence_id})
		else: finished.cancel()
		current=null; view.session=null; view.tick()
func _advance() -> void:
	if current==null or not _focused(): return
	current.advance(read_state.call(),self); tick(0,_focused())
func _flush_cues() -> void:
	if current!=null:
		for event: Dictionary in current.take_cues():
			if cue.is_valid(): cue.call(event.id,event.payload)
func reset() -> void:
	if current!=null: current.cancel()
	current=null; completion_sent=false
	if is_instance_valid(view): view.session=null; view.tick(); view.last_sequence=""
func _exit_tree() -> void: reset()
