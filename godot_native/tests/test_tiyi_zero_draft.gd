extends SceneTree
## Source's inherited arrival 0/default ambiguity is documented, not schema-expanded.
const Builder=preload("res://scripts/ui/phone_pages.gd")
var checks=0
var failures=0
var cases: Array=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1; cases.append({"check":label,"passed":ok})
	if not ok: failures+=1; push_error(label)
func run() -> void:
	var state=root.get_node("State"); state.developer_mode=false; state.d=state.initial()
	state.d.native.chapter=2; state.d.actOne.phase="complete"; state.d.networkMode="cellular"; state.d.ui.libraryFinalsPhase="evidence_gathering"
	state.d.ui.libraryFinalsPuzzle.investigationOpened=true; state.get_phone_entry_session()
	var helper=Builder.new().tiyi_presence
	helper._sync(state.d.ui.libraryFinalsPuzzle)
	check(helper.draft.arrival=="5","unset source zero displays authored default 5")
	var keys=state.d.ui.libraryFinalsPuzzle.keys()
	helper.draft.arrival="0"; helper.observed.arrival=0
	state.act("lib_audit_value",{"field":"arrival","value":0})
	helper._sync(state.d.ui.libraryFinalsPuzzle)
	check(helper.draft.arrival=="0","explicit in-session zero remains visible")
	check(state.d.ui.libraryFinalsPuzzle.auditArrivalMinutes==0,"controller accepts legal zero")
	check(state.d.ui.libraryFinalsPuzzle.keys()==keys,"no persistent bookkeeping or schema expansion")
	state.open_page("phone_home"); helper.reset(); state.open_page("tiyi"); helper._sync(state.d.ui.libraryFinalsPuzzle)
	check(helper.draft.arrival=="5","fresh app mount mirrors source zero fallback to 5")
	check(state.save_game(),"ordinary save accepts legal zero")
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://save.json"))
	check(saved.state.ui.libraryFinalsPuzzle.auditArrivalMinutes==0,"ordinary save stores exactly zero")
	check(state.load_game(),"ordinary reload accepts zero save")
	check(state.d.ui.libraryFinalsPuzzle.auditArrivalMinutes==0,"reloaded model preserves stored zero")
	helper._sync(state.d.ui.libraryFinalsPuzzle)
	check(helper.draft.arrival=="5","fresh reloaded view mirrors source zero fallback to 5")
	check(not state.d.ui.libraryFinalsPuzzle.presenceProofCollected,"draft never earns presence proof")
	check(state.d.ui.libraryFinalsPuzzle.auditAttemptCount==0,"draft never consumes a submission attempt")
	var path=OS.get_environment("TIYI_ZERO_REPORT")
	if path.is_empty(): path="user://tiyi-zero-draft.json"
	var file=FileAccess.open(path,FileAccess.WRITE)
	if file==null: failures+=1; push_error("Cannot write report: "+path)
	else: file.store_string(JSON.stringify({"provenance":"reconstructed recovery-2","checks":checks,"failures":failures,"cases":cases},"\t")); file.close()
	print("TIYI_ZERO: ",checks," checks; ",failures," failures"); quit(1 if failures else 0)
