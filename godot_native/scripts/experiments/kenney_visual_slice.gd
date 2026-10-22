extends Control
## Isolated reference experiment. Never invokes State actions or saves.
const Room = preload("res://scenes/objects/dorm_modular_candidate.tscn")
const SelectedTheme = preload("res://scripts/ui/selected_ui_theme.gd")
const ActorArt = preload("res://assets/rpg/player/player_down_0.png")
var view: SubViewport
var screen: TextureRect
var room: Node2D
var actor: CharacterBody2D
var sprite: Sprite2D
var camera: Camera2D
var marker: Node2D
var hint: Label
var note: Label
var title: Label
var tutorial: Label
var comparison: Button
var pixel_button: Button
var reset_button: Button
var action: Button
var focus_id := ""
var observed := false
var lamp_on := false
var feedback := true
var pixel_mode := false
var reduced_motion := false
var note_open := false
var tween: Tween
var logical_camera := Vector2(500, 1000)
var held_keys: Dictionary = {}
var keyboard := Vector2.ZERO
var pointer_target := Vector2.ZERO
var pointer_walk := false
var blocked_time := 0.0
var tutorial_done := false
var objects: Array[Dictionary] = []

class FocusMarker extends Node2D:
	var active := false
	var warm := false
	func _draw() -> void:
		if warm:
			draw_circle(Vector2.ZERO, 30, Color(1,.77,.38,.13))
		if active:
			# Four quiet corner marks, not a panel or an opaque selection box.
			for sign_x in [-1,1]:
				for sign_y in [-1,1]:
					var p := Vector2(sign_x*35,sign_y*25)
					draw_line(p,p-Vector2(sign_x*9,0),Color("e8d6aa"),1)
					draw_line(p,p-Vector2(0,sign_y*7),Color("e8d6aa"),1)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	RenderingServer.set_default_clear_color(Color("101923"))
	screen=TextureRect.new();screen.mouse_filter=Control.MOUSE_FILTER_IGNORE
	screen.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	screen.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(screen)
	view=SubViewport.new();view.size=Vector2i(960,540)
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	view.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(view);screen.texture=view.get_texture()
	room=Room.instantiate();view.add_child(room)
	actor=CharacterBody2D.new();actor.position=Vector2(531,1000);view.add_child(actor)
	var hit=CollisionShape2D.new();var shape=CircleShape2D.new();shape.radius=13;hit.shape=shape;actor.add_child(hit)
	sprite=Sprite2D.new();sprite.texture=ActorArt;sprite.scale=Vector2.ONE*.6;sprite.position.y=-32;actor.add_child(sprite)
	camera=Camera2D.new();view.add_child(camera);camera.position=logical_camera;camera.zoom=Vector2.ONE*.8
	marker=FocusMarker.new();view.add_child(marker)
	var lamp: Sprite2D=room.get_node("Furnishings/desk_2/lamp_green_4")
	objects=[{"id":"paper","position":Vector2(531,834),"stand":Vector2(531,900),"title":"折起的纸条","node":room.get_node("Canonical0755Paper")},
		{"id":"lamp","position":lamp.global_position,"stand":Vector2(650,lamp.global_position.y),"title":"桌边的灯","node":lamp}]
	title=make_label("寝室 · 独立练习", "hud", "heading")
	tutorial=make_label("方向键移动 · 空格查看 / 收起 · 鼠标点地面或物件", "hud", "tip")
	hint=make_label("", "interaction", "body")
	note=make_label("", "journal", "tip");note.hide()
	comparison=make_button("反馈：开",toggle_feedback)
	pixel_button=make_button("渲染：540",toggle_pixels)
	reset_button=make_button("重来",reset_trial)
	action=make_button("查看",interact)
	resized.connect(layout);layout();refresh_focus()

func make_label(text: String,surface: String,role: String) -> Label:
	var label=Label.new();label.text=text;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	SelectedTheme.apply_label(label,surface,role);add_child(label);return label
func make_button(text: String,callback: Callable) -> Button:
	var button=Button.new();button.text=text;button.custom_minimum_size=Vector2(96,36);button.focus_mode=Control.FOCUS_NONE
	SelectedTheme.apply_button(button,"interaction");button.pressed.connect(callback);add_child(button);return button
func layout() -> void:
	if not is_instance_valid(screen):return
	var space:=Vector2(maxf(180,size.x-32),maxf(120,size.y-146))
	var height:=480 if pixel_mode else 540
	var width:=854 if pixel_mode else 960
	if space.x<space.y:width=maxi(roundi(height*2.0/3.0),roundi(height*space.x/space.y))
	view.size=Vector2i(width,height)
	var ratio:=float(view.size.x)/view.size.y
	var h:=minf(space.y,space.x/ratio)
	screen.size=Vector2(h*ratio,h);screen.position=(size-screen.size)/2
	title.position=Vector2(20,12)
	tutorial.position=Vector2(20,size.y-62)
	tutorial.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	tutorial.size=Vector2(maxf(120,size.x-150),50)
	tutorial.visible=not tutorial_done
	comparison.position=Vector2(maxf(12,size.x-320),40)
	pixel_button.position=Vector2(maxf(110,size.x-212),40)
	reset_button.position=Vector2(maxf(210,size.x-104),40)
	action.position=Vector2(size.x-116,size.y-46)
	position_labels()
func world_to_screen(point: Vector2) -> Vector2:
	return screen.position+(view.canvas_transform*point)*screen.size/Vector2(view.size)
