extends Node
## Routes phone controls to their flat authored surfaces; other UI keeps its
## existing tactile material. The phone scope is ownership, never a name guess.
const ButtonState=preload("res://scripts/ui/tactile_button_state.gd")
const EXEMPT_SCRIPTS := ["phone_drop_button.gd","inventory_item.gd","clock_visual_card.gd"]
const GHOST_SCRIPTS := ["home_app_button.gd","world_phone_launcher.gd"]
const PHONE_ROOT_SCRIPTS := ["res://scripts/ui/phone_chrome.gd","res://scripts/ui/phone_app_frame.gd"]
const PHONE_EXEMPT_ROLES := ["object","hit_region","mask"]

func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 get_tree().node_added.connect(_added)
 _walk(get_tree().root)

func _walk(node: Node) -> void:
 _added(node)
 for child: Node in node.get_children():_walk(child)

func _added(node: Node) -> void:
 if node is Button:_adopt.call_deferred(node.get_instance_id())

func _adopt(instance_id: int) -> void:
 var node: Node=instance_from_id(instance_id)
 if not is_instance_valid(node) or not node is Button or bool(node.get_meta("tactile_exempt",false)):return
 if node.get_node_or_null("TactileMaterialState")!=null:return
 var script: Script=node.get_script()
 var path: String=script.resource_path if script!=null else ""
 for suffix: String in EXEMPT_SCRIPTS:
  if path.ends_with(suffix):return
 if _is_phone_control(node):
  _adopt_phone(node)
  return
 # Custom puzzle hotspots deliberately have no standard button caption; their
 # own draw() is the object, not a UI key. Explicit marking wins over heuristics.
 var compact: bool=bool(node.get_meta("tactile_keep_layout",false))
 var explicit: bool=node.has_meta("tactile_variant")
 var kind: String=str(node.get_meta("tactile_variant",node.get_meta("tactile_intent","")))
 for suffix: String in GHOST_SCRIPTS:
  if path.ends_with(suffix):kind="ghost";compact=true;explicit=true
 if kind.is_empty():
  var style: StyleBox=node.get_theme_stylebox("normal")
  if style is StyleBoxEmpty or node.flat:
   kind="secondary" if node.get_theme_color("font_color").get_luminance()>.6 else "ghost"
  elif style is StyleBoxFlat:
   if style.bg_color.a<.1:kind="ghost"
   elif style.bg_color.get_luminance()<.3:kind="primary"
   elif style.bg_color.get_luminance()<.8:kind="tertiary"
   else:kind="secondary"
  else:kind="secondary"
 if not explicit and kind=="ghost" and node.get_theme_color("font_color").get_luminance()>.6:
  # Light labels formerly floated over dark world art. A neutral white key
  # retains contrast; dark gray ghost labels would disappear on that art.
  kind="secondary"
 # Dedicated chrome/list rows keep original geometry and embedded content.
 if node is CheckBox or node is CheckButton or node.text.is_empty() or (node.name.begins_with("TiyiMinus_") or node.name.begins_with("TiyiPlus_") or node.name.begins_with("PhoneNav_") or node.name.begins_with("Cc98Tab_") or node.name.begins_with("WechatTab_") or node.name.begins_with("ZjudingTab_")) or node.name in ["PhoneAppBack","C35IntroBack","InventoryHandle","TaskTrigger","ControlCenterTrigger"]:
  compact=true
  if not explicit:kind="ghost"
 if node.get_window() is FileDialog:
  # Native dialogs retain a dark panel. Gray ghost ink on that panel fails
  # contrast; use the light key while retaining internal engine geometry.
  kind="secondary";compact=true
 # Only production story/entry roots opt in. Isolated research apparatus and
 # unrelated standalone scenes keep their incumbent skin; explicit exemptions
 # have already returned above and always win.
 if not node.has_meta("tactile_paper_ink"):
  var ancestor: Node=node.get_parent()
  while ancestor!=null:
   if ancestor.get_meta("paper_ink_scope",false):
    node.set_meta("tactile_paper_ink",true);break
   ancestor=ancestor.get_parent()
 var size_name: String=str(node.get_meta("tactile_size","lg" if node.get_theme_font_size("font_size")>=16 else "md"))
 var controller:=ButtonState.new();controller.name="TactileMaterialState"
 node.add_child(controller);controller.setup(node,kind,size_name,compact)

func _is_phone_control(node: Node) -> bool:
 # Pages built outside the main shell (including tests) declare their owner.
 # In the actual game the shell is an unnamed PanelContainer, not PhoneView.
 var ancestor: Node=node
 while ancestor!=null:
  if ancestor.has_meta("phone_ui_scope"):
   return bool(ancestor.get_meta("phone_ui_scope"))
  var script: Script=ancestor.get_script()
  var path: String=script.resource_path if script!=null else ""
  if path in PHONE_ROOT_SCRIPTS:return true
  if path=="res://scripts/main.gd":
   var phone: Node=ancestor.get("phone")
   return is_instance_valid(phone) and (phone==node or phone.is_ancestor_of(node))
  ancestor=ancestor.get_parent()
 return false

func _adopt_phone(button: Button) -> void:
 var role: String=str(button.get_meta("phone_button_role","action"))
 if role in PHONE_EXEMPT_ROLES:return
 # Custom Button scripts may draw puzzle objects, irregular masks or artwork.
 # They retain that ownership unless the author explicitly declares a UI role.
 # Empty captions are deliberately NOT used to distinguish rows from hotspots.
 var script: Script=button.get_script()
 if script!=null and not button.has_meta("phone_button_role"):
  if script.resource_path!="res://scripts/ui/home_app_button.gd":return
 var controller:=ButtonState.new();controller.name="TactileMaterialState"
 button.add_child(controller);controller.setup_phone(button,role)
