extends SceneTree
## Render actual native phone surfaces at both logical and compact widths.
var checks := 0
var failures := 0
var shell: Control
var state: Node
var captured: Array=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("ZH_TEXT_DISPLAY: "+label)
func frames(count: int=4) -> void:
	for i in range(count): await process_frame
func labels(node: Node) -> Array:
	var out: Array=[]
	if node is Label: out.append(node)
	for child in node.get_children(): out.append_array(labels(child))
	return out
func verify_copy(expected: Array, tag: String) -> void:
	var all:=labels(shell.page_body)
	for value: String in expected:
		var found=all.filter(func(x): return x.text==value)
		check(not found.is_empty(),tag+" uses revised copy: "+value)
		for label: Label in found:
			check(label.get_line_count()<=label.get_visible_line_count(),tag+" no clipped lines: "+value)
			var start=label.get_global_transform_with_canvas()*Vector2.ZERO
			var end=label.get_global_transform_with_canvas()*label.size
			var phone_start=shell.phone.get_global_transform_with_canvas()*Vector2.ZERO
			var phone_end=shell.phone.get_global_transform_with_canvas()*shell.phone.size
			check(start.x>=phone_start.x-1 and end.x<=phone_end.x+1,tag+" horizontal bounds: "+value)
			check(start.y>=phone_start.y-1 and end.y<=phone_end.y+1,tag+" vertical bounds: "+value)
			captured.append({"text":value,"size":label.size,"lines":label.get_line_count(),"visible":label.get_visible_line_count()})
func run() -> void:
	state=root.get_node("State");state.developer_mode=true
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames();shell.set_process(false)
	for viewport: Vector2i in [Vector2i(430,860),Vector2i(390,844),Vector2i(1280,720)]:
		root.size=viewport;shell.size=Vector2(viewport)
		state.d=state.initial();state.d.native.page="desktop";shell._refresh();await frames()
		verify_copy(["早八快上课了。不得不说，你还敢赖床，心理素质真硬。"],"wake "+str(viewport))
		state.d.native.wake_warned=true;shell._refresh();await frames()
		verify_copy(["还睡？！\n早八要迟到了！！"],"flash "+str(viewport))
		state.d=state.initial();state.d.native.page="wechat";state.d.flags.codeScattered=false;shell._refresh();await frames()
		shell.phone_builder.friend_open=true;shell._refresh();await frames()
		verify_copy(["速来！老头突然开始点名了，学在浙大雷达签到！","等等——人还在被窝里就想隔空签到？","想得美！这分我今天扣定了！","签到码给你拆碎咯，慢慢找去吧哈哈哈！"],"friend attack "+str(viewport))
		state.d.flags.codeScattered=true;state.d.actOne.phase="system_required";shell._refresh();await frames()
		verify_copy(["签上了吗？？","没赶上。但我刚把弹窗卡死了，正在逼系统给我改后台。","？你没睡醒吧"],"friend reply "+str(viewport))
		check(shell.phone.size==Vector2(430,860),"phone frame preserved")
	await shell.audio_director.shutdown();shell.queue_free();await frames()
	print("ZH_TEXT_DISPLAY ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
