import bpy,json,sys,hashlib,math
from pathlib import Path
from mathutils import Vector,Matrix,Euler
from mathutils.bvhtree import BVHTree
src,out=sys.argv[sys.argv.index('--')+1:];data=json.load(open(src));rows=[];trees=[];geometries=[]
surfaces={s['id']:s for s in data.get('supportSurfaces',[])}
for idx,inst in enumerate(data['instances']):
 p=inst.get('sourcePath')
 if not p:
  matches=list(Path('sources/models').glob('*/'+inst['assetId']+'/'+inst['assetId']+'.blend'));assert len(matches)==1;(p,)=matches
 p=Path(p)
 with bpy.data.libraries.load(str(p),link=False) as(a,b):b.objects=a.objects
 objects=[o for o in b.objects if o and o.type=='MESH']
 for o in objects:bpy.context.collection.objects.link(o)
 bpy.context.view_layer.update()
 m=Matrix.Translation(Vector(inst.get('position',[0,0,0])))@Euler(inst.get('rotationEuler',[0,0,0])).to_matrix().to_4x4()@Matrix.Diagonal(Vector((*inst.get('scale',[1,1,1]),1)))
 points=[];faces=[]
 for o in objects:
  o.data.calc_loop_triangles();offset=len(points);points.extend([m@o.matrix_world@v.co for v in o.data.vertices]);faces.extend([tuple(offset+i for i in t.vertices) for t in o.data.loop_triangles])
 lo=[min(p[i] for p in points) for i in range(3)];hi=[max(p[i] for p in points) for i in range(3)]
 surface=surfaces.get(inst.get('supportSurfaceId'));row=dict(instanceId=inst.get('instanceId',str(idx)),assetId=inst['assetId'],sourcePath=str(p),sourceHashMatches=hashlib.sha256(p.read_bytes()).hexdigest()==inst.get('sourceSha256'),bounds=[lo,hi],supportSurfaceId=inst.get('supportSurfaceId'),scale=inst.get('scale',[1,1,1]),materialOverrides=inst.get('materialOverrides',{}))
 if surface:
  row['supportDeltaM']=lo[2]-surface['z'];xy=surface.get('boundsXY')
  if xy and 'photo_bench_contents' in src:xy=[[xy[0][0],xy[1][0]],[xy[0][1],xy[1][1]]]
  row['supportXYOverlap']=not xy or all(hi[i]>=xy[0][i] and lo[i]<=xy[1][i] for i in [0,1])
  row['supportToleranceM']=inst.get('supportToleranceM');row['notes']=inst.get('notes','')
 rows.append(row);geometries.append((points,faces));trees.append(BVHTree.FromPolygons(points,faces,all_triangles=True))
collisions=[]
for i in range(len(rows)):
 for j in range(i+1,len(rows)):
  a,b=rows[i]['bounds'],rows[j]['bounds'];overlap=[min(a[1][k],b[1][k])-max(a[0][k],b[0][k]) for k in range(3)]
  if min(overlap)>.004:
   hit=trees[i].overlap(trees[j])
   strict=[]
   for ti,tj in hit:
    pa,fa=geometries[i];pb,fb=geometries[j];a=[pa[k] for k in fa[ti]];b=[pb[k] for k in fb[tj]]
    na=(a[1]-a[0]).cross(a[2]-a[0]);nb=(b[1]-b[0]).cross(b[2]-b[0])
    if na.length<1e-12 or nb.length<1e-12:continue
    na.normalize();nb.normalize();da=[na.dot(v-a[0]) for v in b];db=[nb.dot(v-b[0]) for v in a]
    if min(da)<-1e-5 and max(da)>1e-5 and min(db)<-1e-5 and max(db)>1e-5:strict.append((ti,tj))
   if strict:collisions.append(dict(a=rows[i]['instanceId'],b=rows[j]['instanceId'],assets=[rows[i]['assetId'],rows[j]['assetId']],bboxOverlapM=overlap,intersectingTrianglePairs=len(strict),rawTouchingTrianglePairs=len(hit),status='Review required: true surface overlap; intentional contacts may be present'))
json.dump(dict(source=src,units=data.get('units'),coordinateSystem=data.get('coordinateSystem'),instances=rows,intersectionCandidates=collisions,method='Exact transformed native mesh vertices; BVH triangle surface overlap after >4mm broad-phase overlap on all axes; both triangles must cross the opposite plane by >0.01mm to exclude coplanar/touch-only support contacts. Not solid containment or physics certification.'),open(out,'w'),indent=2)
