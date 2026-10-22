extends "res://scripts/chapters/c3_base.gd"
## Native port of QizhenJournalModel + ChapterThreeQizhenLakeController journal.
## Capture is a two-phase runtime capability, not a callable photo-forging action.
const CaptureSession = preload("res://scripts/media/c3_capture_session.gd")
const OPTIONAL: Array = ["dock", "reflection", "swan_cove"]
const SPOTS: Dictionary = {
	"lake_center":{"zone":"open_water","label":"湖心","areas":[[700,380,980,560]],"crop":[836,430],"zoom":1},
	"dock":{"zone":"dock","label":"小码头","areas":[[660,150,1080,380],[632,560,788,700]],"crop":[704,540],"zoom":0},
	"reflection":{"zone":"open_water","label":"倒影水面","areas":[[1150,250,1420,460]],"crop":[1290,350],"zoom":1},
	"swan_cove":{"zone":"swan_cove","label":"黑天鹅围栏","areas":[[700,420,900,560]],"crop":[1165,430],"zoom":1}
}
var capture_session: RefCounted = null
var capture_counter: int = 0
var last_capture: RefCounted = null
var last_capture_result: Dictionary = {}
var owner_only: bool = false

func journal_copy() -> Dictionary:
	return content("chapter3-qizhen-lake.content").get("journal",{})

func pages(s: Dictionary) -> Array:
	if not s.qizhenLake.active or not s.qizhenLake.boardingTutorialCompleted: return []
	return [{"id":"c3_journal","label":"CC98 · 启真湖划船记录"},{"id":"c3_journal_camera","label":"相机 · 湖区取景"}]

func view(page: String, s: Dictionary) -> Dictionary:
	if page not in ["c3_journal","c3_journal_camera"]: return {}
	var j: Dictionary = s.qizhenLake.journal
	var projected: Dictionary = project_thread(j,s.qizhenLake)
	if page == "c3_journal_camera":
		var d: Variant = j.get("pendingDraft")
		var result: Dictionary = {"title":journal_copy().camera.title,"body":journal_copy().camera.hint,"journal":j,"draft":d}
		if d is Dictionary: result.photo = d.photo
		return result
	var body: String = projected.mainCaption
	if projected.archived: body = str(journal_copy().thread.archivedNotice)+"\n"+body
	for reply: Dictionary in projected.replies:
		if owner_only and reply.kind != "owner": continue
		body += "\n\n%d 楼 · %s\n%s" % [int(reply.floor),persona_name(reply.personaId),reply.text]
	return {"title":projected.title,"body":body,"thread":projected,"ownerOnly":owner_only}

func actions(page: String, s: Dictionary) -> Array:
	if page not in ["c3_journal","c3_journal_camera"]: return []
	var j: Dictionary = s.qizhenLake.journal
	var copy: Dictionary = journal_copy()
	var list: Array = []
	if page == "c3_journal":
		list.append(command("c3_journal_filter",copy.thread.showAll if owner_only else copy.thread.ownerOnly))
		if j.status != "archived" and s.qizhenLake.phase != "swan_chase":
			if j.status == "main_draft": list.append(command("c3_journal_publish",copy.thread.publishMain))
			if j.status in ["open","summary_ready"]:
				for spot: String in OPTIONAL:
					if j.optionalPhotos.has(spot) and not j.publishedSpotIds.has(spot):
						list.append(command("c3_journal_reply:"+spot,str(copy.spotNames[spot])+" · "+str(copy.thread.publishReply)))
		list.append(command("c3_journal_return",copy.thread.returnToLake))
		return list
	if j.status == "archived" or s.qizhenLake.phase == "swan_chase": return []
	var draft: Variant = j.get("pendingDraft")
	if draft is Dictionary:
		if draft.kind == "main":
			list.append({"id":"c3_journal_draft","label":copy.camera.saveDraft,"inputs":[{"id":"titleId","label":copy.camera.draftMainTitle,"type":"choice","options":options_for(copy.titles)},{"id":"statusId","label":copy.camera.draftMainStatus,"type":"choice","options":options_for(copy.statuses)}]})
		elif copy.spotCaptions.has(draft.photo.spotId):
			list.append({"id":"c3_journal_draft","label":copy.camera.saveDraft,"inputs":[{"id":"captionId","label":copy.camera.draftSpotCaption,"type":"choice","options":options_for(copy.spotCaptions[draft.photo.spotId])}]})
		list.append(command("c3_journal_retake",copy.camera.retake))
	else:
		list.append(command("c3_photo",copy.camera.shutter))
	list.append(command("c3_journal_close",copy.camera.close))
	return list

