extends RefCounted
const Props=preload("res://campuses/future_learning_center/scripts/motion_prop_metrics.gd")
## Physical two-port track modules. No path solving or completion in the view.
const DIRECTIONS := [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(0,-1)]
const BASE := Vector2i(0,1)
const DESTINATION := Vector2i(4,1)
var tiles: Dictionary = {}
var outlet := 2
var history: Array[Dictionary] = []
var revision := 0
var run_revision := -1
var phase := "ready"
var running := false
var complete := false
var earned := false
var delivered := false
var returning := false
var cargo := "base"
var cell := BASE
var position := Vector2(BASE)
var direction := 0
var incoming := -1
var next_cell := BASE
var progress := 0.0
var edge_valid := true
var edge_stop_progress := 1.0
var fault := ""
var moved := 0.0
var visits: Dictionary = {}
var trace: Array[Vector2] = []
var last_trace: Array[Vector2] = []
var last_stop := Vector2.INF

func _init() -> void:
	for y: int in 3:
		for x: int in 5: tiles[Vector2i(x,y)]={"kind":"straight","rotation":0}
	for point: Vector2i in [Vector2i(0,0),Vector2i(4,0),Vector2i(0,2),Vector2i(4,2)]:
		tiles[point]={"kind":"corner","rotation":3 if point.y==0 else 0}
	tiles[Vector2i(2,1)]={"kind":"oneway","rotation":0}
	trace.append(position)
func ports(point: Vector2i) -> Array[int]:
	if point==BASE or point==DESTINATION: return [0,1,2,3]
	if not tiles.has(point): return []
	var tile: Dictionary=tiles[point]; var r: int=tile.rotation
	return [r,(r+(1 if tile.kind=="corner" else 2))%4]
func accepts(point: Vector2i, entry: int) -> bool:
	if not entry in ports(point): return false
	if point==BASE or point==DESTINATION: return true
	var tile: Dictionary=tiles[point]
	return tile.kind!="oneway" or entry==(int(tile.rotation)+2)%4
func edit(point: Vector2i, replacement := false) -> bool:
	if not tiles.has(point) or point==BASE or point==DESTINATION: return false
	_remember()
	var tile: Dictionary=tiles[point]
	if replacement:
		var kinds:= ["straight","corner","oneway"]
		tile.kind=kinds[(kinds.find(tile.kind)+1)%3]
	else: tile.rotation=(int(tile.rotation)+1)%4
	_invalidate(); return true
func change_outlet() -> void:
	_remember(); outlet={2:3,3:1,1:2}[outlet]; _invalidate()
func set_outlet(value: int) -> bool:
	if value not in [1,2,3] or value==outlet: return false
	_remember(); outlet=value; _invalidate(); return true
func place_module(point: Vector2i, kind: String, rotation: int) -> bool:
	if not tiles.has(point) or point in [BASE,DESTINATION] or kind not in ["straight","corner","oneway"] or rotation<0 or rotation>3: return false
	if tiles[point].kind==kind and tiles[point].rotation==rotation: return false
	_remember(); tiles[point]={"kind":kind,"rotation":rotation}; _invalidate(); return true
func swap_modules(from: Vector2i, to: Vector2i) -> bool:
	if from==to or from in [BASE,DESTINATION] or to in [BASE,DESTINATION] or not tiles.has(from) or not tiles.has(to): return false
	_remember(); var previous: Dictionary=tiles[from].duplicate(); tiles[from]=tiles[to].duplicate(); tiles[to]=previous
	_invalidate(); return true
func return_to_start() -> void:
	running=false; _safe_origin(); phase="ready"
func _remember() -> void:
	history.append({"tiles":tiles.duplicate(true),"outlet":outlet})
	if history.size()>32: history.pop_front()
func undo() -> bool:
	if history.is_empty(): return false
	var previous: Dictionary=history.pop_back(); tiles=previous.tiles.duplicate(true); outlet=previous.outlet
	_invalidate(); return true
