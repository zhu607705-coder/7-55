extends Control
## Original p13-phone-home.css geometry in the source 424×854 interior.
## Canvas-only decoration; all interaction and progression remain in PhonePages.
const SCALE=424.0/378.0
var tower_open=false
var flower_bloomed=false
func _ready() -> void: mouse_filter=Control.MOUSE_FILTER_IGNORE; queue_redraw()
func box(rect: Rect2, color: Color, border: Color=Color.TRANSPARENT, width: float=2) -> void:
	draw_rect(rect,color)
	if border.a>0: draw_rect(rect,border,false,width)
func polygon(origin: Vector2, extent: Vector2, points: Array, color: Color) -> void:
	var vertices=PackedVector2Array()
	for point in points: vertices.append(origin+Vector2(point[0],point[1])*extent/100.0)
	draw_colored_polygon(vertices,color)
func _draw() -> void:
	draw_set_transform(Vector2(0,-40.0/SCALE),0,Vector2.ONE/SCALE)
	# Warm CSS gradient with the upper-left radial highlight.
	for y in range(40,855,7):
		var color=Color("fff6df").lerp(Color("fff0cc"),sin(float(y)/854*PI)*.8)
		draw_rect(Rect2(0,y,424,7),color)
	for x in range(0,424,12): draw_rect(Rect2(x,40,1,814),Color(.98,.91,.73,.04))
	for y in range(48,854,12): draw_rect(Rect2(0,y,424,1),Color(.98,.91,.73,.05))
	polygon(Vector2(238,210),Vector2(170,58),[[0,45],[12,45],[12,28],[26,28],[26,12],[43,12],[43,28],[60,28],[60,45],[74,45],[74,60],[100,60],[100,100],[0,100]],Color("bbecff",.72))
	polygon(Vector2(360,116),Vector2(70,80),[[0,38],[15,38],[15,20],[36,20],[36,0],[64,0],[64,25],[85,25],[85,42],[100,42],[100,100],[0,100]],Color("bbecff",.72))
	box(Rect2(285,450,120,48),Color("bbecff",.35))
	polygon(Vector2(320,252),Vector2(72,28),[[0,64],[14,64],[14,43],[28,43],[28,24],[52,24],[52,39],[76,39],[76,63],[100,63],[100,100],[0,100]],Color("fff5cf",.9))
	polygon(Vector2(205,502),Vector2(239,210),[[0,38],[8,34],[8,25],[15,25],[15,16],[100,16],[100,100],[0,100]],Color("eddab2",.65*.78))
	for x in range(242,431,58): box(Rect2(x,577,6,135),Color("cdb080",.45*.55))
	box(Rect2(310,408,48,78),Color("b7925d",.36))
	box(Rect2(318,400,48,78),Color("ead1a5"),Color("b99c71"))
	box(Rect2(326,413,30,55),Color("285b6f"),Color("1c4555"))
	box(Rect2(328,415,5,51),Color("3d7891"))
	for i in range(6):
		var y=485+i*18
		var step=PackedVector2Array([Vector2(244,y+46),Vector2(339,y),Vector2(339,y+13),Vector2(244,y+59)])
		draw_colored_polygon(step,Color("c3a078")); draw_line(step[0],step[1],Color("f0d3a6"),2)
	box(Rect2(230,596,132,28),Color("d7bb8d")); box(Rect2(230,596,132,3),Color("f2d8ac"))
	box(Rect2(385,502,14,100),Color("99744d",.85))
	for point in [Vector2(376,418),Vector2(346,456),Vector2(380,496),Vector2(337,514)]: polygon(point,Vector2(54,54),[[24,0],[72,0],[72,20],[96,20],[96,68],[74,68],[74,96],[20,96],[20,72],[0,72],[0,24],[24,24]],Color("86b870",.85))
	for y in range(664,764,4): box(Rect2(0,y,424,4),Color("a8d8cc",.45).lerp(Color("eee2bd",.35),(y-664)/100.0))
	for i in range(3): box(Rect2(0,682+[0,12,28][i],424,1),Color("698b7e",[.24,.18,.1][i]))
	# Source clocktower: right 70, top 116, 66×330; same hit target in builder.
	box(Rect2(298,116,48,62),Color("edd9b7"),Color("d3b98d"))
	box(Rect2(296,107,52,11),Color("ead2a7"),Color("d3b98d"))
	for x in [308,326]: box(Rect2(x,139,7,28),Color("75bdd4"),Color("d3b98d"))
	box(Rect2(303,176,44,268),Color("f0dcb8"),Color("d3b98d"))
	box(Rect2(333,178,12,266),Color("e5c89a"))
	box(Rect2(316,240,11,192),Color("d1ba8e"))
	for y in range(240,432,21): box(Rect2(318,y,7,minf(15,432-y)),Color("77c4db"))
	draw_circle(Vector2(325.5,224.5),14.5,Color("f2dfbd")); draw_arc(Vector2(325.5,224.5),14,0,TAU,40,Color("bda37a"),2)
	box(Rect2(324,215,2,9),Color("bda37a")); draw_line(Vector2(325,224),Vector2(331,230),Color("bda37a"),2)
	if not tower_open:
		draw_circle(Vector2(325,224),8,Color("120e08")); draw_circle(Vector2(325,224),6,Color("241d12")); box(Rect2(322,228,4,12),Color("120e08"))
	# Source lake-side bonsai is a decorative app entry, not an invented label.
	polygon(Vector2(354,558),Vector2(40,30),[[45,0],[60,12],[55,30],[85,22],[92,45],[65,48],[60,60],[40,60],[34,46],[8,50],[14,26],[42,32]],Color("6fae59"))
	polygon(Vector2(358,585),Vector2(32,24),[[0,0],[100,0],[82,100],[18,100]],Color("7c4526"))
	polygon(Vector2(360,587),Vector2(28,20),[[0,0],[100,0],[82,100],[18,100]],Color("b46a3c"))
	if flower_bloomed:
		for petal in [[366,558,"e88a9f"],[380,558,"7fb0e8"],[366,572,"e8a05f"],[352,572,"8fce7c"]]: box(Rect2(petal[0],petal[1],8,8),Color(petal[2]))
		box(Rect2(373,565,8,8),Color("f5c542"))
