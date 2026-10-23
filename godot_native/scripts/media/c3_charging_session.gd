extends RefCounted
## Exact 2200ms station transaction. Receipt identity and monotonic elapsed time
## are runtime-only; an arbitrary terminal dictionary cannot recharge the phone.
const DURATION_MS: float = 2200.0
var phase: String = "issued"
var elapsed_ms: float = 0.0
var last_clock: int = 0
var entry_page: String = ""
var context: String = "theater"
var owner: Dictionary = {}

func _init(station_context: String = "theater", authority: Dictionary = {}) -> void:
	context = station_context
	owner = authority

func same_owner(authority: Dictionary) -> bool:
	return owner.is_empty() or is_same(owner, authority)

static func rejection(s: Dictionary, station_context: String = "theater") -> String:
	var host: Dictionary=s.get("native",{}).get("host",{})
	if host.get("phone_modal_open",false) or host.get("minigame_open",false) or not host.get("focused",true): return "no_power_source"
	if station_context == "home_desk":
		return "" if s.get("runtimeMode") == "phone" and s.get("native", {}).get("page") == "desktop" and int(s.get("native", {}).get("chapter", 1)) == 1 and s.get("actOne", {}).get("phase") == "prologue" and not s.get("flags", {}).get("checkinDone", false) and not s.get("ui", {}).get("controlCenterOpen", false) else "no_power_source"
	if station_context != "theater" or not host.get("world_visible", true): return "no_power_source"
	if s.get("runtimeMode") != "rpg" or s.get("rpgScene") != "theater_interior" or s.get("native",{}).get("scene") != "theater_interior" or not s.get("theaterHunt",{}).get("active",false) or s.get("ui",{}).get("controlCenterOpen",false): return "no_power_source"
	var point: Variant = s.get("native",{}).get("player",{})
	if point is Dictionary and point.has("theater_interior"): point = point.theater_interior
	if not point is Dictionary or not point.has("x") or not point.has("y"): return "too_far"
	var x: float = float(point.x)
	var y: float = float(point.y)
	if not is_finite(x) or not is_finite(y): return "too_far"
	var delta: Vector2 = Vector2(maxf(0,absf(x-595.0)-38.5),maxf(0,absf(y-773.0)-46.5))
	if delta.length() > 46.0: return "too_far"
	if s.get("native",{}).get("mode",s.theaterHunt.get("mode","light")) != "light": return "wrong_mode"
	return ""

func begin(s: Dictionary, authority: Dictionary = {}) -> bool:
	if phase != "issued" or not same_owner(s if authority.is_empty() else authority) or not rejection(s, context).is_empty(): return false
	entry_page = str(s.native.page)
	last_clock = Time.get_ticks_msec()
	phase = "charging"
	return true

func sample(s: Dictionary, authority: Dictionary = {}) -> void:
	if phase != "charging": return
	if not same_owner(s if authority.is_empty() else authority) or not rejection(s, context).is_empty() or str(s.native.page) != entry_page:
		cancel()
		return
	var now: int = Time.get_ticks_msec()
	elapsed_ms += minf(100.0,maxf(0.0,now-last_clock))
	last_clock = now
	if elapsed_ms >= DURATION_MS: phase = "complete"

func cancel() -> void:
	if phase in ["issued","charging","complete"]: phase = "cancelled"

func consume(s: Dictionary) -> bool:
	if phase != "complete" or elapsed_ms < DURATION_MS or not same_owner(s) or not rejection(s, context).is_empty() or str(s.native.page) != entry_page: return false
	phase = "consumed"
	return true
