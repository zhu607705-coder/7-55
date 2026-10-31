extends "res://campuses/future_learning_center/scripts/puzzles/optical_scene_visuals.gd"
## Presentation only. Independent source sprites follow authoritative apparatus state.
var paper_windows:Array[Control]=[]
var print_marks:Array[Node2D]=[]
const PAPER_APERTURE_SIZE:=Vector2(750.864,59.885)
const PAPER_APERTURE_X:=104.568
func paper_period()->float:
 var region:Rect2=art.paper_strip.region
 return region.size.x*minf(786/region.size.x,PAPER_APERTURE_SIZE.y/region.size.y)
var alignment_feedback:Node2D
const AlignmentFeedback=preload("res://campuses/future_learning_center/scripts/puzzles/recording_alignment_feedback.gd")
const PrintFeedback=preload("res://campuses/future_learning_center/scripts/puzzles/recording_print_feedback.gd")
func sync(view,dt:float,snap:=false)->void:
 for object in objects.values():object.advance_visual(dt)
 put("Tabletop","tabletop",Vector2(480,315),Vector2(960,440))
 put("NotebookCover","cover",Vector2(110,469),Vector2(150,70))
 if view.has_method("baffle_position"):_recording(view,snap)
 else:_sync_records(view,snap)
func _recording(view,snap:bool)->void:
 for i:int in 2:put("Rail%d"%i,"rail_horizontal",Vector2(445,278+i*44),Vector2(500,15))
 put("BaffleRail","rail_vertical",Vector2(441,242.5),Vector2(14,235))
 put("Endstop","endstop",Vector2(688,300),Vector2(12,65))
 put("Lamp","lamp",Vector2(320,260),Vector2(38,40))
 put("Carriage","carriage",Vector2(view.model.x,300),Vector2(36,32))
 put("Baffle","sliding_baffle",view.baffle_position(),Vector2(22,120))
 put("Camera","camera",Vector2(670,185),Vector2(57,43))
 put("DriveBase","drive_base",Vector2(733,210))
 put("DriveHandle","drive_handle",Vector2(733,view.drive_handle_y()),Vector2(24,24),view.action=="drive" or snap)
 put("Handwheel","handwheel",Vector2(665,445),Vector2(66,66))
 if objects.has("Handwheel"):objects.Handwheel.rotation=view.wheel_angle
 put("RecordsPage","page",Vector2(850,400),Vector2(155,207))
 put("PhotoPaper","page",Vector2(850,390),Vector2(125,110))
func _sync_records(view,snap:bool)->void:
 if alignment_feedback==null:
  alignment_feedback=AlignmentFeedback.new();alignment_feedback.model=view.model;add_child(alignment_feedback)
 alignment_feedback.queue_redraw()
 for i:int in 2:
  var y:=118+i*108
  put("PaperGuide%d"%i,"paper_guide",Vector2(480,y+41.5),Vector2(800,104))
  if paper_windows.size()<=i:
   var window:=Control.new();window.name="PaperWindow%d"%i;window.position=Vector2(PAPER_APERTURE_X,y+11.557);window.size=PAPER_APERTURE_SIZE;window.clip_contents=true;window.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(window);paper_windows.append(window)
  for tile:int in 3:
   var id:="Paper%dTile%d"%[i,tile]
   put(id,"paper_strip",Vector2(PAPER_APERTURE_SIZE.x*.5+(tile-1)*paper_period()+view.model.offsets[i],PAPER_APERTURE_SIZE.y*.5),Vector2(786,PAPER_APERTURE_SIZE.y))
   if objects.has(id) and objects[id].get_parent()!=paper_windows[i]:objects[id].reparent(paper_windows[i],false)
  if print_marks.size()<=i:
   var marks:=PrintFeedback.new();marks.model=view.model;marks.font=view.font;marks.row=i;marks.aperture_origin=paper_windows[i].position;paper_windows[i].add_child(marks);print_marks.append(marks)
  print_marks[i].queue_redraw()
  # Paper and its event ink share one exact aperture clip. Metal lies above both.
  if objects.has("PaperGuide%d"%i):move_child(objects["PaperGuide%d"%i],get_child_count()-1)
 put("FeedRail","rail_horizontal",Vector2(420,405),Vector2(440,13))
 put("Carriage","carriage",Vector2(210+view.model.travel*405,388.5),Vector2(34,29))
 put("Dropgate","dropgate",Vector2(527,350+view.model.gate*36),Vector2(14,50))
 put("Endstop","endstop",Vector2(632,392.5),Vector2(12,49))
 put("Lamp","lamp",Vector2(160,381),Vector2(34,36))
 if objects.has("Lamp"):objects.Lamp.modulate=Color.WHITE if view.model.running and (view.model.elapsed<.18 or (view.model.elapsed>.7 and view.model.elapsed<.9)) else Color(.65,.7,.7)
 put("StarterBase","starter_base",Vector2(740,383),Vector2(54,62))
 put("StarterCap","starter_cap",Vector2(740,377 if view.action=="run" else 372),Vector2(29,19),snap)
 put("PaperRoll","paper_roll",Vector2(850,464),Vector2(70,70))
 if objects.has("PaperRoll"):objects.PaperRoll.rotation=view.roll_angle
