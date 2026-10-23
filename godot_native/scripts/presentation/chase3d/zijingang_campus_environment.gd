extends Node3D
## Original campus scenery informed by ZJU's public architectural photographs.
## The authored755m corridor is compressed scenery, not a surveyed campus route.
## All geometry is presentation-only. The original model owns all collisions.
const Batch=preload("res://scripts/presentation/chase3d/campus_mesh_batch.gd")
const CHUNK_LENGTH: float=40
const ROAD_HALF_WIDTH: float=5.55
const WORLD_PER_METER: float=1.05
const GOAL: float=755
const LEAVES: Array[String]=["2D443E","49634A","72865C"]
var chunks: Dictionary={}
var material_cache: Dictionary={}
var landmarks: Node3D
const MODULE_PATH: String="res://assets/native_755/ride/rodin/"
var module_cache: Dictionary={}

func _has_module(id: String) -> bool:
	return ResourceLoader.exists(MODULE_PATH+id+".glb")

func _module(parent: Node3D,id: String,point: Vector3,yaw: float=0,factor: float=1) -> Node3D:
	if not _has_module(id):return null
	if not module_cache.has(id):module_cache[id]=load(MODULE_PATH+id+".glb")
	var instance: Node3D=module_cache[id].instantiate();instance.name=id
	parent.add_child(instance);instance.position=point;instance.rotation.y=yaw;instance.scale=Vector3.ONE*factor
	instance.set_meta("generated_asset",true)
	return instance

func build_transition(stage: String) -> Node3D:
	var b:=Batch.new();b.materials=material_cache
	b.box("72865C",Vector3(0,-.19,-7),Vector3(100,.18,65))
	b.box("526B7A",Vector3(0,-.065,-7),Vector3(11.1,.09,65))
	for side: int in [-1,1]:
		b.box("C5C1A9",Vector3(side*7.25,-.005,-7),Vector3(3.16,.15,65))
		for n: int in range(4):_tree(b,Vector3(side*11,0,15-n*14),n+side*7)
		_lamp(b,Vector3(side*6.15,0,4),side)
	if stage=="start":
		if not _has_module("campus_glass_canopy"):_canteen(b,Vector3(-24,0,-16))
		_cycle_shelter(b,Vector3(11.7,0,1))
	elif not _has_module("campus_theater_foyer"):_theater(b,Vector3(0,0,-23))
	var node: Node3D=b.finish("ZijingangDeparture" if stage=="start" else "ZijingangArrival")
	if stage=="start":_module(node,"campus_glass_canopy",Vector3(-24,0,-16),PI/2,1.5)
	else:_module(node,"campus_theater_foyer",Vector3(0,0,-27))
	return node

func update_distance(distance: float,ahead: float=115) -> void:
	var first: int=maxi(-1,floori((distance*WORLD_PER_METER-40)/CHUNK_LENGTH))
	var last: int=mini(21,ceili((distance*WORLD_PER_METER+ahead)/CHUNK_LENGTH))
	for index: int in range(first,last+1):
		if chunks.has(index):continue
		var chunk: Node3D=build_chunk(index);add_child(chunk);chunks[index]=chunk
	for index: int in chunks.keys():
		if index<first or index>last:chunks[index].queue_free();chunks.erase(index)
	if landmarks==null:
		var b:=Batch.new();b.materials=material_cache
		if not _has_module("campus_glass_canopy"):_canteen(b,Vector3(-24,0,-16))
		if not _has_module("campus_theater_foyer"):_theater(b,Vector3(0,0,-824))
		landmarks=b.finish("ZijingangLandmarks");add_child(landmarks)
		_module(landmarks,"campus_glass_canopy",Vector3(-24,0,-16),PI/2,1.5)
		_module(landmarks,"campus_theater_foyer",Vector3(0,0,-824))

