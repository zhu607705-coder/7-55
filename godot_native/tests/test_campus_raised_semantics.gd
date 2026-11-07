extends SceneTree
const Layered = preload("res://scripts/presentation/campus_layered_map.gd")
var checks := 0
var failures := 0
func _initialize() -> void:
	var art := Layered.new()
	# Deliberately unsorted source order: semantic passes, not source order,
	# determine road/ground ordering. Raised objects use their measured base Y; ties retain author order.
	art.manifest = {"semanticLayerVersion":2, "layers":[
		{"id":"roof", "renderPass":"raised", "pass":"foreground", "baseline":200.0},
		{"id":"road", "renderPass":"roads"},
		{"id":"paving", "renderPass":"ground"},
		{"id":"grass", "renderPass":"land"},
		{"id":"tree", "renderPass":"raised", "baseline":180.0},
		{"id":"gate", "renderPass":"raised", "baseline":210.0}
	]}
	check(Layered.validate_semantics(art.manifest).is_empty(), "explicit semantic contract accepted")
	check(ids(art.render_plan(220)) == ["grass","water","paving","road","tree","roof","gate"], "ground below road, every raised roof/canopy/gate above road")
	check(ids(art.render_plan(220,true)).is_empty(), "actor in front has no later raised repaint")
	check(ids(art.render_plan(100)) == ["grass","water","paving","road"], "actor behind excludes raised pixels from back pass")
	check(ids(art.render_plan(100,true)) == ["tree","roof","gate"], "raised pixels cover actor from authored foot baselines")
	check(ids(art.render_plan(190)) == ["grass","water","paving","road","tree"], "each object's own footpoint decides depth")
	check(ids(art.render_plan(190,true)) == ["roof","gate"], "separate object front decisions")
	check(ids(art.render_plan(200)).has("roof") and not ids(art.render_plan(200,true)).has("roof"), "baseline equality draws actor in front once")
	art.manifest.layers.append({"id":"same_base_later", "renderPass":"raised", "baseline":200.0})
	check(ids(art.render_plan(220)) == ["grass","water","paving","road","tree","roof","same_base_later","gate"], "raised sorted by world baseline; equal baselines retain authored tie order")
	art.manifest.layers.pop_back()
	art.set_category_visible("buildings", false)
	check(ids(art.render_plan(220)) == ["water"], "visibility does not bypass semantic pass")
	art.category_visibility.clear()
	var projected: Dictionary={"id":"projected_tree", "renderPass":"raised", "baseline":500.0,"depthMode":"projected_y", "origin":[0,90],"scale":1.0,"depthOriginalOriginY":100.0,"depthOriginalScale":0.5,"depthOriginalProjection":20.0}
	art.manifest.layers=[projected]
	var behind := art.render_plan(150)
	var ahead := art.render_plan(150,true)
	check(behind.size()==2 and ahead.size()==1, "projected object participates in both complementary plans")
	check(behind[1].sourceYMax==50.0 and ahead[0].sourceYMin==50.0, "original fractional source transform preserves exact split")
	check(behind[1].sourceYMin==-INF and ahead[0].sourceYMax==INF, "split intervals neither duplicate nor omit source rows")
	check(art.render_plan(500,true).is_empty(), "projected object entirely behind actor after footpoint")
	check(not Layered.validate_semantics({"layers":[]}).is_empty(), "old manifest fails closed")
	check(not Layered.validate_semantics({"semanticLayerVersion":2,"layers":[{"id":"whole_compound","renderPass":"objects"}]}).is_empty(), "ambiguous compound pass rejected")
	check(not Layered.validate_semantics({"semanticLayerVersion":2,"layers":[{"id":"tree","renderPass":"raised"}]}).is_empty(), "raised without footpoint rejected")
	check(not Layered.validate_semantics({"semanticLayerVersion":2,"layers":[{"id":"old_foreground","renderPass":"ground","pass":"foreground"}]}).is_empty(), "old foreground cannot silently remain ground")
	art.manifest.layers=[{"id":"unresolved","renderPass":"ground","semanticCoverage":"unsegmented_compound"},{"id":"missing_coverage","renderPass":"ground"},{"id":"flat","renderPass":"ground","semanticCoverage":"flat_only"}]
	check(art.snapshot().unsegmentedCompoundCount == 1, "snapshot counts explicit unresolved compounds only")
	art.manifest.layers=[]
	check(art.snapshot().unsegmentedCompoundCount == 0, "snapshot does not infer coverage from pass names")
	print("Raised semantic plan: ", checks," checks, ", failures," failures")
	quit(0 if failures==0 else 1)
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func ids(plan: Array[Dictionary]) -> Array[String]:
	var result: Array[String]=[]
	for item: Dictionary in plan:
		result.append("water" if item.kind=="water" else str(item.row.id))
	return result
