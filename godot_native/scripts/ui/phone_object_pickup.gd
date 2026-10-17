extends Control
## Animation design book anchors01–03. This layer reads accepted state only.
## It owns no story/proof callbacks, save data, sound or inventory transactions.
const FONT=preload("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
const Chrome=preload("res://scripts/ui/phone_chrome.gd")
const ACTIONS={"c1_absence":{"anchor":"01","flag":"cardZeroTaken","node":"CheckinAbsenceZero","page":"checkin","digit":"0","slot":"d1","duration_ms":360.0},"c1_tiyi_digit":{"anchor":"02","flag":"tiyiCountTaken","node":"TiyiSevenPickupSource","page":"tiyi","digit":"7","slot":"d2","duration_ms":480.0},"c1_rain_drop":{"anchor":"03","flag":"waterDropTaken","node":"HomeCollectibleDropGlyph","page":"phone_home","item":"waterDrop","duration_ms":340.0}}
var chrome: Control
var read_authority: Callable
var read_runtime: Callable
var state_owner: Dictionary={}
var pending: Dictionary={}
var current: Dictionary={}
var elapsed_ms:=0.0
var started_count:=0
var last_cancel_reason: String=""
var glyph_texture: TextureRect

func setup(phone_chrome: Control,authority: Callable,runtime: Callable) -> void:
	name="PhoneObjectPickup"; chrome=phone_chrome; read_authority=authority; read_runtime=runtime
	size=Vector2(424,854); mouse_filter=Control.MOUSE_FILTER_IGNORE; z_index=80
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

func reset(reason: String="cancel") -> void:
	if is_instance_valid(glyph_texture): glyph_texture.queue_free(); glyph_texture=null
	state_owner={}; pending={}; current={}; elapsed_ms=0; last_cancel_reason=reason
	queue_redraw()

func capture_action(action: String,page_body: Control,state: Dictionary) -> void:
	reset("next-action")
	if not ACTIONS.has(action) or state.get("actOne",{}).get("phase","")!="prologue": return
	var spec: Dictionary=ACTIONS[action]
	if state.get("native",{}).get("page","")!=spec.page or bool(state.get("flags",{}).get(spec.flag,false)): return
	var source: Control=page_body.find_child(spec.node,true,false)
	if source==null or not source.is_visible_in_tree(): return
	var transform:=get_global_transform_with_canvas().affine_inverse()*source.get_global_transform_with_canvas()
	var source_rect:=Rect2(transform.origin,source.size*transform.get_scale())
	if not Rect2(Vector2.ZERO,size).encloses(source_rect): return
	state_owner=state
	pending={"action":action,"spec":spec,"source":source_rect,"font_size":source.get_theme_font_size("font_size")*transform.get_scale().x,"ink":source.get_theme_color("font_color"),"accepted":false}
	if source.has_meta("pickup_texture"):
		pending.kind="texture"; pending.texture=source.get_meta("pickup_texture"); pending.material=source.get_meta("pickup_material")

func accept_action(action: String,previous: Dictionary,next: Dictionary,result: Dictionary) -> void:
	if pending.is_empty() or pending.action!=action: return
	var spec: Dictionary=pending.spec
	if not bool(result.get("handled",false)) or bool(previous.get("flags",{}).get(spec.flag,false)) or not bool(next.get("flags",{}).get(spec.flag,false)):
		reset("no-success-edge"); return
	if spec.has("item"):
		if not bool(next.get("items",{}).get(spec.item,false)): reset("no-earned-item"); return
	elif str(next.get("digits",{}).get(spec.slot,""))!=spec.digit:
		reset("no-earned-digit"); return
	pending.accepted=true

func _valid_owner() -> bool:
	if state_owner.is_empty() or not read_authority.is_valid(): return false
	var state: Dictionary=read_authority.call()
	var data: Dictionary=pending if not pending.is_empty() else current
	if data.is_empty() or not is_same(state_owner,state): return false
	var spec: Dictionary=data.spec
	if str(state.get("native",{}).get("page",""))!=spec.page: return false
	if read_runtime.is_valid():
		var host: Dictionary=read_runtime.call().get("native",{}).get("host",{})
		if bool(host.get("phone_modal_open",false)) or bool(host.get("minigame_open",false)) or bool(host.get("world_visible",false)): return false
		if DisplayServer.get_name()!="headless" and not bool(host.get("focused",true)): return false
	return is_visible_in_tree()

func after_refresh() -> void:
	if pending.is_empty():
		if not current.is_empty(): reset("page-rebuild")
		return
	if not bool(pending.accepted) or not _valid_owner(): reset("invalid-mount"); return
	# The new item slot is built by a Container during this refresh. Sample its
	# real position only after that already-queued layout pass has completed.
	if pending.spec.has("item") and not bool(pending.get("layout_queued",false)):
		pending.layout_queued=true; _start_pending.call_deferred(); return
	_start_pending()

func _start_pending() -> void:
	if pending.is_empty(): return
	if not bool(pending.accepted) or not _valid_owner(): reset("invalid-mount"); return
	var target: Dictionary=chrome.item_receipt_geometry(str(pending.spec.item)) if pending.spec.has("item") else chrome.digit_clue_geometry(str(pending.spec.slot))
	if target.is_empty(): reset("missing-visible-clue"); return
	current=pending.duplicate(true); pending={}
	current.target=target.rect
	if current.spec.has("item"):
		current.receipt_kind=target.kind
		var from: Vector2=current.source.get_center()+Vector2(0,18)
		current.nearby_slot=target.kind=="visible-slot" and from.distance_to(target.rect.get_center())<=60
		chrome.settle_item_acquisition(str(current.spec.item))
	else:
		current.target_font_size=target.font_size; current.target_ink=target.ink
	current.reduced_motion=bool(state_owner.get("native",{}).get("settings",{}).get("reduced_motion",false))
	z_index=111 if current.spec.has("digit") else 80
	elapsed_ms=0; started_count+=1; queue_redraw()
	if current.get("kind","")=="texture":
		glyph_texture=TextureRect.new(); glyph_texture.name="AcceptedSevenGlyph"
		glyph_texture.texture=current.texture; glyph_texture.material=current.material
		glyph_texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; glyph_texture.stretch_mode=TextureRect.STRETCH_SCALE
		glyph_texture.size=current.source.size; glyph_texture.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(glyph_texture); _position_texture()

func _input(event: InputEvent) -> void:
	if current.is_empty() and pending.is_empty(): return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventKey and event.pressed):
		reset("continued-input")

