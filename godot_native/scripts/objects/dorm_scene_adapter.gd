extends Node2D
## Native source-plate objects. Story state changes only in the original actions.
## Timed card/door copies are read-only and never complete a controller action.
const CARD_POINT := Vector2(792,928)
const DOOR_LEAF := Rect2(422,1474,103,114)
const DOOR_FRAME := Rect2(402,1450,144,152)
class Card extends Node2D:
	func _draw() -> void:
		# Byte-for-byte geometry/palette of DormHubScene.createCampusCardPickup.
		draw_rect(Rect2(-19,-11,40,26),Color("21180f",.32))
		draw_rect(Rect2(-20,-13,40,26),Color("e8efec"))
		draw_rect(Rect2(-20,-13,40,26),Color("174f86"),false,2)
		draw_rect(Rect2(-19,-12,38,6),Color("185ba8"))
		draw_rect(Rect2(-15, -1.5,8,9),Color("71b6a0"))
		draw_rect(Rect2(-15,-1.5,8,9),Color("174f86"),false,1)
		draw_rect(Rect2(-.5,-1,15,2),Color("35444d"))
		draw_rect(Rect2(-4.5,4,19,2),Color("718087"))
		draw_circle(Vector2(14,-8),2,Color("e4c45d"))
class Surface extends Node2D:
	var adapter: Node2D
	var role: String
	func _draw() -> void: adapter.draw_surface(self,role)
var world: Control
var state: Dictionary={}
var plate: Texture2D
var source_space: Node2D
var clip: Control
var card: Node2D
var cabinet: Node2D
var lamp: Node2D
var door: Node2D
var overlay: Node2D
var fly_card: Node2D
var door_tail: Node2D
var exit_clip: Control
var active:=false
var card_age:=10.0
var reject_age:=10.0
var exit_age:=10.0
var cabinet_amount:=0.0
var lamp_amount:=Vector2.ZERO
var card_start:=Vector2.ZERO
var card_zoom:=1.0
var door_start:=Rect2()
var last_card_global:=Vector2.ZERO
var last_door_global:=Rect2()
var last_exit_clip_global:=Rect2()
var reduced:=false
var bound_state: Dictionary={}
var previous_scene:=""
var last_view_size:=Vector2.ZERO

func setup(owner_world: Control) -> void:
	world=owner_world;name="DormOriginalObjects"
	plate=load("res://assets/rpg/interiors/dorm_hub.png")
	clip=Control.new();clip.name="WorldObjectClip";clip.mouse_filter=Control.MOUSE_FILTER_IGNORE;clip.clip_contents=true;add_child(clip)
	source_space=Node2D.new();source_space.name="Original941x1672Coordinates";clip.add_child(source_space)
	for role: String in ["cabinet","lamp","door"]:
		var prop:=Surface.new();prop.adapter=self;prop.role=role;prop.name=role.capitalize();source_space.add_child(prop);set(role,prop)
	card=Card.new();card.name="OriginalSourceCampusCard";card.position=CARD_POINT;card.rotation=deg_to_rad(-3);source_space.add_child(card)
	overlay=Node2D.new();overlay.name="DormReadOnlyAcquisitionTail";overlay.z_index=80
	# Main-level read-only copies can reach the existing bag without clipping.
	(world.host_node if is_instance_valid(world.host_node) else world).add_child(overlay)
	fly_card=Card.new();fly_card.name="AcceptedCardCopy";overlay.add_child(fly_card);fly_card.hide()
	exit_clip=Control.new();exit_clip.name="OldWorldContentClip";exit_clip.mouse_filter=Control.MOUSE_FILTER_IGNORE;exit_clip.clip_contents=true;overlay.add_child(exit_clip)
	door_tail=Surface.new();door_tail.adapter=self;door_tail.role="exit_tail";door_tail.name="AcceptedDoorCopy";exit_clip.add_child(door_tail);door_tail.hide()
	State.action_completed.connect(_action_completed)
	State.story_reset.connect(cancel_transients)
	set_process(true);hide()

func _exit_tree() -> void:
	if is_instance_valid(overlay):overlay.queue_free()

func props() -> Dictionary:
	return state.get("native",{}).get("dorm_props",{})

