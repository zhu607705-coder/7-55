#!/usr/bin/env python3
"""Compile deterministic independent sources; no new painting or flattened map fallback."""
from pathlib import Path
from PIL import Image, ImageDraw
import json,hashlib,math,base64,zlib,numpy as np
from campus_layer_selection import load_current
ROOT=Path(__file__).resolve().parents[1];SOURCE=ROOT.parent/'art/campus_layered';OUT=ROOT/'assets/native/campus_layered';MANIFEST=ROOT/'data/native/campus_layered_map.json';SIZE=1024

def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def write(im,p):
 p.parent.mkdir(parents=True,exist_ok=True)
 if p.exists():
  with Image.open(p) as previous:
   if previous.mode==im.mode and previous.size==im.size and previous.tobytes()==im.tobytes():return sha(p)
 im.save(p)
 return sha(p)
def rel(p):return 'res://'+p.relative_to(ROOT).as_posix()

def route_grid(result, roads):
 """Candidate centers for the 16 × 10 campus foot box. Runtime still checks every route edge."""
 half_width,half_height=8,5
 width,height=result['worldSize']
 source_path=ROOT.parent/'src/data/maps/zijingang-campus-runtime.json'
 source=json.loads(source_path.read_text(encoding='utf-8'))['walkability']
 cell=source['cellSize']
 count=source['gridWidth']*source['gridHeight']
 original=np.unpackbits(np.frombuffer(base64.b64decode(source['bitsBase64']),dtype=np.uint8),bitorder='little',count=count)
 support=np.repeat(np.repeat(original.reshape(source['gridHeight'],source['gridWidth']),cell,axis=0),cell,axis=1).astype(bool)
 assert support.shape==(height,width)
 rows=result['navigation'].get('walkSupportSources',[])
 for row in rows:
  if 'sourceFloorOverrideRect' in row:
   x,y,w,h=row['sourceFloorOverrideRect']
   support[y:y+h,x:x+w]=False
 for row in rows:
  x,y=row['origin']; mask=np.asarray(Image.open(SOURCE/row['source']))!=0
  h,w=mask.shape
  assert 0<=x<=width-w and 0<=y<=height-h, row['id']
  support[y:y+h,x:x+w]|=mask
 solid=Image.new('1',(width,height)); painter=ImageDraw.Draw(solid)
 for row in result['navigation'].get('footprints',[]):
  painter.polygon([tuple(p) for p in row['polygon']],fill=1)
 for row in result['waterRegions']:
  x,y=row['origin']
  for l,t,w,h in row['rectsNative']:
   painter.rectangle((x+l,y+t,x+l+w-1,y+t+h-1),fill=1)
 support&=~np.asarray(solid)
 # Integral image counts unsupported pixels inside the exact foot size.
 # With 4px spacing, the four orthogonal neighbors also cover diagonal sweeps.
 step=4
 xs=np.arange(step//2,width,step);ys=np.arange(step//2,height,step)
 sums=np.zeros((height+1,width+1),dtype=np.int32)
 sums[1:,1:]=np.cumsum(np.cumsum(~support,axis=0,dtype=np.int32),axis=1,dtype=np.int32)
 left=np.maximum(0,xs-half_width);right=np.minimum(width,xs+half_width)
 top=np.maximum(0,ys-half_height);bottom=np.minimum(height,ys+half_height)
 count_blocked=sums[np.ix_(bottom,right)]-sums[np.ix_(top,right)]-sums[np.ix_(bottom,left)]+sums[np.ix_(top,left)]
 valid=(count_blocked==0)&((right-left)==2*half_width)&(((bottom-top)==2*half_height)[:,None])
 terrain=np.where(valid,1+roads[np.ix_(ys,xs)],0).astype(np.uint8)
 # The original Web route used conservative 24px cells. Keep an equivalent
 # 12px road margin in the fine grid while preserving access to narrow links.
 radius=12//step
 rim=np.pad(terrain!=2,radius,constant_values=True)
 prefix=np.pad(rim,((1,0),(1,0))).cumsum(axis=0,dtype=np.int32).cumsum(axis=1,dtype=np.int32)
 span=2*radius+1
 core_count=prefix[span:,span:]-prefix[:-span,span:]-prefix[span:,:-span]+prefix[:-span,:-span]
 terrain[core_count==0]=3
 return {'cellSize':step,'size':[len(xs),len(ys)],'footSize':[2*half_width,2*half_height],'terrainDeflateBase64':base64.b64encode(zlib.compress(terrain.tobytes(),9)).decode('ascii')}
def validate_semantics(authoring):
 assert authoring.get('semanticLayerVersion')==2, 'Explicit ground/raised semantic version 2 required'
 for row in authoring['layers']:
  stage=row.get('renderPass'); assert stage in ['land','ground','roads','raised'], f"Ambiguous render pass: {row['id']}"
  if stage=='raised':
   assert math.isfinite(float(row.get('baseline',float('inf')))), f"Measured object foot baseline required: {row['id']}"
   assert row.get('depthMode','baseline') in ['baseline','projected_y']
   if row.get('depthMode')=='projected_y':
    if 'depthOriginalOriginY' in row:
     assert float(row.get('depthOriginalScale',0))>0 and all(math.isfinite(float(row.get(k,float('inf')))) for k in ['depthOriginalOriginY','depthOriginalScale','depthOriginalProjection'])
    else: assert math.isfinite(float(row.get('projectionNative',float('inf'))))
  else: assert row.get('pass','ground') not in ['foreground','depth_object'], f"Depth pixels cannot remain in ground: {row['id']}"

def navigation_pixels(water, visual_alpha):
 if 'navigationMask' not in water:
  return visual_alpha>0
 path=SOURCE/water['navigationMask']
 assert water.get('navigationMaskSha256') and sha(path)==water['navigationMaskSha256'], 'Navigation-water mask identity drift'
 mask=Image.open(path)
 assert mask.mode in ['1','L'], 'Navigation-water mask must be an explicit single-channel 0/255 mask'
 assert mask.size==(visual_alpha.shape[1],visual_alpha.shape[0]), 'Navigation-water mask size mismatch'
 pixels=np.array(mask)!=0
 assert not np.any(pixels & (visual_alpha==0)), 'Navigation-water mask must be a subset of visible water'
 return pixels

def build():
 a,s,ss=load_current();validate_semantics(a);result={'format':'755-campus-layered-map-v1','semanticLayerVersion':2,'worldSize':[4516,3420],'coordinateSystem':'unchanged campus_bootstrap; not campus_qizhen_loop','selectionRevision':s['revision'],'selectionSha256':ss,'layers':[],'waterTiles':[],'waterFrames':[],'waterRegions':[],'walkSupports':[],'navigation':a.get('navigation',{}),'limitations':a.get('limitations',[]),'reviewStatus':a.get('reviewStatus'),'layeringPolicy':'grass/land -> masked true water -> ground/shore/paving -> roads -> raised buildings/canopies/gates split around actor by measured foot baseline'}
 keep=set()
 roads=np.zeros(result['worldSize'][::-1],dtype=bool)
 for row in a['layers']:
  src=SOURCE/row['source'];assert sha(src)==row['sourceSha256'];im=Image.open(src).convert('RGBA');assert im.size==tuple(row['nativeSize']);r={k:v for k,v in row.items() if k not in ['source']};r['tiles']=[]
  if row['renderPass']=='roads':
   assert row['scale']==1
   ox,oy=row['origin']
   roads[oy:oy+im.height,ox:ox+im.width]|=np.asarray(im.getchannel('A'))>0
  for y in range(0,im.height,SIZE):
   for x in range(0,im.width,SIZE):
    tile=im.crop((x,y,min(x+SIZE,im.width),min(y+SIZE,im.height)));b=tile.getchannel('A').getbbox()
    if b is None:continue
    tile=tile.crop(b);p=OUT/row['id']/f'{x}_{y}.png';h=write(tile,p);keep.add(p);r['tiles'].append({'path':rel(p),'rect':[x+b[0],y+b[1],tile.width,tile.height],'sha256':h,'decodedSha256':hashlib.sha256(tile.tobytes()).hexdigest()})
  result['layers'].append(r)
 for water in a['waterSources']:
  assert [sha(SOURCE/f) for f in water['frames']]==water['frameSha256'],'Water source identity drift'
  frames=[Image.open(SOURCE/f).convert('RGBA') for f in water['frames']];assert len(frames)==3 and all(im.size==frames[0].size for im in frames);alphas=[np.array(im)[:,:,3] for im in frames];assert all(np.array_equal(alphas[0],x) for x in alphas[1:]);ox,oy=water['origin'];im=frames[0]
  for y in range(0,im.height,SIZE):
   for x in range(0,im.width,SIZE):
    end=(min(x+SIZE,im.width),min(y+SIZE,im.height));b=im.crop((x,y,*end)).getchannel('A').getbbox()
    if b is None:continue
    paths=[]
    for f,frame in enumerate(frames):
     tile=frame.crop((x+b[0],y+b[1],x+b[2],y+b[3]));p=OUT/'masked_water'/water['id']/f'{x}_{y}_{f}.png';write(tile,p);paths.append(rel(p));keep.add(p)
    result['waterTiles'].append({'id':water['id']+f'_{x}_{y}','sourceId':water['id'],'rect':[ox+x+b[0],oy+y+b[1],b[2]-b[0],b[3]-b[1]],'frames':paths,'frameSha256':[sha(ROOT/f.removeprefix('res://')) for f in paths],'animationMode':water['animationMode']})
  if water['animationMode']=='masked_source_rgb_shift' or 'navigationMask' in water:
   m=navigation_pixels(water,alphas[0]);rects=[]
   for y in range(m.shape[0]):
    t=np.diff(np.r_[False,m[y],False].astype('int8'));starts=np.where(t==1)[0];ends=np.where(t==-1)[0];rects.extend([[int(x),y,int(e-x),1] for x,e in zip(starts,ends)])
   b=Image.fromarray((m*255).astype('uint8')).getbbox()
   if b is None:continue
   result['waterRegions'].append({'id':water['id'],'origin':[ox,oy],'scale':1,'nativeSize':list(im.size),'nativeBounds':[b[0],b[1],b[2]-b[0],b[3]-b[1]],'rectsNative':rects,'pixelCount':int(m.sum()),'kind':'explicit_navigation_water' if 'navigationMask' in water else 'exact_visible_source_water','navigationMaskSha256':water.get('navigationMaskSha256'),'scope':'Explicit navigation water excludes reviewed bridge deck; visual water unchanged.' if 'navigationMask' in water else 'Existing visible-water source mask; not inferred hidden hydrology.'})
 for support in a.get('navigation',{}).get('walkSupportSources',[]):
  path=SOURCE/support['source'];expected=support.get('maskSha256',support.get('maskSha'));assert expected and sha(path)==expected,'Walk-support mask identity drift'
  image=Image.open(path);assert image.mode in ['1','L'],'Walk-support requires explicit single-channel mask'
  pixels=np.array(image)!=0;bounds=Image.fromarray((pixels*255).astype('uint8')).getbbox()
  origin=support['origin'];assert len(origin)==2 and all(math.isfinite(float(v)) and float(v)==int(v) for v in origin),'Walk-support origin must be integer world pixels'
  if bounds is None:continue
  packed=np.packbits(pixels.reshape(-1),bitorder='little').tobytes()
  result['walkSupports'].append({'id':support['id'],'origin':origin,'nativeSize':list(image.size),'nativeBounds':[bounds[0],bounds[1],bounds[2]-bounds[0],bounds[3]-bounds[1]],'bitsBase64':base64.b64encode(packed).decode('ascii'),'maskSha256':expected,'pixelCount':int(pixels.sum()),'scope':'Explicit reviewed load-bearing bridge deck/path only; source floor union; water/solid/gates retain priority.'})
  candidates=support.get('routeCandidateFootCenters',[])
  assert isinstance(candidates,list) and len(candidates)<=192, 'Reviewed route candidates must be bounded'
  assert all(isinstance(p,list) and len(p)==2 and all(isinstance(v,(int,float)) and not isinstance(v,bool) and math.isfinite(v) for v in p) and 0<=p[0]<=4516 and 0<=p[1]<=3420 for p in candidates), 'Invalid reviewed route candidate'
  if candidates:result['walkSupports'][-1]['routeCandidateFootCenters']=candidates
  if 'sourceFloorOverrideRect' in support:
   rect=support['sourceFloorOverrideRect'];assert len(rect)==4 and all(isinstance(v,(int,float)) and math.isfinite(v) and float(v)==int(v) for v in rect) and rect[2]>0 and rect[3]>0
   assert rect[0]>=0 and rect[1]>=0 and rect[0]+rect[2]<=4516 and rect[1]+rect[3]<=3420
   result['walkSupports'][-1]['sourceFloorOverrideRect']=rect

 result['raisedLayers']=[r['id'] for r in result['layers'] if r.get('renderPass')=='raised'];assert result['raisedLayers'], 'No raised semantic content';assert result['waterTiles']
 result['routeGrid']=route_grid(result,roads)
 for p in OUT.rglob('*.png'):
  if p not in keep:p.unlink();p.with_suffix(p.suffix+'.import').unlink(missing_ok=True)
 MANIFEST.parent.mkdir(parents=True,exist_ok=True);MANIFEST.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8',newline='\n');print(json.dumps({'layers':len(result['layers']),'waterTiles':len(result['waterTiles']),'objectTiles':sum(len(x['tiles'])for x in result['layers']),'manifest':str(MANIFEST),'sha256':sha(MANIFEST)}))
if __name__=='__main__':build()
