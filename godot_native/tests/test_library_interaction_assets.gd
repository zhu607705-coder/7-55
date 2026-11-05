extends SceneTree
const Assets=preload("res://scripts/objects/library_interaction_assets.gd")
const Layers=preload("res://scripts/ui/library_world_layers.gd")
const Library=preload("res://scripts/chapters/library022.gd")
const Picker=preload("res://scripts/world_object_picker.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("LIBRARY_INTERACTIONS "+label)
func run()->void:
	var state:Node=root.get_node("State")
	var original:String=JSON.stringify(state.d)
	var assets:=Assets.new();check(assets.ensure_loaded(),"all three generated sheets load atomically")
	if not assets.ready:quit(1);return
	var art:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/art/art_direction_v1.json"))
	var palette:Dictionary={}
	for hex:String in art.palette.colors:palette[Color(hex).to_rgba32()]=true
	for id:String in Assets.CELLS:
		var hashes:Dictionary={}
		for index:int in 16:
			var texture:Texture2D=load(Assets.ROOT+"%s_%02d.png"%[id,index])
			var image:Image=texture.get_image()
			if image.is_compressed():image.decompress()
			check(image.get_size()==Vector2i(Assets.CELLS[id]),"fixed registered frame "+id)
			var bounds:=image.get_used_rect()
			check(bounds.position.x>0 and bounds.position.y>0 and bounds.end.x<image.get_width() and bounds.end.y<=image.get_height(),"no clipped silhouette "+id)
			var valid:=true
			for y:int in image.get_height():
				for x:int in image.get_width():
					var c:=image.get_pixel(x,y)
					if c.a!=0 and (c.a!=1 or not palette.has(c.to_rgba32())):valid=false
			check(valid,"genuine alpha and shared palette "+id)
			hashes[image.get_data().hex_encode().sha256_text()]=true
		check(hashes.size()>=12,"distinct drawn poses "+id)
	var s:Dictionary=state.initial();s.native.chapter=2;s.native.scene="library_interior";s.native.mode="light"
	s.runtimeMode="rpg";s.rpgScene="library_interior";s.ui.libraryFinalsPhase="library_entered"
	s.ui.libraryFinalsPuzzle.entranceRecordRead=true
	var layers:=Layers.new();layers.sync(s)
	check(layers.interactions.ready,"real library presentation owns the generated family")
	var controller:=Library.new();controller.dispatch(s,"lib_backpack");layers.sync(s)
	var before:=JSON.stringify(s);var old_solids:Array=layers.objects.solids.duplicate(true)
	var selected:Dictionary={}
	for i:int in 10:
		layers.tick(.05,s);var pose:Dictionary=layers.interaction_snapshot();selected[pose.bagFrame]=true
		check(pose.bagFrame<=7,"only one physical note, no note painted into the backpack")
		check(pose.staffFrame<=11,"one physical stamp, no second held-stamp drawing")
	check(selected.size()>=4,"inspection advances through the empty pocket poses")
	check(JSON.stringify(s)==before and layers.objects.solids==old_solids,"render clocks never write story or collision")
	var geometry:Dictionary=layers.interactions.backpack_geometry(layers.objects.geometry("backpack"),3)
	var picker:=Picker.new()
	check(picker.contains(geometry,Vector2(geometry.rect.get_center().x,geometry.rect.end.y-10)),"rendered backpack keeps its physical alpha pick")
	layers.motion.observe("lib_front_desk",s,s,{"handled":true})
	check(layers.motion.staff_ms==0,"actual accepted receptionist action triggers response")
	for i:int in 6:layers.tick(.05,s)
	check(layers.interaction_snapshot().staffFrame>=4,"receptionist acknowledges the visitor with an actual hand pose")
	layers.motion.cancel();check(layers.motion.staff_ms<0,"hide/replacement cancels response")
	var settled:=s.duplicate(true);layers.sync(settled,true)
	check(layers.seat.inspect_ms<0 and layers.interaction_snapshot().bagFrame==7,"reload restores open empty pocket without replay")
	settled.native.settings.reduced_motion=true;layers.sync(settled)
	check(layers.interaction_snapshot().staffFrame==0 and layers.interaction_snapshot().paperFrame==15,"reduced motion uses readable stable poses")
	settled.native.scene="campus_bootstrap";layers.sync(settled)
	check(not layers.active and layers.seat.inspect_ms<0,"leaving the scene cancels local gestures")
	check(JSON.stringify(state.d)==original,"fixture and generated textures never modify the user's save")
	print("LIBRARY_INTERACTIONS ",checks," checks, ",failures," failures");quit(1 if failures else 0)