func options_for(entries: Array) -> Array:
	var list: Array=[]
	for entry: Dictionary in entries: list.append(option(entry.id,entry.text))
	return list

func dispatch(s: Dictionary, action: String, value: Variant = null) -> Dictionary:
	if action != "c3_photo" and not action.begins_with("c3_journal_"): return {}
	match action:
		"c3_photo": return request_capture(s,str(value) if value is String else "")
		"c3_journal_capture_result": return finish_capture(s,value)
		"c3_journal_capture_cancel": return cancel_capture(value)
		"c3_journal_draft": return save_draft(s,value)
		"c3_journal_publish": return publish_main(s)
		"c3_journal_retake": return discard_draft(s,"retake")
		"c3_journal_close":
			var result: Dictionary=discard_draft(s,"close")
			result.page="c3_journal"
			return result
		"c3_journal_filter":
			owner_only=not owner_only
			return ok()
		"c3_journal_return":
			if s.qizhenLake.phase in ["inactive","location_search","complete"]: return reject("inactive")
			return enter(s,"qizhen_lake","c3_lake",str(s.rpgCheckpoint))
	if action.begins_with("c3_journal_reply:"): return publish_reply(s,action.trim_prefix("c3_journal_reply:"))
	return {}

func ok(message: String = "", duplicate: bool = false) -> Dictionary:
	return {"handled":true,"accepted":true,"message":message,"duplicate":duplicate}

func reject(reason: String) -> Dictionary:
	var messages: Dictionary={
		"inactive":"这里暂时不能打开湖区相机。","swan_chase":"黑天鹅正追着船尾,顾不上拍照。",
		"journal_locked":"完成上船教学后再打开相机。","journal_archived":"帖子已归档,仅供查看。","archived":"帖子已归档,仅供查看。",
		"unknown_spot":"这里没有可用的湖区拍摄点。","wrong_scene":"返回启真湖后再打开相机。","wrong_spot":"这里构不成画面,靠近本区拍摄位置再拍。",
		"wrong_vehicle":"这里要上船后才能取景。","capture_pending":"相机正在保存这一帧。","capture_invalid":"没有收到这次相机拍下的实际画面，请重新拍摄。",
		"capture_failed":"画面尚未保存，请重新拍摄。","no_draft":"先拍摄并保存主帖草稿。","incomplete_draft":"草稿仍未填写完整。",
		"draft_mismatch":"草稿与当前照片不一致，请重新选择。","orphan_photo":"这张照片已被重拍，请打开当前照片。",
		"not_open":"主帖还没有发布。","no_photo":"这个地点还没有照片。","already_published":"湖区记录只保留一个主帖。"}
	var message: String=str(journal_copy().thread.networkError.body) if reason=="offline" else str(messages.get(reason,"这个操作暂时不可用。"))
	return {"handled":true,"accepted":false,"reason":reason,"message":message}

## Read-only precheck, including source locked → capture_ready compatibility.
func precheck_capture(s: Dictionary, spot: String) -> Dictionary:
	var q: Dictionary=s.qizhenLake
	if not q.active or q.phase=="inactive": return reject("inactive")
	if q.phase=="swan_chase": return reject("swan_chase")
	if not SPOTS.has(spot): return reject("unknown_spot")
	if q.journal.status=="archived": return reject("journal_archived")
	if q.journal.status=="locked" and not q.boardingTutorialCompleted: return reject("journal_locked")
	return ok()

func player_point(s: Dictionary) -> Vector2:
	var p: Variant=s.native.get("player",{})
	if p is Dictionary and p.has("qizhen_lake"): p=p.qizhen_lake
	if p is Array and p.size()>=2: return Vector2(float(p[0]),float(p[1]))
	if p is Dictionary and p.has("x") and p.has("y"): return Vector2(float(p.x),float(p.y))
	return Vector2(INF,INF)

func resolve_spot(zone: String, point: Vector2) -> String:
	for id: String in SPOTS:
		if SPOTS[id].zone != zone: continue
		for area: Array in SPOTS[id].areas:
			if point.x>=float(area[0]) and point.x<=float(area[2]) and point.y>=float(area[1]) and point.y<=float(area[3]): return id
	return ""