func _invalidate() -> void:
	revision+=1; running=false; _safe_origin(); phase="edited"
func _safe_origin() -> void:
	cell=BASE; position=Vector2(BASE); direction=0; incoming=-1; progress=0; moved=0
	delivered=false; returning=false; cargo="base"; complete=false; visits.clear(); trace=[position]; fault=""
func start() -> bool:
	if running: return false
	_safe_origin(); phase="loading"; running=true; run_revision=revision; return true
func cancel() -> void:
	if phase=="complete": return
	running=false; _safe_origin(); phase="cancelled"
func pause() -> void: running=false
func resume() -> bool:
	if phase not in ["loading","moving","unloading"] or run_revision!=revision: return false
	running=true; return true
func advance_one() -> void:
	if phase in ["ready","edited","cancelled","blocked","complete"]: start()
	else: resume()
	step(maxf(.001,1.0-progress)); running=false
func _begin_edge(exit_port: int) -> void:
	direction=exit_port; next_cell=cell+DIRECTIONS[exit_port]; progress=0; phase="moving"
	edge_valid=accepts(next_cell,(exit_port+2)%4)
	# Invert the movement easing at the visible nose-to-seam limit.
	edge_stop_progress=1.0 if edge_valid else .5-sin(asin(1-2*Props.stop_fraction(direction))/3.0)
	fault="返向被单向模块挡住" if tiles.has(next_cell) and tiles[next_cell].kind=="oneway" and not edge_valid else "接缝没有相通"
func step(dt: float) -> void:
	if not running or dt<=0 or not is_finite(dt): return
	if run_revision!=revision: cancel(); return
	var remaining:=dt
	while remaining>.00001 and running:
		var boundary: float=edge_stop_progress if phase=="moving" and not edge_valid else 1.0
		var take: float=minf(remaining,boundary-progress); progress+=take; remaining-=take
		if phase=="moving":
			var previous:=position
			position=Vector2(cell).lerp(Vector2(next_cell),smoothstep(0.0,1.0,progress)); moved+=position.distance_to(previous)
		if progress+.00001<boundary: break
		if phase=="loading":
			cargo="robot"; _begin_edge(0)
		elif phase=="unloading":
			cargo="destination"; delivered=true; returning=true; _begin_edge(outlet)
		elif phase=="moving":
			trace.append(position)
			if not edge_valid: _block(); break
			cell=next_cell; incoming=(direction+2)%4; progress=0
			if cell==BASE and returning:
				complete=delivered and cargo=="destination"; earned=earned or complete; running=false; phase="complete"
				last_trace=trace.duplicate(); last_stop=Vector2.INF; break
			if cell==DESTINATION and not returning: phase="unloading"; continue
			var state:=str(cell)+":"+str(incoming)+":"+str(returning)
			if visits.has(state): fault="这段轨道绕回了同一个入口"; _block(); break
			visits[state]=true
			var exits:=ports(cell); exits.erase(incoming)
			if exits.is_empty(): fault="没有接向下一段的出口"; _block(); break
			_begin_edge(exits[0])
func _block() -> void:
	running=false; phase="blocked"; complete=false; last_trace=trace.duplicate(); last_stop=position
func visible_front()->Vector2:
	return position+Vector2(DIRECTIONS[direction])*Props.front_distance(direction)/Props.CELL
func message() -> String:
	if phase=="blocked": return fault+"。车停在接缝前，可撤回、换模块或转弯再试。"
	return {"ready":"货物要送到右侧站台，小车还要空车回到左侧。", "edited":"轨道已改变。点一个模块，再旋转或更换；从起点重新试跑。", "loading":"夹爪正在把货物放进车厢。", "moving":"货物已送达，观察空车怎样回起点。" if returning else "沿凹槽行驶，看看每个接缝能否通过。", "unloading":"在站台卸货；送达只是这一趟的一半。", "complete":"送达、卸货、空车返回都完成了！也可以试试另一条路线。", "cancelled":"已回到起点，货物和模块都能再次使用。"}.get(phase,"")
