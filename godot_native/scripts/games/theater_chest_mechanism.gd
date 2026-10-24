extends RefCounted
## The controller owns the persistent assembly. A nonce scopes only this view.
const SYMBOLS: Array = ["fan", "butterfly", "lamp"]
const CLEAR_ORDER: Array = ["butterfly", "fan", "lamp"]
const ASSEMBLY: Array = ["butterfly", "lamp", "fan"]
const SOLUTION: Array = ["fan", "butterfly", "lamp"]
var token: Dictionary = {}
var owner: Dictionary = {}
var retired: bool = false
var clue_open: bool = false

static func fresh() -> Dictionary:
	return {"version":1,"cleared":[],"slots":["","",""],"crank_installed":false,"turns":0,"latch_released":false,"drawer_open":false,"brush_taken":false,"vent_clue_seen":false,"legacy":false}

static func ensure(state: Dictionary) -> Dictionary:
	if not state.native.has("theater_chest"):
		var checkpoint:=fresh()
		# Previous scanner transactions already awarded the brush. Preserve both
		# owned and spent rewards; migration never adds or removes an item.
		if bool(state.get("theaterHunt",{}).get("propBoxOpened",false)):
			checkpoint.merge({"cleared":CLEAR_ORDER.duplicate(),"slots":SOLUTION.duplicate(),"crank_installed":true,"turns":1,"latch_released":true,"drawer_open":true,"brush_taken":true,"legacy":true},true)
		state.native.theater_chest=checkpoint
	return state.native.theater_chest

static func valid(state: Dictionary) -> bool:
	var checkpoint: Variant=state.native.get("theater_chest")
	if not checkpoint is Dictionary or checkpoint.size()!=fresh().size():return false
	for key: String in fresh():
		if not checkpoint.has(key):return false
	if typeof(checkpoint.version) not in [TYPE_INT,TYPE_FLOAT] or checkpoint.version!=1:return false
	for key: String in ["crank_installed","latch_released","drawer_open","brush_taken","vent_clue_seen","legacy"]:
		if not checkpoint[key] is bool:return false
	if typeof(checkpoint.turns) not in [TYPE_INT,TYPE_FLOAT] or (float(checkpoint.turns)!=0.0 and float(checkpoint.turns)!=1.0):return false
	if not checkpoint.cleared is Array or checkpoint.cleared.size()>3 or checkpoint.cleared!=CLEAR_ORDER.slice(0,checkpoint.cleared.size()):return false
	if not checkpoint.slots is Array or checkpoint.slots.size()!=3:return false
	var expected: Array=SOLUTION if checkpoint.turns==1 else ASSEMBLY
	for index: int in range(3):
		var piece: Variant=checkpoint.slots[index]
		if not piece is String or (piece!="" and (piece!=expected[index] or piece not in checkpoint.cleared)):return false
	if checkpoint.latch_released!=(checkpoint.turns==1):return false
	if checkpoint.latch_released and (not checkpoint.crank_installed or checkpoint.slots!=SOLUTION):return false
	if checkpoint.drawer_open and not checkpoint.latch_released:return false
	if (checkpoint.brush_taken or checkpoint.vent_clue_seen) and not checkpoint.drawer_open:return false
	if not bool(state.get("theaterHunt",{}).get("propBoxOpened",false)):return false
	if checkpoint.legacy and not checkpoint.brush_taken:return false
	if not checkpoint.legacy:
		var brush_owned: bool=bool(state.get("items",{}).get("fluorescentBrush",false))
		var dusted: bool=bool(state.get("theaterHunt",{}).get("paperDusted",false))
		if brush_owned and not checkpoint.brush_taken:return false
		if dusted and not checkpoint.brush_taken:return false
		if checkpoint.brush_taken and not brush_owned and not dusted:return false
	return true

func _init(state: Dictionary = {}, serial: int = 0) -> void:
	owner=state
	if state.is_empty():retired=true;return
	ensure(state)
	token={"id":serial,"nonce":Crypto.new().generate_random_bytes(16).hex_encode(),"scene":"theater_interior","phase":str(state.get("theaterHunt",{}).get("phase","")),"checkpoint":str(state.get("rpgCheckpoint",""))}

func current(state: Dictionary) -> bool:
	if retired or not is_same(state,owner):return false
	var theater: Dictionary=state.get("theaterHunt",{})
	var native: Dictionary=state.get("native",{})
	return str(state.get("runtimeMode",""))=="rpg" and str(state.get("rpgScene",""))==token.scene and str(native.get("scene",""))==token.scene and str(native.get("mode",theater.get("mode","")))=="light" and bool(theater.get("active",false)) and bool(theater.get("admitted",false)) and bool(theater.get("propBoxOpened",false)) and str(theater.get("phase",""))==token.phase and str(state.get("rpgCheckpoint",""))==token.checkpoint

