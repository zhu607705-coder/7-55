extends SceneTree
const Art=preload("res://scripts/presentation/c3_ticket_gate_art.gd")
const Gate=preload("res://scripts/presentation/c3_ticket_gate_view.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:run.call_deferred()
func run()->void:
	check(ResourceLoader.exists(Art.MATERIAL),"source material synchronized for native runtime")
	var tex:Texture2D=load(Art.MATERIAL)
	check(tex!=null and tex.get_size()==Vector2(1672,941),"registered source dimensions are fixed")
	var image:Image=tex.get_image()
	check(image.get_pixel(0,0).a==0,"source plate has a real transparent background")
	check(Art.GLASS_TINT.a<=.30001 and Art.GLASS_TINT.r<.8,"glass material attenuates original broad bright reflection")
	for p in [Vector2(842,740),Vector2(842,668.5),Vector2(842,657.5)]:
		var body:Rect2=Metrics.visual_rect(p)
		check(body.position.x>Art.LEFT_BODY.end.x and body.end.x<Art.RIGHT_BODY.position.x,"fixed housings leave complete rendered player clear")
	var g:RefCounted=Gate.new()
	for i in 101:
		g.openness=float(i)/100
		var p:Dictionary=g.pose()
		check(p.left_inner>=789 and p.left_inner<=833 and p.right_inner>=836 and p.right_inner<=880,"rendered wing registration remains within exact gate-view ranges")
	g.openness=1
	check(g.pose().left_inner<=Art.LEFT_BODY.end.x and g.pose().right_inner>=Art.RIGHT_BODY.position.x,"fully retracted plate edges are hidden inside fixed slots")
	print("THEATER_GATE_MATERIAL: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