func request_capture(s: Dictionary, requested_spot: String="") -> Dictionary:
	var q: Dictionary=s.qizhenLake
	if s.native.get("scene","")!="qizhen_lake": return reject("wrong_scene")
	var p: Vector2=player_point(s)
	var spot: String=resolve_spot(str(q.zone),p)
	if spot.is_empty() or (not requested_spot.is_empty() and requested_spot!=spot): return reject("wrong_spot")
	var check: Dictionary=precheck_capture(s,spot)
	if not check.accepted: return check
	if q.vehicle!="kayak" and q.zone!="dock": return reject("wrong_vehicle")
	if capture_session!=null: return reject("capture_pending")
	capture_counter+=1
	var session: RefCounted=CaptureSession.new()
	session.id="qizhen-camera-%d-%d" % [Time.get_ticks_usec(),capture_counter]
	session.zone=str(q.zone)
	session.spot_id=spot
	session.expected_player=p
	capture_session=session
	var result: Dictionary=ok()
	result.capture={"session":session,"on_success":"c3_journal_capture_result","on_cancel":"c3_journal_capture_cancel","scene":"qizhen_lake","zone":q.zone,"spotId":spot}
	return result

func cancel_capture(value: Variant) -> Dictionary:
	if capture_session==null or not value is RefCounted or value!=capture_session: return reject("capture_invalid")
	var error: String=str(capture_session.result.get("error",""))
	capture_session.invalidate()
	capture_session=null
	return ok() if error.is_empty() else reject("capture_failed")

func finish_capture(s: Dictionary, value: Variant) -> Dictionary:
	if value is RefCounted and value==last_capture:
		var previous: Dictionary=last_capture_result.duplicate(true)
		previous.duplicate=true
		return previous
	if capture_session==null or not value is RefCounted or value!=capture_session: return reject("capture_invalid")
	var session: RefCounted=capture_session
	capture_session=null
	var check: Dictionary=precheck_capture(s,session.spot_id)
	if not check.accepted:
		session.invalidate()
		return check
	var meta: Dictionary=session.metadata
	var p: Vector2=player_point(s)
	var captured_p: Variant=meta.get("player")
	var valid: bool=session.supplied and not session.consumed and session.image!=null and not session.image.is_empty()
	valid=valid and meta.get("source","")=="world_viewport_crop" and meta.get("scene","")=="qizhen_lake" and meta.get("zone","")==session.zone
	valid=valid and s.native.get("scene","")=="qizhen_lake" and s.qizhenLake.zone==session.zone and resolve_spot(session.zone,p)==session.spot_id
	valid=valid and captured_p is Dictionary and captured_p.has("x") and captured_p.has("y")
	if valid:
		var actual: Vector2=Vector2(float(captured_p.x),float(captured_p.y))
		valid=actual.is_finite() and actual.distance_to(session.expected_player)<0.01 and p.distance_to(actual)<0.01
	for key: String in ["speed","roll","heading","capturedAtSeconds"]:
		valid=valid and (meta.get(key) is float or meta.get(key) is int) and is_finite(float(meta.get(key,INF)))
	if valid:
		valid=float(meta.capturedAtSeconds)>=0 and float(meta.capturedAtSeconds)==floorf(float(meta.capturedAtSeconds))
		valid=valid and session.image.get_width()>=320 and session.image.get_height()>=180 and session.image.get_width()<=3840 and session.image.get_height()<=2160
		valid=valid and image_has_variance(session.image)
	if not valid:
		session.invalidate()
		return reject("capture_invalid")
	var j: Dictionary=s.qizhenLake.journal
	var captured: int=int(meta.capturedAtSeconds)
	var id: String="qizhen-photo-%s-%d" % [session.spot_id,captured]
	var existing: Variant=photo_for(j,session.spot_id)
	if existing is Dictionary and existing.id==id and j.get("pendingDraft") is Dictionary and j.pendingDraft.photo.id==id:
		var duplicate_result: Dictionary=ok("",true)
		duplicate_result.photo=existing
		duplicate_result.draft=j.pendingDraft
		last_capture=session
		last_capture_result=duplicate_result.duplicate(true)
		session.invalidate()
		return duplicate_result
	var folder: String="user://qizhen_journal"
	if DirAccess.make_dir_recursive_absolute(folder)!=OK:
		session.invalidate()
		return reject("capture_failed")
	var path: String=folder+"/"+session.id+".png"
	if session.image.save_png(path)!=OK:
		session.invalidate()
		return reject("capture_failed")
	var recipe: Dictionary=build_recipe(session.spot_id,p,float(meta.heading),float(meta.speed),float(meta.roll),bool(s.qizhenLake.get("swanReleased",false)))
	var photo: Dictionary={"id":id,"spotId":session.spot_id,"capturedAtSeconds":captured,"recipe":recipe,"tags":derive_tags(recipe,floorf(float(meta.speed)+0.5),snappedf(float(meta.roll),0.001)),"nativeImagePath":path,"nativeImageSha256":FileAccess.get_sha256(path)}
	photo.nativeCapture={"source":"world_viewport_crop","width":session.image.get_width(),"height":session.image.get_height()}
	if meta.get("camera") is Dictionary:
		var camera: Dictionary=meta.camera
		if number_in(camera.get("x"),-100000,100000) and number_in(camera.get("y"),-100000,100000) and number_in(camera.get("zoom"),-100000,100000):
			photo.nativeCapture.camera={"x":camera.x,"y":camera.y,"zoom":camera.zoom}
	var kind: String=capture_kind(j,session.spot_id)
	var draft: Dictionary={"id":"qizhen-draft-"+id,"kind":kind,"photo":photo,"titleId":j.mainTitleId if kind=="main" else null,"statusId":j.mainStatusId if kind=="main" else null,"captionId":null}
	if j.status=="locked": j.status="capture_ready"
	if session.spot_id=="lake_center": j.mainPhoto=photo
	else: j.optionalPhotos[session.spot_id]=photo
	apply_draft(j,draft)
	var result: Dictionary=ok("照片已保存。")
	result.photo=photo
	result.draft=draft
	result.page="c3_journal_camera"
	last_capture=session
	last_capture_result=result.duplicate(true)
	session.invalidate()
	return result

