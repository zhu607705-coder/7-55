extends SceneTree
## Exact pre-optimization native algorithm, not a second progression authority.
const Navigation=preload("res://scripts/games/chapter4_guard_navigation.gd")
const BASELINE="res://tests/fixtures/chapter4_guard_navigation_baseline.gd.source.txt"
const BASELINE_SHA="9fdd07012a8216eaf2dc4548955a121eb9cdd9ffe02c400b80ec49acc4f074dc"
var checks:=0
var failures:=0
class Counted extends Navigation:
	var line_calls:=0
	func line(a:Vector2,b:Vector2)->bool:
		line_calls+=1
		return super.line(a,b)
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:run.call_deferred()
func run()->void:
	check(FileAccess.get_sha256(BASELINE)==BASELINE_SHA,"Original navigation oracle retains its exact source bytes")
	var original:=GDScript.new();original.source_code=FileAccess.get_file_as_string(BASELINE)
	check(original.reload()==OK,"Original navigation oracle compiles independently")
	var world:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json")).worlds.duan_yongping_temporal_maze
	var timing:Array=[]
	for floor_data:Dictionary in world.layout.floors:
		var nav:=Counted.new();var old:RefCounted=original.new()
		nav.setup(floor_data.staticCollisions);old.setup(floor_data.staticCollisions)
		check(nav.open==old.open,"Every source grid cell retains identical clearance on "+str(floor_data.storyFloor))
		# Includes exact source-wall boundaries and the legal-player/illegal-nav
		# sliver that previously performed a full graph scan on every frame.
		var points:Array=[Vector2(590,724),Vector2(1001,214),Vector2(622,331.6875),Vector2(622.125,331.6875),Vector2(622.25,281.6875),Vector2(614,331.6875),Vector2(624,420),Vector2(12,10),Vector2(1660,931),Vector2(11.999,10)]
		for wall:Dictionary in floor_data.staticCollisions.slice(0,5):
			for delta:float in [-.001,0,.001]:points.append(Vector2(float(wall.x)-10+delta,float(wall.y)+float(wall.height)*.5))
		for p:Vector2 in points:
			check(nav.nearest(p)==old.nearest(p),"Nearest cell/tie/fallback remains exact at %s %s"%[floor_data.storyFloor,p])
		# Ties between two/four absolute nearest lattice points retain the old
		# ascending-id decision; blocked nearest candidates exercise fallback.
		for p:Vector2 in [Vector2(588,728),Vector2(595,728),Vector2(588,721),Vector2(1001,217)]:
			check(nav.nearest(p)==old.nearest(p),"Equal-distance grid tie remains exact at %s %s"%[floor_data.storyFloor,p])
		for target:Vector2 in [Vector2(590,612),Vector2(624,420),Vector2(622.125,331.6875),Vector2(1001,214)]:
			var began:=Time.get_ticks_usec();var expected:Array=old.path(Vector2(590,724),target);var old_us:=Time.get_ticks_usec()-began
			began=Time.get_ticks_usec();var result:Array=nav.path(Vector2(590,724),target);var cold_us:=Time.get_ticks_usec()-began
			began=Time.get_ticks_usec();var again:Array=nav.path(Vector2(590,724),target);var warm_us:=Time.get_ticks_usec()-began
			check(result==expected and again==expected,"Cold/warm path nodes and smoothing remain exact at %s %s"%[floor_data.storyFloor,target])
			timing.append({"floor":floor_data.storyFloor,"target":[target.x,target.y],"nodes":result.size(),"originalUs":old_us,"coldUs":cold_us,"warmUs":warm_us})
		if floor_data.storyFloor=="A1":
			nav.line_calls=0;nav.nearest(Vector2(590,724))
			check(nav.line_calls<=1,"Absolute nearest reachable grid point avoids the full-grid scan")
			nav.line_calls=0;nav.nearest(Vector2(622.125,331.6875))
			check(nav.line_calls==0,"Illegal nav foot point is rejected before any candidate line scan")
		# Exhaust all directed adjacent edges of each authored floor, including
		# diagonal corners; the cached result is still the original 5px sampler.
		var edges_equal:=true;var edge_count:=0
		if nav.has_method("_grid_line"):
			for id:int in range(nav.open.size()):
				if not nav.open[id]:continue
				var x:int=id%nav.columns;var y:int=id/nav.columns
				for offset:Vector2i in [Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP,Vector2i.DOWN,Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]:
					var nx:=x+offset.x;var ny:=y+offset.y;var next:int=ny*nav.columns+nx
					if nx<0 or nx>=nav.columns or ny<0 or ny>=nav.rows or not nav.open[next]:continue
					var expected:bool=old.line(old.point(id),old.point(next))
					if nav._grid_line(id,next)!=expected or nav._grid_line(id,next)!=expected:edges_equal=false
					edge_count+=1
		check(edges_equal,"All cold/warm directed adjacent edges retain source wall clearance on "+str(floor_data.storyFloor))
		print("GUARD_EDGE_DIFFERENTIAL ",floor_data.storyFloor," ",edge_count)
	# Synthetic open-edge and fractional sliver fixtures retain discrete sample
	# semantics, and setup must invalidate previously cached clear edges.
	var nav:=Counted.new();var old:RefCounted=original.new()
	for walls:Array in [[],[Rect2(34.001,0,.001,90)],[Rect2(35,30,1,1)],[Rect2(35,30,1,1),Rect2(14,42,1,1)]]:
		nav.setup(walls,112,112);old.setup(walls,112,112)
		for a:Vector2 in [Vector2(21,21),Vector2(35,21),Vector2(42,42),Vector2(24.001,50)]:
			for b:Vector2 in [Vector2(49,49),Vector2(91,91),a]:check(nav.line(a,b)==old.line(a,b),"Continuous line keeps original 5px open-edge sampling")
		if nav.has_method("_grid_line"):
			for pair:Array in [[9,10],[10,9],[9,18],[18,9]]:check(nav._grid_line(pair[0],pair[1])==old.line(old.point(pair[0]),old.point(pair[1])),"Setup invalidates directed edge memoization")
	print("GUARD_NAV_TIMINGS ",JSON.stringify(timing))
	print("CHAPTER4_GUARD_NAVIGATION ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
