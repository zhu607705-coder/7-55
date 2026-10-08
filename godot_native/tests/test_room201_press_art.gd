extends SceneTree
## Focused native layer, registration, transparency and visible-control contract.
const View=preload("res://scripts/objects/room201_press_view.gd")
const Model=preload("res://scripts/objects/room201_press_model.gd")
var checks:=0
var failures:=0
var view:Control
var events:Array=[]
func _initialize()->void:run.call_deferred()
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures+=1;push_error(label)
func point(at:Vector2)->Vector2:return view.origin+at*view.fit
func wheel_texel_point(texel:Vector2)->Vector2:
	var node:Sprite2D=view.art.parts.PressureWheel
	return view.art.transform*node.transform*(texel-node.region_rect.position+node.offset)
func check_wheel_rim_picking(state:Dictionary,dimensions:Vector2)->void:
	var wheel_image:Image=view.art.parts.PressureWheel.texture.get_image()
	for pressure:int in [0,3]:
		var adjusted:Dictionary=state.duplicate(true);adjusted.calibration.pressure=pressure
		view.present(adjusted,false,{},true);view.art.sync()
		for texel:Vector2 in [Vector2(1000,260),Vector2(1250,680),Vector2(980,650),Vector2(1240,270)]:
			var at:Vector2=wheel_texel_point(texel)
			check(wheel_image.get_pixelv(Vector2i(texel)).a>.9,"Rim fixture is actual opaque generated art")
			check(view.art.pressure_wheel_contains(at,0),"Transformed opaque rim is inside exact silhouette at "+str(dimensions)+" pressure="+str(pressure))
			check(view._pointer_down(at) and view.gesture=="crank","Opaque rim starts crank at "+str(dimensions)+" pressure="+str(pressure))
			view.cancel_gesture()
		for texel:Vector2 in [Vector2(880,240),Vector2(1330,240),Vector2(1340,710),Vector2(300,300)]:
			var at:Vector2=wheel_texel_point(texel)
			check(wheel_image.get_pixelv(Vector2i(texel)).a<view.art.ALPHA_CUTOFF,"Negative fixture is discarded transparent background")
			check(not view.art.pressure_wheel_contains(at),"Transparent background stays outside bounded silhouette padding")
			var picked:bool=view._pointer_down(at)
			check(not picked or view.gesture!="crank","Transparent background cannot start an invisible wheel target")
			if view._near(at,view.lever_handle(),25):check(picked and view.gesture=="lever","Visible lever keeps priority where transparent wheel canvas overlaps it")
			else:check(not picked,"Far transparent wheel background outside other controls rejects the pointer")
			view.cancel_gesture()
	view.present(state,false,{},true);view.art.sync()
