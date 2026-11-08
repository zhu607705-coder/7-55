extends Node3D
const O = preload("res://campuses/campus_letter/scripts/objects_3d.gd")
var model: RefCounted
var objects: Dictionary = {}
var targets: Dictionary = {}
var bounds := Vector2(5.5,4.0)
var camera_position := Vector3(8,8.8,11)
var camera_target := Vector3(0,.9,0)
var eye_start := Vector3(0,1.65,4.25)
var eye_target := Vector3(0,1.4,0)
var near_limit:float=-4.0
var far_limit:float=4.35
var wood := O.material("b58a61")
var dark := O.material("234950",.3)
var cream := O.material("e6e0cc")
var brass := O.material("b68c48",.7,.33)
var steel := O.material("b8c5c5",.82,.23)
var water: MeshInstance3D
var sculpture_points: Array[Vector3] = []

func build(state: RefCounted) -> void:
	model=state
	match model.active:
		"library": _library()
		"liuhu": _lake()
		"bridge": _bridge()
		"light": _light()
	sync()

func interactive(n: Node3D, id: String, title: String, center: Vector3, extent: Vector3) -> void:
	O.pick(n,id,center,extent)
	targets[id]={"node":n,"point":center,"title":title}

func ground(width: float = 12, depth: float = 9, exterior: bool = false) -> void:
	O.box(self,"Foundation",Vector3(0,-.21,0),Vector3(width,.4,depth),O.material("a7b4ad"))
	var palette: Array[String] = ["b5b3a4","c1bbab","aeb0a4","b9b6a7"]
	var step_: float = 1.0
	for x in range(int(width)):
		for z in range(int(depth)):
			O.box(self,"Paving_%d_%d"%[x,z],Vector3(x-width/2+.5,.002,z-depth/2+.5),Vector3(.986,.025,.986),O.material(palette[(x*13+z*7)%4]))
	var floor_:=O.node(self,"Ground")
	interactive(floor_,"ground","空地",Vector3(0,-.06,0),Vector3(width,.09,depth))
	if exterior:
		O.box(self,"RearLawn",Vector3(0,-.06,-depth/2-1.2),Vector3(width+2,.18,2.4),O.material("687e58"))
		O.imported(self,"ExistingWillowModel",O.WILLOW,Vector3(-1,0,-depth/2-1),.66)
		var garden:=PlaneMesh.new();garden.size=Vector2(90,90)
		O.mesh(self,"SurroundingGarden",garden,Vector3(0,-.22,0),O.material("647057"))
		for i in range(4):
			O.imported(self,"DistantWillow%d"%i,O.WILLOW,Vector3(-16+i*8,-.12,-17-absf(i-1)*2),.7+float(i%2)*.14,float(i)*1.3)

