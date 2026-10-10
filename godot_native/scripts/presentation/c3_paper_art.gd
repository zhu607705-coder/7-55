extends RefCounted
## Literal source-generated 64x50 paper and four walking frames from
## CanteenInteriorScene.ensureCanteenTextures / generatePaperRunTexture.
const ORIGIN=Vector2(32,25)

static func pose_transform(point: Vector2, factor: float, angle: float, flip_x: bool=false, axis_scale: Vector2=Vector2.ONE) -> Transform2D:
	return Transform2D(deg_to_rad(angle),Vector2(-factor if flip_x else factor,factor)*axis_scale,0,point)

static func command_color(rgb: String, opacity: float, alpha: float=1.0, tint: Color=Color.WHITE) -> Color:
	# Phaser setTint multiplies RGB; opacity remains source alpha * sprite alpha.
	var color:=Color(rgb,opacity*alpha)
	return Color(color.r*tint.r,color.g*tint.g,color.b*tint.b,color.a)

static func draw(c: CanvasItem, point: Vector2, factor: float, angle: float, frame: int=-1, alpha: float=1.0, flip_x: bool=false, parent_transform: Transform2D=Transform2D.IDENTITY, axis_scale: Vector2=Vector2.ONE, tint: Color=Color.WHITE) -> void:
	# Defense paints in source-world coordinates. Compose the board camera once;
	# entry/pickup callers retain their existing screen-space, unflipped defaults.
	# axis_scale is the source-local X/Y scale; factor also supports the existing
	# uniform screen-space zoom. Defaults preserve every entry/pickup/defense call.
	c.draw_set_transform_matrix(parent_transform*pose_transform(point,factor,angle,flip_x,axis_scale))
	for command: Array in frame_commands(frame):
		var color:=command_color(str(command[2]),float(command[3]),alpha,tint)
		match command[0]:
			"ellipse":
				var r: Array=command[1]
				var ellipse:=PackedVector2Array()
				for i in range(33):
					var a: float=TAU*i/32.0
					ellipse.append(Vector2(r[0]+cos(a)*r[2]/2,r[1]+sin(a)*r[3]/2)-ORIGIN)
				c.draw_colored_polygon(ellipse,color)
			"polygon", "polyline":
				var points:=PackedVector2Array()
				for p: Array in command[1]:points.append(Vector2(p[0],p[1])-ORIGIN)
				if command[0]=="polygon":c.draw_colored_polygon(points,color)
				else:
					points.append(points[0]);c.draw_polyline(points,color,float(command[4]))
			"line":
				var p: Array=command[1]
				c.draw_line(Vector2(p[0][0],p[0][1])-ORIGIN,Vector2(p[1][0],p[1][1])-ORIGIN,color,float(command[4]))
			"rect":
				var r: Array=command[1]
				c.draw_rect(Rect2(Vector2(r[0],r[1])-ORIGIN,Vector2(r[2],r[3])),color)
	c.draw_set_transform_matrix(parent_transform)

## Pure source-pixel commands keep the shared resting art and run cycle
## independently comparable to the original texture generator, without assets.
static func frame_commands(frame: int=-1) -> Array:
	var lift: float=2.0 if frame>=0 and frame%2==0 else 0.0
	var left: float=-5.0 if frame==1 else 4.0 if frame==3 else 0.0
	var right: float=4.0 if frame==1 else -5.0 if frame==3 else 0.0
	var width: float=54.0 if frame<0 else 48.0 if frame%2==0 else 55.0
	var commands: Array=[["ellipse",[32,43 if frame<0 else 45,width,10 if frame<0 else 8],"0d1c2d",0.34 if frame<0 else 0.3]]
	if frame>=0:
		commands.append(["polygon",[[16,36-lift],[24,38-lift],[21+left,47],[14+left,46]],"41535e",1])
		commands.append(["polygon",[[39,34-lift],[48,33-lift],[50+right,44],[43+right,46]],"41535e",1])
	commands.append(["polygon",[[7,9-lift],[48,6-lift],[58,34-lift],[17,46-lift],[5,36-lift]],"60717c",1])
	var outline: Array=[[5,5-lift],[46,2-lift],[55,30-lift],[15,41-lift],[3,32-lift]]
	commands.append(["polygon",outline,"d7e0e3",1])
	commands.append(["polygon",[[5,5-lift],[25,8-lift],[15,41-lift],[3,32-lift]],"f3f6f3",1])
	commands.append(["polygon",[[25,8-lift],[46,2-lift],[55,30-lift],[34,27-lift],[15,41-lift]],"e5ebec",1])
	commands.append(["polygon",[[46,2-lift],[55,30-lift],[41,18-lift]],"c1ced4",1])
	commands.append(["polyline",outline,"4a6371",0.95,2])
	for edge: Array in [[[25,8-lift],[15,41-lift]],[[34,27-lift],[55,30-lift]]]:
		commands.append(["line",edge,"91a4ae",0.88,2])
	if frame<0:
		commands.append(["line",[[41,18],[46,2]],"91a4ae",0.88,2])
		var pixels: Dictionary={"0":["111","101","101","101","111"],"5":["111","100","111","001","111"],"7":["111","001","010","010","010"]}
		for digit in range(4):
			for y in range(5):
				for x in range(3):
					if pixels["0755"[digit]][y][x]=="1":commands.append(["rect",[13+digit*8+x*2,12+y*2,2,2],"236f9d",0.98])
		commands.append(["rect",[13,24,27,2],"58c7ff",0.9]);commands.append(["rect",[13,29,18,2],"58c7ff",0.9])
	else:
		for r: Array in [[13,13-lift,30,3],[13,20-lift,24,2],[13,25-lift,29,2]]:commands.append(["rect",r,"236f9d",0.98])
	for r: Array in ([[44,23,3,3],[48,22,3,3],[45,28,6,2]] if frame<0 else [[45,22-lift,3,3],[49,21-lift,3,3],[46,28-lift,6,2]]):commands.append(["rect",r,"2f86b4" if frame<0 else "58c7ff",0.92])
	return commands
