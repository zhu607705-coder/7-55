extends RefCounted
## Standalone sample-session authority. Never reads or writes the main game's State.
const IDS := ["library", "liuhu", "bridge", "light"]
var completed: Dictionary = {}
var active := ""
var data: Dictionary = {}
var message := ""

func enter(id: String) -> void:
	assert(id in IDS)
	active = id
	match id:
		"library":
			data = {"stage": 0, "chosen": -1, "inspected": false}
			message = "想找个座位自习。先看看桌上的座位牌。"
		"liuhu":
			data = {"offset": 95.0, "tilt": 52.0, "records": []}
			message = "巡护本上的三个点位，需要与水面倒影一一对应。"
		"bridge":
			data = {"left": 220.0, "right": 740.0, "folded": false, "load": 0, "placed": [], "failed": false}
			message = "把这封信送到桌子另一端。先让纸桥承住三枚砝码。"
		"light":
			data = {"lamp": 235.0, "player_position": Vector2(470, 380), "carrying": false, "delivered": false}
			message = "让分子结构的投影落到刻线里，把来信留在装置旁的信箱。"

func finish() -> void:
	completed[active] = true

func manipulation_snapshot() -> Dictionary:
	return {"active": active, "data": data.duplicate(true)}

func cancel_manipulation(snapshot: Dictionary) -> void:
	if snapshot.get("active", "") == active and snapshot.get("data") is Dictionary:
		data = snapshot.data.duplicate(true)

func adjust(control: String, value: float) -> bool:
	if not is_finite(value): return false
	match [active, control]:
		["liuhu", "horizontal"]: data.offset = clampf(value, -135.0, 135.0)
		["liuhu", "vertical"]: data.tilt = clampf(value, -80.0, 80.0)
		["bridge", "left"]: data.left = clampf(value, 180.0, 420.0)
		["bridge", "right"]: data.right = clampf(value, 540.0, 780.0)
		["light", "lamp"]: data.lamp = clampf(value, 175.0, 560.0)
		_: return false
	return true

func fold_paper() -> void:
	if active != "bridge": return
	data.folded = true
	message = "纸边折起了。把砝码放上去，看看桥面的变化。"

func remove_weights() -> void:
	if active != "bridge": return
	data.load = 0; data.placed=[]; data.failed = false
	message = "砝码已取回。可以重新调整纸桥。"

func move_player(point: Vector2) -> void:
	if active != "light" or not point.is_finite(): return
	data.player_position = point.clamp(Vector2(80,200),Vector2(800,650))

func seat_action(action: String, seat: int = -1) -> bool:
	if active != "library": return false
	match action:
		"inspect":
			data.inspected = true
			message = "空着的椅子不一定可用。021已预约，022暂离，023使用中，024可预约。"
		"reserve":
			if seat != 3:
				message = "这个座位已有使用安排。看看还有哪一个标着“可预约”。"
				return false
			if data.stage != 0: return false
			data.chosen = seat
			data.stage = 1
			message = "已选024。把校园卡拖到桌边的签到感应区。"
		"checkin":
			if data.stage != 1:
				message = "先在桌上的预约终端选择可用座位。"
				return false
			data.stage = 2
			message = "签到完成。现在可以去024座位坐下了。"
		"sit":
			if data.stage != 2 or seat != data.chosen:
				message = "有人不在座位上，也可能仍在使用。先确认预约与签到状态。"
				return false
			data.stage = 3
			message = "终于安心坐下了。离开时记得在终端结束使用，把座位留给下一位。"
		"release":
			if data.stage != 3: return false
			data.stage = 4
			finish()
			message = "来信添了一句：别只看空椅子，先确认座位状态；离开时主动释放。"
		_:
			return false
	return true

func reflection_aligned() -> bool:
	return absf(data.offset) <= 8.0 and absf(data.tilt) <= 7.0

func record_sample(index: int) -> bool:
	if active != "liuhu" or index < 0 or index > 2: return false
	if not reflection_aligned():
		message = "倒影还没对齐。转动岸边的两个手轮，让水中的圆环套住三个反射点。"
		return false
	if index in data.records: return false
	data.records.append(index)
	message = "已记录巡护点%d。观察位置、环境与水面状况，再完成交接。" % (index + 1)
	if data.records.size() == 3:
		finish()
		message = "三个巡护点已交接。来信添了一句：先观察，再核对，记录要能让下一位复现。"
	return true

func bridge_metrics() -> Dictionary:
	var span: float = data.right - data.left
	var centered: bool = data.left <= 440.0 and data.right >= 520.0
	var stiff: float = 3.0 if data.folded else 1.0
	var deflection: float = float(data.load) * pow(span / 300.0, 3.0) * 13.0 / stiff
	return {"span": span, "deflection": deflection, "safe": centered and deflection <= 32.0}

func place_weight(index: int = -1) -> bool:
	if active != "bridge" or data.load >= 3: return false
	if index<0:
		for candidate:int in range(3):
			if candidate not in data.placed:index=candidate;break
	if index<0 or index>2 or index in data.placed:return false
	if data.failed:
		message="先用托盘收回砝码，再调整支点与纸桥。"
		return false
	data.placed.append(index);data.load=data.placed.size()
	var metrics := bridge_metrics()
	if not metrics.safe:
		data.failed = true
		message = "桥面弯下去了。取回砝码，折起纸的边缘，或把支点向内挪，再试一次。"
		return false
	data.failed = false
	message = "第%d枚砝码放稳了。留意支点间距和桥面形变。" % data.load
	if data.load == 3:
		finish()
		message = "承重通过，来信可以送到桌子另一端。相同的纸，折法和支点会改变承载表现。"
	return true

func light_aligned() -> bool:
	return absf(data.lamp - 440.0) <= 12.0

func light_clear() -> bool:
	return data.player_position.y >= 435.0 and data.player_position.x <= 330.0

func take_letter() -> bool:
	if active!="light" or data.delivered:return false
	data.carrying=true
	message="来信拿好了。走到装置旁的信箱，将信投入开口。"
	return true

func deliver_light(slot_distance:float=0) -> bool:
	if active != "light": return false
	if not light_aligned():
		message = "投影还没进入刻线。沿轨道拖动灯座，观察分子影子的位置。"
		return false
	if not light_clear():
		message = "先退到左侧观察位置，避开灯具与雕塑之间的光路。"
		return false
	if not is_finite(slot_distance) or slot_distance>2.5:
		message="先走近信箱，再投入这封信。"
		return false
	if not data.carrying:
		message="先拿起左侧台面上的来信，再放进信箱。"
		return false
	data.delivered = true
	data.carrying = false
	finish()
	message = "来信已经投入信箱，留给下一位来到校园的人。"
	return true
