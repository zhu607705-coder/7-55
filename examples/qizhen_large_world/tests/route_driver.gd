extends RefCounted
## Test-only controller. Sends the same four input channels as a player.
## It never sets position, heading, speed, elapsed, or goal completion.
const Geo=preload("res://scripts/games/lake_geometry.gd")
var nav: AStarGrid2D
var path: PackedVector2Array=PackedVector2Array()
var phase: int=-1
var i: int=0
var throttle: bool=false
var turn: float=0
var brake: bool=false
var use: bool=false
func _init() -> void:
	nav=AStarGrid2D.new();nav.region=Rect2i(0,0,225,400);nav.cell_size=Vector2(40,40);nav.offset=Vector2(20,20);nav.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;nav.update()
	for x in range(225):
		for y in range(400):nav.set_point_solid(Vector2i(x,y),not Geo.water(Vector2(x*40+20,y*40+20),54))
func control(game: RefCounted) -> void:
	var goal: Dictionary=Geo.goals()[game.progress]
	if game.progress!=phase:
		phase=game.progress;i=0
		var from: Vector2i=Vector2i((game.position-Vector2(20,20))/40)
		var dest: Vector2i=Vector2i((goal.point-Vector2(20,20))/40)
		path=nav.get_point_path(from,dest)
		if path.is_empty():push_error("No navigable test path for phase "+str(phase))
	var target: Vector2=goal.point
	while i<path.size()-1 and game.position.distance_to(path[i])<120:i+=1
	if i<path.size():target=path[i]
	# Track a point ahead on the valid grid path. Control is still continuous.
	var close: bool=game.position.distance_to(goal.point)<float(goal.radius)*.68
	var doing: bool=goal.type!="gate" and close
	var angle: float=(target-game.position).angle()
	if doing and goal.type=="dock":angle=-PI/2
	var err: float=angle_difference(game.heading,angle)
	turn=clampf(err*2,-1,1)
	throttle=not doing and absf(err)<.65
	brake=doing or absf(err)>.8
	use=doing
	game.input(throttle,turn,brake,use)
