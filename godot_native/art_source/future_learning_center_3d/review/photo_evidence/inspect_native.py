# Independent read-only inspection; never save Blender input.
import bpy,json,sys,math
from mathutils import Vector
out=sys.argv[sys.argv.index('--')+1]
objects=[]
for o in bpy.context.scene.objects:
 if o.type!='MESH':continue
 o.data.calc_loop_triangles()
 pts=[o.matrix_world@v.co for v in o.data.vertices]
 objects.append(dict(name=o.name,vertices=len(pts),triangles=len(o.data.loop_triangles),bounds=[[min(p[i] for p in pts) for i in range(3)],[max(p[i] for p in pts) for i in range(3)]],finite=all(math.isfinite(v) for p in pts for v in p),materials=[m.name for m in o.data.materials if m],properties={k:str(o[k]) for k in o.keys()}))
lo=[min(o['bounds'][0][i] for o in objects) for i in range(3)];hi=[max(o['bounds'][1][i] for o in objects) for i in range(3)]
json.dump(dict(blender=bpy.app.version_string,objects=objects,bounds=[lo,hi],triangles=sum(o['triangles'] for o in objects),units=bpy.context.scene.unit_settings.system,scaleLength=bpy.context.scene.unit_settings.scale_length),open(out,'w'),indent=2)
