extends RefCounted
## C1 physical desk. Only a bounded return page persists; receipts never do.
const Session = preload("res://scripts/media/c3_charging_session.gd")
var owner: Dictionary = {}
var session: RefCounted
var return_page := ""
var explained := false

static func available(s: Dictionary) -> bool:
	return s.get("runtimeMode") == "phone" and int(s.get("native", {}).get("chapter", 1)) == 1 and s.get("actOne", {}).get("phase") == "prologue" and not s.get("flags", {}).get("checkinDone", false)

func route(s: Dictionary) -> void:
	if not is_same(owner, s):
		if session != null: session.cancel()
		owner = s; session = null; explained = false
		return_page = str(s.ui.get("homeDeskReturnScene")) if s.ui.get("homeDeskReturnScene") in ["phone_home", "bonsai"] else ""
	if session != null and not Session.rejection(s, "home_desk").is_empty(): session.cancel()
	if not available(s): return_page = ""

func returning(s: Dictionary) -> bool:
	return is_same(owner, s) and available(s) and return_page in ["phone_home", "bonsai"]

func dispatch(s: Dictionary, action: String, value: Variant) -> Dictionary:
	route(s)
	if not action.begins_with("c1_desk_"): return {}
	if not available(s): return {"handled": true, "message": "现在不在起床时的桌面。"}
	match action:
		"c1_desk_putdown":
			if s.native.page not in ["phone_home", "bonsai"]: return {"handled": true}
			return_page = s.native.page
			s.ui.homeDeskReturnScene = return_page
			s.native.page = "desktop"; s.currentScene = "desktop"
			var message := "已放下手机。点桌上充电座接线，点手机拿起。" if not explained else ""
			explained = true
			return {"handled": true, "page": "desktop", "message": message}
		"c1_desk_pickup":
			if s.native.page != "desktop" or not returning(s): return {"handled": true}
			if session != null: session.cancel()
			var page := return_page
			return_page = ""
			s.ui.homeDeskReturnScene = null
			s.native.page = page; s.currentScene = page
			return {"handled": true, "page": page}
		"c1_desk_charge":
			if not Session.rejection(s, "home_desk").is_empty(): return {"handled": true}
			if session != null and session.phase in ["issued", "charging", "complete"]: return {"handled": true}
			if int(s.phoneBattery.percent) >= 45 and not s.phoneBattery.lowPowerMode: return {"handled": true, "message": "电量充足，无需再次接线。"}
			session = Session.new("home_desk", s)
			return {"handled": true}
		"c1_desk_cancel":
			if session != null: session.cancel()
			return {"handled": true}
		"c1_desk_charge_result":
			if not value is Session or value != session or not session.consume(s): return {"handled": true}
			s.phoneBattery.percent = maxi(45, int(s.phoneBattery.percent))
			s.phoneBattery.lowPowerMode = false
			s.phoneBattery.rechargeCount += 1
			return {"handled": true, "message": "补电完成，低电量模式已关闭。亮度保持原值，可在控制中心手动调高。"}
	return {"handled": true}