func build_chunk(index: int) -> Node3D:
	var b:=Batch.new();b.materials=material_cache
	var z: float=-index*CHUNK_LENGTH;var distance: float=-z/WORLD_PER_METER
	var waterside: bool=distance>=110 and distance<377
	var works: bool=distance>=377 and distance<566
	var arrival: bool=distance>=566
	b.box("72865C",Vector3(0,-.19,z),Vector3(110,.18,40))
	b.box("526B7A",Vector3(0,-.065,z),Vector3(11.1,.09,40))
	for side: int in [-1,1]:
		b.box("C5C1A9",Vector3(side*7.25,-.005,z),Vector3(3.16,.15,40))
		b.box("E8E0C8",Vector3(side*5.28,.002,z),Vector3(.1,.012,40))
		b.box("D3A451",Vector3(side*7.35,.076,z),Vector3(.24,.018,40))
		for seam: int in range(20):
			var at: float=z+19-seam*2
			b.box("A39B87",Vector3(side*5.69,.07,at),Vector3(.26,.19,1.94))
			b.box("A39B87",Vector3(side*7.25,.076,at),Vector3(3.1,.009,.025))
			if seam%5==0:
				b.box("344452",Vector3(side*5.46,.005,at),Vector3(.22,.018,.6))
				for slot: int in range(5):b.box("7993A1",Vector3(side*5.46,.016,at-.23+slot*.11),Vector3(.2,.009,.024))
		for n: int in range(3):
			var tree_z: float=z+14-n*14
			if not (works and side==1):_tree(b,Vector3(side*(11.5 if arrival else 10.7),0,tree_z),index*13+n,waterside and side==-1)
		_lamp(b,Vector3(side*6.15,.08,z-2),side)
		if not (works and side==1):
			b.box("766E63",Vector3(side*9.6,.28,z-10),Vector3(.66,.56,6))
			b.box("49634A",Vector3(side*9.6,.72,z-10),Vector3(.95,.48,6.2))
			_bench(b,Vector3(side*8.55,.1,z+8),side)
	for n: int in range(5):
		for x: float in [-1.675,1.675]:b.box("E8E0C8",Vector3(x,-.011,z+17-n*8),Vector3(.1,.008,3.2))
	if waterside:
		b.box("547F9D",Vector3(-28,-.38,z),Vector3(29,.04,40))
		b.box("766E63",Vector3(-13.5,-.12,z),Vector3(.7,.65,40))
		b.pole("C5C1A9",Vector3(-13.2,.85,z-20),Vector3(-13.2,.85,z+20),.045)
		for n: int in range(20):
			b.pole("C5C1A9",Vector3(-13.2,0,z+19-n*2),Vector3(-13.2,.9,z+19-n*2),.045)
			b.box("83A7B6",Vector3(-18-posmod(n,5)*3,-.348,z+18-n*2),Vector3(1.6,.006,.07))
		if index%2==0 and _has_module("campus_willow_verge"):_willow_leaves(b,Vector3(-12.1,6.1,z+4.1),index)
	if works:_construction(b,z)
	elif index in [1,3,6,8,15,17] and not _has_module("campus_glass_canopy"):
		_teaching_facade(b,Vector3(24 if index%2 else -24,0,z),index)
	if index in [0,4,16]:_cycle_shelter(b,Vector3(11.7,0,z+7))
	var node: Node3D=b.finish("ZijingangChunk_%d"%index)
	if not works and index in [1,3,6,8,15,17]:
		var side: int=1 if index%2 else -1
		_module(node,"campus_glass_canopy",Vector3(side*24,0,z),-side*PI/2,1.5)
	if waterside and index%2==0:
		_module(node,"campus_willow_verge",Vector3(-12.1,0,z+5),PI/2)
	node.set_meta("distance_start",(index*40-20)/WORLD_PER_METER)
	node.set_meta("distance_end",(index*40+20)/WORLD_PER_METER)
	return node

func _willow_leaves(b: RefCounted,center: Vector3,seed: int) -> void:
	# Rodin returned a bare branching tree. Add original narrow willow leaves,
	# preserving its trunk/bench/rail model rather than accepting the bare crown.
	for strand: int in range(54):
		var angle: float=strand*2.39996+seed*.3
		var radius: float=.6+float(posmod(strand*7,17))/17*2.1
		var start: Vector3=center+Vector3(cos(angle)*radius,.8-radius*.15,sin(angle)*radius)
		var length: float=1.9+float(posmod(strand*11,19))/19*1.8
		var previous: Vector3=start
		for leaf: int in range(15):
			var t: float=float(leaf+1)/15
			var point: Vector3=start+Vector3(cos(angle)*.28*t,-length*t,sin(angle)*.28*t)
			b.pole("49634A",previous,point,.009,.006,3);previous=point
			var side: float=-1 if leaf%2 else 1
			var span:=Vector3(cos(angle)*.15*side,-.12,sin(angle)*.15*side)
			var cross:=Vector3(-sin(angle),0,cos(angle))*.025
			b.quad(LEAVES[posmod(strand+leaf,3)],point,point+span*.5+cross,point+span,point+span*.5-cross,Vector3.UP)
			b.quad(LEAVES[posmod(strand+leaf,3)],point,point+span*.5-cross,point+span,point+span*.5+cross,Vector3.DOWN)