func room(title: String) -> void:
	ground()
	var shell:=O.node(self,"RoomShell")
	O.box(shell,"EastWall",Vector3(6,1.7,0),Vector3(.18,3.4,9),cream)
	O.box(shell,"Ceiling",Vector3(0,3.5,0),Vector3(12,.16,9),O.material("d5d3cb"))
	O.box(shell,"SouthWallLeft",Vector3(-2,1.7,4.55),Vector3(8,3.4,.18),cream)
	O.box(shell,"SouthWallRight",Vector3(5.2,1.7,4.55),Vector3(1.6,3.4,.18),cream)
	O.box(shell,"EntranceLintel",Vector3(3.2,3.0,4.55),Vector3(2.4,.8,.18),cream)
	for x:float in [-3,2.5]:
		O.box(shell,"LinearLightHousing",Vector3(x,3.38,0),Vector3(.16,.07,3.4),dark)
		var diffuser:=O.material("e0ded2");diffuser.emission_enabled=true;diffuser.emission=Color("c0b6a0");diffuser.emission_energy_multiplier=.25
		O.box(shell,"CeilingDiffuser",Vector3(x,3.33,0),Vector3(.11,.025,3.32),diffuser)
		var fill:=OmniLight3D.new();fill.name="CeilingBounce";shell.add_child(fill);fill.position=Vector3(x,2.8,0);fill.omni_range=7;fill.light_energy=.16;fill.light_color=Color("fff8eb")
	O.box(self,"WestWall",Vector3(-6,1.7,0),Vector3(.18,3.4,9),cream)
	O.box(self,"NorthWall",Vector3(0,.55,-4.5),Vector3(12,1.1,.2),cream)
	O.box(self,"NorthLintel",Vector3(0,3.25,-4.5),Vector3(12,.35,.2),cream)
	for x: float in [-5.8,-3.0,0,3.0,5.8]:
		O.box(self,"WindowMullion",Vector3(x,2.05,-4.46),Vector3(.10,2.3,.17),dark)
	for y: float in [1.1,2.1,3.1]: O.box(self,"WindowRail",Vector3(0,y,-4.46),Vector3(11.7,.055,.15),dark)
	var glass:=O.material("a4cccf",.18,.2);glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glass.albedo_color.a=.24
	O.box(self,"WindowGlass",Vector3(0,2.05,-4.51),Vector3(11.8,2,.045),glass)
	O.box(self,"GardenOutside",Vector3(0,-.18,-6.7),Vector3(14,.25,4),O.material("6f8b60"))
	O.imported(self,"WillowOutsideWindow",O.WILLOW,Vector3(0,-.03,-7.2),.65)
	for i in [-1,1]:O.imported(self,"GardenTree%d"%i,O.WILLOW,Vector3(i*6.0,-.03,-9.5),.74,float(i)*.8)
	O.box(self,"OakWallSkirting",Vector3(-5.85,.45,0),Vector3(.10,.9,8.8),wood)
	var sign:=O.label(self,"RoomSign",title,Vector3(-5.72,2.55,-.2),46);sign.rotation.y=PI/2
	for z: float in [-3.3,2.7]:
		O.box(self,"WallLightBack",Vector3(-5.8,2.15,z),Vector3(.12,.6,.15),brass)
		var glow:=O.material("fff1cf");glow.emission_enabled=true;glow.emission=Color("ffdd9d")
		O.box(self,"WallLightDiffuser",Vector3(-5.72,2.15,z),Vector3(.1,.48,.1),glow)

func _bookcase(pos: Vector3, index: int) -> void:
	var n:=O.node(self,"Bookcase%d"%index,pos)
	for x: float in [-.95,.95]: O.box(n,"Side",Vector3(x,1.3,0),Vector3(.08,2.6,.6),wood)
	O.box(n,"Back",Vector3(0,1.3,-.28),Vector3(1.95,2.6,.055),O.material("795f4a"))
	var colors: Array[String]=["344f61","9c7155","899b8c","d9c7a6","645b58","92665a"]
	for shelf in range(5):
		O.box(n,"Shelf%d"%shelf,Vector3(0,.12+shelf*.5,0),Vector3(2,.055,.65),wood)
		for i in range(12):
			var h: float=.3+((i*7+shelf*3)%5)*.024
			var book:=O.node(n,"Book_%d_%d"%[shelf,i],Vector3(-.83+i*.145,.15+shelf*.5+h/2,0))
			O.box(book,"Cover",Vector3.ZERO,Vector3(.117,h,.43),O.material(colors[(i+shelf)%6]))
			O.box(book,"SpineBand",Vector3(0,-h*.24,.219),Vector3(.103,.018,.006),cream)

