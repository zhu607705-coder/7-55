extends SceneTree
## Main keeps destination lifecycle, but coalesces same-page hidden UI rebuilds.
class FittedActivity extends Control:
	func configure_activity_layout(_extent: Vector2,_compact: bool) -> void: pass

var checks:=0
var failures:=0
var mounts:=0
var timed_actions:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func frames() -> void:
	for unused in 5: await process_frame
func timed_friend_fixture(state: Node,shell: Control) -> void:
	state.d.actOne.phase="friend_message_required"
	state.d.native.page="wechat";shell.mobile_world=false;shell._refresh()
	shell.phone_builder.friend_open=true;shell._refresh();await frames()
	check(shell.page_body.find_child("WechatFollowupQuestion",true,false)!=null,"timed C2 friend exchange is mounted")
func check_timed_pages(state: Node,shell: Control) -> void:
	shell.phone_builder.action_requested.connect(func(id,_value):
		if id=="c2_friend_exchange":timed_actions+=1)
	await timed_friend_fixture(state,shell)
	await create_timer(.8).timeout
	shell.mobile_world=true;shell._layout()
	var old:Node=shell.page_body.get_child(0)
	state.changed.emit();await frames()
	check(not is_instance_valid(old),"hidden timed app update destroys previous callback owner")
	await create_timer(1.5).timeout
	check(timed_actions==0 and state.d.actOne.phase=="friend_message_required","hidden change cancels original C2 callback deadline")
	shell.mobile_world=false;shell._layout()
	await create_timer(1.0).timeout
	check(timed_actions==1 and state.d.actOne.phase=="system_required","ordinary return preserves restarted C2 completion exactly once")
	await timed_friend_fixture(state,shell)
	await create_timer(.3).timeout
	shell.mobile_world=true;shell._layout()
	state.d.native.page="phone_home";state.changed.emit();await frames()
	var completed:=timed_actions
	await create_timer(2.3).timeout
	check(timed_actions==completed and state.d.actOne.phase=="friend_message_required","hidden navigation cancels departed C2 callback")
	await timed_friend_fixture(state,shell)
	await create_timer(.3).timeout
	shell.mobile_world=true;shell._layout()
	state.d=state.d.duplicate(true);state.d.actOne.phase="movement_required"
	state.changed.emit();await frames()
	completed=timed_actions
	await create_timer(2.3).timeout
	check(timed_actions==completed and state.d.actOne.phase=="movement_required","state replacement cancels callback from prior C2 phase")
	shell.mobile_world=false;shell._layout();await frames()
	check(timed_actions==completed,"return after reset does not revive cancelled callback")

func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("HIDDEN_PHONE_TEST_ISOLATION_REQUIRED");quit(2);return
	var state:=root.get_node("State")
	state.developer_mode=true;state.d=state.initial()
	var shell:Control=load("res://scenes/main.tscn").instantiate()
	root.add_child(shell);await frames()
	check(state.begin_checkpoint("c2-dorm-exit"),"ordinary chapter checkpoint is available")
	state.d.native.page="phone_home";state.d.runtimeMode="phone"
	shell.mobile_world=false;shell._refresh();await frames()
	shell.page_body.child_entered_tree.connect(func(_child):mounts+=1)
	shell.mobile_world=true;shell._layout()
	check(not shell.phone.visible,"world hides phone")
	var retained:Node=shell.page_body.get_child(0)
	var before:String=JSON.stringify(state.d)
	var start:=Time.get_ticks_usec()
	for unused in 20: shell._refresh()
	var retained_us:=Time.get_ticks_usec()-start
	check(mounts==0 and shell.page_body.get_child(0)==retained,"20 hidden updates reuse the mounted phone page")
	check(shell.phone_page_dirty,"hidden updates mark current page dirty")
	check(JSON.stringify(state.d)==before,"refresh does not mutate gameplay")
	check(shell.world.scene_id==state.d.native.scene,"world refresh still runs")
	# Force only the new guard off to measure the former rebuild path in the
	# same process, same page and same hidden scene. This is CPU wall time only.
	start=Time.get_ticks_usec()
	for unused in 20:
		shell.phone_scroll_page="";shell._refresh()
	var rebuild_us:=Time.get_ticks_usec()-start
	check(mounts==20,"baseline comparator really rebuilt all 20 pages")
	print("HIDDEN_PHONE_REBUILD_MEASUREMENT ",JSON.stringify({"iterations":20,"retainedMounts":0,"baselineMounts":mounts,"retainedUsec":retained_us,"baselineUsec":rebuild_us}))
	await frames()
	mounts=0
	# Hidden navigation must still execute builder route/reset hooks.
	state.d.native.page="settings";shell._refresh()
	check(shell.phone_builder.previous_page=="settings" and mounts==1,"hidden destination change preserves app routing")
	shell.phone_builder.settings_page="display"
	shell._refresh();shell._refresh()
	check(mounts==1,"same hidden destination is retained")
	state.d.native.page="phone_home";shell._refresh()
	state.d.native.page="settings";shell._refresh()
	check(shell.phone_builder.settings_page=="root","rapid hidden exit/return resets local settings navigation")
	state.d.phoneBattery.percent=63;shell._refresh()
	check(shell.phone_page_dirty,"latest hidden state waits for visibility")
	mounts=0
	# Simulate a surface return/cancellation that has no State.changed event.
	shell.mobile_world=false;shell._layout();shell._layout();await frames()
	check(shell.phone.visible and not shell.phone_page_dirty,"layout-only return flushes dirty phone")
	check(mounts==1,"rapid repeated layouts schedule one rebuild")
	check(shell.status_label.text.ends_with("63%"),"visible phone shows latest hidden state")
	mounts=0;shell._layout();await frames()
	check(mounts==0,"clean visible layout does not rebuild")
	# A scheduled visible flush must not build after the player returns to world.
	shell.mobile_world=true;shell._layout();shell._refresh()
	shell.mobile_world=false;shell._layout()
	shell.mobile_world=true;shell._layout();await frames()
	check(mounts==0 and shell.phone_page_dirty,"cancelled visibility retains dirty page without hidden rebuild")
	shell.mobile_world=false;shell._layout();await frames()
	check(mounts==1 and not shell.phone_page_dirty,"later visible return recovers after cancellation")
	# Reset/import may replace the entire state while remembering the same page.
	# Do not retain views or timers bound to the previous state owner.
	shell.mobile_world=true;shell._layout();mounts=0
	state.d=state.d.duplicate(true);shell._refresh()
	check(mounts==1 and is_same(shell.phone_page_state,state.d),"state replacement rebuilds even on the same hidden page")
	shell.mobile_world=false;shell._layout();await frames()
	# A fitted activity hides the phone even when mobile_world is false.
	mounts=0
	var activity:=FittedActivity.new();shell.add_child(activity);shell.active_game=activity
	shell._layout();shell._refresh();shell._refresh()
	check(not shell.phone.visible and mounts==0 and shell.phone_page_dirty,"fitted activity also coalesces hidden updates")
	shell.active_game=null;activity.queue_free();shell._layout();await frames()
	check(shell.phone.visible and mounts==1 and not shell.phone_page_dirty,"activity cancellation refreshes the phone once")
	await check_timed_pages(state,shell)
	shell.queue_free();await frames()
	print("HIDDEN_PHONE_REBUILD checks=",checks," failures=",failures)
	quit(1 if failures else 0)
