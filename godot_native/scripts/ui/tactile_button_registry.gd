extends Node
## Applies the existing shared NativeUi material to late-created UI controls.
## Physical paper/item/artwork hit regions are expressly excluded below.
const ButtonState=preload("res://scripts/ui/tactile_button_state.gd")
const EXEMPT_SCRIPTS := ["phone_drop_button.gd","inventory_item.gd","clock_visual_card.gd"]
const GHOST_SCRIPTS := ["home_app_button.gd","world_phone_launcher.gd"]

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
 if node is CheckBox or node is CheckButton or node.text.is_empty() or (node.name.begins_with("PhoneNav_") or node.name.begins_with("Cc98Tab_") or node.name.begins_with("WechatTab_") or node.name.begins_with("ZjudingTab_")) or node.name in ["PhoneAppBack","C35IntroBack","InventoryHandle","TaskTrigger","ControlCenterTrigger"]:
  compact=true
  if not explicit:kind="ghost"
 if node.get_window() is FileDialog:
  # Native dialogs retain a dark panel. Gray ghost ink on that panel fails
  # contrast; use the light key while retaining internal engine geometry.
  kind="secondary";compact=true
 var size_name: String=str(node.get_meta("tactile_size","lg" if node.get_theme_font_size("font_size")>=16 else "md"))
 var controller:=ButtonState.new();controller.name="TactileMaterialState"
 node.add_child(controller);controller.setup(node,kind,size_name,compact)