func _library() -> void:
	room("图书馆  /  静阅区")
	eye_start=Vector3(3.4,1.65,4.35);eye_target=Vector3(3.35,.98,1.5)
	camera_position=Vector3(8.5,9.2,12.4);camera_target=Vector3(0,.7,0)
	for i in range(3): _bookcase(Vector3(-3.5+i*2.5,0,-3.7),i)
	for i in range(4):
		var x: float=-3.45+i*2.25
		var desk:=O.node(self,"StudyDesk%d"%i,Vector3(x,0,.4))
		O.imported(desk,"DetailedStudyDesk",O.DESK,Vector3.ZERO)
		var solid:=StaticBody3D.new();desk.add_child(solid);var shape:=CollisionShape3D.new();var block:=BoxShape3D.new();block.size=Vector3(1.9,.83,1.28);shape.shape=block;shape.position.y=.415;solid.add_child(shape)
		var chair:=O.imported(self,"ExistingChair%d"%i,O.CHAIR,Vector3(x,0,1.62),1,0)
		interactive(chair,"seat%d"%i,["021 · 已预约","022 · 暂离","023 · 使用中","024 · 可预约"][i],Vector3(0,.55,0),Vector3(.78,1.2,.85))
		O.box(desk,"SeatMarker",Vector3(.56,.94,-.36),Vector3(.55,.17,.035),dark)
		objects["status%d"%i]=O.label(desk,"SeatState",["021 · 已预约","022 · 暂离","023 · 使用中","024 · 可预约"][i],Vector3(.56,.96,-.335),17,"ffffff")
		interactive(desk,"status%d"%i,["021 · 已预约","022 · 暂离","023 · 使用中","024 · 可预约"][i],Vector3(.5,1.03,-.34),Vector3(.7,.35,.3))
		O.imported(desk,"BoundReadingBook",O.BOOK,Vector3(-.4,.874,.14),1,float(i)*.045)
		O.imported(desk,"ArticulatedReadingLamp",O.READING_LAMP,Vector3(-.65,.873,-.4))
		var reading_light:=SpotLight3D.new();desk.add_child(reading_light);reading_light.position=Vector3(-.48,1.27,-.4);reading_light.rotation_degrees.x=-80;reading_light.light_color=Color("fff1d7");reading_light.light_energy=.22;reading_light.spot_range=1.1;reading_light.spot_angle=42
	var terminal:=O.node(self,"ReservationTerminal",Vector3(4.5,0,3.1))
	O.box(terminal,"Plinth",Vector3(0,.55,0),Vector3(.8,1.1,.6),dark)
	O.box(terminal,"ScreenHousing",Vector3(0,1.25,-.04),Vector3(1.05,.56,.11),dark).rotation.x=-.18
	O.box(terminal,"Screen",Vector3(0,1.25,.021),Vector3(.96,.47,.012),O.material("deeee4"))
	objects.terminal=O.label(terminal,"ScreenText","预约座位\n024  可预约",Vector3(0,1.25,.034),26)
	interactive(terminal,"terminal","预约终端",Vector3(0,1.22,0),Vector3(1.1,.7,.32))
	var scanner:=O.node(self,"CardScanner",Vector3(4.05,.8,2.15))
	O.box(scanner,"ScannerStand",Vector3(0,-.4,0),Vector3(.6,.8,.6),wood)
	O.box(scanner,"ScannerPad",Vector3.ZERO,Vector3(.48,.06,.37),dark)
	O.ring(scanner,"NFCContact",Vector3(0,.035,0),.115,.008,brass)
	interactive(scanner,"scanner","签到感应区",Vector3(0,.08,0),Vector3(.7,.3,.6))
	O.box(self,"CardCounter",Vector3(2.4,.45,3.0),Vector3(.8,.9,.7),wood)
	var card:=O.node(self,"CampusCard",Vector3(2.4,.93,3.0))
	O.box(card,"CardBody",Vector3.ZERO,Vector3(.18,.006,.11),O.material("366f78"))
	var text_:=O.label(card,"CardPrint","校园卡",Vector3(0,.02,0),24,"ffffff");text_.rotation.x=-PI/2
	interactive(card,"card","校园卡 · 拖到感应区",Vector3.ZERO,Vector3(.34,.16,.26));objects.card=card
	objects.card_origin=card.position

