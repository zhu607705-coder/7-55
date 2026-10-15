extends SceneTree
const Presenter=preload("res://scripts/presentation/chase_transition_3d_presenter.gd")
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.get_node("State").developer_mode=true
	var view=Presenter.new();view.validation_reference=true;view.manual_clock=true;root.add_child(view);view.size=Vector2(960,676)
	var worst: float=0;var comparisons: int=0;var clock_errors: int=0
	for stage: String in ["start","finish"]:
		view.play(stage)
		for frame: int in range(view.source_manifest.stages[stage].size()-1):
			for fraction: float in [.01,.49,.99]:
				view.elapsed=(frame+fraction)/24.0-0.00001;view.advance(0.00001)
				if view.frame!=frame:clock_errors+=1
				for name: String in view.source_manifest.referenceNodes:
					var source: Array=view.source_manifest.stages[stage][frame].referenceWorld[name]
					worst=maxf(worst,view.source_world_transform(name).origin.distance_to(Vector3(source[12],source[13],source[14])));comparisons+=1
	var no_interpolation: bool=not view.source_animation.is_playing() and view.source_root.physics_interpolation_mode==Node.PHYSICS_INTERPOLATION_MODE_OFF
	print("FRACTIONAL_SOURCE_24FPS comparisons=",comparisons," max_contact_position_error=",worst," clock_errors=",clock_errors," no_unspecified_pose_interpolation=",no_interpolation)
	view.dispose();view.queue_free();await process_frame;quit(0 if worst<.0001 and clock_errors==0 and no_interpolation else 1)
