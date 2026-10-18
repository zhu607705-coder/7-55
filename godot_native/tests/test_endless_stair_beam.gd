extends SceneTree
const Clip = preload("res://scripts/presentation/endless_stair_beam_clipper.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures+=1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func ray(angle: float) -> Vector3:
	return Vector3(cos(angle),sin(angle),0)
# Independent scalar slab-ray check; used only to show the old edge-ray miss
# and sample the returned continuous prefix independently of polygon clipping.
func ray_hit(origin: Vector3,direction: Vector3,maximum: float,box: Dictionary) -> bool:
	var o: Vector3 = box.inverse*origin
	var d: Vector3 = box.inverse.basis*direction.normalized()
	var half: Vector3 = box.half
	var near := 0.0
	var far := maximum
	for axis in 3:
		if absf(d[axis])<.0000001:
			if absf(o[axis])>half[axis]: return false
		else:
			var a: float = (-half[axis]-o[axis])/d[axis]
			var b: float = (half[axis]-o[axis])/d[axis]
			near=maxf(near,minf(a,b)); far=minf(far,maxf(a,b))
			if far<near: return false
	return far>=near
func assert_safe(origin: Vector3,left: Vector3,right: Vector3,length: float,box: Dictionary,label: String) -> void:
	for sample in 101:
		# Convex interpolation samples the actual triangle, not an expanded arc.
		var edge := left.normalized().lerp(right.normalized(),float(sample)/100.0)*length
		check(not ray_hit(origin,edge,edge.length(),box),label+" sample "+str(sample))
func run() -> void:
	var origin := Vector3.ZERO
	var left := ray(deg_to_rad(-.75))
	var right := ray(deg_to_rad(.75))
	var thin := Clip.cache_box(Transform3D(Basis.IDENTITY,Vector3(3,0,0)),Vector3(.01,.01,.12))
	check(not ray_hit(origin,left,4.4,thin) and not ray_hit(origin,right,4.4,thin),"fixture: both old boundary rays miss the intervening 2cm pillar")
	check(ray_hit(origin,Vector3.RIGHT,4.4,thin),"fixture: the pillar intersects triangle interior")
	var reach: float = Clip.wedge_reach(origin,left,right,4.4,thin)
	check(absf(reach-2.978)<.00002,"continuous wedge clips interior pillar at near face minus safety inset")
	assert_safe(origin,left,right,reach,thin,"thin pillar prefix")
	var rotated := Clip.cache_box(Transform3D(Basis(Vector3.UP,.6)*Basis(Vector3.FORWARD,.32),Vector3(2.6,0,0)),Vector3(.04,.35,.4))
	reach=Clip.wedge_reach(origin,ray(-.1),ray(.1),4.4,rotated)
	check(reach>2.0 and reach<2.6,"rotated board clips before its centre")
	assert_safe(origin,ray(-.1),ray(.1),reach,rotated,"rotated board prefix")
	var inside := Clip.cache_box(Transform3D(Basis.IDENTITY,Vector3.ZERO),Vector3(.2,.2,.2))
	check(Clip.wedge_reach(origin,left,right,4.4,inside)==0.0,"source inside box returns zero")
	var miss := Clip.cache_box(Transform3D(Basis.IDENTITY,Vector3(2,2,0)),Vector3(.2,.2,.2))
	check(Clip.wedge_reach(origin,left,right,4.4,miss)==4.4,"off-wedge box preserves full reach")
	var behind := Clip.cache_box(Transform3D(Basis.IDENTITY,Vector3(-2,0,0)),Vector3(.2,.2,.2))
	check(Clip.wedge_reach(origin,left,right,4.4,behind)==4.4,"box behind emitter preserves full reach")
	var distant := Clip.cache_box(Transform3D(Basis.IDENTITY,Vector3(8,0,0)),Vector3(.2,.2,.2))
	check(Clip.wedge_reach(origin,left,right,4.4,distant)==4.4,"box beyond radius preserves full reach")
	var scaled := Clip.cache_box(Transform3D(Basis.IDENTITY.scaled(Vector3(2,.5,3)),Vector3(3,0,0)),Vector3(.1,.1,.1))
	reach=Clip.wedge_reach(origin,left,right,4.4,scaled)
	check(absf(reach-2.788)<.00003,"nonuniform scaling preserves world-space safety distance")
	assert_safe(origin,left,right,reach,scaled,"scaled box prefix")
	check(is_equal_approx(Clip.all_boxes_reach(origin,left,right,4.4,[distant,thin,scaled]),reach),"multiple boxes choose nearest conservative prefix")
	check(Clip.wedge_reach(origin,Vector3.ZERO,right,4.4,thin)==0.0,"degenerate direction safely returns zero")
	check(Clip.wedge_reach(origin,left,right,0.0,thin)==0.0,"zero range stays zero")
	check(Clip.wedge_reach(origin,Vector3.RIGHT,Vector3.RIGHT,4.4,thin)<3.0,"degenerate line wedge still clips")
	var rng := RandomNumberGenerator.new()
	rng.seed = 755106
	for trial in 80:
		var basis := Basis.from_euler(Vector3(rng.randf_range(-.8,.8),rng.randf_range(-.8,.8),rng.randf_range(-.8,.8)))
		basis = basis.scaled(Vector3(rng.randf_range(.5,2),rng.randf_range(.5,2),rng.randf_range(.5,2)))
		var at := Vector3(rng.randf_range(.5,4),rng.randf_range(-.4,.4),rng.randf_range(-.15,.15))
		var box := Clip.cache_box(Transform3D(basis,at),Vector3(rng.randf_range(.015,.25),rng.randf_range(.015,.25),rng.randf_range(.1,.4)))
		reach=Clip.wedge_reach(origin,ray(-.15),ray(.15),4.4,box)
		check(reach>=0 and reach<=4.4,"random reach bounds "+str(trial))
		assert_safe(origin,ray(-.15),ray(.15),reach,box,"random "+str(trial))
	print("BEAM_WEDGE_CLIP: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
