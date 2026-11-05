extends Node
## Presentation adapter only: does not consume input, replace signals or own game state.
const Typography=preload("res://scripts/ui/native_typography.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const TactileMaterial=preload("res://scripts/ui/tactile_button_material.gd")
const PhoneFlatMaterial=preload("res://scripts/ui/phone_flat_button_material.gd")
const PHONE_STYLE_STATES := ["normal","hover","pressed","hover_pressed","disabled","focus"]
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
var _custom_label := false
var phone_flat := false
var _phone_role := "action"
var _phone_sources: Dictionary={}
var _phone_styles: Dictionary={}
var _phone_config: Array=[]
var _phone_apply_queued := false

func setup(target: Button,kind: String,size_name: String,keep_layout: bool=false) -> void:
 button=target;_custom_label=button.get_node_or_null("NativeSymbolIcon")!=null;variant=kind if kind in TactileMaterial.VARIANTS else "secondary";compact=keep_layout
 var px: int=16 if size_name=="lg" else 14
 unit=float(button.get_theme_font_size("font_size") if button.get_meta("tactile_compensated_type",false) else px)/14.0
 material=Ui.tactile_material(variant,unit)
 material.paper_ink=bool(button.get_meta("tactile_paper_ink",false))
 # Dropdown redesign is explicitly deferred. Exempt physical objects never
 # reach this adapter; only the existing story UI material becomes flat.
 material.paper_flat=material.paper_ink and not button is OptionButton and not button is MenuButton
 var original: StyleBox=button.get_theme_stylebox("normal")
 _padding=Vector4(original.get_margin(SIDE_LEFT),original.get_margin(SIDE_TOP),original.get_margin(SIDE_RIGHT),original.get_margin(SIDE_BOTTOM)) if compact else Vector4(18,1,18,1)*unit
 _padding.y=maxf(_padding.y,0.0 if compact else unit);_padding.w=maxf(_padding.w,0.0 if compact else unit)
 material.content_margin_left=_padding.x;material.content_margin_right=_padding.z+(24*unit if variant=="text" else 0.0)
 material.content_margin_top=_padding.y;material.content_margin_bottom=_padding.w
 button.set_meta("tactile_variant",variant);button.set_meta("tactile_size",size_name)
 button.set_meta("tactile_unit",unit)
 if not compact:
  var inherited_font: Font=button.get_theme_font("font")
  if inherited_font==Typography.body_font() or inherited_font.resource_path.ends_with("MorningNote-Regular.ttf"):
   button.add_theme_font_override("font",Typography.display_font());button.set_meta("typography_role","display")
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
 if phone_flat:
  if not _phone_apply_queued:
   _phone_apply_queued=true
   _apply_phone.call_deferred()
  return
 # Late scene refreshes can update text/disabled; they must not resurrect a
 # different colored face after this presentation adapter is installed.
 _apply.call_deferred()

func _apply() -> void:
 if not is_instance_valid(button) or _updating:return
 _updating=true
 # Switch light/dark disabled polarity with its ink, including first adoption.
 if material.paper_ink:material.disabled_amount=1.0 if button.disabled else 0.0
 if compact and button.get_meta("tactile_compensated_type",false):
  unit=float(button.get_theme_font_size("font_size"))/14.0;material.unit=unit
  button.set_meta("tactile_unit",unit)
  _padding.y=maxf(_padding.y,0.0 if compact else unit);_padding.w=maxf(_padding.w,0.0 if compact else unit)
  material.content_margin_top=_padding.y;material.content_margin_bottom=_padding.w
  _label_line=null
 if not compact:
  var px: int=roundi(14*unit)
  if button.get_theme_font_size("font_size")!=px:
   button.add_theme_font_size_override("font_size",px);_label_line=null
  if button.get_theme_font("font")==Typography.body_font():
   button.add_theme_font_override("font",Typography.display_font());button.set_meta("typography_role","display");_label_line=null
 for key: String in ["normal","hover","pressed","hover_pressed","disabled"]:
  if button.get_theme_stylebox(key)!=material:button.add_theme_stylebox_override(key,material)
 var ink: Color=Color.TRANSPARENT if _custom_label else material.label_color()
 for key: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
  if not button.get_theme_color(key).is_equal_approx(ink):button.add_theme_color_override(key,ink)
 var disabled_ink: Color=Color.TRANSPARENT if _custom_label else material.label_color(true)
 if not button.get_theme_color("font_disabled_color").is_equal_approx(disabled_ink):button.add_theme_color_override("font_disabled_color",disabled_ink)
 for key: String in ["icon_normal_color","icon_hover_color","icon_pressed_color","icon_hover_pressed_color","icon_focus_color"]:
  if not button.get_theme_color(key).is_equal_approx(ink):button.add_theme_color_override(key,ink)
 if material.paper_ink:
  var focus: StyleBox=button.get_theme_stylebox("focus")
  if not focus is StyleBoxFlat or focus.border_color!=TactileMaterial.PaperInk.FOCUS:
   button.add_theme_stylebox_override("focus",TactileMaterial.PaperInk.focus_style())
 # Focus ownership, tab order and focus_mode intentionally remain unchanged.
 _updating=false

func _process(delta: float) -> void:
 if not is_instance_valid(button):return
 if phone_flat:
  if _phone_settings()!=_phone_config:_apply_phone()
  return
 if not button.is_visible_in_tree():return
 if _label_line==null or _last_label!=button.text:
  _last_label=button.text;_label_line=TextLine.new()
  _label_line.add_string(button.text if not _custom_label and not "\n" in button.text else "",button.get_theme_font("font"),button.get_theme_font_size("font_size"))
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
 # A dark primary face cannot fade to light under already-switched dark ink.
 _disabled=disabled_target if material.paper_ink else move_toward(_disabled,disabled_target,delta/.160)
 if old.is_equal_approx(Vector4(_hover,_press,_lift,_disabled)) and is_equal_approx(old_shadow,_shadow_press) and is_equal_approx(old_color,_color_press):return
 material.shadow_press=_shadow_press;material.color_press=_color_press
 material.hover_amount=_hover;material.press_amount=_press;material.lift_amount=_lift;material.disabled_amount=_disabled
 # Offset the drawn face and its content together; keep hit region/layout stable.
 _updating=true
 var content_shift: float=0.0 if material.paper_flat else _press*minf(unit,_padding.w)
 material.content_margin_top=_padding.y+content_shift
 material.content_margin_bottom=_padding.w-content_shift
 _updating=false
 button.queue_redraw()

func setup_phone(target: Button, role: String="action") -> void:
 button=target;phone_flat=true;compact=true;_phone_role=role
 _custom_label=button.get_node_or_null("NativeSymbolIcon")!=null
 process_mode=Node.PROCESS_MODE_ALWAYS
 _apply_phone()
 button.theme_changed.connect(_theme_changed)
 # No font replacement, minimum size, margin inflation, content displacement
 # or custom label drawing. Native Button owns input, toggles and its label.

func _phone_settings() -> Array:
 return [str(button.get_meta("phone_button_role",_phone_role)),
  bool(button.get_meta("phone_button_selected",false)),
  button.get_meta("phone_button_fill") if button.has_meta("phone_button_fill") else null,
  button.get_meta("phone_button_ink") if button.has_meta("phone_button_ink") else null,
  button.get_meta("phone_button_border") if button.has_meta("phone_button_border") else null]

func _apply_phone() -> void:
 _phone_apply_queued=false
 if not is_instance_valid(button) or _updating:return
 _updating=true
 _phone_config=_phone_settings();_phone_role=_phone_config[0]
 _custom_label=button.get_node_or_null("NativeSymbolIcon")!=null
 var selected: bool=_phone_config[1]
 var ink: Color=button.get_theme_color("font_color")
 if _phone_config[3] is Color:ink=_phone_config[3]
 for key: String in PHONE_STYLE_STATES:
  var current: StyleBox=button.get_theme_stylebox(key)
  if not _phone_styles.has(key) or current!=_phone_styles[key]:
   _phone_sources[key]=current
  var source: StyleBox=_phone_sources[key]
  # A texture/custom material or Empty style may represent actual object art
  # or a deliberately transparent native target. Do not invent its geometry.
  if not source is StyleBoxFlat:
   _phone_styles.erase(key)
   continue
  var flat: StyleBox=PhoneFlatMaterial.from_authored(source,_phone_role,selected,ink,key)
  if _phone_config[2] is Color and key!="focus":
   var fill: Color=_phone_config[2]
   flat.bg_color=fill.lerp(ink,.12 if key in ["pressed","hover_pressed"] else .06 if key in ["hover","disabled"] else 0.0)
  if _phone_config[4] is Color and key!="focus":flat.border_color=_phone_config[4]
  _phone_styles[key]=flat
  button.add_theme_stylebox_override(key,flat)
 if _phone_config[3] is Color and not _custom_label:
  for key: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color","font_disabled_color"]:
   button.add_theme_color_override(key,ink)
 _ensure_phone_disabled_contrast()
 material=button.get_theme_stylebox("normal")
 button.set_meta("phone_button_material","flat")
 _updating=false
 button.queue_redraw()

func _ensure_phone_disabled_contrast() -> void:
 # Disabled is still readable. This adjusts only the native disabled caption,
 # never semantic roles, app backgrounds, normal ink or composite children.
 if _custom_label:return
 var disabled_style: StyleBox=button.get_theme_stylebox("disabled")
 if not disabled_style is StyleBoxFlat or disabled_style.bg_color.a<1.0:return
 var background: Color=disabled_style.bg_color
 var authored: Color=button.get_theme_color("font_disabled_color")
 if authored.a<=0.0:return # A custom/accessibility label may be intentionally hidden.
 var visible_ink: Color=background.lerp(Color(authored,1.0),authored.a)
 if Ui._contrast(visible_ink,background)>=4.5:return
 var endpoint: Color=Color.BLACK if Ui._contrast(Color.BLACK,background)>Ui._contrast(Color.WHITE,background) else Color.WHITE
 for step in range(1,21):
  var corrected: Color=visible_ink.lerp(endpoint,float(step)/20.0)
  if Ui._contrast(corrected,background)>=4.5:
   button.add_theme_color_override("font_disabled_color",corrected)
   return