func _process(delta: float) -> void:
	if current.is_empty(): return
	if not _valid_owner(): reset("state_owner-or-surface-changed"); return
	if bool(read_authority.call().get("native",{}).get("settings",{}).get("reduced_motion",false)): current.reduced_motion=true
	elapsed_ms+=maxf(0,delta)*1000
	if elapsed_ms>=float(current.spec.duration_ms): reset("finished"); return
	_position_texture()
	queue_redraw()

func _position_texture() -> void:
	if not is_instance_valid(glyph_texture) or current.is_empty(): return
	var pose:=sample_at(elapsed_ms)
	glyph_texture.position=pose.anchor; glyph_texture.rotation=pose.rotation; glyph_texture.scale=pose.scale
	glyph_texture.modulate.a=pose.alpha

func sample_at(milliseconds: float) -> Dictionary:
	if current.is_empty(): return {}
	if current.spec.anchor=="02": return _seven_sample(milliseconds)
	if current.spec.anchor=="03": return _water_sample(milliseconds)
	var source: Rect2=current.source; var target: Rect2=current.target
	var start:=source.get_center(); var end:=target.get_center(); var half:=Vector2(0,source.size.y/2)
	var ratio: float=float(current.target_font_size)/float(current.font_size)
	if bool(current.get("reduced_motion",false)):
		return {"center":end,"anchor":end+half*ratio,"rotation":0.0,"scale":Vector2.ONE*ratio,"alpha":1.0,"ink":current.target_ink,"imprint":true}
	var ms:=clampf(milliseconds,0,float(current.spec.duration_ms))
	var anchor:=start+half; var rotation:=0.0; var squash:=Vector2(1.04,.94); var ink: Color=current.ink
	if ms<=110:
		var p:=ms/110.0; anchor=start+half+Vector2(0,-6)*p; rotation=deg_to_rad(8)*p; squash=squash.lerp(Vector2.ONE,p)
	elif ms<=280:
		var p: float=(ms-110)/170.0; var lift:=start+half+Vector2(0,-6); var landing:=end+half*Vector2(1.08,.90)*ratio; var bend:=lift.lerp(landing,.5)+Vector2(-24,-20)
		anchor=(1-p)*(1-p)*lift+2*(1-p)*p*bend+p*p*landing
		rotation=deg_to_rad(8)*(1-p); squash=Vector2.ONE.lerp(Vector2(1.08,.90)*ratio,p); ink=ink.lerp(current.target_ink,p)
	else:
		var p: float=(ms-280)/80.0; squash=Vector2(1.08,.90).lerp(Vector2.ONE,p)*ratio; anchor=end+half*squash; ink=current.target_ink
	var center: Vector2=anchor-(half*squash).rotated(rotation)
	return {"center":center,"anchor":anchor,"rotation":rotation,"scale":squash,"alpha":1.0,"ink":ink,"imprint":ms>=110}