func photo_for(j: Dictionary, spot: String) -> Variant:
	return j.get("mainPhoto") if spot=="lake_center" else j.optionalPhotos.get(spot)

func capture_kind(j: Dictionary, spot: String) -> String:
	if spot!="lake_center": return "spot"
	return "spot" if j.publishedSpotIds.has("lake_center") or j.status in ["open","summary_ready","archived"] else "main"

func build_recipe(spot: String, p: Vector2, heading: float, speed: float, roll: float, swan_gone: bool=false) -> Dictionary:
	var definition: Dictionary=SPOTS[spot]
	# JavaScript Math.round is floor(x+0.5), including negative half steps.
	var recipe: Dictionary={"zone":definition.zone,"cropCenterX":definition.crop[0],"cropCenterY":definition.crop[1],"zoomStep":definition.zoom,"kayakX":int(floorf(p.x+0.5)),"kayakY":int(floorf(p.y+0.5)),"headingBucket":posmod(int(floorf(heading/(PI/4.0)+0.5)),8)}
	if spot=="swan_cove":
		var distance: float=p.distance_to(Vector2(1160,400))
		recipe.swanDistanceBucket="gone" if swan_gone else "near" if distance<330 else "mid" if distance<430 else "far"
	if spot=="reflection":
		var clarity: float=clampf(1.0-absf(speed)/240.0-absf(roll)/1.2,0,1)
		recipe.rippleClarityBucket="clear" if clarity>=0.66 else "partial" if clarity>=0.33 else "lost"
	return recipe

func derive_tags(recipe: Dictionary, speed: float, roll: float) -> Array:
	var tags: Array=[]
	if absf(speed)>90: tags.append("high_speed")
	if absf(roll)>0.18: tags.append("tilted")
	if absf(speed)<=90 and absf(roll)<=0.18: tags.append("composition_ok")
	if recipe.get("rippleClarityBucket")=="clear": tags.append("ripple_clear")
	elif recipe.get("rippleClarityBucket") in ["partial","lost"]: tags.append("ripple_broken")
	if recipe.get("swanDistanceBucket")=="near": tags.append("swan_near")
	elif recipe.get("swanDistanceBucket")=="far": tags.append("swan_far")
	elif recipe.get("swanDistanceBucket")=="gone": tags.append("swan_aftermath")
	return tags

func apply_draft(j: Dictionary, draft: Dictionary) -> void:
	if draft.kind=="main":
		if j.status=="capture_ready": j.status="main_draft"
		j.mainTitleId=draft.titleId
		j.mainStatusId=draft.statusId
	j.pendingDraft=draft

func contains_option(entries: Array, id: Variant) -> bool:
	for entry: Dictionary in entries:
		if entry.id==id: return true
	return false