func sync(next: Dictionary, scene: String) -> void:
	if not is_same(bound_state,next):
		cancel_transients();bound_state=next
		cabinet_amount=1.0 if next.native.get("dorm_props",{}).get("cabinet_open",false) else 0.0
		lamp_amount=Vector2(1 if next.native.get("dorm_props",{}).get("lamp_01_on",false) else 0,1 if next.native.get("dorm_props",{}).get("lamp_03_on",false) else 0)
	state=next;reduced=bool(state.native.get("settings",{}).get("reduced_motion",false))
	active=scene=="dorm_hub" and bool(state.actOne.dormHubUnlocked)
	visible=active
	if scene!=previous_scene:
		card_age=10;reject_age=10;fly_card.hide()
		if scene!="campus_bootstrap":
			exit_age=10;door_tail.hide()
		previous_scene=scene
	card.visible=active and state.actOne.phase=="inventory_required" and not state.actOne.inventoryRecovered

func configure_view(origin: Vector2, zoom: float) -> void:
	if not active:return
	var hud: Dictionary=world.hud_metrics(world._hud_line())
	clip.position=Vector2(0,hud.header_height)
	clip.size=Vector2(world.size.x,maxf(0,world.size.y-hud.header_height-hud.body_height-hud.body_gap))
	source_space.position=origin+Vector2(245,0)*zoom-clip.position
	source_space.scale=Vector2.ONE*zoom*.5
	last_card_global=_root_point(origin+(CARD_POINT*.5+Vector2(245,0))*zoom)
	last_door_global=Rect2(_root_point(origin+(DOOR_FRAME.position*.5+Vector2(245,0))*zoom),DOOR_FRAME.size*zoom*.5*_root_scale())
	last_exit_clip_global=Rect2(_root_point(clip.position),_root_point(clip.position+clip.size)-_root_point(clip.position))
	card_zoom=zoom*.5*_root_scale()
	for node: Node2D in [cabinet,lamp,door]:node.queue_redraw()

func _root_point(local: Vector2) -> Vector2:
	var pixel:=world.get_global_transform_with_canvas()*local
	if is_instance_valid(world.host_node) and is_instance_valid(world.host_node.get("world_view")):
		var view: SubViewportContainer=world.host_node.world_view
		return view.get_global_transform_with_canvas()*(pixel*view.size/Vector2(world.get_viewport().size))
	return pixel

func _root_scale() -> float:
	return _root_point(Vector2.RIGHT).distance_to(_root_point(Vector2.ZERO))

func cancel_transients() -> void:
	card_age=10;reject_age=10;exit_age=10
	if is_instance_valid(fly_card):fly_card.hide()
	if is_instance_valid(door_tail):door_tail.hide()

func _action_completed(action: String, before: Dictionary, after: Dictionary, _result: Dictionary) -> void:
	if action=="c2_recover_card" and before.native.scene=="dorm_hub" and not before.actOne.inventoryRecovered and after.actOne.inventoryRecovered:
		card_start=overlay.get_global_transform_with_canvas().affine_inverse()*last_card_global
		card_age=0;fly_card.show();card.hide()
	elif action=="c2_dorm_exit" and before.native.scene=="dorm_hub":
		if before.actOne.phase=="movement_ready" and before.actOne.canLeaveDorm and before.actOne.manualControlTested and after.native.scene=="campus_bootstrap":
			exit_clip.position=overlay.get_global_transform_with_canvas().affine_inverse()*last_exit_clip_global.position
			exit_clip.size=last_exit_clip_global.size
			door_start=Rect2(overlay.get_global_transform_with_canvas().affine_inverse()*last_door_global.position-exit_clip.position,last_door_global.size)
			exit_age=0;door_tail.show()
		else:reject_age=0

func observe_input(event: InputEvent) -> void:
	# A new input can always dismiss a successful exit tail. It is never a lock.
	if exit_age<.38 and ((event is InputEventKey and event.pressed) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)):
		exit_age=10;door_tail.hide()

