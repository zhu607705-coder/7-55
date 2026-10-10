extends SceneTree
## Isolated source-domain and real primary/backup regression. Requires State's
## production SaveDomainGuard hook; missing hook is an explicit failing test.
const Guard=preload("res://scripts/save_domain_guard.gd")
const Migration=preload("res://scripts/save_migration.gd")
var checks:=0
var failures:=0
var state: Node
var guard:=Guard.new()
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok: failures+=1; push_error("SAVE DOMAIN: "+label)
func put(value: Dictionary,path: String,replacement: Variant) -> void:
 var keys:=path.split(".")
 var parent: Dictionary=value
 for index in range(keys.size()-1): parent=parent[keys[index]]
 parent[keys[-1]]=replacement
func corrupt(path: String,value: Variant,label: String="") -> void:
 var invalid: Dictionary=state.initial()
 put(invalid,path,value)
 var before:=JSON.stringify(invalid)
 check(not guard.validate(invalid),"reject "+path+" "+label)
 check(JSON.stringify(invalid)==before,"validation never mutates "+path)
func run() -> void:
 if not OS.get_user_data_dir().begins_with("/tmp/"):
  push_error("Refusing domain persistence tests outside isolated /tmp HOME/XDG_DATA_HOME."); quit(2); return
 state=root.get_node("State")
 check(guard.validate(state.initial()),"initial complete source state validates: "+guard.failure)
 var source_path:=ProjectSettings.globalize_path("res://../src/core/SaveStore.ts")
 if FileAccess.file_exists(source_path):
  var manifest=JSON.parse_string(FileAccess.get_file_as_string(Guard.PATH))
  check(manifest.sourceSha256==FileAccess.get_sha256(source_path),"exported allowed domains match actual source hash")
 var migration:=Migration.new()
 for checkpoint in state.developer_checkpoints():
  var decoded: Dictionary=migration.decode({"version":35,"state":checkpoint.state},state.initial())
  check(decoded.get("ok",false),"source checkpoint normalizes: "+str(checkpoint.id))
  if decoded.get("ok",false): check(guard.validate(decoded.state),"source checkpoint domains: "+str(checkpoint.id)+" "+guard.failure)
 for path in Guard.ENUMS:
  corrupt(path,"unrecognized-story-value")
  corrupt(path,1,"numeric replacement")
  for allowed in guard.domains[Guard.ENUMS[path]]:
   var valid: Dictionary=state.initial(); put(valid,path,allowed)
   check(guard.validate(valid),"preserve known source value: "+path+"="+str(allowed))
 for path in Guard.NULLABLE_ENUMS:
  corrupt(path,"unrecognized-story-value")
  var valid: Dictionary=state.initial(); put(valid,path,null)
  check(guard.validate(valid),"nullable enum stays nullable: "+path)
 for path in Guard.ARRAY_ENUMS:
  corrupt(path,["unrecognized-story-value"])
  corrupt(path,[1],"numeric element")
  var valid: Dictionary=state.initial(); put(valid,path,guard.domains[Guard.ARRAY_ENUMS[path]].duplicate())
  check(guard.validate(valid),"preserve every known array value: "+path)
 for path in Guard.INLINE_ENUMS:
  corrupt(path,"unrecognized-story-value")
  for allowed in Guard.INLINE_ENUMS[path]:
   var valid: Dictionary=state.initial(); put(valid,path,allowed)
   check(guard.validate(valid),"preserve source inline discriminant: "+path+"="+str(allowed))
 for path in Guard.INTEGER_RANGES:
  var bounds: Array=Guard.INTEGER_RANGES[path]
  corrupt(path,bounds[0]-1,"underflow")
  corrupt(path,bounds[1]+1,"overflow")
  corrupt(path,float(bounds[0])+.5,"fraction")
  for boundary in bounds:
   var valid: Dictionary=state.initial(); put(valid,path,boundary)
   check(guard.validate(valid),"inclusive source bound: "+path+"="+str(boundary))
 for path in Guard.NONNEGATIVE_INTEGERS:
  corrupt(path,-1,"negative counter")
  corrupt(path,.5,"fractional counter")
 for path in ["wallet.campusCardCents","wallet.cashCents","chapter4.chaseAttempt","qizhenLake.journal.threadSeed"]:
  corrupt(path,-1); corrupt(path,.5); corrupt(path,9007199254740992.0,"unsafe integer")
 for path in ["qizhenLake.chaseDistance","qizhenLake.chaseBestDistance"]:
  corrupt(path,-1); corrupt(path,1001)
 corrupt("ui.brightness",-1); corrupt("ui.brightness",101)
 corrupt("qizhenLake.signRotations",[0,0]); corrupt("qizhenLake.signRotations",[0,0,4]); corrupt("qizhenLake.signRotations",[0,0,.5])
 corrupt("actOne.cc98Login.lockUntilMs",-1); corrupt("clockCalibration.selectedTargetSeconds",86400)
 for placement in [{"pieceId":"unknown","slotId":"morning_slot_01","orientation":"up"},{"pieceId":"desk_pair_01","slotId":"unknown","orientation":"up"},{"pieceId":"desk_pair_01","slotId":"morning_slot_01","orientation":"down"}]:
  corrupt("chapter4.room204Placements",[placement],"unknown placement domain")
 var placement: Dictionary=guard.room204.canonicalCompletePlacements[0]
 corrupt("chapter4.room204Placements",[placement,placement],"duplicate piece and slot")
 var permuted: Dictionary=state.initial()
 permuted.chapter4.room204Placements=guard.room204.canonicalCompletePlacements.duplicate(true)
 permuted.chapter4.room204Placements[0].slotId="morning_slot_02"
 permuted.chapter4.room204Placements[1].slotId="morning_slot_01"
 check(guard.validate(permuted),"source allows any unique piece-to-slot permutation, not only canonical recovery layout")
 var passthrough: Dictionary=state.initial()
 passthrough.native.future_safe_metadata={"text":"原样保留","proof":{"levels":[]}}
 passthrough.native.c4_stair_proof={"untouched":"guard does not grant or repair evidence"}
 passthrough.qizhenLake.journal.mainTitleId="source-valid-unknown-title"
 passthrough.qizhenLake.journal.mainStatusId="source-valid-unknown-status"
 var original:=JSON.stringify(passthrough)
 check(guard.validate(passthrough) and original==JSON.stringify(passthrough),"source nullable text and native proofs/metadata are never rewritten")
 # Use the production State path, so a missing hook cannot masquerade as coverage.
 var bad: Dictionary=state.initial(); bad.actOne.phase="unrecognized-story-value"
 check(not state.validate_snapshot(bad),"production State invokes the guard")
 if not state.validate_snapshot(bad):
  state.developer_mode=false
  state.d=state.initial(); check(state.save_game(),"valid first snapshot saves")
  state.d.native.page="weather"; check(state.save_game(),"second save leaves valid backup")
  var envelope=state._read_native_save(state.SAVE_PATH)
  envelope.state.actOne.phase="unrecognized-story-value"
  var file=FileAccess.open(state.SAVE_PATH,FileAccess.WRITE)
  file.store_string(JSON.stringify(envelope)); file.close()
  state.d=state.initial()
  check(state.load_game(),"corrupt primary recovers actual backup")
  check(state.d.actOne.phase=="prologue" and state.d.native.page=="alarm","recovery selects backup rather than malformed primary")
  check(not state.d.native.log.is_empty(),"real backup recovery records its notice")
  check(state.save_game(),"recovered valid state repairs primary")
 print("Native save domain guard: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