func run()->void:
	view=View.new();root.add_child(view)
	view.press_event_requested.connect(func(event:Dictionary):events.append(event))
	await process_frame
	check(view.art!=null and view.art.built,"Native generated-image part tree is built")
	for key:String in ["StationaryWorkbench","Carriage","TransparentClockSheet","PressureWheel","HorizontalRailKnob","VerticalRailKnob","PressHousing","PressLever","PressHead"]:
		check(view.art.parts[key] is Sprite2D and view.art.parts[key].texture!=null,"Raster layer is a real textured Sprite2D: "+key)
	var sheet_image:Image=view.art.parts.TransparentClockSheet.texture.get_image()
	check(sheet_image.get_pixel(629,478).a>.1 and sheet_image.get_pixel(629,478).a<.8,"Original sheet interior retains partial alpha")
	check(sheet_image.get_pixel(300,300).a<4.0/255.0,"Low-alpha sheet exterior is discarded rather than flattened")
	check(view.art.shader.code.contains("sample_color * item_tint") and view.art.shader.code.contains("alpha_cutoff"),"Low-alpha shader keeps native CanvasItem opacity")
	for dimensions:Vector2 in [Vector2(1280,720),Vector2(390,844),Vector2(430,860),Vector2(844,390)]:
		view.size=dimensions;view.layout_scene(Rect2(Vector2(14,125),dimensions-Vector2(28,187)))
		var state:Dictionary=Model.initial();state.inserted=true;view.present(state,false,{},true);view.interactive=true;view.art.sync()
		check(view.art.parts.StationaryWorkbench.visible!=view.narrow,"Portrait uses reflowed native parts: "+str(dimensions))
		check(view.art.parts.PortraitBase.visible==view.narrow,"Portrait base is a silhouette-masked independent crop")
		check(view.art.parts.Carriage.position.is_equal_approx(view.carriage_center()),"Carriage visible position equals input geometry")
		check(view.art.parts.TransparentClockSheet.position.is_equal_approx(view.carriage_center()),"Inserted original sheet follows carriage")
		check(view.plate_size.x*view.fit>=100 or dimensions.y<500,"Portrait sheet remains readable instead of whole-scene shrinking")
		for handle:Dictionary in view.rail_handles():
			var sprite:Sprite2D=view.art.parts.HorizontalRailKnob if handle.axis=="horizontal" else view.art.parts.VerticalRailKnob
			check(sprite.position.is_equal_approx(handle.point),"Rendered rail knob is its own hit target")
			check(view.play_area.has_point(point(handle.point)),"Rail knob remains in safe play area")
			check(view._near(point(handle.point)+Vector2(21,0),handle.point,48),"Rail has at least a 44px touch diameter")
			check(view._pointer_down(point(handle.point)) and view.gesture==handle.axis,"Actual visible rail owns correct gesture")
			view._pointer_up(point(handle.point)+Vector2(28,0) if handle.axis=="horizontal" else point(handle.point)+Vector2(0,28))
			check(events.back().axis==handle.axis,"Visible rail dispatches its bounded model axis")
		check(view._pointer_down(point(view.lever_handle())) and view.gesture=="lever","Visible wooden grip owns lever gesture")
		view.cancel_gesture()
		check(view._pointer_down(point(view.wheel)) and view.gesture=="crank","Visible pressure spool owns crank gesture")
		view.cancel_gesture()
		check(view._near(point(view.lever_handle())+Vector2(21,0),view.lever_handle(),25),"Lever has at least a 44px touch diameter")
		check(view.art.pressure_wheel_contains(point(view.wheel)+Vector2(21,0)),"Visible wheel center retains at least a 44px touch diameter")
		check_wheel_rim_picking(state,dimensions)
		var old_carriage:Vector2=view.art.parts.Carriage.position
		var old_horizontal:Vector2=view.art.parts.HorizontalRailKnob.position
		var old_vertical:Vector2=view.art.parts.VerticalRailKnob.position
		var old_wheel_angle:float=view.art.parts.PressureWheel.rotation
		var hinge:Vector2=view.art.parts.PressLever.position
		var pressure_anchor:Vector2=view.art.parts.PressureWheel.position
		state.calibration=Model.source().registration.calibration.duplicate();view.present(state,false,{},true);view.art.sync()
		check(view.art.parts.Carriage.position!=old_carriage and view.art.parts.HorizontalRailKnob.position!=old_horizontal and view.art.parts.VerticalRailKnob.position!=old_vertical,"State moves carriage and both independent rails")
		check(view.art.parts.PressureWheel.rotation!=old_wheel_angle,"Accepted pressure changes native wheel pose")
		view.begin_press();view.show_feedback("success");view.reduced=false
		var last_head:Vector2=Vector2.ZERO
		for clock:float in [0.0,.4,.68]:
			view.motion_time=clock;view.art.sync()
			check(view.art.parts.PressLever.position.is_equal_approx(hinge),"Fixed lever hinge survives press pose "+str(clock))
			check(view.art.parts.PressureWheel.position.is_equal_approx(pressure_anchor),"Pressure spool retains its left shaft attachment")
			var head:Vector2=view.art.parts.PressHead.position
			if clock>0:check(not head.is_equal_approx(last_head),"Ram visibly changes between up, down and rebound")
			last_head=head
			if clock==.4:
				var head_sprite:Sprite2D=view.art.parts.PressHead
				var surface:Rect2=Rect2(head_sprite.position+head_sprite.offset*head_sprite.scale,head_sprite.region_rect.size*head_sprite.scale)
				for local:Vector2 in view.CONTACTS:
					var contact:Vector2=view.carriage_center()+local*view.carriage_art_scale()
					check(surface.has_point(contact),"Down platen covers each calibrated contact at "+str(dimensions))
					var texel:Vector2=(contact-head_sprite.position)/head_sprite.scale-head_sprite.offset+head_sprite.region_rect.position
					check(head_sprite.texture.get_image().get_pixel(int(texel.x),int(texel.y)).a>.5,"Calibrated contact hits opaque platen metal, not a transparent sprite corner")
		view.motion="";view.present(Model.initial(),false,{},true);view.art.sync()
		check(view.art.parts.TransparentClockSheet.position.is_equal_approx(view.loose_center),"Uninserted original sheet stays distinct from brass fixture")
		check(view.art.parts.Carriage.position.is_equal_approx(view.center),"Brass fixture never flies in with inventory sheet")
		view.plate_available=false;view.art.sync();check(not view.art.parts.TransparentClockSheet.visible,"Missing original item leaves fixture empty")
		view.plate_available=true
	view.queue_free();await process_frame
	print("ROOM201_PRESS_ART: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
