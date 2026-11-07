extends SceneTree
const Layered=preload("res://scripts/presentation/campus_layered_map.gd")
var checks:=0
var failures:=0
func check(value:bool,label:String)->void:
 checks+=1
 if not value:failures+=1;push_error(label)
func ids(plan:Array[Dictionary])->Array[String]:
 var result:Array[String]=[]
 for item:Dictionary in plan:
  if item.kind!="water":result.append(str(item.row.id))
 return result
func _initialize()->void:
 var art:=Layered.new()
 art.manifest=JSON.parse_string(FileAccess.get_file_as_string(Layered.MANIFEST))
 check(Layered.validate_semantics(art.manifest).is_empty(),"actual manifest semantics")
 var count:=0
 for row:Dictionary in art.manifest.layers:
  if not str(row.id).begins_with("west_sports_south_tree_"):continue
  count+=1
  check(row.renderPass=="raised" and row.depthMode=="baseline","independent measured tree")
  var foot:float=float(row.baseline)
  check(ids(art.render_plan(foot-1,true)).has(row.id),"tree covers actor north of base")
  check(not ids(art.render_plan(foot-1)).has(row.id),"north base not painted twice")
  check(ids(art.render_plan(foot+1)).has(row.id),"actor covers tree south of base")
  check(not ids(art.render_plan(foot+1,true)).has(row.id),"south base not painted twice")
  check(ids(art.render_plan(foot)).has(row.id),"baseline equality actor in front")
  var back:=ids(art.render_plan(foot+1));var tree_index:=back.find(row.id)
  for candidate:Dictionary in art.manifest.layers:
   if candidate.renderPass=="roads":check(back.find(candidate.id)<tree_index,"tree always follows road")
  for tile:Dictionary in row.tiles:check(FileAccess.get_sha256(tile.path)==tile.sha256,"tree actual tile SHA")
 check(count==6,"exactly six original trees split")
 print("V9 actual six-tree depth: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
