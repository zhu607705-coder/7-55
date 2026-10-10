extends SceneTree
const Presenter=preload("res://scripts/presentation/chase_transition_3d_presenter.gd")
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.get_node("State").developer_mode=true
	var view=Presenter.new();view.validation_reference=true;view.manual_clock=true;root.add_child(view);view.size=Vector2(960,676)
	var max_position: float=0;var worst: String="";var max_basis: float=0;var max_screen: float=0
	for stage: String in ["start","finish"]:
		view.play(stage)
		for frame: int in range(view.source_manifest.stages[stage].size()):
			view.render_source_frame(stage,frame)
			for name: String in view.source_manifest.referenceNodes:
				var expected: Array=view.source_manifest.stages[stage][frame].referenceWorld[name]
				var transform: Transform3D=view.source_world_transform(name)
				var sample: Dictionary=view.source_manifest.stages[stage][frame]
				var qp: Array=sample.cameraQuaternion;var cp: Array=sample.cameraPosition
				var camera_basis:=Basis(Quaternion(qp[0],qp[1],qp[2],qp[3]))
				var point:=Vector3(expected[12],expected[13],expected[14])
				var relative: Vector3=camera_basis.inverse()*(point-Vector3(cp[0],cp[1],cp[2]))
				if relative.z<-.1:
					var focal: float=270.0/tan(deg_to_rad(float(sample.cameraFov))*.5)
					var source_pixel:=Vector2(480+relative.x/-relative.z*focal,270-relative.y/-relative.z*focal)
					max_screen=maxf(max_screen,source_pixel.distance_to(view.source_camera.unproject_position(point)))
				var error: float=transform.origin.distance_to(Vector3(expected[12],expected[13],expected[14]))
				if error>max_position:max_position=error;worst="%s F%d %s"%[stage,frame,name]
				for axis: int in range(3):
					max_basis=maxf(max_basis,transform.basis[axis].distance_to(Vector3(expected[axis*4],expected[axis*4+1],expected[axis*4+2])))
	print("SOURCE3D_POSE max_position=",max_position," max_basis=",max_basis," worst=",worst," camera_pixels=",max_screen)
	print("SOURCE3D nodes=",view.source_nodes.size()," bones=",view.source_bones.size()," clips=",view.source_animation.get_animation_list())
	view.dispose();view.queue_free();await process_frame
	quit(0 if max_position<.005 and max_basis<.01 and max_screen<.05 else 1)