func _bridge() -> void:
	room("工程实践  /  纸桥实验")
	eye_start=Vector3(0,1.65,2.6);eye_target=Vector3(0,1.16,0)
	camera_position=Vector3(6.4,7.1,9.2);camera_target=Vector3(0,1,0)
	var assembly_start:int=get_child_count()
	O.imported(self,"DetailedWorktable",O.TABLE,Vector3(0,0,.2),1.0)
	# The existing table is 1.25 × .60 × 1 metres, scaled uniformly for the apparatus.
	O.pick(self,"worktable_surface",Vector3(0,2.025,.2),Vector3(3.9,.1,2.1)).collision_layer=1
	for i in range(2):
		var support:=O.node(self,"IndependentSupport%d"%i,Vector3(-1.4 if i==0 else 1.4,2.08,.1))
		O.imported(support,"DetailedSupport",O.SUPPORT,Vector3.ZERO)
		interactive(support,"left" if i==0 else "right","支点 · 沿桌面拖动",Vector3(0,.25,.12),Vector3(.42,.65,1.15))
		objects["left" if i==0 else "right"]=support
	objects.paper=O.node(self,"PaperBridge",Vector3(0,2.565,.1))
	interactive(objects.paper,"paper","纸桥 · 点击折边",Vector3.ZERO,Vector3(3.4,.20,.75))
	for i in range(3):
		var w:=O.node(self,"Weight%d"%i,Vector3(-2.6+i*.5,1.84,1.8))
		O.imported(w,"MachinedWeight",O.WEIGHT,Vector3.ZERO)
		interactive(w,"weight%d"%i,"砝码 · 拖到纸桥",Vector3(0,.2,0),Vector3(.45,.5,.45));objects["weight%d"%i]=w
		objects["weight_origin%d"%i]=w.position
	O.box(self,"WeightRack",Vector3(-2.1,.90,1.8),Vector3(1.8,1.8,.8),wood)
	var hook:=O.node(self,"ResetTray",Vector3(1.9,1.1,2.6));O.box(hook,"Tray",Vector3.ZERO,Vector3(.8,.08,.6),dark)
	O.box(self,"TrayStand",Vector3(1.9,.55,2.6),Vector3(.7,1.05,.5),wood)
	interactive(hook,"unload","收回砝码",Vector3(0,.1,0),Vector3(.85,.25,.65))
	O.label(hook,"TrayLabel","取回砝码",Vector3(0,.18,.32),24)
	O.envelope(self,Vector3(1.2,2.09,-.3))
	var assembly:=Node3D.new();assembly.name="TabletopApparatus"
	var parts:Array[Node]=get_children().slice(assembly_start)
	add_child(assembly)
	for part:Node in parts:part.reparent(assembly,false)
	assembly.scale=Vector3.ONE*.55
	for i in range(2):
		O.imported(self,"ExistingSideChair%d"%i,O.CHAIR,Vector3(-3.7+i*7.2,0,-.1),1,PI/2 if i==0 else -PI/2)
	O.bench(self,Vector3(1.8,0,-3.4))
	var board:=O.node(self,"PhysicalLabBoard",Vector3(-3.5,1.6,-3.6))
	O.box(board,"Frame",Vector3.ZERO,Vector3(3.2,1.75,.12),wood)
	O.box(board,"Board",Vector3(0,0,.07),Vector3(3.05,1.6,.04),dark)
	O.label(board,"Title","一张纸，三枚砝码",Vector3(0,.48,.11),36,"f1e8d5")
	O.label(board,"Clue","折起两侧  ·  缩短跨度\n观察形变，再增加载荷",Vector3(0,-.12,.11),26,"f1e8d5")

func _rebuild_paper() -> void:
	var root: Node3D=objects.paper
	for n in root.get_children():
		if n is MeshInstance3D: n.free()
	var left_: float=(model.data.left-480.0)/180.0
	var right_: float=(model.data.right-480.0)/180.0
	var deflect: float=minf(model.bridge_metrics().deflection*.008,.62)
	var paper_mat:=O.material("f5eedb");paper_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(32):
		var x1: float=lerpf(-1.75,1.75,i/32.0);var x2: float=lerpf(-1.75,1.75,(i+1)/32.0)
		var y1: float=-deflect*maxf(0,sin(PI*clampf((x1-left_)/(right_-left_),0,1)))
		var y2: float=-deflect*maxf(0,sin(PI*clampf((x2-left_)/(right_-left_),0,1)))
		for v: Vector3 in [Vector3(x1,y1,-.35),Vector3(x2,y2,.35),Vector3(x2,y2,-.35),Vector3(x1,y1,-.35),Vector3(x1,y1,.35),Vector3(x2,y2,.35)]: st.add_vertex(v)
		if model.data.folded:
			for z: float in [-.35,.35]:
				for v: Vector3 in [Vector3(x1,y1,z),Vector3(x2,y2+.12,z),Vector3(x2,y2,z),Vector3(x1,y1,z),Vector3(x1,y1+.12,z),Vector3(x2,y2+.12,z)]:st.add_vertex(v)
	st.generate_normals();O.mesh(root,"FoldedSheet" if model.data.folded else "FlatSheet",st.commit(),Vector3.ZERO,paper_mat)

