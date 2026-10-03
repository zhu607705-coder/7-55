extends SceneTree
## Public-identity UI fixtures. This is not earned C2 traversal evidence.
const Wayfinding=preload("res://scripts/ui/campus_wayfinding.gd")
const Pages=preload("res://scripts/ui/phone_pages.gd")
var checks:=0
var failures:=0
var pages=Pages.new()
var s: Dictionary
var view: Control
var surface: Control
var actions: Array=[]
var routes: Array=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("CAMPUS WAYFINDING: "+message)
func frames(n:=3) -> void:
	for i in n: await process_frame
func show() -> void:
	if is_instance_valid(view): view.free()
	pages.s=s;view=pages.native_library.build(pages,"library_app");view.scale=Vector2.ONE*pages.PHONE_SCALE;surface.add_child(view);await frames()
func click(control: Control) -> void:
	check(control!=null and control.is_visible_in_tree(),"Visible actual input target")
	if control==null:return
	var point:=control.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;root.push_input(motion,true)
	var down:=InputEventMouseButton.new();down.position=point;down.global_position=point;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;root.push_input(down,true);await process_frame
	var up:=InputEventMouseButton.new();up.position=point;up.global_position=point;up.button_index=MOUSE_BUTTON_LEFT;root.push_input(up,true);await frames()
func node(id: String) -> Control:return view.find_child(id,true,false)
func run() -> void:
	root.get_node("State").developer_mode=true
	var font: Font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	var map: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/maps/zijingang-campus-runtime.json"))
	check(Wayfinding.LIBRARY_GATE==Vector2(map.libraryGate.x,map.libraryGate.y),"Public location matches existing source gate")
	var landmark: Dictionary=map.landmarks[0]
	check(landmark.id=="foundation_library" and Wayfinding.LIBRARY_CENTER==Vector2(landmark.x,landmark.y),"Identity uses existing source landmark")
	for dimensions in [Vector2(390,690),Vector2(430,706),Vector2(960,540)]:
		for scale in [1.0,.76]:
			for zoom in [.45,1.1,1.6]:
				var context={"scene_id":"campus_bootstrap","origin":dimensions/2-Wayfinding.LIBRARY_GATE*zoom,"player":Wayfinding.LIBRARY_GATE,"zoom":zoom}
				var visible:=Rect2(0,44,dimensions.x,dimensions.y-94)
				var layout:=Wayfinding.label_layout(context,font,scale,visible)
				check(not layout.is_empty(),"Gate label remains visible across viewport, split-scale and zoom")
				if not layout.is_empty():
					check(float(layout.physical_font_size)>=16,"Physical identity type is at least16px")
					check(visible.encloses(layout.rect),"Identity is in-world and clear of HUD")
	var context={"scene_id":"campus_bootstrap","origin":Vector2(480,270)-Wayfinding.LIBRARY_GATE*1.1,"player":Vector2(2550,650),"zoom":1.1}
	var handoff_context=context.duplicate()
	handoff_context.player=Wayfinding.LIBRARY_GATE
	for unavailable in [Rect2(0,44,960,-10),Rect2(0,44,-1,540),Rect2(0,44,960,0),Rect2(0,44,0,540)]:
		check(Wayfinding.label_layout(handoff_context,font,1,unavailable).is_empty(),"Viewport handoff without usable scene area hides identity safely")
	check(Wayfinding.label_layout(context,font,1,Rect2(0,44,960,446)).is_empty(),"No distant identity revealed while player remains at dorm")
	context.player=Wayfinding.LIBRARY_GATE;context.origin+=Vector2(1600,0)
	check(Wayfinding.label_layout(context,font,1,Rect2(0,44,960,446)).is_empty(),"Camera pan cannot clamp an offscreen building label to HUD")
	context.origin-=Vector2(1600,0);context.scene_id="campus_qizhen_loop"
	check(Wayfinding.label_layout(context,font,1,Rect2(0,44,960,446)).is_empty(),"No labels in a different campus projection")
	s=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":2,"page":"library_app","scene":"campus_bootstrap","mode":"light","selected_item":""}
	s.actOne.phase="complete";s.actOne.dormHubUnlocked=true;s.ui.librarySeatReserved=true;s.ui.librarySelectedSeat="022"
	surface=Control.new();surface.position=Vector2(3,40);surface.size=Vector2(424,814);root.add_child(surface)
	var theme:=Theme.new();theme.default_font=font;surface.theme=theme
	pages.action_requested.connect(func(id,value):actions.append([id,value]))
	pages.page_requested.connect(func(page):routes.append(page))
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(1280,720)]:
		root.size=dimensions;surface.scale=Vector2.ONE*minf(1.0,minf((dimensions.x-36)/430.0,(dimensions.y-36)/860.0))
		pages.native_library.local_page="seat";pages.native_library.selected_library="基础馆";pages.native_library.seat_view="list";pages.native_library.seat_section=2
		await show()
		var location_link:Button=node("LibraryBuildingLocationLink")
		var intersects_label:=false
		for child in location_link.get_parent().get_children():
			if child is Label and child.get_rect().intersects(location_link.get_rect()):intersects_label=true
		check(not intersects_label,"Location link does not cover title or remaining-seat count")
		check(location_link.get_theme_font_size("font_size")*location_link.get_global_transform_with_canvas().get_scale().x>=14,"Location link remains readable at actual phone-shell scale")
		if dimensions.x<1100:check(location_link.get_global_rect().size.y>=44,"Tall-mobile location link has a44px physical target")
		var before:=JSON.stringify(s)
		await click(node("LibraryBuildingLocationLink"));await show()
		check(view.name=="LibraryBuildingLocation","Reservation link opens optional building location")
		check(node("LibraryLocationIdentity").text=="基础馆 · 基础图书馆","Reservation and facade names are explicitly joined")
		check(node("LibraryCampusMap").texture is AtlasTexture and node("LibraryTowerReference").texture is AtlasTexture,"Map and close view share exact original source artwork")
		var map_view:TextureRect=node("LibraryCampusMap");var tower:TextureRect=node("LibraryTowerReference")
		check(map_view.texture.region==Wayfinding.MAP_REGION and tower.texture.region==Wayfinding.TOWER_REGION,"Crops retain fixed source-pixel regions")
		check(map_view.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED and tower.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"Neither projection nor tower is stretched")
		check(node("LibraryLocationScroll").get_h_scroll_bar().max_value<=node("LibraryLocationScroll").size.x,"Location content has no horizontal overflow")
		await click(node("PhoneNav_back"));await show()
		check(pages.native_library.local_page=="seat" and pages.native_library.seat_view=="list" and pages.native_library.seat_section==2,"Back preserves reservation viewing state")
		check(JSON.stringify(s)==before,"Opening and dismissing location writes no story, item, route or reservation facts")
		await click(node("LibraryBuildingLocationLink"));await show();await click(node("PhoneNav_back"));await show()
		check(JSON.stringify(s)==before and pages.native_library.local_page=="seat","Repeated open/close is side-effect free")
	pages.native_library.selected_library="主馆";await show()
	check(node("LibraryBuildingLocationLink")==null,"Other buildings are never given the foundation-library identity")
	check(routes.is_empty() and actions.all(func(action):return action[0]=="phone_refresh"),"All location inputs only request local redraw, never a world action")
	view.free();surface.free();await frames()
	print("Campus wayfinding: ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
