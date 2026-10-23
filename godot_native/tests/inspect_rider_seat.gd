extends SceneTree
const Rider=preload("res://scripts/presentation/chase3d/source_rider.gd")
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var rider:=Rider.new();rider.asset_directory="res://assets/native_755/ride/";root.add_child(rider)
	await process_frame
	var seat: MeshInstance3D=rider.nodes.rider_0026
	var bounds: AABB=seat.get_aabb()
	var center: Vector3=rider.to_local(seat.to_global(bounds.get_center()))
	var top: Vector3=rider.to_local(seat.to_global(bounds.get_center()+Vector3(0,bounds.size.y*.5,0)))
	print("SEAT_BOUNDS ",bounds," center=",center," top=",top)
	print("CURRENT_HIPS ",rider.campus_human.joint_point("Hips"))
	print("PELVIC_SEAT_ANCHOR ",rider.campus_human.surface_contact("seat",""))
	for id: String in ["leftGrip","rightGrip","leftPedal","rightPedal"]:print(id," ",rider.to_local(rider.reference_world(id).origin))
	quit()