func _lake() -> void:
	eye_start=Vector3(.9,1.65,4.35);eye_target=Vector3(.9,1.15,-1.0);near_limit=1.1
	camera_position=Vector3(9.4,8.2,12);camera_target=Vector3(0,.5,-.5)
	ground(13,10,true)
	O.box(self,"LakeBasin",Vector3(0,.05,-2.2),Vector3(10,.18,5.4),O.material("255c64"))
	var shader:=Shader.new();shader.code="""shader_type spatial;
uniform vec4 water_color : source_color = vec4(0.15,0.42,0.46,1.0);
void fragment(){float ripple=sin(UV.x*100.0+TIME*.8)*sin(UV.y*90.0-TIME*.4); ALBEDO=water_color.rgb+vec3(ripple*.012);ROUGHNESS=.27;METALLIC=.42;}
"""
	var wm:=ShaderMaterial.new();wm.shader=shader
	water=O.box(self,"WaterSurface",Vector3(0,.17,-2.2),Vector3(9.9,.035,5.25),wm)
	for x: float in [-5.15,5.15]:O.box(self,"LakeCoping",Vector3(x,.28,-2.2),Vector3(.3,.35,5.7),cream)
	O.box(self,"NearBank",Vector3(0,.25,.55),Vector3(10.6,.3,.35),cream)
	for x: float in [-4.7,-2.4,0,2.4,4.7]:
		O.cylinder(self,"RailingPost",Vector3(x,.79,.62),.04,1.05,dark)
	for y: float in [.75,1.27]:O.rod(self,"BankRailing",Vector3(-4.7,y,.62),Vector3(4.7,y,.62),.033,dark)
	O.imported(self,"ExistingGlassCanopy",O.CANOPY,Vector3(6.5,0,-8.4),.8)
	O.bench(self,Vector3(-4,0,2.8),PI/2)
	# Three physical survey poles and independent floating observation markers.
	for i in range(3):
		var x: float=-3+i*3.0;var z: float=-2.6-absf(i-1)*.4
		var pole:=O.node(self,"SurveyPole%d"%i,Vector3(x,.18,z))
		O.cylinder(pole,"FloatingFoot",Vector3(0,.05,0),.25,.1,dark)
		O.cylinder(pole,"Pole",Vector3(0,.6,0),.025,1.2,brass)
		O.ball(pole,"SurveyTarget",Vector3(0,1.2,0),.12,O.material("e1b263",.5))
		O.label(pole,"Number",str(i+1),Vector3(0,1.55,0),34,"f2e5c6")
		var marker:=O.node(self,"ObservationRing%d"%i,Vector3(x,.24,z+1.2))
		O.ring(marker,"FloatingRing",Vector3.ZERO,.28,.023,brass)
		O.cylinder(marker,"ReflectionPoint",Vector3.ZERO,.06,.012,cream)
		interactive(marker,"record%d"%i,"记录巡护点 %d"%(i+1),Vector3(0,.06,0),Vector3(.85,.3,.85));objects["record%d"%i]=marker;objects["record_origin%d"%i]=marker.position
		O.ring(self,"ReferenceReflection%d"%i,marker.position+Vector3(0,-.018,0),.34,.012,O.material("d5e3d2"))
	var station:=O.node(self,"ObservationStation",Vector3(1.1,0,2.6))
	for x: float in [-.9,.9]:O.box(station,"StationLeg",Vector3(x,.55,0),Vector3(.12,1.1,.55),dark)
	O.box(station,"StationTop",Vector3(0,1.12,0),Vector3(2.2,.10,1.0),wood)
	O.box(station,"ObservationLog",Vector3(-.65,1.19,.2),Vector3(.55,.04,.44),cream)
	var log_text:=O.label(station,"LogText","巡护记录",Vector3(-.65,1.22,.2),22);log_text.rotation.x=-PI/2
	for i in range(2):
		var dial:=O.node(station,"SurveyWheel%d"%i,Vector3(.05+i*.65,1.45,0))
		O.cylinder(dial,"WheelPedestal",Vector3(0,-.18,0),.06,.35,dark)
		objects["wheel%d"%i]=O.imported(dial,"DetailedSurveyWheel",O.WHEEL,Vector3.ZERO)
		var indicator:=O.box(dial,"Needle",Vector3(0,.18,.04),Vector3(.025,.12,.035),cream);objects["needle%d"%i]=indicator
		interactive(dial,"horizontal" if i==0 else "vertical","方向轮 · 拖动" if i==0 else "俯仰轮 · 拖动",Vector3.ZERO,Vector3(.6,.6,.3));objects["dial%d"%i]=dial
	O.label(station,"WheelLabels","方向        俯仰",Vector3(.39,1.12,.53),25)

