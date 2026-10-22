extends SceneTree
const Sequence=preload("res://scripts/presentation/chapter4_lamp_sequence.gd")
func _initialize()->void:
	var source_path:=OS.get_environment("LAMP_SOURCE_FRAMES")
	if source_path.is_empty():source_path="res://tests/fixtures/chapter4_lamp_sequence.json"
	var fixture:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source_path))
	var checks:=0;var failures:=0;var max_error:=0.0
	for row in fixture.frames:
		var native:=Sequence.frame(row.time,row.reduced);var source:Dictionary=row.frame
		var pairs:=[[native.duration,source.durationMs],[native.rise,source.cameraRiseProgress],[native.reveal,source.sceneReveal],[native.led,source.ledLevel],[native.core,source.coreLevel],[native.glow,source.glowLevel],[native.caption,source.captionLevel],[native.camera.y,source.cameraHeight],[-native.camera.z,source.cameraRadius],[native.look.y,source.cameraLookAtHeight],[native.scale,source.artworkScale],[native.offset*100,source.artworkOffsetY]]
		for pair in pairs:
			checks+=1;var error:=absf(float(pair[0])-float(pair[1]));max_error=maxf(max_error,error)
			if error>0.00001:failures+=1;push_error("Source frame mismatch time=%s reduced=%s %s"%[row.time,row.reduced,pair])
	print("CHAPTER4_LAMP_SEQUENCE_TESTS ",checks," checks; ",failures," failures; max_error=",max_error)
	quit(1 if failures else 0)
