extends SceneTree
const Model = preload("res://campuses/campus_letter/scripts/experience_model.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void: run.call_deferred()
func expect(condition: bool, label: String) -> void:
	checks+=1
	if not condition: failures.append(label);push_error(label)

func run() -> void:
	var model := Model.new()
	model.enter("library")
	expect(not model.seat_action("sit",3),"An empty seat does not bypass reservation")
	expect(not model.seat_action("checkin"),"Check-in needs a reservation")
	expect(not model.seat_action("reserve",0),"Existing reservation is protected")
	expect(model.seat_action("reserve",3),"Available seat is reservable")
	expect(model.seat_action("checkin"),"Card check-in accepted")
	expect(not model.seat_action("sit",1),"Own reservation cannot claim somebody else's seat")
	expect(model.seat_action("sit",3),"Student takes their own seat")
	expect(not model.completed.has("library"),"Sitting alone does not finish lifecycle")
	expect(model.seat_action("release") and model.completed.has("library"),"Release completes the seat lifecycle")
	model.enter("liuhu")
	expect(not model.adjust("lamp",440.0),"Control cannot affect a different sample")
	expect(not model.adjust("horizontal",NAN),"Invalid control coordinate is rejected")
	var old_snapshot:=model.manipulation_snapshot()
	expect(not model.record_sample(0),"Misaligned reflections cannot generate records")
	model.data.offset=0.0;model.data.tilt=0.0
	expect(model.record_sample(2) and model.record_sample(0),"Observation order is free")
	expect(not model.record_sample(0),"Duplicate point is not counted")
	expect(not model.completed.has("liuhu"),"Two points are insufficient")
	expect(model.record_sample(1) and model.completed.has("liuhu"),"Three distinct points complete handover")
	model.enter("bridge")
	model.cancel_manipulation(old_snapshot)
	expect(model.data.has("left") and not model.data.has("offset"),"Stale cancellation cannot overwrite the next sample")
	expect(not model.place_weight() and model.data.failed,"Wide flat sheet bends under trial load")
	model.enter("bridge");model.data.left=350.0;model.data.right=610.0;model.data.folded=true
	for i in range(3): expect(model.place_weight(),"Supported folded bridge carries weight %d"%i)
	expect(model.completed.has("bridge"),"Three weights complete delivery")
	model.enter("bridge");model.adjust("left",350);model.adjust("right",610);model.fold_paper()
	expect(model.place_weight(2),"An individual weight can be placed out of order")
	expect(not model.place_weight(2) and model.data.load==1,"The same weight cannot count twice")
	model.remove_weights();expect(model.data.placed.is_empty() and model.data.load==0,"Recovery returns every physical weight")
	model.enter("light")
	expect(not model.deliver_light(),"Wrong projection cannot complete")
	model.data.lamp=440.0
	expect(not model.deliver_light(),"Aligned projection still needs clear observation position")
	model.data.player_position=Vector2(260,450)
	expect(not model.deliver_light(),"The letter must be physically picked up")
	model.take_letter()
	expect(not model.deliver_light(6.0),"A visible mailbox cannot receive a letter from out of reach")
	expect(model.deliver_light(),"Alignment and yielding together allow delivery")
	expect(model.completed.size()==4,"Four independent complete samples")
	var app:Node3D=load("res://campuses/campus_letter/scenes/samples.tscn").instantiate();root.add_child(app)
	await process_frame
	expect(not app.overview and is_instance_valid(app.player),"Entry is a first-person body, not an overview camera")
	expect(not app.hud.get_node("Feedback").visible and not app.hud.get_node("OrbitTip").visible and not app.object_label.visible,"Default scene has no explanatory text")
	for id:String in Model.IDS:
		app.open_sample(id);await process_frame
		expect(app.world.find_children("*","Label3D",true,false).is_empty(),"No text on physical objects in "+id)
		expect(app.world.find_children("*","Skeleton3D",true,false).is_empty() and not app.world.targets.has("person") and not app.world.targets.has("partner"),"No reused person model or invisible character target in "+id)
	var eye:Vector3=app.player.position;app._toggle_view()
	expect(app.overview,"Overview is separately switchable")
	app._toggle_view();expect(not app.overview and app.player.position.is_equal_approx(eye),"Returning from overview preserves the player's location")
	app.open_sample("bridge");await physics_frame
	var p:Vector2=app.camera.unproject_position(app.world.point("left"))
	app._press(p,0);app._move(p+Vector2(45,0),0)
	expect(app.model.data.left!=220.0,"Touch manipulates the actual 3D support")
	app._press(p,1);app._release(p,1);expect(app.pointer==0,"Second finger cannot steal or release the manipulation")
	app.cancel_drag();expect(is_equal_approx(app.model.data.left,220.0) and app.pointer==-2,"Cancellation restores the object and releases ownership")
	app.queue_free();await process_frame
	print("CAMPUS_LETTER_TESTS checks=",checks," failures=",failures)
	quit(1 if not failures.is_empty() else 0)
