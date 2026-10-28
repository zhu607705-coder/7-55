extends Node
## Presentation adapter only: does not consume input, replace signals or own game state.
const Typography=preload("res://scripts/ui/native_typography.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const TactileMaterial=preload("res://scripts/ui/tactile_button_material.gd")
var button: Button
var material: StyleBox
var variant := "secondary"
var unit := 1.0
var compact := false
var _updating := false
var _hover := 0.0
var _press := 0.0
var _lift := 0.0
var _disabled := 0.0
var _padding := Vector4.ZERO
var _shadow_press := 0.0
var _color_press := 0.0
var _last_label := ""
var _label_line: TextLine

func setup(target: Button,kind: String,size_name: String,keep_layout: bool=false) -> void:
 button=target;variant=kind if kind in TactileMaterial.VARIANTS else "secondary";compact=keep_layout
 var px: int=16 if size_name=="lg" else 14
 unit=float(button.get_theme_font_size("font_size") if button.get_meta("tactile_compensated_type",false) else px)/14.0
 material=Ui.tactile_material(variant,unit)
 var original: StyleBox=button.get_theme_stylebox("normal")
 _padding=Vector4(original.get_margin(SIDE_LEFT),original.get_margin(SIDE_TOP),original.get_margin(SIDE_RIGHT),original.get_margin(SIDE_BOTTOM)) if compact else Vector4(18,1,18,1)*unit
 _padding.y=maxf(_padding.y,unit);_padding.w=maxf(_padding.w,unit)
 material.content_margin_left=_padding.x;material.content_margin_right=_padding.z+(24*unit if variant=="text" else 0.0)
 material.content_margin_top=_padding.y;material.content_margin_bottom=_padding.w
 button.set_meta("tactile_variant",variant);button.set_meta("tactile_size",size_name)
 button.set_meta("tactile_unit",unit)
 if not compact:
  var inherited_font: Font=button.get_theme_font("font")
  if inherited_font==Typography.body_font() or inherited_font.resource_path.ends_with("MorningNote-Regular.ttf"):
   button.add_theme_font_override("font",Typography.display_font())
  button.custom_minimum_size.y=maxf(button.custom_minimum_size.y,40.0*unit)
  button.add_theme_font_size_override("font_size",px)
 if not compact:
  button.add_theme_constant_override("icon_max_width",roundi(16*unit))
  button.add_theme_constant_override("h_separation",roundi(8*unit))
 if variant in ["primary","secondary","tertiary"]:button.flat=false
 var legacy_shadow:=button.get_node_or_null("SelectedTextShadow")
 if legacy_shadow is CanvasItem:legacy_shadow.hide()
 _apply()
 button.theme_changed.connect(_theme_changed)
 process_mode=Node.PROCESS_MODE_ALWAYS

func _theme_changed() -> void:
 if _updating:return
 # Late scene refreshes can update text/disabled; they must not resurrect a
 # different colored face after this presentation adapter is installed.
 _apply.call_deferred()

func _apply() -> void:
 if not is_instance_valid(button) or _updating:return
 _updating=true
 if compact and button.get_meta("tactile_compensated_type",false):
  unit=float(button.get_theme_font_size("font_size"))/14.0;material.unit=unit
  button.set_meta("tactile_unit",unit)
  _padding.y=maxf(_padding.y,unit);_padding.w=maxf(_padding.w,unit)
  material.content_margin_top=_padding.y;material.content_margin_bottom=_padding.w
  _label_line=null
 if not compact:
  var px: int=roundi(14*unit)
  if button.get_theme_font_size("font_size")!=px:
   button.add_theme_font_size_override("font_size",px);_label_line=null
  if button.get_theme_font("font")==Typography.body_font():
   button.add_theme_font_override("font",Typography.display_font());_label_line=null
 for key: String in ["normal","hover","pressed","hover_pressed","disabled"]:
  if button.get_theme_stylebox(key)!=material:button.add_theme_stylebox_override(key,material)
 var ink: Color=TactileMaterial.PALETTES[variant][3]
 for key: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
  if not button.get_theme_color(key).is_equal_approx(ink):button.add_theme_color_override(key,ink)
 var disabled_ink:=Color("bcc2ca") if variant=="primary" else Color("626a75")
 if not button.get_theme_color("font_disabled_color").is_equal_approx(disabled_ink):button.add_theme_color_override("font_disabled_color",disabled_ink)
 for key: String in ["icon_normal_color","icon_hover_color","icon_pressed_color","icon_hover_pressed_color","icon_focus_color"]:
  if not button.get_theme_color(key).is_equal_approx(ink):button.add_theme_color_override(key,ink)
 # Existing keyboard focus style and focus_mode intentionally remain unchanged.
 _updating=false

func _process(delta: float) -> void:
 if not is_instance_valid(button):return
 if not button.is_visible_in_tree():return
 if _label_line==null or _last_label!=button.text:
  _last_label=button.text;_label_line=TextLine.new()
  _label_line.add_string(button.text if not "\n" in button.text else "",button.get_theme_font("font"),button.get_theme_font_size("font_size"))
  material.label_line=_label_line;material.label_alignment=button.alignment
  material.label_inset=24*unit if button.icon!=null else 0.0
  button.queue_redraw()
 var hover_target: float=1.0 if button.is_hovered() and not button.disabled else 0.0
 var press_target: float=1.0 if button.is_pressed() and not button.disabled else 0.0
 var disabled_target: float=1.0 if button.disabled else 0.0
 var old:=Vector4(_hover,_press,_lift,_disabled)
 var old_shadow: float=_shadow_press
 var old_color: float=_color_press
 _shadow_press=move_toward(_shadow_press,press_target,delta/.140)
 _color_press=move_toward(_color_press,press_target,delta/.160)
 _hover=move_toward(_hover,hover_target,delta/.160)
 _press=move_toward(_press,press_target,delta/.120)
 _lift=move_toward(_lift,hover_target,delta/.140)
 _disabled=move_toward(_disabled,disabled_target,delta/.160)
 if old.is_equal_approx(Vector4(_hover,_press,_lift,_disabled)) and is_equal_approx(old_shadow,_shadow_press) and is_equal_approx(old_color,_color_press):return
 material.shadow_press=_shadow_press;material.color_press=_color_press
 material.hover_amount=_hover;material.press_amount=_press;material.lift_amount=_lift;material.disabled_amount=_disabled
 # Offset the drawn face and its content together; keep hit region/layout stable.
 _updating=true
 material.content_margin_top=_padding.y+_press*unit
 material.content_margin_bottom=_padding.w-_press*unit
 _updating=false
 button.queue_redraw()
