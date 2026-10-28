extends Control
## Developer-only overview; every shape comes from the actual world authorities.
const Space=preload("res://scripts/space/north_floor_space.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
var world:Control
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;z_index=4000
func _process(_delta:float)->void:queue_redraw()
func _draw()->void:
	if not is_instance_valid(world) or not world.north_space.active:return
	var origin:Vector2=world.size/2-world.camera*world.zoom
	var zoom:float=world.zoom
	for gap:Rect2 in world.north_space.voids:
		draw_rect(Rect2(origin+gap.position*zoom,gap.size*zoom),Color(.9,.13,.15,.28))
	for ground:Rect2 in world.north_space.regions:
		draw_rect(Rect2(origin+ground.position*zoom,ground.size*zoom),Color(.17,.88,.61,.72),false,1)
	var solids:Array=[]
	for row:Dictionary in world.collisions:solids.append(world._rect(row))
	if world.chapter4_layers!=null:solids.append_array(world.chapter4_layers.collisions(world.get_node("/root/State").d))
	for solid:Rect2 in solids:
		draw_rect(Rect2(origin+solid.position*zoom,solid.size*zoom),Color(.08,.8,.94,.14))
		draw_rect(Rect2(origin+solid.position*zoom,solid.size*zoom),Color(.08,.8,.94,.75),false,1)
	for cover:Dictionary in world.foreground:
		var bounds:Rect2=world._rect(cover.get("maskBounds",cover))
		var baseline:float=float(cover.get("baselineY",cover.get("sortY",0)))
		draw_line(origin+Vector2(bounds.position.x,baseline)*zoom,origin+Vector2(bounds.end.x,baseline)*zoom,Color(1,.77,.16),2)
	var feet:Rect2=Metrics.foot_rect(world.player)
	var valid:bool=world.can_stand(world.player)
	var color:=Color(.25,1,.38) if valid else Color(1,.15,.7)
	draw_rect(Rect2(origin+feet.position*zoom,feet.size*zoom),color,false,2)
	draw_circle(origin+Vector2(world.player.x,Space.foot_y(world.player))*zoom,3,color)
	if world.font!=null:
		var text:="空间审阅 %s  红：非地面  青：实体边界  黄：遮挡基线  绿：完整脚部"%world._last_floor
		draw_style_box(_label_style(),Rect2(12,8,920,34))
		draw_string(world.font,Vector2(22,32),text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)

func _label_style()->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color(.02,.06,.08,.92)
	return style
