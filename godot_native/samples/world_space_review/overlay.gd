extends Control
const Body=preload("res://scripts/player_metrics.gd")
var world:Control
func _ready()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE;z_index=4000
func _process(_delta:float)->void:queue_redraw()
func _draw()->void:
	if not is_instance_valid(world):return
	var origin:Vector2=world.size/2-world.camera*world.zoom;var zoom:float=world.zoom
	for gap:Rect2 in world.world_space.voids:draw_rect(Rect2(origin+gap.position*zoom,gap.size*zoom),Color(.9,.13,.15,.23))
	for region:Rect2 in world.world_space.regions:draw_rect(Rect2(origin+region.position*zoom,region.size*zoom),Color(.17,.88,.61,.65),false,1)
	for cover:Dictionary in world.foreground:
		var bounds:Rect2=world._rect(cover.get("maskBounds",cover));var baseline:float=float(cover.get("baselineY",cover.get("sortY",cover.get("bottom",0))))
		draw_line(origin+Vector2(bounds.position.x,baseline)*zoom,origin+Vector2(bounds.end.x,baseline)*zoom,Color(1,.77,.16),1)
	var body:Rect2=world.kayak_collision_rect(world.player,world.kayak.heading) if world.kayak else Body.foot_rect(world.player)
	draw_rect(Rect2(origin+body.position*zoom,body.size*zoom),Color(.25,1,.38) if world.can_stand(world.player) else Color(1,.15,.7),false,2)
	var style:=StyleBoxFlat.new();style.bg_color=Color(.02,.06,.08,.92)
	draw_style_box(style,Rect2(8,8,944,29))
	draw_string(world.font,Vector2(16,29),"空间审阅  "+world.world_space.variant+"  红：非地面  黄：遮挡基线  绿：脚底 / 船体",HORIZONTAL_ALIGNMENT_LEFT,924,13,Color.WHITE)