func _tree(b: RefCounted,p: Vector3,seed: int,willow: bool=false) -> void:
	var height: float=5.8+posmod(seed,4)*.28
	b.pole("70503B",p,p+Vector3(.12,height,0),.2,.095)
	for branch: int in range(5):
		var angle: float=branch*TAU/5+seed*.37
		var tip: Vector3=p+Vector3(cos(angle)*1.6,height-.7,sin(angle)*1.6)
		b.pole("70503B",p+Vector3(0,height*.63,0),tip,.085,.025)
		b.foliage(tip+Vector3(0,.65,0),Vector3(1.55,1.15,1.5),seed+branch,LEAVES)
		if willow:
			for strand: int in range(4):
				var start: Vector3=tip+Vector3(cos(angle+strand*.4)*.7,.3,sin(angle+strand*.4)*.7)
				b.pole("72865C",start,start+Vector3(.18,-2.3-posmod(strand+seed,3)*.18,.12),.045,.018,4)
	b.foliage(p+Vector3(0,height+.5,0),Vector3(1.8,1.3,1.8),seed,LEAVES)

func _lamp(b: RefCounted,p: Vector3,side: int) -> void:
	b.pole("344452",p,p+Vector3(0,5.3,0),.085,.055)
	b.pole("344452",p+Vector3(0,5.25,0),p+Vector3(-side*.85,5.55,0),.045)
	b.box("7993A1",p+Vector3(-side*.87,5.52,0),Vector3(.65,.12,.34))
	b.box("F4EAD5",p+Vector3(-side*.87,5.45,0),Vector3(.54,.035,.26))

func _bench(b: RefCounted,p: Vector3,side: int) -> void:
	for slat: int in range(4):b.box("A1744E",p+Vector3((slat-1.5)*.13,.46,0),Vector3(.11,.07,1.9))
	for slat: int in range(3):b.box("C79B62",p+Vector3(side*.29,.69+slat*.14,0),Vector3(.06,.11,1.9))
	for end: float in [-.65,.65]:b.box("344452",p+Vector3(0,.22,end),Vector3(.44,.44,.075))

func _teaching_facade(b: RefCounted,p: Vector3,seed: int) -> void:
	var side: int=1 if p.x>0 else -1
	b.box("C77964",p+Vector3(0,5.5,0),Vector3(16,11,27))
	for floor_index: int in range(3):
		var y: float=1.65+floor_index*3.4
		b.box("E8E0C8",p+Vector3(-side*8.12,y-1.15,0),Vector3(.26,.28,27.3))
		for col: int in range(9):
			var at: Vector3=p+Vector3(-side*8.05,y,-11.7+col*2.9)
			b.box("344452",at,Vector3(.12,2.15,2.06))
			b.box("547F9D" if (col+seed)%3 else "83A7B6",at+Vector3(-side*.08,0,0),Vector3(.05,1.87,1.84))
			b.box("E8E0C8",at+Vector3(-side*.12,0,0),Vector3(.04,1.94,.075))
			b.box("E8E0C8",at+Vector3(-side*.12,.08,0),Vector3(.04,.055,1.88))
	b.box("C5C1A9",p+Vector3(0,11.1,0),Vector3(16.6,.25,27.7))
	# The shallow colonnade echoes the campus' shaded pedestrian edges.
	for n: int in range(10):b.box("E8E0C8",p+Vector3(-side*9.6,1.65,-12+n*2.7),Vector3(.26,3.3,.26))
	b.box("C5C1A9",p+Vector3(-side*9,3.45,0),Vector3(3.2,.2,28))

