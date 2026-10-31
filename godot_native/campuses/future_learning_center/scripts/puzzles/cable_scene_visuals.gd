extends "res://campuses/future_learning_center/scripts/puzzles/optical_scene_visuals.gd"
## Reuses only immutable sprite utility; never invokes the optical sync/model.
const RasterPath=preload("res://campuses/future_learning_center/scripts/puzzles/cable_raster_path.gd")
var cables:Dictionary={}
var board:Node2D
func cable(id:String,path:PackedVector2Array,parent:Node2D)->void:
 if not art.has("cable_strip"):return
 if not cables.has(id):
  var line=RasterPath.new();line.name=id;parent.add_child(line);cables[id]=line
  line.configure(art.cable_strip.texture,art.cable_strip.region)
 cables[id].present(path)
func orient_plug(id:String,key:String,direction:Vector2)->void:
 if not objects.has(id) or direction.length_squared()<.01:return
 var axis:=Vector2(553,-239) if key=="plug_square" else Vector2(607,-222)
 objects[id].rotation=direction.angle()-axis.angle()
func move_object(id:String,parent:Node2D)->void:
 if objects.has(id) and objects[id].get_parent()!=parent:objects[id].reparent(parent,false)
func board_put(id:String,key:String,at:Vector2,box:=Vector2.ZERO)->void:
 put(id,key,at,box);move_object(id,board)
func sync(view,dt:float,_snap:=false)->void:
 for object in objects.values():object.advance_visual(dt)
 put("Tabletop","tabletop",Vector2(480,300),Vector2(960,440))
 if view.has_method("board_offset"):_flex(view)
 else:_signal(view)
func _signal(view)->void:
 put("SourceCard","card",Vector2(150,225),Vector2(145,110))
 put("Distribution","distribution",Vector2(411,235),Vector2(132,130))
 put("CacheCard","card",Vector2(405,360),Vector2(127,72))
 for i:int in 2:put("Monitor%d"%i,"monitor",view.model.positions[i],Vector2(145,113))
 for port:String in view.SignalSync.OUTPUTS+view.SignalSync.INPUTS:
  put("Socket_"+port,"socket_square" if port in ["source","bus_in"] else "socket_round",view.port_at(port),Vector2(20,20))
 for input:String in view.SignalSync.INPUTS:
  var start:Vector2=view.port_at(input)
  var connected:bool=view.model.cables.has(input)
  var finish:Vector2=view.port_at(str(view.model.cables.get(input,""))) if connected else start+Vector2(-40,30)
  if view.cable_input==input:finish=view.pointer+view.cable_grab_offset
  cable("Cable_"+input,PackedVector2Array([start,finish]),self)
  var plug_key:="plug_square" if input=="bus_in" else "plug_round"
  put("Plug_"+input,plug_key,finish,Vector2(28,28));orient_plug("Plug_"+input,plug_key,start-finish)
 put("Notes","cover",Vector2(112,478),Vector2(155,65))
 put("Records","card",Vector2(410,478),Vector2(220,65))
 for id:String in objects:
  objects[id].z_index=4 if id.begins_with("Plug_") else 2 if id.begins_with("Socket_") else 1
 for line in cables.values():line.z_index=3
 # Housings behind leads; separate plugs remain visible above their sockets.
 for id:String in ["Tabletop","SourceCard","Distribution","CacheCard","Monitor0","Monitor1"]:
  if objects.has(id):move_child(objects[id],0)
 if objects.has("Tabletop"):objects.Tabletop.z_index=0;move_child(objects.Tabletop,0)
func _flex(view)->void:
 if board==null:board=Node2D.new();board.name="PortableBoard01";add_child(board)
 board.position=view.board_offset()
 board_put("Fixture","fixture",Vector2(437,280.5),Vector2(494,293))
 board_put("Handle","handle",Vector2(480,122),Vector2(190,56))
 board_put("Pillar","pillar",view.Model.PILLAR.get_center(),art.pillar.box)
 board_put("Adapter","adapter",Vector2(275,164),Vector2(56,56))
 if objects.has("Adapter"):objects.Adapter.rotation=view.model.orientation*TAU/3
 for i:int in 3:
  var path:PackedVector2Array=view.route_preview(i,view._visible_cable(view.model.cable_path(i)))
  if view.dragging==i:path=PackedVector2Array([Vector2(350,view.PORT_Y[i]),view.to_board(view.pointer)+view.cable_grab_offset])
  cable("Cable%d"%i,path,board)
  if cables.has("Cable%d"%i):cables["Cable%d"%i].modulate=Color(1.15,1.15,1.15,.85) if view.route_drag==i else Color.WHITE
  board_put("Plug%d"%i,"plug_round",path[-1],Vector2(28,28));orient_plug("Plug%d"%i,"plug_round",path[-2]-path[-1])
  board_put("RouteClip%d"%i,"route_clip",view.to_board(view.pointer)+view.route_grab_offset if view.route_drag==i else view.model.point_at_distance(view.model.cable_path(i),75),Vector2(34,20))
  var clip_id:="RouteClip%d"%i
  if objects.has(clip_id):
   var committed:PackedVector2Array=view.model.cable_path(i)
   var tangent:Vector2=view.model.point_at_distance(committed,76)-view.model.point_at_distance(committed,74)
   objects[clip_id].rotation=tangent.angle()-PI/2
  for side:int in 2:board_put("Socket%d_%d"%[side,i],"socket_round",Vector2(350 if side==0 else 610,view.PORT_Y[i]),Vector2(28,28))
 for station:int in 2:put("Dock%d"%station,"dock",Vector2(794,139+station*66),Vector2(128,48))
 put("StarterBase","starter_base",Vector2(730,300),Vector2(64,72))
 put("StarterCap","starter_cap",Vector2(730,289),Vector2(29,19))
 put("Notebook","cover",Vector2(113,470),Vector2(130,65))
 put("Reel","reel",Vector2(222,470),Vector2(58,50))
 if objects.has("NotebookPage"):objects.NotebookPage.set_presented(false)
 if view.notebook:put("NotebookPage","fixture",Vector2(480,280),Vector2(640,380))
 for id:String in objects:
  objects[id].z_index=4 if id.begins_with("Plug") or id.begins_with("RouteClip") else 2 if id.begins_with("Socket") else 1
 for line in cables.values():line.z_index=3
 if objects.has("Pillar"):objects.Pillar.z_index=5
 if objects.has("NotebookPage"):objects.NotebookPage.z_index=10
 if objects.has("Fixture"):board.move_child(objects.Fixture,0)
 if objects.has("Tabletop"):objects.Tabletop.z_index=0;move_child(objects.Tabletop,0)