func save_draft(s: Dictionary, value: Variant) -> Dictionary:
	var q: Dictionary=s.qizhenLake
	var j: Dictionary=q.journal
	if not q.active or q.phase=="inactive": return reject("inactive")
	if q.phase=="swan_chase": return reject("swan_chase")
	if j.status=="archived": return reject("journal_archived")
	if j.status=="locked" and not q.boardingTutorialCompleted: return reject("journal_locked")
	if not value is Dictionary or not j.get("pendingDraft") is Dictionary: return reject("no_draft")
	var draft: Dictionary=j.pendingDraft.duplicate(true)
	# Direct full-draft submissions retain the source identity/orphan checks.
	if value.has("photo"):
		if not value.photo is Dictionary or not value.has("id"): return reject("draft_mismatch")
		draft=value.duplicate(true)
	else:
		for key: String in ["titleId","statusId","captionId"]:
			if value.has(key): draft[key]=value[key]
	if draft.id!="qizhen-draft-"+str(draft.photo.id): return reject("draft_mismatch")
	var stored: Variant=photo_for(j,str(draft.photo.spotId))
	if not stored is Dictionary or stored.id!=draft.photo.id: return reject("orphan_photo")
	var expected: String=capture_kind(j,str(stored.spotId))
	if draft.kind!=expected: return reject("draft_mismatch")
	var copy: Dictionary=journal_copy()
	if draft.kind=="main":
		if not contains_option(copy.titles,draft.get("titleId")) or not contains_option(copy.statuses,draft.get("statusId")): return reject("incomplete_draft")
	else:
		if not copy.spotCaptions.has(stored.spotId) or not contains_option(copy.spotCaptions[stored.spotId],draft.get("captionId")): return reject("incomplete_draft")
	var sanitized: Dictionary={"id":draft.id,"kind":draft.kind,"photo":stored,"titleId":draft.titleId if draft.kind=="main" else null,"statusId":draft.statusId if draft.kind=="main" else null,"captionId":draft.captionId if draft.kind=="spot" else null}
	var duplicate: bool=drafts_equal(j.pendingDraft,sanitized)
	if not duplicate:
		if j.status=="locked": j.status="capture_ready"
		apply_draft(j,sanitized)
	var result: Dictionary=ok(str(copy.camera.draftSaved),duplicate)
	result.draft=j.pendingDraft
	return result

func drafts_equal(a: Dictionary, b: Dictionary) -> bool:
	return a.id==b.id and a.kind==b.kind and a.photo.id==b.photo.id and a.get("titleId")==b.get("titleId") and a.get("statusId")==b.get("statusId") and a.get("captionId")==b.get("captionId")

func discard_draft(s: Dictionary, reason: String="close") -> Dictionary:
	var j: Dictionary=s.qizhenLake.journal
	var draft: Variant=j.get("pendingDraft")
	var result: Dictionary=ok()
	result.discarded=false
	if not draft is Dictionary: return result
	var saved: bool=(draft.get("titleId")!=null and not str(draft.titleId).is_empty() and draft.get("statusId")!=null and not str(draft.statusId).is_empty()) if draft.kind=="main" else (draft.get("captionId")!=null and not str(draft.captionId).is_empty())
	if reason=="close" and saved: return result
	if not j.publishedSpotIds.has(draft.photo.spotId):
		if draft.kind=="main" and j.get("mainPhoto") is Dictionary and j.mainPhoto.id==draft.photo.id:
			j.mainPhoto=null
			if j.status=="main_draft": j.status="capture_ready"
		elif draft.kind=="spot" and j.optionalPhotos.has(draft.photo.spotId) and j.optionalPhotos[draft.photo.spotId].id==draft.photo.id:
			j.optionalPhotos.erase(draft.photo.spotId)
	j.pendingDraft=null
	result.discarded=true
	return result

func precheck_main_publish(s: Dictionary) -> Dictionary:
	var j: Dictionary=s.qizhenLake.journal
	if s.qizhenLake.phase=="swan_chase": return reject("swan_chase")
	if j.status=="archived": return reject("archived")
	if j.status in ["open","summary_ready"]:
		var d: Variant=j.get("pendingDraft")
		var retry: bool=not d is Dictionary or d.kind!="main" or (j.get("mainPhoto") is Dictionary and d.id=="qizhen-draft-"+str(j.mainPhoto.id))
		return ok("",true) if retry else reject("already_published")
	if j.status=="locked": return reject("journal_locked")
	if j.status=="capture_ready": return reject("no_draft")
	var draft: Variant=j.get("pendingDraft")
	if not draft is Dictionary or draft.kind!="main": return reject("no_draft")
	if not draft.get("titleId") or not draft.get("statusId"): return reject("incomplete_draft")
	if s.networkMode!="campus_wifi": return reject("offline")
	return ok()

func publish_main(s: Dictionary) -> Dictionary:
	var check: Dictionary=precheck_main_publish(s)
	if not check.accepted or check.duplicate: return check
	var j: Dictionary=s.qizhenLake.journal
	var draft: Dictionary=j.pendingDraft
	j.threadSeed=int(j.threadSeed) if int(j.threadSeed)>=1 else randi_range(1,2147483647)
	if str(j.threadId).is_empty(): j.threadId="qizhen-journal-"+str(j.threadSeed)
	unique(j.publishedSpotIds,"lake_center")
	j.mainTitleId=draft.titleId
	j.mainStatusId=draft.statusId
	j.pendingDraft=null
	j.status="open"
	return ok("划船记录已发布。")