func screen_to_world(point: Vector2) -> Vector2:
	return view.canvas_transform.affine_inverse()*((point-screen.position)*Vector2(view.size)/screen.size)
func position_labels() -> void:
	if not is_instance_valid(hint):return
	var p:=world_to_screen(marker.position)
	hint.position=Vector2(clampf(p.x-hint.size.x-28,12,maxf(12,size.x-hint.size.x-12)),clampf(p.y-8,90,size.y-80))
	note.position=Vector2(clampf(p.x+30,12,maxf(12,size.x-note.size.x-12)),clampf(p.y-52,90,size.y-100))
func _physics_process(delta: float) -> void:
	if note_open:
		actor.velocity=Vector2.ZERO
	else:
		var direction=keyboard
		if pointer_walk:
			var diff=pointer_target-actor.position
			if diff.length()<8:pointer_walk=false
			else:direction=diff.normalized()
		actor.velocity=direction.limit_length()*150.0
		var previous:=actor.position
		actor.move_and_slide()
		actor.position=actor.position.clamp(Vector2(20,20),Vector2(921,1652))
		if pointer_walk and actor.position.distance_to(previous)<.1:
			blocked_time+=delta
			if blocked_time>.3:pointer_walk=false;blocked_time=0.0
		else:blocked_time=0.0
		if direction.length_squared()>0:
			tutorial_done=true;tutorial.hide()
	logical_camera=logical_camera.lerp(actor.position,1.0-exp(-7.0*delta))
	camera.position=snapped_camera(logical_camera,camera.zoom.x) if pixel_mode else logical_camera
	refresh_focus();position_labels()
static func snapped_camera(point: Vector2,zoom: float) -> Vector2:
	return (point*zoom).round()/zoom
func refresh_focus() -> void:
	var next:="";var best:=100.0
	for object in objects:
		var distance:float=actor.position.distance_to(object.stand)
		if distance<best:next=object.id;best=distance
	if next!=focus_id:
		cancel_feedback();focus_id=next
		if note_open:close_note()
	if focus_id.is_empty():
		marker.active=false;hint.hide();action.disabled=true
	else:
		var object=get_object(focus_id)
		marker.position=object.position;marker.active=feedback
		hint.text=object.title;hint.show();action.disabled=false
	marker.warm=lamp_on and focus_id=="lamp";marker.queue_redraw()
	action.text="收起" if note_open else ("开 / 关灯" if focus_id=="lamp" else "查看")
func get_object(id: String) -> Dictionary:
	for object in objects:
		if object.id==id:return object
	return {}
func interact() -> void:
	if focus_id.is_empty():return
	pointer_walk=false
	if focus_id=="paper":
		if note_open:close_note();return
		observed=true;note_open=true;note.text="纸角折过两次。\n0755 还留在上面。";note.show()
		pulse(get_object("paper").node)
	else:
		lamp_on=not lamp_on
		get_object("lamp").node.modulate=Color(1.12,1.08,.9) if lamp_on else Color.WHITE
		pulse(get_object("lamp").node)
	refresh_focus();position_labels()
func pulse(node: Node2D) -> void:
	cancel_feedback()
	if not feedback or reduced_motion:return
	# Brightness only: do not stretch pixel artwork or change collision/anchor.
	tween=create_tween();tween.tween_property(node,"self_modulate",Color(1.2,1.16,1.04),.10)
	tween.tween_property(node,"self_modulate",Color.WHITE,.18)
func cancel_feedback() -> void:
	if tween and tween.is_valid():tween.kill()
	for object in objects:
		if is_instance_valid(object.node):object.node.self_modulate=Color.WHITE
func close_note() -> void:
	note_open=false;note.hide()
func toggle_feedback() -> void:
	feedback=not feedback;comparison.text="反馈：开" if feedback else "反馈：关";cancel_feedback();refresh_focus()
func toggle_pixels() -> void:
	pixel_mode=not pixel_mode;view.size=Vector2i(854,480) if pixel_mode else Vector2i(960,540)
	# Keep the same world field of view; UI remains in the native window layer.
	camera.zoom=Vector2.ONE*(.8*view.size.y/540.0)
	pixel_button.text="渲染：480" if pixel_mode else "渲染：540";layout()
func reset_trial() -> void:
	cancel_feedback();close_note();observed=false;lamp_on=false;pointer_walk=false;held_keys.clear();keyboard=Vector2.ZERO
	actor.position=Vector2(531,1000);logical_camera=actor.position;camera.position=logical_camera
	get_object("lamp").node.modulate=Color.WHITE;refresh_focus()
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		held_keys.clear();keyboard=Vector2.ZERO;pointer_walk=false;cancel_feedback()
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]:
			held_keys[event.keycode]=event.pressed
			keyboard=Vector2(float(held_keys.get(KEY_RIGHT,false))-float(held_keys.get(KEY_LEFT,false)),float(held_keys.get(KEY_DOWN,false))-float(held_keys.get(KEY_UP,false)))
			pointer_walk=false
		if event.pressed and not event.echo and event.keycode==KEY_SPACE:
			interact();get_viewport().set_input_as_handled()
		if event.pressed and event.keycode==KEY_ESCAPE:close_note();pointer_walk=false
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		if not Rect2(screen.position,screen.size).has_point(event.position):return
		var point=screen_to_world(event.position)
		for object in objects:
			if point.distance_to(object.position)<52:
				if focus_id==object.id:interact()
				else:close_note();pointer_target=object.stand;pointer_walk=true
				return
		pointer_target=point;pointer_walk=true;close_note()
