extends SceneTree
## Reconstructed recovery-2 regression: 468 authored setter cases + 36 submissions.
const Library=preload("res://scripts/chapters/library022.gd")
var checks=0
var failures=0
var rows: Array=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1; rows.append({"check":label,"passed":ok})
	if not ok: failures+=1; push_error(label)
func fresh(row: Dictionary) -> Dictionary:
	var s: Dictionary=root.get_node("State").initial()
	s.native.chapter=2; s.native.page="tiyi"; s.actOne.phase="complete"; s.networkMode="cellular"
	s.ui.libraryFinalsPhase=row.phase
	s.ui.libraryFinalsPuzzle.investigationOpened=row.opened
	s.ui.libraryFinalsPuzzle.entranceRecordRead=true; s.ui.libraryFinalsPuzzle.archivedRuleRead=true
	s.ui.libraryFinalsPuzzle.archivedRuleBriefingSeen=true
	s.ui.libraryFinalsPuzzle.presenceProofCollected=row.passed
	return s
func report() -> void:
	var path=OS.get_environment("TIYI_SOURCE_REPORT")
	if path.is_empty(): path="user://tiyi-presence-source.json"
	var file=FileAccess.open(path,FileAccess.WRITE)
	if file==null: failures+=1; push_error("Cannot write report: "+path)
	else: file.store_string(JSON.stringify({"provenance":"reconstructed recovery-2","checks":checks,"failures":failures,"cases":rows},"\t")); file.close()
	print("TIYI_SOURCE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
func run() -> void:
	root.get_node("State").developer_mode=true
	var oracle: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/tiyi_audit_oracle.json"))
	for row: Dictionary in oracle.drafts:
		var s=fresh(row); var expected=s.duplicate(true)
		for key in row.puzzle: expected.ui.libraryFinalsPuzzle[key]=row.puzzle[key]
		var module=Library.new(); module.dispatch(s,"lib_audit_value",{"field":row.field,"value":row.value})
		check(JSON.parse_string(JSON.stringify(s))==JSON.parse_string(JSON.stringify(expected)),"source draft "+str(checks)+" "+JSON.stringify([row.phase,row.opened,row.passed,row.field,row.value]))
	for row: Dictionary in oracle.submissions:
		var s=fresh(row); var expected=s.duplicate(true)
		for key in row.puzzle: expected.ui.libraryFinalsPuzzle[key]=row.puzzle[key]
		for key in row.items: expected.items[key]=row.items[key]
		var module=Library.new(); module.dispatch(s,"lib_audit",{"arrival":str(int(row.values.arrivalMinutes)),"notice":str(int(row.values.publicNoticeFloor)),"proofs":str(int(row.values.proofCount))})
		check(JSON.parse_string(JSON.stringify(s))==JSON.parse_string(JSON.stringify(expected)),"source submit "+str(checks)+" "+JSON.stringify([row.phase,row.opened,row.passed,row.values]))
	report()