func precheck_reply(s: Dictionary, spot: String) -> Dictionary:
	var j: Dictionary=s.qizhenLake.journal
	if s.qizhenLake.phase=="swan_chase": return reject("swan_chase")
	if j.status=="archived": return reject("archived")
	if j.status=="locked": return reject("journal_locked")
	if j.status in ["capture_ready","main_draft"]: return reject("not_open")
	if j.publishedSpotIds.has(spot): return ok("",true)
	if spot=="lake_center" or not j.optionalPhotos.has(spot): return reject("no_photo")
	if s.networkMode!="campus_wifi": return reject("offline")
	return ok()

func publish_reply(s: Dictionary, spot: String) -> Dictionary:
	var check: Dictionary=precheck_reply(s,spot)
	if not check.accepted or check.duplicate: return check
	unique(s.qizhenLake.journal.publishedSpotIds,spot)
	# Source leaves the caption-bearing pending draft intact after posting.
	return ok("照片已追加到帖子。")

## Unsigned 32-bit source-exact FNV / seed mixing / mulberry32 / Fisher-Yates.
func imul32(a: int, b: int) -> int:
	var low: int=(a & 65535)*(b & 65535)
	var cross: int=((a>>16)&65535)*(b&65535)+(a&65535)*((b>>16)&65535)
	return (low+((cross & 65535)<<16)) & 0xffffffff

func fnv1a(text_value: String) -> int:
	var hash_value: int=0x811c9dc5
	for i: int in text_value.length():
		var code: int=text_value.unicode_at(i)
		# JS hashes UTF-16 code units, including surrogate pairs for astral text.
		if code>65535:
			var pair: int=code-65536
			hash_value=imul32(hash_value ^ (0xd800+(pair>>10)),0x01000193)
			code=0xdc00+(pair & 1023)
		hash_value=imul32(hash_value ^ code,0x01000193)
	return hash_value

func mixed_seed(seed: int, salt: int) -> int:
	var h: int=(seed & 0xffffffff)^0x9e3779b9
	h=imul32(h ^ (salt & 0xffffffff),0x85ebca6b)
	h=h ^ (h>>13)
	h=imul32(h,0xc2b2ae35)
	return (h ^ (h>>16)) & 0xffffffff

func random_step(rng: Dictionary) -> float:
	rng.a=(int(rng.a)+0x6d2b79f5) & 0xffffffff
	var t: int=int(rng.a)
	t=imul32(t ^ (t>>15),t | 1)
	t=(t ^ ((t+imul32(t ^ (t>>7),t | 61)) & 0xffffffff)) & 0xffffffff
	return float((t ^ (t>>14)) & 0xffffffff)/4294967296.0

func select_replies(pool: Array, seed: int, count_value: int, salt: int) -> Array:
	var indices: Array=range(pool.size())
	var rng: Dictionary={"a":mixed_seed(seed,salt)}
	for i: int in range(indices.size()-1,0,-1):
		var j: int=int(floorf(random_step(rng)*float(i+1)))
		var held: int=indices[i]
		indices[i]=indices[j]
		indices[j]=held
	var output: Array=[]
	for i: int in range(clampi(count_value,0,pool.size())): output.append(pool[indices[i]])
	return output

func reply_salt(tags: Array, input: Dictionary, publish_order: int) -> int:
	var parts: Array=tags.duplicate()
	parts.append_array(["capsize:%d" % int(input.get("capsizeCount",0)),"dockCollision:%d" % int(input.get("dockCollisionCount",0)),"swanAlert:%d" % int(input.get("swanAlertLevel",0)),"order:%d" % publish_order])
	return fnv1a("\n".join(parts))

func option_text(entries: Array, id: Variant, fallback: String="") -> String:
	for entry: Dictionary in entries:
		if entry.id==id: return str(entry.text)
	return fallback

func spot_caption(photo: Dictionary) -> String:
	if photo.spotId=="lake_center": return ""
	var entries: Array=journal_copy().spotCaptions.get(photo.spotId,[])
	return "" if entries.is_empty() else str(entries[fnv1a(photo.id)%entries.size()].text)

func main_caption(status_text: String, photo: Variant) -> String:
	if not photo is Dictionary: return status_text+"。主图还没拍，等我先把船划到湖心。"
	var labels: Array=[]
	for tag: String in photo.tags:
		var label_value: String=str(journal_copy().tagLabels.get(tag,""))
		if not label_value.is_empty(): labels.append(label_value)
	var tag_part: String="标签："+"、".join(labels)+"。" if not labels.is_empty() else ""
	return status_text+"。主图是在湖心按的快门，"+tag_part+"先占 1 楼，后面慢慢补。"

