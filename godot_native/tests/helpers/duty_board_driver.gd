extends RefCounted
const Duty=preload("res://scripts/games/chapter4_duty_board.gd")
static func events()->Array:
	return [{"kind":"swap","a":"main_elevator","b":"classroom_104"},{"kind":"swap","a":"main_elevator","b":"classroom_105"},{"kind":"flip","id":"main_elevator"},{"kind":"flip","id":"classroom_104"}]
static func prepare(controller:RefCounted,state:Dictionary)->void:
	for event:Dictionary in events():controller.dispatch(state,"c4_duty_event",event)
static func point(tree:SceneTree,board:Control,at:Vector2,touch:bool,pressed:bool)->void:
	var global:Vector2=board.get_global_transform_with_canvas()*(at*board.factor())
	if touch:
		var e:=InputEventScreenTouch.new();e.index=0;e.position=global;e.pressed=pressed;tree.root.push_input(e,true)
	else:
		var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=global;e.pressed=pressed;tree.root.push_input(e,true)
	for i:int in 3:await tree.process_frame
static func gesture(tree:SceneTree,panel:Control,a:Vector2,b:Vector2,touch:bool)->void:
	var board:Control=panel.workbench
	panel.scroll.ensure_control_visible(board)
	for i:int in 3:await tree.process_frame
	await point(tree,board,a,touch,true)
	await point(tree,board,b,touch,false)
static func solve(tree:SceneTree,panel:Control,touch:bool)->void:
	for event:Dictionary in events():
		var board:Control=panel.workbench
		var order:Array=panel.session.draft.dutyOrder
		var a:Vector2=board.row_rect(order.find(event.get("a",event.get("id")))).get_center()
		var b:Vector2=board.row_rect(order.find(event.b)).get_center() if event.kind=="swap" else a
		await gesture(tree,panel,a,b,touch)
static func stamp(tree:SceneTree,panel:Control,touch:bool)->void:
	var at:Vector2=panel.workbench.seal_rect().get_center()
	await gesture(tree,panel,at,at,touch)
