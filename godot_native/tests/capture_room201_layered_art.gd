extends "res://tests/capture_room201_press.gd"
## Same source-seeded Main fixture, plus the calibrated contact endpoint.
func frozen_pose(panel:Control,time:float,label:String)->void:
	if label.ends_with("embossed-rebound"):
		panel.view.set_process(false);panel.view.motion_time=.4;panel.view.queue_redraw()
		await capture(label.replace("embossed-rebound","calibrated-contact"))
	await super.frozen_pose(panel,time,label)
