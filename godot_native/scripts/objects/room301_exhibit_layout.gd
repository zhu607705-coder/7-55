extends RefCounted
## Native presentation geometry in the unchanged 1672 x 941 A3 source space.
## Controller facts and the original archive solver remain elsewhere.
static var _data:Dictionary={}
static func data()->Dictionary:
	if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/room301-exhibit.json"))
	return _data
static func rect(row:Array)->Rect2:return Rect2(float(row[0]),float(row[1]),float(row[2]),float(row[3]))
static func archive_bounds()->Rect2:return rect(data().archiveTarget)
static func active(scene:String,floor_id:String)->bool:return scene==data().sceneId and floor_id==data().floor
static func adjusted_collisions(original:Array)->Array:
	var result:Array=original.filter(func(box:Dictionary)->bool:return str(box.get("id","")) not in data().replacedCollisionIds)
	for object:Dictionary in data().objects:
		for i:int in object.solids.size():
			var area:Rect2=rect(object.solids[i])
			result.append({"id":"room301_"+object.id+"_"+str(i),"x":area.position.x,"y":area.position.y,"width":area.size.x,"height":area.size.y,"objectId":object.id})
	return result
