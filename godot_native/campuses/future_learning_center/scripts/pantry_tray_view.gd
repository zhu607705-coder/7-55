extends "res://campuses/future_learning_center/scripts/physical_bench.gd"
const Model = preload("res://campuses/future_learning_center/scripts/pantry_tray_model.gd")
const HOME := Vector2(430,377)
const DESTINATION := Vector2(430,213)
const SPACING := 90.0
const DOCK := Vector2(870,352)
const DRAIN := Vector2(870,443)
const HINTS := ["杯身两道铜线之间，是各自要的水量。四杯都要备好。", "水位都合格，也可能偏。比较同一只杯放在内外杯垫时的变化。", "水位可以在铜线之间微调。外侧的一点变化，比内侧更明显。"]
var model = Model.new()
var selected_slot := -1
var tray_center := HOME
var tray_height := 0.0
var tray_angle := 0.0
var previous_phase := ""
var carry_preview := 0.0
var cup_delta := Vector2.ZERO

func open() -> void:
	bench_mode = "pantry"; book_open = false; book_page = 0
	previous_phase = ""; cancel_gesture(); clear_motion(); show()
	notice("四杯都要接到铜线之间，再稳稳送达。把杯子放到右侧出水口下。")
	queue_redraw()

func close() -> void:
	model.cancel(); super.close()

func _lost_focus() -> void:
	model.cancel(); carry_preview = 0; cup_delta = Vector2.ZERO

func cancel_gesture() -> void:
	model.set_draining(false)
	super.cancel_gesture(); carry_preview = 0; cup_delta = Vector2.ZERO; selected_slot = -1

func _assembly_stamp() -> String: return str([model.cups, model.support, model.dock_slot])

func local_point(x: float, z: float, height: float) -> Vector3:
	var pivot: float = model.support * SPACING
	return miniature.p(tray_center, tray_height) + Vector3(pivot,0,0)*miniature.U + Basis(Vector3.FORWARD,tray_angle)*Vector3(x-pivot,height,z)*miniature.U

func cup_at(slot: int) -> Vector2:
	if model.dock_slot == slot: return DOCK
	return miniature.screen(local_point(Model.ARMS[slot]*SPACING,0,55))

func dock_base() -> Vector3: return miniature.visible_p(DOCK,55)-Vector3(0,.42,0)

func valve_at() -> Vector2: return DOCK+Vector2(42,-59 if model.tap_open else -29)

func slot_at(slot: int) -> Vector2:
	return miniature.screen(local_point(Model.ARMS[slot]*SPACING,0,12))

func handle_at() -> Vector2:
	return miniature.screen(local_point(model.support*SPACING,0,100))

func support_at() -> Vector2:
	return miniature.screen(local_point(model.support*SPACING,77,12))

func _press(at: Vector2) -> void:
	pointer = at; press_at = at
	if (Rect2(book_at-Vector2(240,270),Vector2(480,270)).has_point(at) if book_open else Rect2(832,74,104,61).has_point(at)):
		gesture = "book"; book_origin = book_at
		return
	book_open = false
	if at.distance_to(valve_at()) < 29:
		gesture = "valve"; cue("grip",at); return
	if at.distance_to(handle_at()) < 34:
		gesture = "handle"; cue("grip",at); return
	if model.earned and model.editable() and at.distance_to(support_at()) < 28:
		gesture = "support"; cue("grip",at); return
	if not model.editable(): return
	for i: int in 4:
		if at.distance_to(cup_at(i)) < 37 or at.distance_to(slot_at(i)) < 31:
			if model.dock_slot >= 0 and model.dock_slot != i:
				notice("先把出水口下的杯子放回托盘。"); return
			model.stop_water()
			selected_slot = i; gesture = "cup"; cue("grip",at); return

func _object_move(at: Vector2) -> void:
	if gesture == "cup":
		cup_delta = (at-press_at).limit_length(600)
		model.set_draining(selected_slot == model.dock_slot and at.distance_to(DRAIN) < 42)
	elif gesture == "handle" and model.phase == "held": carry_preview = clampf((press_at.y-at.y)/150,0,1)

