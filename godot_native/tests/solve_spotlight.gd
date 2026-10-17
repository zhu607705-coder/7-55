extends SceneTree
## Validate source-authored physical input routes; never edit gameplay state to win.
const Model=preload("res://scripts/games/c3_spotlight_model.gd")
func _initialize()->void:
	var rules:=Model.new()
	var fixture:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/spotlight_balance_samples.json"))
	for route:Dictionary in fixture.cases:
		var proof:Dictionary=route.proof
		var verified:Dictionary=rules.validate(proof,int(proof.round),int(proof.attempt))
		if verified.get("status","")!="won":push_error("Source route failed native validation");quit(1);return
		print("Spotlight ",proof.round," validated ticks=",verified.tick," attempt=",proof.attempt)
	quit()