func _light() -> void:
	eye_start=Vector3(-1.1,1.65,6.2);eye_target=Vector3(-.2,1.20,-.5);far_limit=6.4
	camera_position=Vector3(8.4,6.8,11.8);camera_target=Vector3(0,1.25,-.6)
	ground(13,14,true)
	O.imported(self,"ExistingCampusCanopy",O.CANOPY,Vector3(7.5,0,-9.4),.85)
	var wall:=O.node(self,"ProjectionWall",Vector3(0,0,-3.55))
	O.box(wall,"StoneWall",Vector3(0,2.05,0),Vector3(6.6,4.1,.23),O.material("c1c0b4")).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	O.box(wall,"WallCap",Vector3(0,4.12,0),Vector3(6.8,.10,.35),cream)
	O.label(wall,"Caption","母校之光",Vector3(-2.05,3.55,.14),42)
	O.label(wall,"Subcaption","光落成形",Vector3(0,.34,.14),22)
	var plinth:=O.node(self,"SculpturePlinth",Vector3(0,0,-.8))
	O.cylinder(plinth,"TravertineBase",Vector3(0,.23,0),.82,.46,O.material("d1c9b6"))
	O.cylinder(plinth,"BronzeFoot",Vector3(0,.49,0),.57,.07,brass)
	var sculpture:=O.node(self,"IndependentLightSculpture",Vector3(0,.52,-.8))
	O.imported(sculpture,"DetailedCastHands",O.HANDS,Vector3.ZERO)
	O.rod(sculpture,"LeftCradle",Vector3(-.22,.73,.02),Vector3(.183,.88,.305),.028,steel)
	O.rod(sculpture,"RightCradle",Vector3(.3,.73,.03),Vector3(.183,.88,.305),.028,steel)
	for i in range(9):
		var t: float=i/8.0;var p:=Vector3(sin(t*TAU+.3)*.62,.88+t*1.45,cos(t*TAU+.3)*.32)
		sculpture_points.append(p+sculpture.position)
		O.ball(sculpture,"MoleculeAtom%02d"%i,p,.12 if i%2==0 else .09,steel)
		if i>0: O.rod(sculpture,"MoleculeBond%02d"%i,sculpture_points[i-1]-sculpture.position,p,.025,steel)
		if i>2: O.rod(sculpture,"CrossBond%02d"%i,sculpture_points[i-3]-sculpture.position,p,.019,steel)
	# The wall engraving is the same 3D structure projected from the target lamp location.
	var ideal:=Vector3(0,1.18,3.4);var projected: Array[Vector3]=[]
	for p: Vector3 in sculpture_points:
		var q:=ideal+(p-ideal)*((-3.417-ideal.z)/(p.z-ideal.z));projected.append(q)
		var r:=O.ring(self,"EngravedAtom",q,.14,.008,brass);r.rotation.x=PI/2;r.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in range(1,projected.size()):
		var line:=O.rod(self,"EngravedBond",projected[i-1],projected[i],.006,brass);line.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	O.rod(self,"LampRail",Vector3(-3,.04,3.4),Vector3(1.5,.04,3.4),.035,dark)
	for x: float in [-3,-2,-1,0,1]:
		O.box(self,"RailTick",Vector3(x,.06,3.4),Vector3(.025,.025,.20),brass)
	objects.lamp=O.lamp(self,Vector3(-2.28,0,3.4))
	interactive(objects.lamp,"lamp","灯座 · 沿轨道拖动",Vector3(0,.65,0),Vector3(.6,1.45,.6))
	var spot:=SpotLight3D.new();spot.name="SculptureLight";spot.light_color=Color("fff3df");spot.light_energy=.85;spot.spot_range=12;spot.spot_angle=34;spot.shadow_enabled=true;spot.shadow_bias=.12;spot.shadow_normal_bias=1.0
	objects.lamp.add_child(spot);spot.position=Vector3(0,1.18,-.24);objects.spot=spot
	objects.mailbox=O.imported(self,"CampusLetterBox",O.LETTER_BOX,Vector3(-2,0,2.8))
	interactive(objects.mailbox,"mailbox","投入来信",Vector3(0,1.19,.24),Vector3(.68,.25,.30))
	var flaps:Array[Node]=objects.mailbox.find_children("MailSlotFlap","Node3D",true,false)
	if not flaps.is_empty():objects.mail_flap=flaps[0]
	O.box(self,"LetterPedestal",Vector3(-4,.45,2.7),Vector3(.75,.9,.65),wood)
	objects.letter=O.envelope(self,Vector3(-4,.935,2.7));interactive(objects.letter,"letter","来信 · 放入信箱",Vector3.ZERO,Vector3(.65,.32,.55));objects.letter_origin=objects.letter.position
	O.bench(self,Vector3(2.5,0,3.0))
	for x: float in [-3.18,-2.88]:
		var footprint:=O.cylinder(self,"WaitingFootprint",Vector3(x,.025,3.3),.105,.012,brass);footprint.scale.z=1.9
	O.label(self,"WaitingLabel","等候处",Vector3(-3.0,.04,3.8),26).rotation.x=-PI/2

