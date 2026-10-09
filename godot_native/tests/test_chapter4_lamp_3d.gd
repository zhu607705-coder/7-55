extends SceneTree
const Activity=preload("res://scripts/games/chapter4_activity.gd")
const Presenter=preload("res://scripts/presentation/chapter4_lamp_3d.gd")
const Sequence=preload("res://scripts/presentation/chapter4_lamp_sequence.gd")
var checks:=0
var failures:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func advance(view:Control,ms:float)->void:
	while ms>0:
		var dt:=minf(100,ms);view.advance(dt);ms-=dt
func drain()->void:await process_frame;await process_frame
func run()->void:
	var owner:=root.get_node("State")
	for reduced in [false,true]:
		check(owner.begin_checkpoint("c4-755-closure"),"Original earned closure fixture exists")
		owner.d.native.settings.reduced_motion=reduced
		var controller:RefCounted
		for module in owner.modules:
			if str(module.get_script().resource_path)=="res://scripts/chapters/chapter4.gd":controller=module
		var issued:Dictionary=controller.dispatch(owner.d,"c4_lamp_start")
		var activity:=Activity.new();root.add_child(activity);activity.setup(issued.game);activity.set_process(false)
		activity.completed.connect(func(proof):owner.act("c4_closure_done",proof))
		activity.configure_activity_layout(Vector2(1180,812),false);await drain()
		var view:Control=activity.lamp_view
		check(view.uses_blender_lamp,"Production closure selects the real Blender lamp by default")
		var mesh:SubViewportContainer=view.lamp_3d
		check(mesh.available and mesh.mesh_count==14,"All 14 source lamp meshes were imported")
		check(mesh.triangle_count==30318,"Production uses reviewed 30318-triangle LOD1")
		check(mesh.viewport.own_world_3d and mesh.viewport.gui_disable_input,"3D world and input are isolated")
		check(mesh.viewport.msaa_3d==Viewport.MSAA_DISABLED and mesh.stretch_shrink==1,"Measured optimization keeps full render resolution and removes unnecessary MSAA")
		var point_lights:=0
		for child in mesh.scene.get_children():
			if child is OmniLight3D:point_lights+=1
		check(point_lights==0,"No redundant point-light passes remain")
		for key in mesh.materials:
			check(mesh.materials[key].cull_mode==BaseMaterial3D.CULL_BACK and mesh.imported_materials[key].cull_mode==BaseMaterial3D.CULL_DISABLED,"Closed opaque surfaces cull only runtime backfaces, never change GLB resources")
		check(mesh.stars.multimesh.instance_count==640,"Stars use one bounded native instanced mesh")
		check(not mesh.environment.glow_enabled,"No incompatible or high-whiteness postprocessing")
		check(not view.art.visible and not view.star_canvas.visible,"Old PNG and CPU star layers do not render underneath")
		var baseline:Dictionary=owner.d.duplicate(true)
		var imported_led:float=mesh.imported_materials[mesh.LED_NAME].emission_energy_multiplier
		var imported_core:float=mesh.imported_materials[mesh.CORE_NAME].emission_energy_multiplier
		for t in [0,120,1000,2200,2350,2750,3000,3890,4150,5800]:
			mesh.apply_frame(Sequence.frame(t,reduced),"playback")
			check(owner.d==baseline,"Rendering time %d cannot mutate story state"%t)
			check(mesh.model.transform==Transform3D.IDENTITY,"Lamp itself never rotates or deforms")
			check(mesh.camera.position.is_equal_approx(mesh.CAMERA_START.lerp(mesh.CAMERA_END,float(Sequence.frame(t,reduced).rise))),"Actual reference camera path uses original rise signal")
			if reduced:check(mesh.camera.position.is_equal_approx(mesh.CAMERA_END),"Reduced motion always uses the fixed final camera")
		check(mesh.imported_materials[mesh.LED_NAME].emission_energy_multiplier==imported_led and mesh.imported_materials[mesh.CORE_NAME].emission_energy_multiplier==imported_core,"Imported GLB materials were not mutated")
		check(is_equal_approx(mesh.materials[mesh.LED_NAME].emission_energy_multiplier,1.8),"Approved low-glow LED peak is retained")
		check(is_equal_approx(mesh.materials[mesh.CORE_NAME].emission_energy_multiplier,0.85),"Approved low-glow core peak is retained")
		mesh.apply_frame(Sequence.frame(4000,reduced),"playback")
		var caption_updates:int=mesh.update_count
		mesh.apply_frame(Sequence.frame(4500,reduced),"playback")
		check(mesh.update_count==caption_updates,"Caption-only source changes never redraw a static 3D scene")
		view._update_art()
		check(mesh.materials[mesh.LED_NAME].emission_energy_multiplier==0 and mesh.materials[mesh.CORE_NAME].emission_energy_multiplier==0,"Questions return to unlit geometry")
		advance(view,120 if reduced else 1150);view.choose("purpose","seek_truth")
		advance(view,160 if reduced else 980);advance(view,120 if reduced else 1150);view.choose("person","clear_minded")
		advance(view,160 if reduced else 980)
		check(view.stage=="saved" and owner.d.chapter4.factIds.has("zhu_two_questions_answered"),"Both original Zhu answers save before playback")
		advance(view,240 if reduced else 1100)
		check(view.stage=="playback","Original saved confirmation starts playback")
		var before_pause:float=view.playback_ms
		var camera_before:Transform3D=mesh.camera.transform
		var updates_before:int=mesh.update_count
		view.advance(100,false)
		check(view.playback_ms==before_pause and mesh.camera.transform==camera_before and mesh.update_count==updates_before,"Unfocused owner freezes time, camera, and render requests")
		var duration:=3600 if reduced else 5800
		advance(view,duration-1);view.acknowledge()
		check(view.stage=="playback" and not owner.d.chapter4.completed,"No early acknowledgement or mesh-driven completion")
		advance(view,1);await drain()
		check(view.stage=="final" and not owner.d.chapter4.completed,"Playback only opens final confirmation")
		for dimensions in [Vector2(390,844),Vector2(430,860),Vector2(844,390),Vector2(1180,812),Vector2(1280,720)]:
			activity.configure_activity_layout(dimensions,true);await drain();view._update_art()
			var mesh_rect:=Rect2(mesh.position,mesh.size)
			var panel_rect:=Rect2(view.panel.position,view.panel.size)
			check(Rect2(Vector2.ZERO,dimensions).encloses(mesh_rect),"Mesh viewport stays contained at "+str(dimensions))
			check(not mesh_rect.intersects(panel_rect),"Final lamp and answer summary do not cover each other at "+str(dimensions))
			check(Rect2(Vector2.ZERO,dimensions).encloses(panel_rect),"Final controls stay within view at "+str(dimensions))
			check(mesh.camera.fov>=mesh.VERTICAL_FOV and mesh.camera.fov<65,"Narrow camera fits through FOV instead of distorting geometry")
		view._update_art();var stable_updates:int=mesh.update_count
		for i in 30:view.advance(16.6667)
		check(mesh.update_count==stable_updates,"Static final mesh is not re-rendered every frame")
		view.acknowledge();check(owner.d.chapter4.completed,"Only explicit final acknowledgement completes the original controller")
		var frozen:Dictionary=owner.d.duplicate(true)
		view.dispose();mesh.apply_frame(Sequence.frame(0),"playback");view.acknowledge()
		check(owner.d==frozen and mesh.disposed,"Disposal cancels mesh updates and any late action")
		check(mesh.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Disposed 3D viewport stops drawing")
		activity.queue_free();await drain()
	# The original layered path stays available as an explicit source-only rollback.
	owner.begin_checkpoint("c4-755-closure")
	var controller:RefCounted
	for module in owner.modules:
		if str(module.get_script().resource_path)=="res://scripts/chapters/chapter4.gd":controller=module
	var issued:Dictionary=controller.dispatch(owner.d,"c4_lamp_start")
	issued.game.lampPresentation="layered"
	var fallback:=Activity.new();root.add_child(fallback);fallback.setup(issued.game);fallback.set_process(false)
	check(not fallback.lamp_view.uses_blender_lamp and fallback.lamp_view.art.visible,"Original five-layer consumer remains a working rollback")
	fallback.queue_free();await drain()
	print("CHAPTER4_LAMP_3D: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
