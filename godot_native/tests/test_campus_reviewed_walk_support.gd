extends SceneTree
const Layered=preload("res://scripts/presentation/campus_layered_map.gd")
var checks:=0
var failures:=0
func _initialize() -> void:
	var art:=Layered.new()
	art.ready=true
	var bits:=PackedByteArray();bits.resize(60);bits.fill(0)
	for y in range(20):
		for x in range(12,24):
			var i:=y*24+x;bits[i/8]|=1<<(i%8)
	art.walk_supports=[{"id":"reviewed","origin":Vector2.ZERO,"width":24,"height":20,"bits":bits,"bounds":Rect2(12,0,12,20)}]
	var source:=PackedByteArray();source.resize(4);source.fill(0)
	for y in range(5):
		for x in range(3):
			var i:=y*6+x;source[i/8]|=1<<(i%8)
	var definition:Dictionary={"cellSize":4,"gridWidth":6,"gridHeight":5}
	var feet:=Rect2(2.25,1.2,19.5,14.625)
	check(art.reviewed_support_covers(feet,source,definition),"unchanged 19.5x14.625 foot fully covered by source/support union")
	check(not art.reviewed_support_covers(Rect2(30,0,19.5,14.625),source,definition),"outside support immediately rejected")
	var hole:=8*24+16;bits[hole/8]&=~(1<<(hole%8));art.walk_supports[0].bits=bits
	check(not art.reviewed_support_covers(feet,source,definition),"one-pixel hole away from foot center rejects")
	bits[hole/8]|=1<<(hole%8);art.walk_supports[0].bits=bits
	check(not art.reviewed_support_covers(Rect2(4.6,1.2,19.5,14.625),source,definition),"fractional unsupported foot strip rejects")
	art.water_regions=[{"bounds":Rect2(17,2,1,1),"rects":[Rect2(17,2,1,1)]}]
	check(not art.reviewed_support_covers(feet,source,definition),"true water wins over support")
	art.water_regions=[]
	art.solid_polygons=[PackedVector2Array([Vector2(17,2),Vector2(18,2),Vector2(18,3),Vector2(17,3)])]
	check(not art.reviewed_support_covers(feet,source,definition),"solid wins over support")
	art.solid_polygons=[]
	check(not art.reviewed_support_covers(feet,PackedByteArray(),{}),"missing original source cannot fill unreviewed half")
	check(art.walk_support_intersects(feet) and not art.walk_support_intersects(Rect2(100,100,1,1)),"local refinement gate avoids global added sampling")
	art.release()
	check(art.walk_supports.is_empty(),"release clears support data")
	print("Reviewed support: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(label)