func _process(delta: float) -> void:
	if world==null or state.is_empty():return
	if not world.is_visible_in_tree() or (is_instance_valid(world.host_node) and is_instance_valid(world.host_node.get("world_frame")) and not world.host_node.world_frame.is_visible_in_tree()) or world._shell_input_blocked() or (exit_age<.38 and last_view_size!=Vector2.ZERO and last_view_size!=world.size):
		cancel_transients()
	last_view_size=world.size
	var wanted_cabinet:=1.0 if props().get("cabinet_open",false) else 0.0
	var wanted_lamp:=Vector2(1 if props().get("lamp_01_on",false) else 0,1 if props().get("lamp_03_on",false) else 0)
	cabinet_amount=wanted_cabinet if reduced else move_toward(cabinet_amount,wanted_cabinet,delta/.26)
	lamp_amount=wanted_lamp if reduced else lamp_amount.move_toward(wanted_lamp,delta/.22)
	reject_age+=maxf(0,delta)
	if active:
		for node: Node2D in [cabinet,lamp,door]:node.queue_redraw()
	if card_age<.46:
		if card_age<.38 and world.scene_id=="dorm_hub":
			# The restored bag changes available viewport size. Keep the copy on
			# the same source desk through that layout change, not old screen pixels.
			card_start=overlay.get_global_transform_with_canvas().affine_inverse()*_root_point(world.size/2-world.camera*world.zoom+(CARD_POINT*.5+Vector2(245,0))*world.zoom)
			card_zoom=world.zoom*.5*_root_scale()
		card_age+=maxf(0,delta)
		var target:=card_start
		var shell=world.host_node
		if is_instance_valid(shell) and is_instance_valid(shell.get("inventory_buttons")):
			var slot: Control=shell.inventory_buttons.get_node_or_null("WorldItem_campusCard")
			if slot!=null and slot.is_visible_in_tree():target=overlay.get_global_transform_with_canvas().affine_inverse()*slot.get_global_rect().get_center()
		var slide:=minf(card_age/.16,1.0)
		var flight:=clampf((card_age-.38)/.08,0,1)
		fly_card.position=card_start if reduced else (card_start+Vector2(-14,0)*card_zoom*slide).lerp(target,flight)
		fly_card.rotation=0 if reduced else deg_to_rad(-3+5*slide)*(1-flight)
		fly_card.scale=Vector2.ONE*card_zoom*lerpf(1.0,.65,flight)
		fly_card.modulate.a=1.0-clampf((card_age-.38)/.08,0,1)
		if card_age>=.46:fly_card.hide()
	if exit_age<.38:
		# Arrival subtitles can be taller than the departed room's one-line HUD.
		# Intersect both content areas without moving the captured leaf.
		var hud: Dictionary=world.hud_metrics(world._hud_line())
		var bottom:=overlay.get_global_transform_with_canvas().affine_inverse()*_root_point(Vector2(0,world.size.y-hud.body_height-hud.body_gap))
		exit_clip.size.y=minf(last_exit_clip_global.size.y,maxf(0,bottom.y-exit_clip.position.y))
		exit_age+=maxf(0,delta);door_tail.queue_redraw()
		if exit_age>=.38:door_tail.hide()

func draw_surface(canvas: Node2D, role: String) -> void:
	match role:
		"cabinet":
			if cabinet_amount<=0:return
			var width:=63.0*lerpf(1,.2,cabinet_amount)
			canvas.draw_rect(Rect2(421,249,132,140),Color("101a20"))
			canvas.draw_rect(Rect2(425,316,125,4),Color("333e43"))
			canvas.draw_texture_rect_region(plate,Rect2(421,249,width,140),Rect2(421,249,63,140))
			canvas.draw_texture_rect_region(plate,Rect2(553-width,249,width,140),Rect2(490,249,63,140))
		"lamp":
			for i: int in range(2):
				var point:=Vector2(812,242 if i==0 else 782)
				canvas.draw_circle(point,64,Color(.52,.72,1,.12*lamp_amount[i]))
				canvas.draw_circle(point,38,Color(.65,.82,1,.09*lamp_amount[i]))
		"door":
			if reject_age>=.18:return
			var stress:=sin(PI*clampf(reject_age/.18,0,1)) if not reduced else 0.0
			canvas.draw_texture_rect_region(plate,DOOR_LEAF,DOOR_LEAF)
			canvas.draw_texture_rect_region(plate,Rect2(DOOR_LEAF.position+Vector2(stress,0),DOOR_LEAF.size),DOOR_LEAF)
			var handle:=Vector2(514,1540)
			canvas.draw_set_transform(handle,deg_to_rad(6*stress))
			canvas.draw_texture_rect_region(plate,Rect2(-7,-14,14,28),Rect2(507,1526,14,28))
			canvas.draw_set_transform(Vector2.ZERO)
		"exit_tail":
			var t:=clampf(exit_age/.38,0,1)
			var opacity:=1-t
			var scale_factor:=door_start.size/DOOR_FRAME.size
			# Left hinge is source x422; frame and authored campus camera stay fixed.
			var leaf:=Rect2(door_start.position+(DOOR_LEAF.position-DOOR_FRAME.position)*scale_factor,DOOR_LEAF.size*scale_factor)
			leaf.size.x*=1.0 if reduced else lerpf(1.0,.22,t)
			canvas.draw_texture_rect_region(plate,leaf,DOOR_LEAF,Color(1,1,1,opacity))

func snapshot() -> Dictionary:
	return {"active":active,"card_visible":card.visible,"card_tail":card_age<.46,"door_rejection":reject_age<.18,"exit_tail":exit_age<.38,"cabinet_amount":cabinet_amount,"lamp_amount":lamp_amount,"object_nodes":[card.name,cabinet.name,lamp.name,door.name]}
