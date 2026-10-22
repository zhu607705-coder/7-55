extends SceneTree
## Catalogue feedback is read-only once earned; first-grant gates stay unchanged.
const Library=preload("res://scripts/chapters/library022.gd")
const CORRECT="three-minute-leave-method"
const MISSING="还没有经过核验的馆藏搜索记录。"
var checks=0
var failures=0
var library=Library.new()
var source: Dictionary
var records: Dictionary={}
var results: Array=[]

func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("CATALOGUE REPEAT: "+message)
func fresh() -> Dictionary:
	var s: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":2,"scene":"library_interior","page":"library_catalog","mode":"light","settings":{}}
	s.actOne.phase="complete"; s.actOne.cc98Login.authenticated=true; s.networkMode="campus_wifi"
	s.ui.libraryFinalsPhase="evidence_gathering"
	return s
func acknowledge(s: Dictionary,id: String) -> void:
	var session=library.story_session(s)
	check(session!=null and session.sequence_id==id,"ordinary source dialogue is issued: "+id)
	if session==null: return
	check(session.attach(s,self),"source dialogue attaches to test host")
	for line in session.lines: session.advance(s,self)
	check(library.dispatch(s,"lib_story_complete",session).get("story_finished","")==id,"source dialogue completes normally")
func repeat_read_only(s: Dictionary,id: String,expected: String) -> void:
	var before=JSON.stringify(s)
	var response: Dictionary=library.dispatch(s,"lib_catalog_select",id)
	check(response.get("message","")==expected,"repeat feedback matches actual record/proof: "+id)
	check(JSON.stringify(s)==before,"repeat preserves complete saved state: "+id)
	check(library.story_session(s)==null,"repeat queues no acquisition story: "+id)
	check(not response.has("page") and not response.has("scene") and not response.has("game"),"repeat has no navigation or game side effect")
func run() -> void:
	root.get_node("State").developer_mode=true
	source=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/library-finals.content.json"))
	for record: Dictionary in source.library.catalogResults: records[record.id]=record
	var already="已获得线索：索书号 %s。" % records[CORRECT].callNumber
	var s=fresh()
	# The source investigation/terminal/search/selection path still earns the item once.
	s.ui.libraryFinalsPuzzle.occupancyNoteCollected=true; s.items.occupancyNote=true
	library.dispatch(s,"lib_investigate","occupancyNote"); acknowledge(s,"cc98_occupation_post_opened")
	library.dispatch(s,"lib_catalog_terminal")
	library.dispatch(s,"lib_catalog_search",source.library.catalogQuery)
	check(s.ui.libraryFinalsPuzzle.catalogSearchCompleted,"ordinary exact search earns its proof")
	var acquired=library.dispatch(s,"lib_catalog_select",CORRECT)
	check(acquired.message=="获得索书号 I247.55 / 755。" and s.items.callNumber755 and s.ui.libraryFinalsPuzzle.callNumberCollected,"first valid selection retains original acquisition behavior")
	acknowledge(s,"library_catalog_match_found")
	for i in range(3): repeat_read_only(s,CORRECT,already)
	for id: String in records:
		if id!=CORRECT: repeat_read_only(s,id,str(records[id].note))
	library.dispatch(s,"lib_shelf")
	check(not s.items.callNumber755 and s.ui.libraryFinalsPuzzle.archivedRuleCollected and s.items.archivedLeaveRule,"ordinary shelf consumes755 and grants its existing rule document")
	for i in range(3): repeat_read_only(s,CORRECT,already)
	check(not s.items.callNumber755 and s.ui.libraryFinalsPuzzle.clueIds.count("call_number_755")==1,"repeat after consumption never recreates755 or duplicates the clue")
	for id: String in records:
		if id!=CORRECT: repeat_read_only(s,id,str(records[id].note))
	repeat_read_only(s,"missing-record","没有找到该馆藏条目。")
	# Test the original grant predicate across phase, proof, durable acquisition,
	# inventory presence and every record, including an unrecognized record.
	var ids=records.keys()+["missing-record"]
	for phase: String in ["library_entered","evidence_gathering","top_ten_rising","pass_ready"]:
		for searched: bool in [false,true]:
			for collected: bool in [false,true]:
				for held: bool in [false,true]:
					for id: String in ids:
						var value=fresh(); value.ui.libraryFinalsPhase=phase
						value.ui.libraryFinalsPuzzle.catalogSearchCompleted=searched
						value.ui.libraryFinalsPuzzle.callNumberCollected=collected
						value.items.callNumber755=held
						if collected: value.ui.libraryFinalsPuzzle.clueIds=["call_number_755"]
						var before=JSON.stringify(value)
						var response: Dictionary=library.dispatch(value,"lib_catalog_select",id)
						var grants=phase=="evidence_gathering" and searched and not collected and id==CORRECT
						var actual_grant=not collected and value.ui.libraryFinalsPuzzle.callNumberCollected
						check(actual_grant==grants,"original first-grant predicate: %s/%s/%s/%s/%s" % [phase,searched,collected,held,id])
						if grants:
							check(value.items.callNumber755 and value.ui.libraryFinalsPuzzle.clueIds.count("call_number_755")==1,"valid initial selection grants exactly the original item/clue")
							check(library.story_session(value)!=null,"only first valid acquisition requests its source story")
						else:
							check(JSON.stringify(value)==before,"non-grant combination leaves complete state unchanged")
							check(library.story_session(value)==null,"non-grant combination never queues acquisition")
							var message=str(response.get("message",""))
							if collected and id==CORRECT: check(message==already,"durable acquired clue is acknowledged independently of consumed inventory")
							elif not searched: check(message==MISSING,"missing search still blocks all first acquisitions/selections")
							elif id!=CORRECT: check(message==str(records[id].note) if records.has(id) else message=="没有找到该馆藏条目。","proven search reports record feedback, never missing search")
							else: check(message=="当前无法领取这条馆藏线索。","wrong phase preserves grant gate without claiming proven search is missing")
						results.append({"phase":phase,"searched":searched,"collected":collected,"held":held,"record":id,"grant":actual_grant})
	var out=OS.get_environment("UI_QA_REPORT")
	if not out.is_empty():
		var file=FileAccess.open(out,FileAccess.WRITE); file.store_string(JSON.stringify({"checks":checks,"failures":failures,"grantMatrix":results},"\t")); file.close()
	print("LIBRARY_CATALOG_REPEAT: ",checks," checks; ",failures," failures; ",results.size()," grant combinations")
	quit(1 if failures else 0)
