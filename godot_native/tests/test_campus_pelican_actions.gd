extends "res://tests/test_campus_rider_action_chain.gd"
func _initialize() -> void:
	pelican_mode=true
	super._initialize()
func lowest_sole(avatar: Node3D,side: String) -> float:return avatar.lowest_web_height(side)
func check_avatar(view: Control) -> void:
	check(view.campus_human.name=="CampusPelican","production transition selects the original avian rig")
	check(not view.campus_human.generated_asset,"avian rig cannot silently load the rejected human mesh")
	check(view.feather_transition!=null and view.surface.material is ShaderMaterial,"production has feather handoff and fine-pixel film material")
	for frame: int in [0,3,6,10,40,90]:
		view.render_source_frame("start",frame)
		check(view.campus_human.visible==(frame>=6),"start swaps original pixel student to pelican under feathers at "+str(frame))
		check(view.feather_transition.student.visible!=view.campus_human.visible,"exactly one avatar form is visible")
	for frame: int in [0,90,112,115,117,122,132]:
		view.render_source_frame("finish",frame)
		check(view.campus_human.visible==(frame<117),"finish restores original pixel student at "+str(frame))
		check(view.feather_transition.student.visible!=view.campus_human.visible,"return has one visible avatar")
	view.play("start",false,true)
	check(not view.feather_transition.visible and view.campus_human.visible,"reduced motion directly shows correct departure form without swirl")
	view.play("finish",false,true)
	check(not view.feather_transition.visible and view.feather_transition.student.visible,"reduced motion directly restores the original protagonist")
