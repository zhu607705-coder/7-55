extends SceneTree
## Source defaults and repeated DEV fixtures must never alias live state containers.
var checks:=0
var failures:=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("CHECKPOINT ISOLATION: "+label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var state=root.get_node("State")
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"formal-save probe is isolated")
	if failures: quit(1); return
	var base: Dictionary={"known":[],"existing":{"defaults":[0]},"scalar":1}
	var incoming: Dictionary={"known":[[1],{"values":[2]}],"unknown":{"nested":[{"label":"source"}]},"existing":{"overrides":[3]},"scalar":5,"bool":false,"nullable":null,"text":"原文"}
	var base_before:=JSON.stringify(base); var incoming_before:=JSON.stringify(incoming)
	var merged: Dictionary=state.merge_defaults(base,incoming)
	check(merged.scalar==5 and merged.bool==false and merged.nullable==null and merged.text=="原文","scalar and null values are preserved exactly")
	check(merged.existing.defaults==[0] and merged.existing.overrides==[3],"nested defaults and incoming keys both survive")
	merged.known[0].append(8); merged.known[1].values.append(9)
	merged.unknown.nested[0].label="run-only"; merged.existing.overrides.append(4); merged.existing.defaults.append(1)
	check(JSON.stringify(incoming)==incoming_before,"all incoming containers are deeply isolated")
	check(JSON.stringify(base)==base_before,"fallback containers remain unchanged")
	incoming.known[0].append(22); incoming.unknown.nested[0].label="source-changed"
	check(merged.known[0]==[1,8] and merged.unknown.nested[0].label=="run-only","later source mutations cannot change live state")
	state.developer_mode=false; state.d=state.initial()
	check(state.save_game(),"valid formal baseline persists before DEV")
	var formal:=JSON.stringify(state.d)
	var save_hash:=FileAccess.get_sha256(state.SAVE_PATH)
	var source_fixtures: Array=state.developer_checkpoints()
	var source_before:=JSON.stringify(source_fixtures).sha256_text()
	for fixture: Dictionary in source_fixtures:
		check(state.begin_checkpoint(str(fixture.id)),"first exact source visit "+str(fixture.id))
		var clue_before: Array=state.d.qizhenLake.mapClueIds.duplicate(true)
		var facts_before: Array=state.d.chapter4.factIds.duplicate(true)
		# Deliberate DEV-only mutation, never an accepted story action/proof.
		state.d.qizhenLake.mapClueIds.append("run-only")
		state.d.chapter4.factIds.append("run-only")
		check(state.begin_checkpoint(str(fixture.id)),"repeat source visit "+str(fixture.id))
		check(state.d.qizhenLake.mapClueIds==clue_before and state.d.chapter4.factIds==facts_before,"repeat restores original independent arrays "+str(fixture.id))
	check(JSON.stringify(source_fixtures).sha256_text()==source_before,"all117 cached authored snapshots remain byte-equivalent")
	check(not state.save_game(),"DEV cannot overwrite formal save")
	check(FileAccess.get_sha256(state.SAVE_PATH)==save_hash,"formal save bytes remain unchanged")
	state.restore_formal()
	check(not state.developer_mode and JSON.stringify(state.d)==formal,"leaving DEV restores exact formal state")
	print("Checkpoint isolation: ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)
