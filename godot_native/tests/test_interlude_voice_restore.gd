extends "res://tests/test_interlude_evidence_controls.gd"
## Real Main audio ownership and actual-file imports in a disposable profile.
const BASELINE_SAVE := "user://voice-before-audition.json"

func voice_ids(snapshot: Dictionary) -> Array:
 return snapshot.native.get("c35_listened",[]) + snapshot.native.get("c35_reviewed",[])

func wait_for_heard(id: String) -> RefCounted:
 var session: RefCounted=main.media_host.current
 check(session!=null and session.clip_id==id and not session.fallback,"real audio owns requested clip: "+id)
 if session==null:return null
 var deadline:int=Time.get_ticks_msec()+int(session.duration_ms)+5000
 while not state.d.native.get("c35_listened",[]).has(id) and Time.get_ticks_msec()<deadline and session.phase=="playing":await process_frame
 check(state.d.native.get("c35_listened",[]).has(id),"real sampled audio earns its own receipt: "+id)
 return session

func run() -> void:
 if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
 state=root.get_node("State");state.developer_mode=false;state.d=state.initial()
 state.d.native.chapter=3;state.d.native.scene="";state.d.native.page="c35_recovery";state.d.runtimeMode="phone";state.d.qizhenLake.phase="complete";state.d.qizhenLake.active=true
 state.act("c35_begin");state.act("c35_journal","safe_return");state.open_page("c35_voice")
 root.size=Vector2i(430,860)
 main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await frames()
 # Headless has no focused OS window. Only that fact is injected; Controls,
 # AudioStreamPlayer, State import, Main reset and autosave remain real.
 main.media_host.setup(func()->Dictionary:
  var snapshot:Dictionary=main._read_runtime_state();snapshot.native.host.focused=true;return snapshot)
 check(state.validate_snapshot(state.d),"ordinary interlude fixture passes save validation")
 check(state.export_save(BASELINE_SAVE)==OK,"export a real save before any audition")
 var baseline:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASELINE_SAVE)).state
 check(voice_ids(baseline).is_empty(),"exported baseline contains no audio receipts")
 for disposition:String in ["playing","paused","finished","stopped"]:
  await click("▶","CLIP 91")
  var stale:RefCounted=await wait_for_heard("stone")
  if stale==null:break
  if disposition=="paused":await click("暂停","CLIP 91")
  elif disposition=="finished":
   var finish_deadline:int=Time.get_ticks_msec()+3000
   while stale.phase=="playing" and Time.get_ticks_msec()<finish_deadline:await process_frame
  elif disposition=="stopped":await back()
  check(stale.phase==disposition,"import interrupts the expected audio lifecycle: "+disposition)
  var imported:Dictionary=state.import_save(BASELINE_SAVE);await frames()
  check(imported.get("ok",false),"ordinary file import succeeds during "+disposition)
  check(main.media_host.current==null and stale.phase=="stopped","Main retires old audio during "+disposition+" import")
  check(voice_ids(state.d).is_empty(),"import must not transfer old audio evidence: "+disposition)
  check(state.d.native.log==baseline.native.log,"import does not append stale-session feedback: "+disposition)
  var saved:Dictionary=state._read_native_save(state.SAVE_PATH)
  check(not saved.is_empty() and voice_ids(saved.state).is_empty(),"actual autosave retains the imported audio evidence: "+disposition)
  check(state.get_view("c35_voice").get("media_session")==null,"new snapshot cannot expose the old runtime session")
  await click("▶","CLIP D7");await create_timer(.15).timeout
  check(voice_ids(state.d).is_empty(),"new audition cannot reapply the retired receipt: "+disposition)
  await back();state.open_page("c35_voice");await frames()
 # Same-snapshot navigation still retains an honestly earned receipt.
 await click("▶","CLIP 91");await wait_for_heard("stone");await back()
 check(state.d.native.get("c35_listened",[]).count("stone")==1,"ordinary Back retains current-snapshot evidence exactly once")
 check(state.save_game(),"current evidence remains saveable")
 check(state._read_native_save(state.SAVE_PATH).state.native.get("c35_listened",[]).count("stone")==1,"current evidence persists to the actual file")
 # A failed write restores the original snapshot and its current audition.
 state.open_page("c35_voice");await frames();await click("▶","CLIP D7")
 var interrupted:RefCounted=main.media_host.current
 var before_failed:Dictionary=state.d
 check(DirAccess.make_dir_absolute(state.SAVE_PATH+".tmp")==OK,"create isolated write obstruction")
 var rejected:Dictionary=state.import_save(BASELINE_SAVE)
 check(not rejected.get("ok",false),"write failure rejects import")
 check(is_same(state.d,before_failed) and state.d.native.get("c35_listened",[]).count("stone")==1,"failed import restores the exact snapshot and earned evidence")
 check(DirAccess.remove_absolute(state.SAVE_PATH+".tmp")==OK,"remove isolated write obstruction")
 check(interrupted!=null and interrupted==main.media_host.current and interrupted.phase=="playing","rejected import leaves the existing audition playing")
 var completed:RefCounted=await wait_for_heard("lake")
 check(completed==interrupted and state.d.native.get("c35_listened",[]).count("lake")==1,"the original audition earns one receipt after rollback")
 check(state.d.native.get("c35_listened",[]).count("stone")==1,"audition completion preserves the previously earned receipt")
 await main.shutdown();main.queue_free();await frames()
 var failures:int=checks.filter(func(row:Dictionary):return not row.pass).size()
 print("INTERLUDE_VOICE_RESTORE ",checks.size()," checks; ",failures," failures")
 quit(1 if failures else 0)
