extends SceneTree
var view: Node2D
var frames: int=0
func _initialize() -> void:call_deferred("start")
func start() -> void:
 view=load("res://scenes/blender_lake_sample.tscn").instantiate();root.add_child(view);view.title_open=false;view.set_process(false);view._sync(0,true)
func _process(_dt: float) -> bool:
 if view==null:return false
 frames+=1
 view._sync(1./30)
 if frames==4:call_deferred("save")
 return false
func save() -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/first-light.png"))
 for p in [Vector2(6000,2850),Vector2(5810,3655),Vector2(6200,2740)]:print("ALIGN ",p," 2d ",view.world_to_screen(p)," 3d ",view.ground_to_screen_3d(p)," error ",view.world_to_screen(p).distance_to(view.ground_to_screen_3d(p)))
 quit()