func project_thread(j: Dictionary, input: Dictionary) -> Dictionary:
	var copy: Dictionary=journal_copy()
	var published: bool=j.status in ["open","summary_ready","archived"]
	var title: String=option_text(copy.titles,j.get("mainTitleId"),"（标题未定）") if published else "（标题未定）"
	var status_text: String=option_text(copy.statuses,j.get("mainStatusId"),"（状态未定）") if published else "（状态未定）"
	var replies: Array=[]
	var next_floor: int=2
	if published and j.get("mainPhoto") is Dictionary:
		var main_salt: int=reply_salt(j.mainPhoto.tags,input,0)
		for picked: Dictionary in select_replies(copy.replyPools.main,int(j.threadSeed),2+(main_salt%2),main_salt):
			replies.append({"id":picked.id,"kind":"passerby","floor":next_floor,"personaId":picked.personaId,"text":picked.text,"photo":null,"likes":picked.likes})
			next_floor+=1
		for publish_index: int in range(j.publishedSpotIds.size()):
			var spot: String=j.publishedSpotIds[publish_index]
			if spot=="lake_center" or not j.optionalPhotos.has(spot): continue
			var photo: Dictionary=j.optionalPhotos[spot]
			replies.append({"id":"owner-"+str(photo.id),"kind":"owner","floor":next_floor,"personaId":null,"text":spot_caption(photo),"photo":photo,"likes":str(2+fnv1a(photo.id)%30)})
			next_floor+=1
			var salt: int=reply_salt(photo.tags,input,publish_index+1)
			for picked: Dictionary in select_replies(copy.replyPools[spot],int(j.threadSeed),1+(salt%2),salt):
				replies.append({"id":picked.id,"kind":"passerby","floor":next_floor,"personaId":picked.personaId,"text":picked.text,"photo":null,"likes":picked.likes})
				next_floor+=1
	var unpublished: Array=[]
	for spot: String in OPTIONAL:
		if j.optionalPhotos.has(spot) and not j.publishedSpotIds.has(spot): unpublished.append(spot)
	return {"status":j.status,"threadId":j.threadId if not str(j.threadId).is_empty() else "qizhen-journal-thread","title":title,"statusText":status_text,"board":copy.thread.board,"mainPhoto":j.get("mainPhoto"),"mainCaption":main_caption(status_text,j.get("mainPhoto")),"replies":replies,"pendingDraft":j.get("pendingDraft"),"unpublishedSpotIds":unpublished,"archived":j.status=="archived"}

func persona_name(id: Variant) -> String:
	if id==null: return str(journal_copy().thread.authorRole)
	if not cache.has("journal_personas"):
		cache.journal_personas=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/cc98.thread-personas.json"))
	for persona: Dictionary in cache.journal_personas:
		if persona.id==id: return str(persona.nickname)
	return str(id)

func image_for(photo: Variant) -> Image:
	if not photo is Dictionary: return null
	var path: String=str(photo.get("nativeImagePath",""))
	if not path.begins_with("user://qizhen_journal/") or path.contains("..") or not FileAccess.file_exists(path): return null
	if FileAccess.get_sha256(path)!=str(photo.get("nativeImageSha256","")): return null
	var result: Image=Image.load_from_file(path)
	return result if result!=null and not result.is_empty() else null

## Shared save-owner hooks: nullable source photo/draft fields are dictionaries
## after capture. Generic null/scalar shape checks cannot validate these records.
func number_in(value: Variant, minimum: float, maximum: float, integer: bool=false) -> bool:
	if not value is int and not value is float: return false
	var n: float=float(value)
	return is_finite(n) and n>=minimum and n<=maximum and (not integer or n==floorf(n))

func validate_photo_record(value: Variant) -> bool:
	if not value is Dictionary or not value.get("id") is String or str(value.id).is_empty(): return false
	if not SPOTS.has(value.get("spotId")) or not number_in(value.get("capturedAtSeconds"),0,INF,true): return false
	var recipe: Variant=value.get("recipe")
	if not recipe is Dictionary or recipe.get("zone") not in ["dock","open_water","channel","swan_cove"]: return false
	for key: String in ["cropCenterX","kayakX"]:
		if not number_in(recipe.get(key),0,1672): return false
	for key: String in ["cropCenterY","kayakY"]:
		if not number_in(recipe.get(key),0,941): return false
	if not number_in(recipe.get("zoomStep"),0,2,true) or not number_in(recipe.get("headingBucket"),0,7,true): return false
	if recipe.has("swanDistanceBucket") and recipe.swanDistanceBucket not in ["near","mid","far","gone"]: return false
	if recipe.has("rippleClarityBucket") and recipe.rippleClarityBucket not in ["clear","partial","lost"]: return false
	if not value.get("tags") is Array or value.tags.size()>8: return false
	var seen: Array=[]
	for tag: Variant in value.tags:
		if not tag is String or not journal_copy().tagLabels.has(tag) or seen.has(tag): return false
		seen.append(tag)
	if value.has("nativeImagePath") or value.has("nativeImageSha256"):
		if not value.get("nativeImagePath") is String or not value.get("nativeImageSha256") is String: return false
		var path: String=value.nativeImagePath
		var digest: String=value.nativeImageSha256
		if not path.begins_with("user://qizhen_journal/") or path.contains("..") or not path.ends_with(".png") or digest.length()!=64: return false
		for i: int in range(digest.length()):
			if "0123456789abcdef".find(digest.substr(i,1))<0: return false
	if value.has("nativeCapture"):
		var metadata: Variant=value.nativeCapture
		if not metadata is Dictionary or metadata.get("source")!="world_viewport_crop": return false
		if not number_in(metadata.get("width"),320,3840,true) or not number_in(metadata.get("height"),180,2160,true): return false
		if metadata.has("camera"):
			if not metadata.camera is Dictionary: return false
			for key: String in ["x","y","zoom"]:
				if not number_in(metadata.camera.get(key),-100000,100000): return false
	return true

