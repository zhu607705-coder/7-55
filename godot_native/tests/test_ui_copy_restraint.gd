extends SceneTree
## Presentation-only checks: preserve concrete tasks, controls and original story.
const Pages=preload("res://scripts/ui/phone_pages.gd")
const Chapter=preload("res://scripts/chapters/chapter1_2.gd")
const Pause=preload("res://scripts/ui/native_pause_overlay.gd")
const MiniGame=preload("res://scripts/ui/minigame_host.gd")
var checks:=0
var failures:=0
var pages=Pages.new()
var chapter=Chapter.new()
var state:Node
var s:Dictionary
var page:Control
func _initialize():run.call_deferred()
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;push_error("UI COPY: "+label)
func frames(n:int=3):
 for i in n:await process_frame
func texts(node:Node)->String:
 var result:=""
 if node is Label or node is Button:result+=node.text+"\n"
 for child:Node in node.get_children():result+=texts(child)
 return result
func show(route:String):
 if is_instance_valid(page):page.free()
 s.native.page=route
 pages.entry_session=chapter.phone_entry_session(s)
 pages.entry_session.advance(2000)
 page=pages.build(route,chapter.view(route,s),s)
 root.add_child(page)
 page.scale=Vector2.ONE*minf(root.size.x/424.0,root.size.y/820.0)
 await frames()
func capture(name:String):
 var output:=OS.get_environment("COPY_CAPTURE_DIR")
 if output.is_empty() or DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"capture "+name)
func run():
 if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
 state=root.get_node("State");s=state.initial();s.networkMode="campus_wifi"
 s.native.settings.reduced_motion=true
 for extent:Vector2i in [Vector2i(430,860),Vector2i(390,844)]:
  root.size=extent
  for utility:String in ["logistics","messages","all_apps","lost_found"]:
   pages.zjuding_panel=utility
   await show("zjuding")
   var copy:=texts(page)
   check(not copy.contains("只读取") and not copy.contains("只聚合") and not copy.contains("当前已公开状态") and not copy.contains("仅显示"),"utility removes implementation reports: "+utility)
   check(page.find_child("ZjudingTab_home",true,false)!=null,"utility keeps its ordinary home path: "+utility)
   if utility=="logistics":check(copy.contains("后勤状态台") and copy.contains("网络、预约与校园导航"),"logistics retains its purpose and current service rows")
   if utility=="messages":check(copy.contains("校园通知") and copy.contains("条消息") and copy.contains("校园网"),"messages retains count and real network state")
   if utility=="lost_found":check(copy.contains("物品档案") and copy.contains("暂无档案"),"empty archive remains explicit")
   await capture("%dx%d-%s"%[extent.x,extent.y,utility])
  await show("settings")
  for section:String in ["activity","about"]:
   pages.settings_page=section;await show("settings")
   var copy:=texts(page)
   check(not copy.contains("剧情记录") and not copy.contains("开发调试"),"settings omits internal commentary: "+section)
   if section=="activity":check(copy.contains("重新建立 IMG_0755 索引") and copy.contains("07:55"),"activity records and evidence remain unchanged")
   if section=="about":check(page.find_child("NativeSaveTools",true,false)!=null and copy.contains("自动保存与上一版本恢复"),"save access and real status remain")
   await capture("%dx%d-%s"%[extent.x,extent.y,section])
  s.flags.codeScattered=true
  await show("wechat");pages.friend_open=true;await show("wechat")
  var copy:=texts(page)
  check(copy.contains("速来！老头突然开始点名了，学在浙大雷达签到！") and copy.contains("这是签到码"),"original first-chapter messages preserved")
  check(not copy.contains("任务：找回四位签到码"),"chat no longer duplicates shared task")
  await capture("%dx%d-friend"%[extent.x,extent.y])
  await show("control_center")
  check(texts(page).contains("自动保存已开启") and page.find_child("ControlResetOpen",true,false)!=null,"controls preserve saving and reset entry")
  var owner:=Control.new();root.add_child(owner)
  var resumed:=[0]
  var overlay=Pause.mount(owner,func():resumed[0]+=1)
  overlay.present(true,"manual");await frames()
  check(overlay.is_open() and not overlay.body.visible and overlay.body.text.is_empty(),"manual pause has no repeated recovery sentence")
  check(overlay.resume_button.text=="继续" and overlay.resume_button.is_visible_in_tree(),"pause still has explicit Continue")
  await capture("%dx%d-manual-pause"%[extent.x,extent.y])
  overlay.present(true,"focus");await frames()
  check(overlay.body.visible and overlay.body.text=="离开画面时已自动暂停。","automatic pause keeps useful cause")
  await capture("%dx%d-focus-pause"%[extent.x,extent.y])
  owner.free();await frames()
 if is_instance_valid(page):page.free()
 var game:=MiniGame.new();game.size=Vector2(960,540);root.size=Vector2i(960,540)
 game.setup({"type":"kayak","phase":"boarding"});root.add_child(game);game.set_process(false)
 await frames()
 check(game._modal_title()=="准备好了吗？" and game.start_button.visible,"minigame keeps ready state and Start")
 check(game.hint.text.contains("交替划动左右桨") and game.hint.text.contains("后退"),"minigame keeps actual paddle instructions")
 check(not game._show_kayak_reverse_hint(),"ready screen does not repeat its reverse instruction")
 await capture("960x540-kayak-intro")
 game.start_button.pressed.emit()
 check(game.running and game.control_buttons.left.visible and game.control_buttons.right.visible,"Start still exposes both paddle controls")
 check(not game._show_kayak_reverse_hint(),"initial live instruction is not duplicated")
 game.model.stroke("left");game._refresh()
 check(game._show_kayak_reverse_hint(),"live steering feedback retains a reverse reminder")
 game.toggle_pause();check(not game._show_kayak_reverse_hint(),"pause suppresses inactive paddle instructions")
 game.toggle_pause();check(game._show_kayak_reverse_hint(),"resume restores live reverse help")
 for side:String in ["right","left","right"]:game.model.stroke(side)
 game._check_terminal();game._refresh()
 check(game.sent and game._modal_title()=="安全抵达" and not game.pending_result.is_empty(),"earned result retains success and original proof")
 check(game.hint.text.is_empty() and not game.hint.visible and not game._show_kayak_reverse_hint(),"success has one outcome and no inactive control footer")
 await capture("960x540-kayak-success")
 game.restart()
 check(game.hint.visible and game.hint.text.contains("后退") and not game._show_kayak_reverse_hint(),"retry restores one complete instruction")
 game.free();await frames()
 print("UI_COPY_RESTRAINT: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
