extends SceneTree
const Part=preload("res://scripts/objects/theater_clue_part.gd")
const Motion=preload("res://scripts/presentation/c3_theater_clue_motion.gd")
const Clues=preload("res://scripts/presentation/c3_theater_clue_view.gd")
const Layers=preload("res://scripts/ui/chapter3_world_layers.gd")
const Chapter=preload("res://scripts/chapters/chapter3.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func fixture(phase:="entry_ticket")->Dictionary:
	var s:Dictionary=root.get_node("State").initial()
	s.native.chapter=3;s.native.page="c3_theater";s.native.scene="theater_interior";s.native.mode="light"
	s.runtimeMode="rpg";s.rpgScene="theater_interior";s.theaterHunt.active=true;s.theaterHunt.phase=phase
	s.theaterHunt.ticketCodeRead=true # Do not open the separately tested entry dialogue.
	s.items.greaseTissue=true;s.items.fluorescentBrush=true
	s.native.player={"x":476,"y":755} if phase=="entry_ticket" else {"x":936,"y":228}
	return s
func run()->void:
	var counts:Array=[]
	var seen:Dictionary={}
	for ms in range(0,1121,20):
		var count:=0
		for y in range(0,62,4):
			for x in range(0,230,4):
				var p:=Motion.GLASS.position+Vector2(x+2,y+2)
				var clear:bool=Motion.cleared(p,ms)
				check(not seen.has(p) or clear,"a wiped cell never becomes oily again")
				if clear:seen[p]=true;count+=1
		counts.append(count)
	check(counts[0]==0 and counts[-1]==928,"tissue goes from fully covered to all 928 glass cells clear")
	check(Motion.poster(0).phase=="contact" and Motion.poster(500).phase=="wipe" and Motion.poster(1200).phase=="peel","contact, wipe, ticket lift are separate beats")
	check(Motion.poster(1500).ticket_alpha<1 and Motion.poster(1500).cloth_alpha==0,"ticket settles only after tissue withdrawal")
	check(absf(Motion.dust(220).brush_contact.x-Motion.VENT_LIP.x)<=5 and Motion.dust(380).brush_contact.y==Motion.VENT_LIP.y,"short sweep keeps the bristles on the authored vent lip")
	check(Motion.dust(400).flutter==0 and absf(Motion.dust(700).flutter)<=1.7 and Motion.dust(1250).flutter==0,"paper edge responds softly and settles without a hard fold")
	check(Motion.dust(700).paper==Motion.PAPER and Motion.dust(900).paper==Motion.PAPER,"the source paper body never recoils sideways")
	check(Motion.dust(649).edge==0 and Motion.dust(1300).edge==1,"fluorescence begins only after the first powder contact")
	for ms in range(0,1600,20):
		var grains:Array=Motion.grains(ms)
		check(grains.size()<=6,"powder is bounded to six small local grains")
		for grain:Dictionary in grains:check(Rect2(810,112,142,95).has_point(grain.point),"powder remains on the existing vent to paper route")
	var controller:RefCounted=Chapter.new()
	var s:=fixture()
	var view:RefCounted=Clues.new();view.sync(s)
	controller.physical(s,"theater_poster")
	check(s.theaterHunt.posterCleaned and s.items.theaterTicketHalfA and not s.items.greaseTissue,"unchanged controller immediately consumes tissue and grants half A")
	var accepted:=JSON.stringify(s)
	view.sync(s);check(view.poster_ms==0,"only accepted false-to-true edge starts wiping")
	view.tick(.1,s);var age:float=view.poster_ms
	controller.physical(s,"theater_poster");view.sync(s)
	check(view.poster_ms==age and JSON.stringify(s)==accepted,"repeat interaction neither restarts the wipe nor changes the accepted reward")
	view.settle();check(JSON.stringify(s)==accepted,"cancelling presentation cannot undo or repeat the reward")
	view.sync(s.duplicate(true));check(view.poster_ms==INF,"save reload shows the accepted settled result without replay")
	s=fixture("prop_setup");view=Clues.new();view.sync(s)
	controller.physical(s,"theater_backstage_vent")
	check(s.theaterHunt.paperDusted and s.theaterHunt.phase=="spotlight_ready" and not s.items.fluorescentBrush,"unchanged controller immediately consumes brush and marks paper")
	accepted=JSON.stringify(s);view.sync(s)
	check(view.paper_active(),"accepted dust edge starts the physical paper response")
	for i in 20:view.tick(.1,s)
	check(not view.paper_active() and JSON.stringify(s)==accepted,"elapsed presentation ends without any progression write")
	view.sync(s,true);check(not view.paper_active(),"scene reload never replays accepted powder")
	for interrupt in ["dark","scene","phase","reduced","pause"]:
		s=fixture("prop_setup");view=Clues.new();view.sync(s);controller.physical(s,"theater_backstage_vent");view.sync(s)
		match interrupt:
			"dark":s.native.mode="dark"
			"scene":s.native.scene="campus_bootstrap"
			"phase":s.theaterHunt.phase="spotlight_hunt"
			"reduced":s.native.settings.reduced_motion=true
			"pause":s.ui.controlCenterOpen=true
		accepted=JSON.stringify(s);view.tick(.02,s)
		check(not view.paper_active() and JSON.stringify(s)==accepted,"interruption settles harmlessly: "+interrupt)
	s=fixture();s.native.mode="dark";view=Clues.new();view.sync(s);controller.physical(s,"theater_poster");view.sync(s)
	check(not s.theaterHunt.posterCleaned and view.poster_ms==INF,"rejected dark interaction does not start a success animation")
	var layers:RefCounted=Layers.new();s=fixture("prop_setup");layers.sync(s,true);controller.physical(s,"theater_backstage_vent");layers.sync(s)
	var entries:Array=layers.entries(s)
	check(entries.filter(func(e:Dictionary)->bool:return e.id=="stage_paper").is_empty(),"during powder only one paper renderer is mounted")
	check(entries.filter(func(e:Dictionary)->bool:return e.id=="theater_vent_contact").size()==1,"layers mount one local vent/paper presentation")
	layers.theater_clues.settle();entries=layers.entries(s)
	check(entries.filter(func(e:Dictionary)->bool:return e.id=="stage_paper").size()==1,"after settle the existing paper renderer resumes once")
	var renderer:=Node2D.new();root.add_child(renderer)
	var focus_connections:int=root.focus_exited.get_connections().size()
	s=fixture("prop_setup");view=Clues.new();view.sync(s);controller.physical(s,"theater_backstage_vent");view.sync(s)
	accepted=JSON.stringify(s);view._bind_owner(renderer)
	check(view.paper_active(),"binding a first renderer preserves the accepted response")
	root.focus_exited.emit()
	check(not view.paper_active() and JSON.stringify(s)==accepted,"window focus loss cancels only presentation")
	view.present(renderer,{"origin":Vector2(7,11),"zoom":.75},s,200.0)
	await process_frame;await process_frame
	var object_scene:Node2D=view.object_scene
	check(is_instance_valid(object_scene) and object_scene.get_parent()==renderer,"native clue scene belongs to the world renderer")
	var objects:Node2D=object_scene.get_node("VisibleSurface/Objects")
	for object_name in ["OilMask","Tissue","TicketHalf","VentBrush","Powder","Paper"]:
		check(objects.get_node(object_name) is Node2D,"independently addressable native object: "+object_name)
	check(object_scene.clip.clip_contents and object_scene.clip.mouse_filter==Control.MOUSE_FILTER_IGNORE,"clipped visual scene does not steal existing world input")
	check(objects.position==Vector2(7,11) and objects.scale==Vector2.ONE*.75,"native object root owns camera transform")
	check(Part.oil_density(Vector2(43,13))>.64 and Part.oil_density(Vector2(225,2))<.3,"oil has thick dark smears and thinner readable glass")
	s=fixture();view.sync(s,true);view.present(renderer,{"origin":Vector2.ZERO,"zoom":1.0},s,200.0)
	check(object_scene.oil.visible and not object_scene.tissue.visible and not object_scene.ticket.visible,"dirty poster mounts only its oil before accepted contact")
	controller.physical(s,"theater_poster");view.sync(s);view.poster_ms=750;view.present(renderer,{"origin":Vector2.ZERO,"zoom":1.0},s,200.0)
	check(object_scene.tissue.visible and object_scene.ticket.visible and object_scene.oil.elapsed_ms==750,"accepted wipe drives independently owned tissue, oil and ticket")
	check(object_scene.tissue.position==Motion.poster(750).cloth,"tissue node uses its own moving contact pivot")
	s=fixture("prop_setup");view.sync(s,true);controller.physical(s,"theater_backstage_vent");view.sync(s);view.dust_ms=700
	view.present(renderer,{"origin":Vector2.ZERO,"zoom":1.0},s,200.0)
	check(object_scene.paper.visible and object_scene.brush.position==Motion.dust(700).brush_contact,"vent children own source contact and paper reaction")
	check(absf(object_scene.right.polygon[1].x-32)<.5 and object_scene.left.polygon[1].x==14,"only the narrow outer strip flutters; the paper body does not fold")
	check(object_scene.brush.scale==Vector2.ONE*.62,"vent brush is a scene-sized prop rather than a full inventory icon")
	check(object_scene.left.material==object_scene.right.material and object_scene.marked_left.material==object_scene.marked_right.material,"local contact mask stays continuous across both paper facets")
	check(is_equal_approx(object_scene.marked_left.material.get_shader_parameter("reveal"),Motion.dust(700).edge),"paper material reveals from the powder-contact edge")
	var other_objects:Node2D=load("res://scenes/theater_clue_objects.tscn").instantiate();renderer.add_child(other_objects)
	check(other_objects.marked_left.material!=object_scene.marked_left.material,"each native scene owns an independent contact-reveal material")
	other_objects.free()
	view.dust_ms=Motion.DUST_MS-1;view.present(renderer,{"origin":Vector2.ZERO,"zoom":1.0},s,200.0)
	check(object_scene.right.polygon[1]==Vector2(32,-32) and object_scene.right.polygon[2]==Vector2(32,32),"final edge returns to the exact source sheet geometry")
	check(object_scene.marked_left.material.get_shader_parameter("reveal")==1.0,"final marked texture is complete before normal-paper handoff")
	view.settle();check(not object_scene.visible,"cancellation immediately retires the native object scene")
	renderer.free()

	check(root.focus_exited.get_connections().size()==focus_connections,"removing renderer disconnects its window signal")
	# Cancellation and removal can occur in the same frame as a deferred mount.
	var pending_renderer:=Node2D.new();root.add_child(pending_renderer)
	s=fixture();view=Clues.new();view.sync(s)
	view.present(pending_renderer,{"origin":Vector2.ZERO,"zoom":1.0},s,0.0);view.settle()
	await process_frame
	check(is_instance_valid(view.object_scene) and not view.object_scene.visible,"same-frame cancellation cannot revive a queued native presentation")
	pending_renderer.free();await process_frame
	pending_renderer=Node2D.new();root.add_child(pending_renderer)
	view=Clues.new();view.sync(s);view.present(pending_renderer,{"origin":Vector2.ZERO,"zoom":1.0},s,0.0)
	pending_renderer.free();await process_frame
	check(not is_instance_valid(view.object_scene) and view.owner==null,"renderer removal before deferred mount leaves no orphan native objects")
	print("THEATER_CLUE_REACTIONS ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
