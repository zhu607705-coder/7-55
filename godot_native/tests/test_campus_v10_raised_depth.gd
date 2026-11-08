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
 var fixture:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/campus_v10_raised_ids.json"))
 check(Layered.validate_semantics(art.manifest).is_empty(),"manifest semantics")
 var count:=0
 for row:Dictionary in art.manifest.layers:
  if not row.id in fixture.ids:continue
  count+=1
  check(row.renderPass=="raised" and row.depthMode=="baseline","explicit object "+str(row.id))
  var foot:float=float(row.baseline)
  check(ids(art.render_plan(foot-1,true)).has(row.id),"north actor occluded "+str(row.id))
  check(not ids(art.render_plan(foot-1)).has(row.id),"no north duplicate")
  check(ids(art.render_plan(foot+1)).has(row.id),"south actor in front")
  check(not ids(art.render_plan(foot+1,true)).has(row.id),"no south duplicate")
  check(ids(art.render_plan(foot)).has(row.id),"equal baseline actor in front")
  var back:=ids(art.render_plan(foot+1))
  for candidate:Dictionary in art.manifest.layers:
   if candidate.renderPass=="roads":check(back.find(candidate.id)<back.find(row.id),"raised after road")
  for tile:Dictionary in row.tiles:check(FileAccess.get_sha256(tile.path)==tile.sha256,"tile identity")
 check(count==fixture.ids.size(),"exact added object count")
 print("V10 actual raised-depth: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
