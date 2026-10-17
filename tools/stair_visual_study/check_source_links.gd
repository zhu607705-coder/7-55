extends SceneTree
const Model=preload("res://scripts/games/chapter4_stair_model.gd")
var checks:int=0
var failed:bool=false
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:
  push_error(label)
  failed=true
func _initialize()->void:
 var d:Dictionary=Model.data()
 var level:Dictionary=d.levels[1]
 var camera:Dictionary=d.cameras[level.id]
 var found:Dictionary={}
 var invalidated:int=0
 var stats:Dictionary={}
 for a in range(4):
  for b in range(3):
   for c in range(4):
    for e in range(3):
     for view in Model.VIEWS:
      var state:Dictionary=Model.initial(level)
      state.values={"b_lower_stair":a,"b_mid_lift":b,"b_upper_stair":c,"b_exit_slide":e}
      state.view=view
      var edges:Array=Model.edges(level,state,camera)
      var counts:Dictionary={"physical":0,"mechanism":0,"perspective":0}
      for edge in edges:
       counts[edge.kind]+=1
       if edge.kind=="perspective":
        check(float(edge.distance)<=6.0,"distance limit")
        check(edge.valid,"tangent valid")
        stats[edge.id]=int(stats.get(edge.id,0))+1
        if not found.has(edge.id):found[edge.id]=state.duplicate(true)
      check(counts.physical==4,"original four physical edges preserved")
      check(counts.mechanism==(1 if b==2 else 0)+(2 if e==2 else 0),"mechanism edge requires its exact source state")
 for id in found:
  var state:Dictionary=found[id]
  var had:bool=false
  for edge in Model.edges(level,state,camera):
   if edge.id==id:had=true
  check(had,"positive witness exists")
  var removed:bool=false
  for view in Model.VIEWS:
   var changed:Dictionary=state.duplicate(true)
   Model.apply(level,changed,camera,{"type":"view","value":view})
   var still:bool=false
   for edge in Model.edges(level,changed,camera):
    if edge.id==id:still=true
   if not still:removed=true
  check(removed,"source recomputation removes perspective link at a nonmatching view")
  if removed:invalidated+=1
 check(found.size()==2,"both authored perspective links have valid source witnesses")
 # Six face views are inspection only and must not silently enter gameplay.
 for face in ["front","back","left","right","top","bottom"]:
  var state:Dictionary=Model.initial(level)
  check(not Model.apply(level,state,camera,{"type":"view","value":face}),"unapproved inspection view rejected by source game")
 var replay:Dictionary=Model.initial(level)
 var actions:Array=[
  {"type":"step","id":"b_lower_stair","delta":-1},
  {"type":"step","id":"b_lower_stair","delta":-1},
  {"type":"view","value":"south_west"},
  {"type":"walk","node":"B_MID_LIFT_LOW"},
  {"type":"step","id":"b_mid_lift","delta":1},
  {"type":"step","id":"b_mid_lift","delta":1},
  {"type":"walk","node":"B_UPPER_HIGH"},
  {"type":"step","id":"b_upper_stair","delta":1},
  {"type":"view","value":"top_oblique"},
  {"type":"walk","node":"B_HIGH_ISLAND"},
  {"type":"step","id":"b_exit_slide","delta":1},
  {"type":"step","id":"b_exit_slide","delta":1},
  {"type":"walk","node":"B_EXIT"}]
 var trace:Array=[snapshot(level,replay,camera,{"type":"initial"},[])]
 for action in actions:
  var route:Array=Model.path(level,replay,camera,str(action.node)) if action.type=="walk" else []
  check(Model.apply(level,replay,camera,action),"source route action accepted "+JSON.stringify(action))
  trace.append(snapshot(level,replay,camera,action,route))
 check(replay.node==level.exitNodeId,"source route reaches original exit")
 var args:PackedStringArray=OS.get_cmdline_user_args()
 if args.size()==2 and args[0]=="--trace":
  var file:FileAccess=FileAccess.open(args[1],FileAccess.WRITE)
  check(file!=null,"trace destination writable")
  if file:file.store_string(JSON.stringify({"source":"original chapter4_stair_model.gd","level":"stair_b","checks":checks,"failed":failed,"trace":trace},"  "))
 print("SOURCE_REPLAY ",JSON.stringify(actions))
 print("SOURCE_LINKS_OK checks=",checks," exhaustive_states=432 perspective_witnesses=",JSON.stringify(found)," invalidated=",invalidated," count=",JSON.stringify(stats))
 quit(1 if failed else 0)

func snapshot(level:Dictionary,state:Dictionary,camera:Dictionary,action:Dictionary,route:Array)->Dictionary:
 var positions:Dictionary={}
 for node in level.nodes:
  var p:Vector3=Model.position(level,state,node.id)
  positions[node.id]=[p.x,p.y,p.z]
 return {"action":action.duplicate(true),"route":route.duplicate(),"state":state.duplicate(true),"positions":positions,"edges":Model.edges(level,state,camera)}