func _seven_sample(milliseconds: float) -> Dictionary:
	var source: Rect2=current.source; var target: Rect2=current.target
	var ratio: float=target.size.y/source.size.y
	var end: Vector2=target.get_center()-source.size*ratio/2
	var anchor:=source.position+Vector2(0,-3); var rotation:=deg_to_rad(6); var squash:=Vector2.ONE
	var ms:=clampf(milliseconds,0,480)
	if bool(current.get("reduced_motion",false)) or ms>=360:
		anchor=end; rotation=0; squash=Vector2.ONE*ratio
	elif ms<=140:
		var p:=ms/140.0; anchor=anchor.lerp(source.position+Vector2(10,-10),p); rotation=lerpf(deg_to_rad(6),deg_to_rad(14),p)
	else:
		var p: float=(ms-140)/220.0; var start:=source.position+Vector2(10,-10); var bend:=start.lerp(end,.5)+Vector2(15,-20)
		anchor=(1-p)*(1-p)*start+2*(1-p)*p*bend+p*p*end; rotation=deg_to_rad(14)*(1-p); squash=Vector2.ONE*lerpf(1,ratio,p)
	return {"center":anchor+(source.size*squash/2).rotated(rotation),"anchor":anchor,"rotation":rotation,"scale":squash,"alpha":1.0}

func _water_sample(milliseconds: float) -> Dictionary:
	var source: Rect2=current.source
	var start:=source.get_center(); var contact:=start+Vector2(0,18)
	var end: Vector2=current.target.get_center() if bool(current.nearby_slot) else contact
	var final_extent: float=minf(current.target.size.x,current.target.size.y) if bool(current.nearby_slot) else 20.0
	if bool(current.get("reduced_motion",false)):
		return {"center":end if bool(current.nearby_slot) else start,"scale":Vector2.ONE,"shape_mix":1.0,"extent":final_extent,"ripple":0.0,"alpha":1.0,"arc_length":0.0}
	var ms:=clampf(milliseconds,0,340); var center:=start; var squash:=Vector2(.88,1.18)
	var mix:=0.0; var ripple:=0.0; var alpha:=1.0
	var bend:=contact.lerp(end,.5)+Vector2(0,-minf(12,contact.distance_to(end)/3))
	var arc_length:=_arc_length(contact,bend,end)
	if arc_length>60: bend=contact.lerp(end,.5); arc_length=contact.distance_to(end)
	if ms<=120:
		var p:=ms/120.0; var gravity:=p*p
		center=(start+Vector2(0,source.size.y*.18/2)).lerp(contact,gravity)
		squash=squash.lerp(Vector2(1.32,.58),gravity)
	elif ms<260:
		var p: float=(ms-120)/140.0; mix=p
		center=(1-p)*(1-p)*contact+2*(1-p)*p*bend+p*p*end
		squash=Vector2(1.32,.58).lerp(Vector2.ONE,p)
	else:
		center=end; squash=Vector2.ONE; mix=1; alpha=1-(ms-260)/80.0
	if ms>=120 and ms<220: ripple=1-(ms-120)/100.0
	return {"center":center,"scale":squash,"shape_mix":mix,"extent":lerpf(source.size.y,final_extent,mix),"ripple":ripple,"alpha":alpha,"arc_length":arc_length}