func _cycle_shelter(b: RefCounted,p: Vector3) -> void:
	for n: int in range(5):
		for x: float in [-1.35,1.35]:b.pole("7993A1",p+Vector3(x,0,n*2),p+Vector3(x,2.5,n*2),.06)
		b.box("83A7B6",p+Vector3(0,2.55,n*2),Vector3(3.3,.09,2))
		b.box("7993A1",p+Vector3(0,2.62,n*2),Vector3(3.4,.055,.06))
	for n: int in range(10):
		var at: Vector3=p+Vector3(.3,0,n*.8)
		b.pole("7993A1",at,at+Vector3(0,.7,0),.035)
		b.pole("7993A1",at+Vector3(0,.7,0),at+Vector3(.65,.7,0),.035)
		b.pole("7993A1",at+Vector3(.65,.7,0),at+Vector3(.65,0,0),.035)

func _construction(b: RefCounted,z: float) -> void:
	# Every work fence stays outside the original rideable lane and footpath.
	b.box("D8C7A0",Vector3(19,-.01,z),Vector3(19,.18,40))
	for n: int in range(10):
		var at: Vector3=Vector3(10,.9,z+18-n*4)
		b.box("7993A1",at,Vector3(.12,1.8,3.9))
		b.box("E8E0C8",at+Vector3(-.08,.64,0),Vector3(.04,.09,3.9))
		b.pole("344452",at+Vector3(0,-.9,-1.9),at+Vector3(0,1,-1.9),.045)
		b.box("D3A451",at+Vector3(-.09,-.4,0),Vector3(.04,.24,.8))
	for n: int in range(4):b.box("A1744E",Vector3(16+n*1.5,.5,z+7-n*4),Vector3(2.6,1,1.3))

func _canteen(b: RefCounted,p: Vector3) -> void:
	b.box("E8E0C8",p+Vector3(0,4.2,0),Vector3(22,8.4,36))
	for level: int in range(2):
		for col: int in range(12):
			var at: Vector3=p+Vector3(11.05,2+level*3.7,-16+col*2.9)
			b.box("547F9D",at,Vector3(.1,2.65,2.62));b.box("C5C1A9",at+Vector3(.08,0,0),Vector3(.06,2.8,.075))
	for n: int in range(10):
		var at: Vector3=p+Vector3(13.3,0,-16+n*3.5)
		b.pole("A9BCC2",at,at+Vector3(0,4.35,0),.12)
		b.box("83A7B6",at+Vector3(-.6,4.45,0),Vector3(4,.09,3.45))
		b.box("7993A1",at+Vector3(-.6,4.55,0),Vector3(4.1,.08,.075))
	b.box("C5C1A9",p+Vector3(0,8.55,0),Vector3(23,.3,37))

func _theater(b: RefCounted,p: Vector3) -> void:
	# A broad low auditorium, glazed foyer and shallow layered entrance canopy.
	# White roof ribs derive from campus motifs, not a claim of surveyed replication.
	b.box("E8E0C8",p+Vector3(0,6,-5),Vector3(32,12,22))
	b.box("344452",p+Vector3(0,4.9,6.1),Vector3(28,9.6,.25))
	for col: int in range(16):
		var x: float=-13.1+col*1.75
		var entrance: bool=absf(x)<2.5
		b.box("547F9D" if col%3 else "83A7B6",p+Vector3(x,6.25 if entrance else 5,6.3),Vector3(1.62,6 if entrance else 8.5,.09))
		b.box("C5C1A9",p+Vector3(x-.86,6.25 if entrance else 5,6.4),Vector3(.075,6 if entrance else 9,.1))
	for floor_y: float in [2.8,5.9,9.2]:b.box("C5C1A9",p+Vector3(0,floor_y,6.45),Vector3(28,.08,.12))
	for side: int in [-1,1]:
		b.box("C5C1A9",p+Vector3(side*18,3,0),Vector3(7,6,17))
		for rib: int in range(14):
			var x: float=side*(.6+rib*1.16)
			var y: float=12.6+.7*pow(absf(x)/16.0,2)
			b.box("E8E0C8",p+Vector3(x,y,-3),Vector3(1.22,.2,25),Basis(Vector3.FORWARD,side*.06))
		b.box("7993A1",p+Vector3(side*3.4,3.2,7),Vector3(6.5,.15,3))
		for x: float in [-2.2,2.2]:b.box("A9BCC2",p+Vector3(side*3.4+x,1.5,7.4),Vector3(.1,3,.1))
	b.box("C5C1A9",p+Vector3(0,-.03,13),Vector3(42,.09,14))