func matches(value: Variant) -> bool:return not retired and value is Dictionary and value==token
func invalidate() -> void:retired=true;owner={}
func cancel(value: Variant) -> bool:
	if not matches(value):return false
	invalidate();return true

func snapshot() -> Dictionary:
	var result: Dictionary=owner.native.theater_chest.duplicate(true)
	var remaining: Array=[]
	for symbol: String in SYMBOLS:
		if symbol not in result.slots:remaining.append(symbol)
	if not result.crank_installed:remaining.append("crank")
	result.merge({"session":token.duplicate(true),"remaining":remaining,"clue_open":clue_open,"clue_order":[]})
	return result

func apply(state: Dictionary, action: String, value: Variant) -> Dictionary:
	if not current(state) or not value is Dictionary or not matches(value.get("session")):
		return {"handled":true,"ephemeral":true,"accepted":false,"message":"这次箱内查看已经结束。"}
	var checkpoint: Dictionary=owner.native.theater_chest
	if action=="inspect":
		if checkpoint.cleared.size()<3:return _result(false,"纸条还压在零件下面。")
		clue_open=not clue_open
		return _result(true)
	if action=="clue":
		if not checkpoint.drawer_open:return _result(false)
		var changed: bool=not checkpoint.vent_clue_seen
		checkpoint.vent_clue_seen=true
		return _result(true,"示意图标着后台通风口：沿栅格边缘施粉，追光下就能看到纸条的痕迹。",changed)
	if str(state.theaterHunt.phase)!="prop_setup":return _result(false)
	match action:
		"clear":
			var piece:=str(value.get("piece",""))
			if piece in checkpoint.cleared:return _result(true)
			if checkpoint.cleared.size()>=3 or piece!=CLEAR_ORDER[checkpoint.cleared.size()]:return _result(false,"这块还被压着，先移开上面的零件。")
			checkpoint.cleared.append(piece)
			return _result(true,"下面露出一张机关装配草图。" if checkpoint.cleared.size()==3 else "",true)
		"place":
			if checkpoint.latch_released:return _result(false)
			var piece:=str(value.get("piece",""))
			if piece=="crank":
				if not value.get("slot") is String or value.get("slot")!="axle":return _result(false,"转柄要装在轮盘中轴。")
				if checkpoint.crank_installed:return _result(true)
				checkpoint.crank_installed=true
				return _result(true,"",true)
			var destination: Variant=value.get("slot")
			if piece not in SYMBOLS or typeof(destination) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(destination)) or float(destination)!=floor(float(destination)) or destination<0 or destination>2:return _result(false)
			if piece not in checkpoint.cleared:return _result(false,"先把零件从堆里移出来。")
			if piece!=ASSEMBLY[int(destination)]:return _result(false,"边缘的缺口对不上，放不进去。")
			if checkpoint.slots[int(destination)]==piece:return _result(true)
			checkpoint.slots[int(destination)]=piece
			return _result(true,"",true)
		"turn":
			if checkpoint.latch_released:return _result(false,"锁舌已经退开，可以拉开夹层了。")
			if not checkpoint.crank_installed:return _result(false,"轮盘中轴还缺一枚转柄。")
			if checkpoint.slots!=ASSEMBLY:return _result(false,"凹槽里的零件还没装齐，转柄被卡住了。")
			if typeof(value.get("direction")) not in [TYPE_INT,TYPE_FLOAT] or value.get("direction")!=1:return _result(false,"磨损的箭头指向顺时针。")
			checkpoint.slots=SOLUTION.duplicate();checkpoint.turns=1;checkpoint.latch_released=true
			return _result(true,"连杆带动锁舌退开了。",true)
		"open":
			if checkpoint.drawer_open:return _result(true)
			if not checkpoint.latch_released:return _result(false,"锁舌还扣着夹层，需要转动机关。")
			checkpoint.drawer_open=true
			return _result(true,"夹层里放着荧光粉刷和一张通风口示意图。",true)
		"take":
			if not checkpoint.drawer_open or checkpoint.brush_taken:return _result(false)
			checkpoint.brush_taken=true;state.items.fluorescentBrush=true
			return _result(true,"取得荧光粉刷。可以回到后台通风口了。",true)
	return _result(false)

func _result(accepted: bool, message: String="", changed: bool=false) -> Dictionary:
	return {"handled":true,"ephemeral":not changed,"accepted":accepted,"message":message,"mechanism":snapshot()}
