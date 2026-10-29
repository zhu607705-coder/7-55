extends SceneTree
const Body=preload("res://scripts/player_metrics.gd")
const Space=preload("res://scripts/space/spatial_rules.gd")
const FloorSpace=preload("res://campuses/future_learning_center/scripts/floor_space.gd")
var checks:=0
var failures:Array[String]=[]
var results:Array[Dictionary]=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);printerr("WALL_STORAGE_FAIL: "+label)
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	for floor_number:int in [2,3,4]:
		var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/future_learning_center/data/floor_%d.json"%floor_number))
		var space=FloorSpace.new();space.configure(data)
		var start:=Vector2(data.spawn[0],data.spawn[1])-Body.FOOT_CENTER_OFFSET
		var count:=0
		for item:Dictionary in data.objects:
			if item.asset not in ["cabinet","parts_rack","pantry_wall_unit","pantry_fridge"]:continue
			count+=1
			var label:="%dF %s"%[floor_number,item.id]
			check(item.has("wallStorage"),label+" wall placement metadata")
			if not item.has("wallStorage"):continue
			var footprint:=Space.rect(item.footprint)
			var wall_y:float=item.wallStorage.wallY
			check(absf(footprint.position.y-wall_y)<=1.0,label+" rear edge touches wall seam")
			var source:=Space.rect(item.crop);var bounds:=Space.rect(item.bounds)
			check(absf(bounds.size.x/bounds.size.y-source.size.x/source.size.y)<.00001,label+" no sprite stretching")
			var front:=Space.rect(item.wallStorage.access).get_center()-Body.FOOT_CENTER_OFFSET
			check((front+Body.FOOT_CENTER_OFFSET).y-footprint.end.y<=96,label+" reachable within normal interaction distance")
			check(space.can_stand(front),label+" complete feet fit in front")
			check(not space.route(start,front).is_empty(),label+" approached from floor spawn")
			var stopped:Vector2=space.move(front,Vector2(0,-70))
			check(space.can_stand(stopped),label+" collision stops safely")
			check(stopped.distance_to(front)<69,label+" solid cabinet or original wall stops forward walking")
			check((stopped+Body.FOOT_CENTER_OFFSET).y>footprint.end.y,label+" cannot walk through cabinet")
			check(space.move(stopped,Vector2(0,35)).distance_to(stopped)>30,label+" can back away")
			var module:Dictionary=data.modules.filter(func(m:Dictionary)->bool:return m.id==item.room)[0]
			var origin:=Vector2(module.at[0],module.at[1])-Vector2(module.crop[0],module.crop[1])*float(module.scale)
			for window:Array in item.wallStorage.sourceWall.get("sourceWindows",[]):
				var pane:=Rect2(origin+Vector2(window[0],window[1])*float(module.scale),Vector2(window[2],window[3])*float(module.scale))
				check(not bounds.intersects(pane),label+" does not cover source-image window")
		if floor_number==3:
			var fridges:Array=data.objects.filter(func(o:Dictionary)->bool:return o.asset=="pantry_fridge")
			check(fridges.size()==1,"3F pantry has the user-confirmed refrigerator")
			if fridges.size()==1:
				var fridge:Dictionary=fridges[0]
				check(fridge.room=="pantry","refrigerator belongs only to the 3F pantry")
				for other:Dictionary in data.objects:
					if other.room=="pantry" and other.asset in ["pantry_wall_unit","cabinet"]:
						check(Space.rect(fridge.bounds).position.x>Space.rect(other.bounds).end.x,"refrigerator stands right of pantry cupboards")
		results.append({"floor":floor_number,"storageUnits":count})
	var report:={"checks":checks,"failures":failures,"floors":results,"engine":Engine.get_version_info()}
	var target:=OS.get_environment("FLC_WALL_REPORT")
	if not target.is_empty():
		var file:=FileAccess.open(target,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	print("WALL_STORAGE: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
