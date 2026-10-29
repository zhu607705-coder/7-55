extends Node
## Local review entry only. Production entry remains scenes/entry.tscn.
func _ready()->void:
	var local_review=false
	if OS.has_feature("web"):
		local_review=bool(JavaScriptBridge.eval("location.hostname==='127.0.0.1' && location.pathname.endsWith('/geometry.html')",true))
	if local_review:
		State.story_reset.emit();State.d=State.initial();State.developer_mode=true
		State.d.native.chapter=2;State.d.native.scene="library_interior";State.d.runtimeMode="rpg";State.d.rpgScene="library_interior"
		State.d.rpgCheckpoint="library_entrance";State.d.actOne.phase="complete";State.d.ui.libraryFinalsPhase="evidence_gathering"
		State.d.native.positions={"library_interior:":{"x":1018.0,"y":280.0}}
	if local_review and not await WebContent.ensure_state(State.d):return
	var main=load("res://scenes/main.tscn").instantiate();add_child(main)
	if local_review:main._show_world_mobile.call_deferred()