func validate_journal_snapshot(j: Variant) -> bool:
	if not j is Dictionary or j.get("status") not in ["locked","capture_ready","main_draft","open","summary_ready","archived"]: return false
	if not j.get("threadId") is String or not number_in(j.get("threadSeed"),0,9007199254740991.0,true): return false
	if j.get("mainPhoto")!=null and (not validate_photo_record(j.mainPhoto) or j.mainPhoto.spotId!="lake_center"): return false
	if not j.get("optionalPhotos") is Dictionary or j.optionalPhotos.size()>3: return false
	for spot: Variant in j.optionalPhotos:
		if spot not in OPTIONAL or not validate_photo_record(j.optionalPhotos[spot]) or j.optionalPhotos[spot].spotId!=spot: return false
	# Source SaveStore preserves nullable authored IDs verbatim, including IDs
	# absent from the current catalog. Live draft authoring still validates choices.
	if j.get("mainTitleId")!=null and not j.mainTitleId is String: return false
	if j.get("mainStatusId")!=null and not j.mainStatusId is String: return false
	if not j.get("publishedSpotIds") is Array or j.publishedSpotIds.size()>4: return false
	var seen: Array=[]
	for spot: Variant in j.publishedSpotIds:
		if not SPOTS.has(spot) or seen.has(spot): return false
		seen.append(spot)
	if j.get("summaryChoice")!=null and j.summaryChoice not in ["safe_return","details_withheld"]: return false
	for key: String in ["summaryPublished","fishingAssistUnlocked","fishingAssistConsumed","memoryCardUnlocked"]:
		if not j.get(key) is bool: return false
	var draft: Variant=j.get("pendingDraft")
	if draft==null: return true
	if not draft is Dictionary or draft.get("kind") not in ["main","spot"] or not validate_photo_record(draft.get("photo")): return false
	var stored: Variant=photo_for(j,str(draft.photo.spotId))
	if not stored is Dictionary or stored.id!=draft.photo.id or draft.get("id")!="qizhen-draft-"+str(stored.id): return false
	if JSON.parse_string(JSON.stringify(stored))!=JSON.parse_string(JSON.stringify(draft.photo)): return false
	for key: String in ["titleId","statusId","captionId"]:
		if not draft.has(key) or (draft[key]!=null and not draft[key] is String): return false
	if draft.kind=="main":
		if stored.spotId!="lake_center": return false
	elif stored.spotId=="lake_center":
		# Runtime source permits an already-published main-photo retake. Native
		# retains it until close; browser SaveStore discards this particular draft.
		if not j.publishedSpotIds.has("lake_center"): return false
	return true


func image_has_variance(image: Image) -> bool:
	if image==null or image.is_empty() or not image.get_used_rect().has_area(): return false
	# Bounded 17x11 grid rejects unreadable black/flat framebuffer captures without
	# scanning the entire image or comparing against any fabricated target image.
	var low: Vector3=Vector3(INF,INF,INF)
	var high: Vector3=Vector3(-INF,-INF,-INF)
	for y: int in range(11):
		for x: int in range(17):
			var pixel: Color=image.get_pixel(int(float(x)*(image.get_width()-1)/16.0),int(float(y)*(image.get_height()-1)/10.0))
			if pixel.a<0.01: continue
			low=Vector3(minf(low.x,pixel.r),minf(low.y,pixel.g),minf(low.z,pixel.b))
			high=Vector3(maxf(high.x,pixel.r),maxf(high.y,pixel.g),maxf(high.z,pixel.b))
	return low.is_finite() and high.distance_to(low)>0.025
