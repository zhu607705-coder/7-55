extends RefCounted
## Source ChapterFourRoom204Model + source atlas foot-box transforms.
static var cache: Dictionary = {}
static func data() -> Dictionary:
	if cache.is_empty():
		var layout: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-three-floor-maze.layout.json"))
		var content: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-755.content.json"))
		var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/rpg/interiors/finale/finale_environment_manifest.json"))
		cache={"layout":layout.room204Runtime,"groups":content.room204.groups,"sheets":{}}
		for sheet in manifest.spritesheets:
			if sheet.id in ["chapter4_room204_furniture","chapter4_room204_residual","chapter4_story_items","chapter4_clock_states","chapter4_power_panel_states"]:
				cache.sheets[sheet.id]={"path":sheet.sourceFile.replace("src/assets/","res://assets/"),"frames":{}}
				for frame in sheet.frames: cache.sheets[sheet.id].frames[frame.id]=frame
	return cache
static func point(p: Dictionary) -> Vector2: return Vector2(float(p.x),float(p.y))
static func rect(r: Dictionary) -> Rect2: return Rect2(float(r.x),float(r.y),float(r.width),float(r.height))
static func normalize(placements: Array) -> Array:
	var d: Dictionary=data(); var pieces: Array=[]; var slots: Array=[]; var out: Array=[]
	for entry in d.layout.initialPiecePairs: pieces.append(entry.pieceId)
	for entry in d.layout.slotTargets: slots.append(entry.slotId)
	var used_pieces: Array=[]; var used_slots: Array=[]
	for p in placements:
		if not p is Dictionary or p.get("pieceId") not in pieces or p.get("slotId") not in slots or p.get("orientation")!="up" or p.pieceId in used_pieces or p.slotId in used_slots: continue
		out.append(p.duplicate()); used_pieces.append(p.pieceId); used_slots.append(p.slotId)
	return out
static func complete(placements: Array) -> bool: return normalize(placements).size()==12
static func group_complete(group: Dictionary,placements: Array) -> bool:
	var pieces: Array=[]
	for p in normalize(placements): pieces.append(p.pieceId)
	for m in group.mappings:
		if m.pieceId not in pieces: return false
	return true
static func presentation(state: Dictionary) -> String:
	var c: Dictionary=state.get("chapter4",{})
	if c.get("floor","")!="A2": return "hidden"
	if c.get("phase","")=="room204_restore": return "interactive"
	if c.get("phase","") in ["maintenance_repair","blackout_light_grid","final_chase","final_minute_recovery","return_to_clock","morning_checkin","exterior_closure","complete"] and "room204_restored" in c.get("factIds",[]) and complete(c.get("room204Placements",[])): return "restored"
	return "hidden"
static func group_available(state: Dictionary) -> bool:
	var c: Dictionary=state.get("chapter4",{})
	return c.get("phase","")=="room204_restore" and c.get("floor","")=="A2" and c.get("mode","")=="light" and "misaligned_stair_solved" in c.get("factIds",[]) and "a3_reference_observed" in c.get("factIds",[]) and "room204_residual_observed" in c.get("factIds",[])
static func group_result(current: Array,id: String,target: String,orientation: String="up") -> Dictionary:
	var placements: Array=normalize(current); var group: Dictionary={}
	for entry in data().groups:
		if entry.id==id: group=entry
	if group.is_empty(): return {"accepted":false,"issue":"room204_unknown_group"}
	if target!=id or orientation!="up": return {"accepted":false,"issue":"room204_wrong_group"}
	if group_complete(group,placements): return {"accepted":false,"issue":"room204_group_already_placed"}
	var occupied: Array=[]; var pieces: Array=[]; var missing: Array=[]; var slots: Array=[]
	for p in placements: occupied.append(p.slotId); pieces.append(p.pieceId)
	for m in group.mappings:
		if m.pieceId not in pieces: missing.append(m)
		if m.slotId not in occupied: slots.append(m.slotId)
	if slots.size()<missing.size(): return {"accepted":false,"issue":"room204_group_conflict"}
	for m in missing:
		var slot: String=m.slotId if m.slotId in slots else slots[0]
		slots.erase(slot); placements.append({"pieceId":m.pieceId,"slotId":slot,"orientation":"up"})
	return {"accepted":true,"placements":placements,"rationale":group.rationale}
static func entities(state: Dictionary) -> Array:
	if presentation(state)=="hidden": return []
	var d: Dictionary=data(); var l: Dictionary=d.layout; var out: Array=[]; var placed: Dictionary={}; var slots: Dictionary={}
	for p in normalize(state.chapter4.get("room204Placements",[])): placed[p.pieceId]=p
	for slot in l.slotTargets: slots[slot.slotId]=slot.center
	for piece in l.initialPiecePairs:
		var restored: bool=placed.has(piece.pieceId); var p: Vector2=point(slots[placed[piece.pieceId].slotId] if restored else piece.position)
		if restored: out.append(entity(piece.deskFrame,p+point(l.pairOffsets.desk),0,piece.pieceId,"desk"))
		out.append(entity(piece.chairFrame,p+point(l.pairOffsets.chair),0 if restored else float(piece.angle),piece.pieceId,"chair"))
	for table in l.discussionTables:
		var visible: bool=false
		for id in table.pieceIds:
			if not placed.has(id): visible=true
		if visible: out.append(entity(table.frame,point(table.position),float(table.angle),table.id,"table"))
	out.append(entity(l.podium.frame,point(l.podium.position),0,"podium","podium"))
	out.sort_custom(func(a,b): return a.position.y<b.position.y)
	return out
static func entity(frame: String,p: Vector2,angle: float,id: String,kind: String) -> Dictionary:
	return {"frame":frame,"position":p,"angle":angle,"id":id,"kind":kind,"depth":p.y+1}
static func entity_collision(e: Dictionary) -> Rect2:
	var frame: Dictionary=data().sheets.chapter4_room204_furniture.frames[e.frame]
	var b: Rect2=rect(frame.collisionBounds[0].bounds); var pivot: Vector2=point(frame.pivot); var scale: float=float(data().layout.uniformScale); var radians: float=deg_to_rad(float(e.angle))
	var center: Vector2=(b.get_center()-pivot)*scale; center=center.rotated(radians)+e.position
	var dims: Vector2=b.size*scale; var width: float=absf(dims.x*cos(radians))+absf(dims.y*sin(radians)); var height: float=absf(dims.x*sin(radians))+absf(dims.y*cos(radians))
	return Rect2(center-Vector2(width,height)/2,Vector2(width,height))
static func collisions(state: Dictionary) -> Array:
	var out: Array=[]
	for e in entities(state): out.append(entity_collision(e))
	return out
static func distance(p: Vector2,bounds: Rect2) -> float: return p.distance_to(p.clamp(bounds.position,bounds.end))
