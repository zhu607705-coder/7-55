extends SceneTree
## Real renderer snapshots. Forced material states are labeled, not input proof.
const MaterialStyle=preload("res://scripts/ui/tactile_button_material.gd")
var output: String
func _initialize() -> void:run.call_deferred()
func frames() -> void:
 for unused in 5:await process_frame
func label(host: Control,text: String,pos: Vector2,px: int=16) -> void:
 var item:=Label.new();item.text=text;item.position=pos
 item.add_theme_font_size_override("font_size",px);item.add_theme_color_override("font_color",Color("343a43"));host.add_child(item)
func run() -> void:
 if DisplayServer.get_name()=="headless":push_error("Actual GL renderer required");quit(2);return
 output=OS.get_environment("UI_CAPTURE_DIR")
 if output.is_empty():quit(2);return
 DirAccess.make_dir_recursive_absolute(output)
 create_timer(60).timeout.connect(func():quit(2))
 root.size=Vector2i(1200,650);DisplayServer.window_set_size(root.size)
 for size_name: String in ["md","lg"]:
  var host:=Control.new();host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(host)
  var background:=ColorRect.new();background.color=Color("e5e7eb");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.mouse_filter=Control.MOUSE_FILTER_IGNORE;host.add_child(background)
  label(host,"Native Godot material / "+size_name+" / forced state close-ups",Vector2(24,20),22)
  label(host,"Geometry shadow approximation; existing Medium 500, not claimed as CSS 600",Vector2(24,55),14)
  var modes: Array[String]=["rest","hover","pressed","focus","disabled"]
  for i in modes.size():label(host,modes[i],Vector2(185+i*195,100))
  for row in MaterialStyle.VARIANTS.size():
   var variant: String=MaterialStyle.VARIANTS[row]
   label(host,variant,Vector2(24,162+row*90))
   for col in modes.size():
    var button:=Button.new();button.text="确认 Continue";button.position=Vector2(160+col*195,150+row*90)
    button.custom_minimum_size.x=170;button.set_meta("tactile_variant",variant);button.set_meta("tactile_size",size_name)
    button.add_theme_font_override("font",load("res://ui_assets/fonts/MorningNote-Medium.ttf"))
    host.add_child(button);await frames()
    var state: Node=button.get_node("TactileMaterialState");state.set_process(false)
    var material: StyleBox=button.get_theme_stylebox("normal")
    if modes[col]=="hover":material.hover_amount=1;material.lift_amount=1
    if modes[col]=="pressed":
     material.press_amount=1;material.shadow_press=1;material.color_press=1
     material.content_margin_top+=material.unit;material.content_margin_bottom-=material.unit
    if modes[col]=="focus":button.draw.connect(draw_focus.bind(button))
    if modes[col]=="disabled":button.disabled=true;material.disabled_amount=1
    button.queue_redraw()
  await frames();await RenderingServer.frame_post_draw
  var error:=root.get_texture().get_image().save_png(output.path_join("native-tactile-"+size_name+".png"))
  if error!=OK:push_error("Screenshot failed");quit(2);return
  host.queue_free();await frames()
 print("NATIVE_TACTILE_CAPTURE_OK");quit()

func draw_focus(button: Button) -> void:
 button.get_theme_stylebox("focus").draw(button.get_canvas_item(),Rect2(Vector2.ZERO,button.size))