func _object_release(at: Vector2, cancelled: bool) -> void:
	if cancelled:
		model.stop_water()
		if gesture == "cup" and selected_slot >= 0: return_part("cup"+str(model.cups[selected_slot]),cup_at(selected_slot)+cup_delta,cup_at(selected_slot))
		return
	if gesture == "cup" and selected_slot >= 0:
		if at.distance_to(DOCK) < 47 and model.dock_slot < 0:
			if model.dock(selected_slot): notice("向上拨橙色阀柄，细流接水；向下拨停水。")
			return
		if model.dock_slot == selected_slot and (at.distance_to(DOCK) < 47 or at.distance_to(DRAIN) < 45):
			return_part("cup"+str(model.cups[selected_slot]),cup_at(selected_slot)+cup_delta,DOCK)
			return
		for i: int in 4:
			var tray_target: Vector2 = miniature.screen(local_point(Model.ARMS[i]*SPACING,0,55))
			if at.distance_to(tray_target) < 45 or at.distance_to(slot_at(i)) < 42:
				var source: int = model.cups[selected_slot]
				var target: int = model.cups[i]
				var target_from := cup_at(i)
				var source_from := cup_at(selected_slot)+cup_delta
				var changed: bool = model.undock(i) if model.dock_slot == selected_slot else model.swap(selected_slot,i)
				if changed:
					return_part("cup"+str(target),target_from,cup_at(selected_slot))
					return_part("cup"+str(source),source_from,cup_at(i))
					cue("seat",slot_at(i))
				return
		return_part("cup"+str(model.cups[selected_slot]),cup_at(selected_slot)+cup_delta,cup_at(selected_slot))
		notice("杯子回到原位。可以放到杯垫，或右侧出水口下。")
	elif gesture == "valve":
		if absf(at.y-press_at.y) <= 8: notice("向上拨阀柄接水，向下拨停水。")
		elif not model.set_tap(at.y < press_at.y): notice("先把一只杯放在出水口下面。")
	elif gesture == "handle":
		if model.phase == "tilted" and at.y-press_at.y > 20:
			model.lower()
		elif model.editable():
			if press_at.y-at.y > 18:
				if not model.lift(): notice("出水口下还有一只杯，先放回杯垫。")
			else: notice("握住提手往上提一点，看看托盘往哪边偏。")
		elif model.phase == "held":
			if press_at.y-at.y > 60:
				if not model.send(): notice("托盘虽平，但有杯水位还没到铜线之间。先放下补水或倒回。")
			elif at.y-press_at.y > 20: model.lower()
		elif model.phase == "delivered" and at.y-press_at.y > 30:
			model.lower(); notice("托盘回到大桌。也可以移动前沿橙色卡扣，换一条支撑线再试。")
	elif gesture == "support":
		var value: float = clampf(snappedf(model.support+(at.x-press_at.x)/SPACING,.25),-.25,.25)
		if model.move_support(value): notice("提手换了位置。重新摆杯，再试提一次。")

func _process(dt: float) -> void:
	if not visible: return
	_tick_shell(dt); model.step(dt)
	var target_center := HOME
	var target_height := 0.0
	var target_angle := 0.0
	if model.phase in ["lifting","held","tilted"]:
		target_height = 48
		target_angle = clampf(model.moment()*.0012,-.18,.18)
	elif model.phase == "delivering":
		var t: float = clampf(model.elapsed/Model.DELIVERY_SECONDS,0,1)
		target_center = HOME.lerp(DESTINATION,smoothstep(0,1,t))
		target_height = 48*sin(PI*t)+15
	elif model.phase == "delivered": target_center = DESTINATION
	if model.phase == "held": target_center = HOME.lerp(DESTINATION,carry_preview*.24)
	var speed: float = 1 if reduced_motion else 1-exp(-dt*15)
	tray_center = tray_center.lerp(target_center,speed)
	tray_height = lerpf(tray_height,target_height,speed)
	tray_angle = lerpf(tray_angle,target_angle,speed)
	if previous_phase != model.phase:
		previous_phase = model.phase
		if model.phase == "tilted": notice("托盘偏了。可以换杯位，也可以放下后微调水量。")
		elif model.phase == "held": notice("提稳了，往后方茶几送。" if model.portions_ready() else "托盘是平的，但水位还没备齐。放下后对照杯身铜线。")
		elif model.phase == "delivered": notice("茶送到了。拉回提手还能再试；前沿卡扣可以换支撑线。")
	queue_redraw()

