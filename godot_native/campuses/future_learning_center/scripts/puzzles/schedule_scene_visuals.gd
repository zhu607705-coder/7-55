extends Node2D
## All object pixels are original web-generated textures. This layer reads state;
## it never starts a trial, produces an artifact, updates a save, or owns input.
const ObjectSprite=preload("res://campuses/future_learning_center/scripts/puzzles/schedule_object_sprite.gd")
var art:Dictionary={}
var objects:Dictionary={}
var page_amount:=0.0
var reduced_motion:=false
var _first:=true
var _settle_tool:=-2
var _settle_input_tool:=-2
var _settle_target:=Vector2.ZERO
var _settle_task:=-1
var _settle_age:=1.0
func _ready()->void:
 z_index=-1
 var background:=ColorRect.new();background.color=Color("253236");background.size=Vector2(960,540);background.mouse_filter=Control.MOUSE_FILTER_IGNORE;background.z_index=-100;add_child(background)
func reset_motion()->void:_first=true;_settle_age=1.0
func settle_tool(view,tool:int,from:Vector2,to:Vector2,task:=-1)->void:
 _settle_input_tool=tool;_settle_tool=1 if tool==3 else tool;_settle_target=to;_settle_task=task;_settle_age=0.0
 _tool(view,"SettlingTool",_settle_tool,from,-2,0,true,true)
func settling_pickup(at:Vector2)->int:
 if _settle_age<.12 and objects.has("SettlingTool") and objects.SettlingTool.visible and at.distance_to(objects.SettlingTool.position)<28:return _settle_input_tool
 return -2
func object_at(id:String,fallback:Vector2)->Vector2:
 return objects[id].position if objects.has(id) else fallback
func _place(id:String,texture:Texture2D,region:Rect2,box:Vector2,at:Vector2,depth:int,dt:float,direct:=false,lift:=0.0,shown:=true):
 if not objects.has(id):
  var object=ObjectSprite.new();object.name=id;object.manual_advance=true;add_child(object)
  var configured:bool=object.configure(texture,region,box);assert(configured);objects[id]=object
 var object=objects[id]
 if object.texture!=texture or object.region_rect!=region or object.logical_box_size!=box:
  var reconfigured:bool=object.configure(texture,region,box);assert(reconfigured)
 object.z_index=depth;object.set_reduced_motion(reduced_motion);object.set_presented(shown)
 if shown:object.present(at,direct or _first,lift);object.advance_visual(dt)
 return object
func _part(id:String,key:String,at:Vector2,depth:int,dt:float,direct:=false,shown:=true):
 var spec:Dictionary=art[key]
 return _place(id,spec.texture,spec.region,spec.box,at,depth,dt,direct,0.0,shown)
func _tool(view,id:String,tool:int,at:Vector2,depth:int,dt:float,shown:=true,direct:=true):
 if tool in [0,1]:return _place(id,view.CAMERA_TEXTURE,view.CAMERA_REGION,Vector2(48,40),at,depth,dt,direct,0,shown)
 if tool==2:return _place(id,view.WORKTABLE_TEXTURE,view.WORKTABLE_REGION,Vector2(46,32),at,depth,dt,direct,0,shown)
 return _place(id,view.GLOVES_TEXTURE,view.GLOVES_REGION,Vector2(44,36),at,depth,dt,direct,0,shown)
func sync(view,dt:float,snap:=false)->void:
 if art.is_empty():return
 _first=_first or snap
 if _first or view.held_tool>=-1 or view.held_task>=0:_settle_age=1.0
 _settle_age+=dt
 var settling:bool=_settle_age<.12 and not reduced_motion
 _part("Tabletop","tabletop",Vector2(480,287),-90,dt)
 _part("ScheduleBoard","board",Vector2(545.5,246.5),-80,dt)
 _part("ToolTray","tray",Vector2(145,249),-75,dt)
 for i:int in 3:_tool(view,"TrayTool%d"%i,i,Vector2(70+i*75,220),-30,dt,i!=1 or view.model.cameras==2)
 _tool(view,"Gloves",-1,Vector2(145,300),-30,dt)
 _part("ReserveDock","cradle",Vector2(870,470),-50,dt)
 _tool(view,"ReserveCamera",0,Vector2(870,470),-30,dt,view.model.cameras<2 and view.held_tool!=3)
 for task:int in 4:
  var held:bool=view.held_task==task
  var target:Vector2=view.pointer+view.task_grab_offset if held else view.card_point(task)
  var card=_part("TaskCard%d"%task,"card",target,-8 if held else -40,dt,held)
  card.present(target,held or _first,1.0 if held else 0.0);card.advance_visual(0)
  var center:Vector2=card.position
  _place("TaskArtifact%d"%task,view.ARTIFACT_TEXTURES[task],view.ARTIFACT_REGIONS[task],view.ARTIFACT_BOXES[task],center+Vector2(-35,10),-6 if held else -20,dt,true)
  _tool(view,"AssignedTool%d"%task,view.model.tools[task],center+Vector2(33,10),-6 if held else -20,dt,not(settling and _settle_task==task))
  var output_at:=Vector2(350+task*105,451)
  _part("OutputDock%d"%task,"cradle",output_at,-50,dt)
  var output_id:="Output%d"%task
  var shown:bool=view.model.artifacts[task]
  if shown and not _first and (not objects.has(output_id) or not objects[output_id].visible):
   _place(output_id,view.ARTIFACT_TEXTURES[task],view.ARTIFACT_REGIONS[task],view.ARTIFACT_BOXES[task],center,-20,0,true)
  _place(output_id,view.ARTIFACT_TEXTURES[task],view.ARTIFACT_REGIONS[task],view.ARTIFACT_BOXES[task],output_at,-20,dt,false,0,shown)
 _part("StarterBase","starter_base",Vector2(870,340),-30,dt)
 var pressing:bool=view.pending_tap=="crank"
 var down:bool=pressing or (view.model.running and not view.model.paused)
 _part("StarterCap","starter_cap",Vector2(870,328+4*int(down)),-10,dt)
 _part("UndoWrench","wrench",Vector2(238,471+2*int(view.pending_tap=="undo")),-10,dt,true)
 _part("NotebookCover","cover",Vector2(117,464),-10,dt)
 var destination:=1.0 if view.paper_open else 0.0
 page_amount=destination if reduced_motion or _first else move_toward(page_amount,destination,dt/.16)
 var page=_part("NotebookPage","page",Vector2(117,464).lerp(Vector2(159.5,249.5),page_amount),0,dt,true,page_amount>0)
 if page_amount>0:
  page.scale*=lerpf(.12,1.0,page_amount);page.modulate.a=page_amount
 _tool(view,"HeldTool",view.held_tool,view.pointer+view.tool_grab_offset,-2,dt,view.held_tool>=-1 and view.held_tool<3)
 _tool(view,"HeldSpare",0,view.pointer+view.tool_grab_offset,-2,dt,view.held_tool==3)
 _tool(view,"SettlingTool",_settle_tool,_settle_target,-2,dt,settling,false)
 _first=false
