extends SceneTree
const CameraRig = preload("res://kit/camera_rig.gd")
const Owners = preload("res://kit/pointer_owners.gd")
const Surface = preload("res://kit/history_surface.gd")
const Inputs = preload("res://kit/capture_inputs.gd")

class InputProbe extends Node:
	var touches := 0
	var drags := 0
	var mouse_buttons := 0
	var mouse_moves := 0
	func _input(event: InputEvent) -> void:
		if event is InputEventScreenTouch: touches += 1
		elif event is InputEventScreenDrag: drags += 1
		elif event is InputEventMouseButton: mouse_buttons += 1
		elif event is InputEventMouseMotion: mouse_moves += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var owners := Owners.new()
	assert(owners.start(0, "left"))
	assert(owners.start(1, "right"))
	assert(not owners.start(0, "third"))
	assert(not owners.start(2, "left"))
	assert(not owners.start(-2, "other"))
	assert(not owners.start(2, ""))
	owners.release(0)
	assert(owners.start(-1, "left"))
	assert(owners.has_owner("right"))
	owners.clear()
	assert(owners.owners.is_empty())
	var first := Surface.viewport(root)
	var second := Surface.viewport(root)
	first.size = Vector2i(390, 844)
	second.size = Vector2i(180, 210)
	# own_world_3d uses the private resolved world, not the optional world_3d override.
	assert(first.find_world_3d() != second.find_world_3d())
	assert(first.gui_disable_input and not first.physics_object_picking)
	var display := Surface.image(root, first)
	assert(display.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	var camera := Camera3D.new()
	first.add_child(camera)
	var basis := CameraRig.configure(camera, Vector2(390, 844), Vector3.ZERO, 6.7)
	assert(is_equal_approx(camera.size, 6.7 * 844.0 / 390.0))
	assert(is_equal_approx(basis.determinant(), 1.0))
	assert(is_equal_approx(rad_to_deg(asin(basis.z.y)), 50.0))
	assert(is_equal_approx(rad_to_deg(atan2(-basis.x.z, basis.x.x)), 8.0))
	CameraRig.configure(camera, Vector2(1200, 600), Vector3(1, 2, 3), 6.7, 5.0)
	assert(is_equal_approx(camera.size, 5.0))
	var probe := InputProbe.new()
	root.add_child(probe)
	await process_frame
	var inputs := Inputs.new()
	inputs.touch(0, Vector2(20, 20), true)
	inputs.drag(0, Vector2(25, 30))
	assert(inputs.last[0] == Vector2(25, 30))
	inputs.touch(0, Vector2(25, 30), false)
	assert(inputs.last.is_empty())
	inputs.mouse_button(Vector2(10, 10), true)
	inputs.mouse_move(Vector2(30, 40))
	inputs.mouse_button(Vector2(30, 40), false)
	assert(not inputs.mouse_pressed)
	await process_frame
	print("INPUT_PROBE touches=", probe.touches, " drags=", probe.drags, " buttons=", probe.mouse_buttons, " moves=", probe.mouse_moves)
	if probe.touches != 2 or probe.drags != 1 or probe.mouse_buttons != 2 or probe.mouse_moves < 1:
		push_error("Observation kit ordinary input delivery failed")
		quit(1)
		return
	probe.free()
	display.free()
	first.free()
	second.free()
	print("OBSERVATION_KIT camera=50/8 independent_worlds=true ownership=true ordinary_event_delivery=true rendered=false")
	quit()
