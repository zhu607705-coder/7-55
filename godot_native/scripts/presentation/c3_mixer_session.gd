extends RefCounted
## Presentation-only lifetime for CanteenInteriorScene's mixer. Never consumes an
## item, writes a sequence, judges a recipe, or grants a reward. The controller
## remains the only authority; a changed attempt count closes either outcome.
const RECIPE: Array = ["blackCoffee", "sparklingWater", "lemonTea"]
const NAMES: Dictionary = {"blackCoffee":"黑咖啡", "sparklingWater":"气泡水", "lemonTea":"柠檬茶"}
const COLORS: Dictionary = {"blackCoffee":0x242226, "sparklingWater":0x40bfe8, "lemonTea":0xf0edcf}
const BUTTON_X: Array = [-210, 0, 210]
var bound_state: Dictionary = {}
var button_order: Array = []
var active: bool = false
var close_reason: String = ""
var opened_attempt: int = 0
var drinks: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter3-canteen.content.json")).drinks

func open(s: Dictionary, random: RandomNumberGenerator = null) -> bool:
	if active: return is_same(s, bound_state)
	if str(s.get("native", {}).get("scene", "")) != "canteen_interior": return false
	bound_state = s
	opened_attempt = int(s.get("canteenHunt", {}).get("drinkMixAttemptCount", 0))
	var order: Array = RECIPE.duplicate()
	if random == null:
		random = RandomNumberGenerator.new()
		random.randomize()
	for index in range(order.size() - 1, 0, -1):
		var other: int = random.randi_range(0, index)
		var old: String = order[index]
		order[index] = order[other]
		order[other] = old
	button_order = avoid_answer_order(order)
	active = true
	close_reason = ""
	return true

static func avoid_answer_order(shuffled: Array) -> Array:
	var order: Array = shuffled.duplicate()
	# Source rotates only the identity permutation, once per panel lifetime.
	if order == RECIPE: order.append(order.pop_front())
	return order

func close(reason: String = "dismissed") -> void:
	active = false
	button_order.clear()
	bound_state = {}
	close_reason = reason

func synchronize(s: Dictionary) -> bool:
	if not active: return false
	if not is_same(s, bound_state) or str(s.get("native", {}).get("scene", "")) != "canteen_interior":
		close("context_changed")
		return false
	var attempt: int = int(s.get("canteenHunt", {}).get("drinkMixAttemptCount", 0))
	if attempt != opened_attempt:
		close("attempt_complete" if attempt > opened_attempt else "context_changed")
		return false
	return true

func snapshot(s: Dictionary) -> Dictionary:
	if not synchronize(s): return {}
	var c: Dictionary = s.get("canteenHunt", {})
	var items: Dictionary = s.get("items", {})
	var slots: Array = []
	for index in range(button_order.size()):
		var id: String = button_order[index]
		var owned: bool = bool(items.get(id, false))
		slots.append({"id":id, "owned":owned, "label":("倒入"+str(NAMES[id])) if owned else (str(NAMES[id])+"·未持有"), "color":COLORS[id], "x":BUTTON_X[index], "action":"c3_mix:"+id})
	var layers: Array = []
	for index in range(c.get("drinkMixSequence", []).size()):
		var id: String = str(c.drinkMixSequence[index])
		if not COLORS.has(id): continue
		layers.append({"id":id, "color":COLORS[id], "rect":Rect2(-49, 37-index*38, 98, 36), "alpha":0.92})
	var read_shelf: bool = bool(c.get("drinkShelfRead", false))
	return {"title":"食堂新品混合台", "prompt":str(drinks.mixerPrompt), "glassLabel":"大玻璃杯", "shelfRead":read_shelf, "shelfStatus":"货架提示已记录：黑色 → 蓝色 → 白色" if read_shelf else "货架提示：尚未查看", "slots":slots, "layers":layers}

func missing_feedback() -> String:
	return str(drinks.ingredientMissing)
