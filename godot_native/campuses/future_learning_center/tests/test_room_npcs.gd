extends SceneTree
const Floor=preload("res://campuses/future_learning_center/scripts/floor_view.gd")
const Body=preload("res://scripts/player_metrics.gd")
const Space=preload("res://scripts/space/spatial_rules.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FLC_NPC: "+label)
func _initialize()->void:run.call_deferred()
func opaque_point(world:Node2D,person:Dictionary)->Vector2:
	var geometry:Dictionary=world.npc_geometry(person)
	var image:Image=geometry.texture.get_image()
	if image.is_compressed():image.decompress()
	for y:int in range(20,110,3):
		for x:int in range(20,76,3):
			if image.get_pixel(x,y).a>.1:
				var point:Vector2=geometry.rect.position+Vector2(x+.5,y+.5)*Body.DISPLAY_SCALE
				if not world.npc_at(point).is_empty():return point
	return Vector2.INF
func run()->void:
	create_timer(90).timeout.connect(func()->void:push_error("FLC_NPC: watchdog");quit(2))
	var world=Floor.new();root.add_child(world);world.set_process(false);world.user_control=false
	var ids:Dictionary={}
	var expected_people:=0
	var exercised_rooms:Dictionary={}
	for entry:Array in [[2,"team"],[3,"recording"]]:
		var floor_number:int=entry[0]
		var room:String=entry[1]
		check(world.load_floor(floor_number),"load NPC floor")
		var people:Array=world.data.get("npcs",[])
		check(people.size()>=1 and people.size()<=2,"room contains one or two independent people")
		expected_people+=people.size()
		for person:Dictionary in people:
			check(world.load_floor(floor_number),"reload intended floor for "+str(person.id))
			exercised_rooms[room]=true
			check(not ids.has(str(person.id)),"stable NPC id unique across floors");ids[str(person.id)]=true
			check(str(person.room)==room,"person belongs to intended room")
			check(Vector2(person.frameSize[0],person.frameSize[1])==Body.FRAME and int(person.frameCount)==2,"existing two-frame player-sized master")
			check(FileAccess.file_exists(person.path),"existing transparent resource exists")
			var geometry:Dictionary=world.npc_geometry(person)
			check(geometry.texture.get_size()==Vector2(192,128),"existing image frame dimensions")
			check(geometry.rect==Body.visual_rect(world.npc_foot(person)-Body.FOOT_CENTER_OFFSET),"same scale and calibrated foot anchor as player")
			var foot_box:=Body.foot_rect(world.npc_foot(person)-Body.FOOT_CENTER_OFFSET)
			var solid_conflicts:Array[String]=[]
			for prop:Dictionary in world.data.objects:
				if not prop.get("mounted",false) and foot_box.intersects(Space.rect(prop.footprint)):solid_conflicts.append(str(prop.id))
			check(solid_conflicts.is_empty(),"NPC feet never overlap solid props: "+str(solid_conflicts))
			var peer_conflicts:Array[String]=[]
			for peer:Dictionary in people:
				if str(peer.id)==str(person.id):continue
				if foot_box.intersects(Body.foot_rect(world.npc_foot(peer)-Body.FOOT_CENTER_OFFSET)):peer_conflicts.append(str(peer.id))
			check(peer_conflicts.is_empty(),"NPC feet never overlap another person: "+str(person.id)+" "+str(peer_conflicts))
			var cover_conflicts:Array[String]=[]
			for cover:Dictionary in world.data.occluders:
				var modules:Array=world.data.modules.filter(func(m:Dictionary)->bool:return m.id==cover.module)
				if modules.is_empty():continue
				var module:Dictionary=modules[0]
				var origin:=Vector2(module.at[0],module.at[1])-Vector2(module.crop[0],module.crop[1])*float(module.scale)
				var source:Rect2=Space.rect(cover.rect)
				var painted:=Rect2(origin+source.position*float(module.scale),source.size*float(module.scale))
				if geometry.rect.intersects(painted):cover_conflicts.append(str(cover.module)+" "+str(cover.rect))
			check(cover_conflicts.is_empty(),"first-batch actor render avoids wall covers: "+str(cover_conflicts))
			check(not world.space.can_stand(world.npc_foot(person)-Body.FOOT_CENTER_OFFSET),"NPC foot blocks the shared complete-foot predicate")
			check(not world.load_floor(floor_number,world.npc_foot(person)),"old actor location now occupied by NPC is rejected for existing restore fallback")
			var door:Dictionary=world.data.doors.filter(func(d:Dictionary)->bool:return d.room==room)[0]
			var inside:=Vector2(door.inside[0],door.inside[1])-Body.FOOT_CENTER_OFFSET
			var outside:=Vector2(door.outside[0],door.outside[1])-Body.FOOT_CENTER_OFFSET
			check(world.space.segment_clear(inside,outside),"NPC does not block door sweep")
			world.set_foot(Vector2(door.outside[0],door.outside[1]))
			var approach:Vector2=world.npc_approach(person)
			check(approach.is_finite(),"NPC has a reachable interaction side")
			if not approach.is_finite():continue
			var anchor:=approach-Body.FOOT_CENTER_OFFSET
			check(world.space.can_stand(anchor),"complete feet fit beside person")
			check(not world.space.route(outside,anchor).is_empty() and not world.space.route(anchor,outside).is_empty(),"NPC side has round-trip route through door")
			var blocked_sides:=0
			for direction:Vector2 in [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]:
				var start:Vector2=world.npc_foot(person)+direction*55.0-Body.FOOT_CENTER_OFFSET
				if not world.space.can_stand(start):continue
				var stopped:Vector2=world.space.move(start,-direction*80.0)
				check(world.space.can_stand(stopped),"swept NPC contact remains legal")
				check((stopped+Body.FOOT_CENTER_OFFSET-world.npc_foot(person)).dot(direction)>0,"cannot tunnel through NPC feet")
				check(world.space.move(stopped,direction*35).distance_to(stopped)>30,"can retreat after NPC contact")
				blocked_sides+=1
			check(blocked_sides>=2,"at least two circulation sides remain clear")
			var point:=opaque_point(world,person)
			check(point.is_finite(),"actual opaque NPC pixel is pickable")
			check(world.npc_at(geometry.rect.position+Vector2(.1,.1)).is_empty(),"transparent corner never steals a click")
			if not point.is_finite():continue
			check(not world.talk_to_npc(str(person.id)) and world.npc_reply.is_empty(),"remote actor cannot speak through doorway")
			world.point_action(point)
			check(world.npc_pending==str(person.id) and not world.route.is_empty() and world.npc_reply.is_empty(),"far pointer queues approach, not remote dialogue")
			world.user_control=true
			var cancel:=InputEventScreenTouch.new();cancel.index=2;cancel.pressed=true;cancel.canceled=true
			world._unhandled_input(cancel)
			check(world.npc_pending.is_empty() and world.route.is_empty() and world.npc_reply.is_empty(),"touch cancellation retires a queued NPC approach")
			world.point_action(point);world.touch_vector=Vector2.RIGHT;world._process(1.0/60);world.touch_vector=Vector2.ZERO
			check(world.npc_pending.is_empty() and world.route.is_empty(),"manual locomotion cancels automatic NPC approach")
			world.point_action(point)
			for i:int in 1600:
				world._process(1.0/60)
				if world.npc_pending.is_empty():break
			world.user_control=false
			check(world.npc_pending.is_empty() and world.npc_reply_id==str(person.id),"ordinary movement reaches NPC before reply")
			check(world.invalid_frames==0,"NPC route never clips collision")
			var before:Dictionary=world.data.duplicate(true)
			var signature:String=world._completion_signature()
			world._clear_npc_interaction();world.set_foot(approach);world.user_control=true
			var key:=InputEventKey.new();key.keycode=KEY_SPACE;key.pressed=true
			world._unhandled_input(key)
			check(world.npc_reply_id==str(person.id),"nearby Space reaches same short interaction")
			world._clear_npc_interaction()
			var touch:=InputEventScreenTouch.new();touch.index=2;touch.pressed=true;touch.canceled=true;touch.position=world.world_to_screen(point)
			world._unhandled_input(touch)
			check(world.npc_reply.is_empty() and world.npc_pending.is_empty(),"canceled touch cannot begin NPC interaction")
			touch.canceled=false;world._unhandled_input(touch)
			check(world.npc_reply_id==str(person.id),"ordinary nearby touch responds")
			check(world.data==before and world._completion_signature()==signature,"reply never changes authored data or room progression")
			world._tick_npc_feedback(7)
			check(world.npc_reply.is_empty() and world.npc_reply_id.is_empty(),"short feedback expires without permanent label")
			world.talk_to_npc(str(person.id));world.npc_pending=str(person.id)
			world._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
			check(world.npc_reply.is_empty() and world.npc_pending.is_empty() and world.route.is_empty(),"focus loss clears response and queued interaction")
			world.talk_to_npc(str(person.id));world.npc_pending=str(person.id)
			world.toggle_overview()
			check(world.npc_reply.is_empty() and world.npc_pending.is_empty(),"overview retires response")
			world.toggle_overview();world.user_control=false
			var key_name:String=room
			var station_approach:Vector2=world.puzzle_approach(key_name)
			check(station_approach.is_finite() and world.set_foot(station_approach),"existing room station still reachable")
			world.npc_pending=str(person.id);world.npc_reply="transient"
			world.point_action(Space.rect(world.puzzle_anchor(key_name).bounds).get_center())
			check(is_instance_valid(world.active_puzzle) and world.active_puzzle.visible,"station click keeps priority over NPC")
			check(world.npc_pending.is_empty() and world.npc_reply.is_empty(),"opening station retires ambient interaction")
			if is_instance_valid(world.active_puzzle):world.active_puzzle.close()
			if floor_number==2:
				var original:Vector2=world.signal_sync_approach()
				check(original.is_finite() and world.set_foot(original) and world.open_signal_sync(),"original team signal bench stays reachable and opens")
				world.signal_sync.close()
			world.npc_pending=str(person.id);world.npc_reply="transient"
			world.load_floor(4)
			check(world.npc_pending.is_empty() and world.npc_reply.is_empty(),"floor handoff clears ambient state")
			check(world.npc_by_id(str(person.id)).is_empty(),"retired-floor person cannot be interacted with")
	check(ids.size()==expected_people and exercised_rooms.size()==2,"every authored person across both target rooms exercised")
	check(Floor.PuzzleAnchors.size()==24,"existing room anchor registry unchanged")
	world.queue_free();await process_frame
	print("FLC_ROOM_NPCS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
