extends Node
## The same floor and workbench controllers, in a separate no-autoload project.
var host:SubViewportContainer
var world:Node2D
func _ready()->void:
	host=SubViewportContainer.new();host.size=Vector2(960,540);host.stretch=false;add_child(host)
	var viewport:=SubViewport.new();viewport.size=Vector2i(960,540);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;host.add_child(viewport)
	world=preload("res://campuses/future_learning_center/scripts/floor_view.gd").new();viewport.add_child(world)
	get_tree().root.size_changed.connect(fit);fit()
	world.load_floor(2)
	var area:=OS.get_environment("FLC_REVIEW_AREA")
	if OS.has_feature("web"):area=str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('area') || ''"))
	if area=="locker":
		world.load_floor(3)
		if not world.set_foot(world.locker_approach()):push_error("Locker review spawn is blocked")
		return
	if area=="coupling":
		world.load_floor(3)
		if not world.set_foot(world.coupling_approach()):push_error("Coupling review spawn is blocked")
		return
	if area=="pantry":
		world.load_floor(3)
		if not world.set_foot(world.pantry_approach()):push_error("Pantry review spawn is blocked")
		return
	if area=="team":
		if not world.set_foot(world.signal_sync_approach()):push_error("Team review spawn is blocked")
		return
	if area in ["solar","robotics"]:
		if not world.set_foot(world.motion_approach(area)):push_error("Motion lab review spawn is blocked")
		return
	var puzzle_area:=area.trim_prefix("puzzle:")
	if puzzle_area in world.PuzzleAnchors:
		world.load_floor(int(world.PuzzleAnchors[puzzle_area][2]))
		var approach:Vector2=world.puzzle_approach(puzzle_area)
		if approach.is_finite():world.set_foot(approach)
		else:push_error("Puzzle review approach is blocked: "+puzzle_area)
		return
	if area=="stairs":
		world.load_floor(3)
		var landing:Dictionary=world.data.transits.filter(func(t:Dictionary)->bool:return t.id=="northeast_stair")[0]
		world.set_foot(Vector2(landing.arrival[0],landing.arrival[1]));world.open_transit();return
	var point:Array=world.data.workshopReference.capture
	if not world.set_foot(Vector2(point[0],point[1])):push_error("Workshop review spawn is blocked")
func fit()->void:
	var ratio:float=minf(get_viewport().size.x/960.0,get_viewport().size.y/540.0)
	host.scale=Vector2.ONE*ratio;host.position=(Vector2(get_viewport().size)-Vector2(960,540)*ratio)/2