static func _arc_length(start: Vector2,bend: Vector2,end: Vector2) -> float:
	var previous:=start; var length:=0.0
	for i in range(1,21):
		var p:=i/20.0; var point: Vector2=(1-p)*(1-p)*start+2*(1-p)*p*bend+p*p*end
		length+=previous.distance_to(point); previous=point
	return length

func _draw_water(pose: Dictionary) -> void:
	var source: Rect2=current.source; var center: Vector2=pose.center
	var mix: float=pose.shape_mix; var alpha: float=pose.alpha
	if mix<1:
		draw_set_transform(center,0,pose.scale)
		draw_rect(Rect2(-source.size/2,source.size),Color(Color("7db6ec"),alpha*(1-mix)))
		draw_set_transform(Vector2.ZERO)
	if float(pose.ripple)>0:
		var contact: Vector2=source.get_center()+Vector2(0,18+source.size.y*.29)
		for side: float in [-1,1]:
			var edge:=contact+Vector2(side*(source.size.x/2+4*pose.ripple),0)
			draw_line(edge,edge+Vector2(side*4,0),Color(Color("6aa8df"),pose.ripple*alpha),1)
	if mix>0:
		var icon: Dictionary=Chrome.PIXEL_ICONS.waterDrop
		var unit: float=float(pose.extent)/10
		var origin:=center-Vector2(9,10)*unit/2
		for y in range(icon.rows.size()):
			for x in range(str(icon.rows[y]).length()):
				var cell: String=str(icon.rows[y]).substr(x,1)
				if cell!=".": draw_rect(Rect2(origin+Vector2(x,y)*unit,Vector2.ONE*unit),Color(Color(icon.palette[cell]),mix*alpha))

func _draw() -> void:
	if current.is_empty(): return
	if current.get("kind","")=="texture": return
	if current.spec.anchor=="03": _draw_water(sample_at(elapsed_ms)); return
	var sample:=sample_at(elapsed_ms)
	var source: Rect2=current.source
	# The complete old frame and gray0 remain in the authoritative page.
	# Only the glyph copy moves, with its bottom edge as contact pivot.
	var base_size: Vector2=source.size
	var pivot:=Vector2(base_size.x/2,base_size.y)
	var fs:=ceili(float(current.font_size)); var font_ratio: float=float(current.font_size)/fs
	var digit: String=current.spec.digit
	var width: float=FONT.get_string_size(digit,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x*font_ratio
	var baseline:=Vector2((base_size.x-width)/2,(base_size.y-FONT.get_height(fs)*font_ratio)/2+FONT.get_ascent(fs)*font_ratio)-pivot
	draw_set_transform_matrix(get_transform_for_glyph(sample.anchor,sample.rotation,sample.scale,baseline,font_ratio))
	draw_string(FONT,Vector2.ZERO,digit,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,sample.ink)
	draw_set_transform(Vector2.ZERO)

static func get_transform_for_glyph(anchor: Vector2,rotation: float,squash: Vector2,baseline: Vector2,font_ratio: float) -> Transform2D:
	var pivot:=Transform2D(rotation,squash,0,anchor)
	return pivot*Transform2D(0,Vector2.ONE*font_ratio,0,baseline)