func _book_lines() -> Array[String]:
	if book_page > 0: return ["备茶记录", HINTS[book_page-1]]
	match model.phase:
		"tilted": return ["本次试提", "托盘向%s偏。四只杯都在，可以交换杯位后再试。" % ("右" if model.last_moment > 0 else "左")]
		"held": return ["本次试提", "托盘已提稳，水量合格，尚未送达。" if model.portions_ready() else "托盘虽平，还有杯水量未在铜线之间。"]
		"delivering": return ["本次搬运", "托盘正在移向沙发茶几，送达后才记为完成。"]
		"delivered": return ["本次送达", "四杯茶已稳稳放到沙发茶几。拉回提手，可以继续试。"]
		"lifting": return ["正在试提", "提手正在受力，等托盘停稳后再看结果。"]
	# Configuration changes and cancelled trials return to neutral guidance;
	# neither is a new completed experiment or a fabricated history entry.
	return ["备茶记录", "铜线是各杯需水量。细流接水；接多了，握杯移到下方水槽倒回。"]

func _draw() -> void:
	draw_table("茶水休息区 · 备水与平衡")
	ink("沙发茶几",Vector2(42,235),18)
	if not book_open:ApparatusStyle.grip(self,Vector2(884,103),"book")
	ink("细流阀",Vector2(821,224),17)
	ink("4 ml/s",Vector2(826,248),16)
	if not model.draining: ink("倒回水槽",Vector2(824,480),16)
	for i: int in 4:
		var cup: int = model.cups[i]
		if gesture == "cup" and selected_slot == i: continue
		# Tags follow the tray's front edge, clear of the pale metal rim in every pose.
		var at: Vector2 = miniature.screen(local_point(Model.ARMS[i]*SPACING,92,6))+Vector2(-38,13)
		if model.dock_slot == i: at = DOCK+Vector2(-38,61)
		draw_rect(Rect2(at-Vector2(4,18),Vector2(86,23)),Color("253e46"))
		ink("%s %d ml" % [char(65+cup),roundi(model.water[cup])],at,17,Color("f5f1e4"))
	if model.phase == "table": ApparatusStyle.grip(self,handle_at(),"vertical",gesture=="handle")
	if model.earned and model.editable(): ApparatusStyle.grip(self,support_at(),"horizontal",gesture=="support")
	draw_cues()
	if feedback_seconds > 0:
		draw_rect(Rect2(16,486,928,46),Color("253e46"))
		ink(feedback,Vector2(28,516),20,Color("f5f1e4"))
	draw_book()

func draw_room_prop(canvas: CanvasItem, box: Rect2, served := false) -> void:
	# Small independent state prop on the existing tabletop, inside its silhouette.
	var c := box.position + Vector2(box.size.x*.77,box.size.y*.28)
	if served: c = box.get_center()-Vector2(0,5)
	var s := .4 if served else .5
	canvas.draw_rect(Rect2(c-Vector2(51,16)*s,Vector2(102,32)*s),Color("36777b"))
	for i: int in 4:
		var at := c+Vector2((i-1.5)*23,-3)*s
		canvas.draw_circle(at,7*s,Color("e2e2d5"))
		canvas.draw_circle(at-Vector2(0,2)*s,4*s,Color("db8248"))
