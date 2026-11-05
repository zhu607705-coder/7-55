extends StyleBoxFlat
## Flat phone control surface. Copy the authored palette and geometry, remove
## elevation, and add only the explicitly selected segment's static ink rule.
## There is no custom draw stack, gradient, bevel, emboss or animated offset.
const INK := Color("222322")

static func from_authored(source: StyleBoxFlat, role: String, selected: bool, ink: Color, state: String) -> StyleBoxFlat:
 var flat:=load("res://scripts/ui/phone_flat_button_material.gd").new() as StyleBoxFlat
 # Resource properties cover the exact asymmetric border/radius details too.
 # Never copy the script: this instance must remain the flat material type.
 for property: Dictionary in flat.get_property_list():
  var key: String=property.name
  if property.usage & PROPERTY_USAGE_STORAGE and key!="script" and not key.begins_with("resource_"):
   flat.set(key,source.get(key))
 # Preserve computed margins before changing any drawn border. Godot otherwise
 # derives -1 margins from border widths and silently enlarges tiny controls.
 flat.content_margin_left=source.get_margin(SIDE_LEFT)
 flat.content_margin_top=source.get_margin(SIDE_TOP)
 flat.content_margin_right=source.get_margin(SIDE_RIGHT)
 flat.content_margin_bottom=source.get_margin(SIDE_BOTTOM)
 flat.shadow_size=0;flat.shadow_offset=Vector2.ZERO;flat.shadow_color=Color.TRANSPARENT
 flat.expand_margin_left=0;flat.expand_margin_top=0;flat.expand_margin_right=0;flat.expand_margin_bottom=0
 flat.corner_radius_top_left=mini(flat.corner_radius_top_left,4)
 flat.corner_radius_top_right=mini(flat.corner_radius_top_right,4)
 flat.corner_radius_bottom_left=mini(flat.corner_radius_bottom_left,4)
 flat.corner_radius_bottom_right=mini(flat.corner_radius_bottom_right,4)
 flat.corner_detail=2;flat.anti_aliasing=false
 if role=="segment" and selected and state!="focus":
  # A selected tab remains identifiable without relying on two similar hues.
  # This stays inside the original rect; content and hit geometry do not move.
  flat.border_width_bottom=maxi(3,flat.border_width_bottom)
  flat.border_color=ink if ink.a>0.0 else INK
 return flat
