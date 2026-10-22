extends SceneTree
var view: Node2D
var checks: Array[Dictionary]=[]
var errors: Array[String]=[]
var out: String
func _initialize() -> void:
 out=ProjectSettings.globalize_path("res://../verification/");call_deferred("run")
func settle() -> void:
 for n in range(3):await process_frame
 await RenderingServer.frame_post_draw
func save(label: String) -> Image:
 var image: Image=root.get_texture().get_image();image.save_png(out+label+".png");return image
func run() -> void:
 view=load("res://scenes/blender_lake_sample.tscn").instantiate();root.add_child(view);view.set_process(false);view.title_open=false
 for size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844),Vector2i(1024,768)]:
  root.size=size;view._update_layout();view.touch_mode=true;view.game.position=Vector2(5810,3655);view.game.progress=1;view.game.speed=0;view._sync(0,true)
  await settle();save("hud-%dx%d"%[size.x,size.y])
  checks.append({"kind":"native_responsive_screenshot","size":[size.x,size.y],"file":"hud-%dx%d.png"%[size.x,size.y]})
 root.size=Vector2i(390,844);view._update_layout();view._set_overview(true);view._sync(0,true);await settle();save("sample-map-narrow")
 view._set_overview(false);view.title_open=true;view._sync(0,true);await settle();save("sample-title-narrow");view.title_open=false
 root.size=Vector2i(1280,720);view._update_layout();view.game.position=Vector2(6000,2850);view.game.progress=0;view._sync(0,true)
 view._set_overview(true);view._sync(0,true);await settle();save("sample-map-context")
 view._set_overview(false);view._sync(0,true)
 var img:=Image.create(24,24,false,Image.FORMAT_RGBA8);img.fill(Color(1,0,1,1))
 var probe:=Sprite3D.new();probe.name="QAOnlyDepthProbe";probe.texture=ImageTexture.create_from_image(img);probe.pixel_size=.06;probe.rotation.x=-PI/2;probe.shaded=false;probe.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD;probe.no_depth_test=false;view.world_3d.add_child(probe)
 for config in [{"label":"depth-water-visible","point":Vector2(5720,2850),"height":.12,"visible":true},{"label":"depth-bank-occluded","point":Vector2(6400,2850),"height":.12,"visible":false},{"label":"depth-above-bank-visible","point":Vector2(6400,2850),"height":1.2,"visible":true}]:
  var p: Vector2=(config.point-view.WORLD_ORIGIN)/view.WORLD_UNIT;probe.position=Vector3(p.x,config.height,p.y)
  await settle();var picture: Image=save(config.label)
  var pixel: Vector2=view.lake_camera.unproject_position(probe.global_position)
  var c: Color=picture.get_pixelv(Vector2i(pixel));var magenta: bool=c.r>.7 and c.b>.7 and c.g<.2
  var ok: bool=magenta==bool(config.visible)
  checks.append({"kind":"actual_native_depth_probe","label":config.label,"pixel":[pixel.x,pixel.y],"color":[c.r,c.g,c.b],"visible_expected":config.visible,"passed":ok})
  if not ok:errors.append(config.label)
 probe.queue_free()
 var result: Dictionary={"checks":checks,"failures":errors,"same_actor_depth_configuration":true,"method":"Native Godot screenshots of the same Sprite3D depth configuration in clear water, below bank surface, and above bank surface; no mocked renderer"}
 var f:=FileAccess.open(out+"native-visual-checks.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));print("VISUAL_CHECKS ",JSON.stringify(result));quit(0 if errors.is_empty() else 1)
