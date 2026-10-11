extends SceneTree
## Native renderer presentation reel, separate from the actual-shell input acceptance test.
const Assembly=preload("res://scripts/ui/lake_rod_assembly_view.gd")
const Kayak=preload("res://scripts/games/kayak_model.gd")
const Visual=preload("res://scripts/ui/kayak_visual.gd")
const SCHEDULE: Array=[[.25,"left",false],[1.0,"right",false],[1.75,"left",false],[1.94,"right",false],[2.65,"left",true],[3.4,"right",true],[4.2,"left",false],[4.85,"left",false],[5.5,"left",false],[6.2,"right",false]]
var frame_index:=0
var stage: Control
var assembly: Control
var paddle: Control
var output: String="res://.screenshots/lake_reel"
func _initialize() -> void: run.call_deferred()
class PaddlePane extends Control:
	var visual: RefCounted=Visual.new()
	var model: RefCounted=Kayak.new()
	var font: Font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	var caption: String="各自入水，各自回桨"
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO,size),Color("244f60"))
		for y in range(60,540,38):
			for x in range(22,560,54):draw_line(Vector2(x,y),Vector2(x+19,y),Color("356476"),2)
		visual.draw(self,Vector2(size.x/2,280),2.8,{"heading":-PI/2+model.heading,"roll":model.roll,"speed":model.speed,"strokeEvents":model.inputs,"tick":model.tick},model.elapsed*1000)
		text_at(Vector2(size.x/2,38),"左右独立划桨",24)
		text_at(Vector2(size.x/2,526),caption,19)
		text_at(Vector2(size.x/2,558),"柳枝桨弯曲受力  ·  警示牌桨保持刚性",15)
	func text_at(p: Vector2,s: String,n: int) -> void:
		var w:=font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,n).x;draw_string(font,p-Vector2(w/2,0),s,HORIZONTAL_ALIGNMENT_LEFT,-1,n,Color("e8eddf"))
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	root.size=Vector2i(1180,600)
	stage=Control.new();stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(stage)
	var left:=Control.new();left.position=Vector2(0,0);left.size=Vector2(590,600);stage.add_child(left)
	var state: Node=root.get_node("State");state.developer_mode=true;state.begin_checkpoint("c3-qizhen-paper")
	var result: Dictionary=state.act("c3_lake_combine")
	assert(result.has("world_effect"))
	assembly=Assembly.new();left.add_child(assembly);assembly.setup({"read_state":func():return state.d});assembly.set_process(false)
	paddle=PaddlePane.new();paddle.position=Vector2(590,0);paddle.size=Vector2(590,600);stage.add_child(paddle);paddle.model.configure({"phase":"world","bounded":false})
	if "--capture" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
		for i in 240:
			update_at(i/30.0)
			await process_frame;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"/frame_%04d.png"%i)
		print("LAKE REEL FRAMES: ",ProjectSettings.globalize_path(output));quit();return
	process_frame.connect(advance)
func advance() -> void:
	update_at(frame_index/60.0);frame_index+=1
	if frame_index>=480:frame_index=0;paddle.model=Kayak.new();paddle.model.configure({"phase":"world","bounded":false})
func update_at(seconds: float) -> void:
	# All paddle impulses use the unmodified real model; this camera follows the boat.
	var target_tick:=int(round(seconds*120))
	while paddle.model.tick<target_tick:
		for event: Array in SCHEDULE:
			if paddle.model.tick==int(round(float(event[0])*120)):
				paddle.model.stroke(event[1],event[2])
				paddle.caption=("左桨" if event[1]=="left" else "右桨")+("后划 · 倒退" if event[2] else "前划 · 推进")
		paddle.model.step()
		if paddle.model.status!="running":break
	if seconds>=1.94 and seconds<2.4:paddle.caption="两侧动作重叠，各自完成一桨"
	if seconds>=4.85 and seconds<6.2:paddle.caption="连续左桨，船身与手臂响应侧倾"
	if seconds>=6.2:paddle.caption="换右桨，原有平衡模型恢复船身"
	assembly.elapsed_ms=minf(seconds*1000,4199)
	assembly.queue_redraw();paddle.queue_redraw()
