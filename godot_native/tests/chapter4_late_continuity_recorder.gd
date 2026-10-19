extends "res://tests/test_full_campaign.gd"
## Real uninterrupted campaign proofs create both saves; no developer seeds.
var late_capture_dir:=OS.get_environment("C4_LATE_CAPTURE_DIR")
func run() -> void:
	var owner: Node=root.get_node("State")
	owner.action_completed.connect(func(action: String,_before: Dictionary,_after: Dictionary,_result: Dictionary):
		if action not in ["c4_stairs_complete","c4_chase_done"] or late_capture_dir.is_empty(): return
		DirAccess.make_dir_recursive_absolute(late_capture_dir)
		check(owner.export_save(late_capture_dir.path_join(action+".json"))==OK,"earned late C4 snapshot "+action)
	)
	await super.run()