func sync() -> void:
	match model.active:
		"library":
			if model.data.stage>=2:objects.card.position=Vector3(4.05,.855,2.15)
		"bridge":
			objects.left.position.x=(model.data.left-480.0)/180.0;objects.right.position.x=(model.data.right-480.0)/180.0
			_rebuild_paper()
			for i in range(3):
				var slot:int=model.data.placed.find(i)
				objects["weight%d"%i].position=Vector3(-.46+slot*.46,2.565-minf(model.bridge_metrics().deflection*.008,.62),.1) if slot>=0 else objects["weight_origin%d"%i]
		"liuhu":
			for i in range(3):
				var n: Node3D=objects["record%d"%i];n.position=objects["record_origin%d"%i]+Vector3(model.data.offset*.008,0,model.data.tilt*.012)
				n.get_child(0).material_override=O.material("b7e3ca",.3) if i in model.data.records else brass
			objects.wheel0.rotation.z=-model.data.offset*.01;objects.wheel1.rotation.z=-model.data.tilt*.015
		"light":
			objects.lamp.position.x=(model.data.lamp-440.0)/90.0
			objects.spot.look_at(Vector3(0,1.8,-.8),Vector3.UP)
			if objects.has("mail_flap"):
				objects.mail_flap.rotation.x=-.95 if model.light_aligned() and model.light_clear() else 0.0
			if model.data.delivered:
				objects.letter.global_position=objects.mailbox.to_global(Vector3(0,1.19,.13));objects.letter.rotation=Vector3.ZERO

func point(id: String) -> Vector3:
	var t: Dictionary=targets[id]
	return t.node.to_global(t.point)
