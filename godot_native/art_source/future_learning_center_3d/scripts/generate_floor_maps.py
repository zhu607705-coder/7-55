"""Deterministic locally-authored PBR maps. No photographic material identity is inferred."""
from pathlib import Path
import math,json,struct,zlib,hashlib
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'web/assets/materials/floors';OUT.mkdir(parents=True,exist_ok=True)
N=512

def png(path,pixels):
 def chunk(tag,data):return struct.pack('>I',len(data))+tag+data+struct.pack('>I',zlib.crc32(tag+data)&0xffffffff)
 raw=b''.join(b'\x00'+bytes(pixels[y*N*3:(y+1)*N*3]) for y in range(N))
 path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',N,N,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))

def hash2(x,y):
 h=((x*374761393+y*668265263+4127)^0x6ac690c5)&0xffffffff;h=((h^(h>>13))*1274126177)&0xffffffff
 return ((h^(h>>16))&0xffff)/65535-.5

def noise(x,y,grid):
 x=x*grid/N;y=y*grid/N;i=int(x);j=int(y);u=x-i;v=y-j;u=u*u*(3-2*u);v=v*v*(3-2*v)
 a=hash2(i%grid,j%grid);b=hash2((i+1)%grid,j%grid);c=hash2(i%grid,(j+1)%grid);d=hash2((i+1)%grid,(j+1)%grid)
 return (a*(1-u)+b*u)*(1-v)+(c*(1-u)+d*u)*v

cloud=[];grain=[]
for y in range(N):
 for x in range(N):
  cloud.append(.65*noise(x,y,4)+.35*noise(x,y,12));grain.append(.6*noise(x,y,64)+.4*noise(x,y,192))

profiles={
 'warm_gray_fine':{'name':'浅暖灰细纹 · 照片基准','base':[166,163,158],'roughness':.62,'repeat_m':1.2,'joint_m':0,'evidence':'3F north photo appearance; actual material category/brand is unconfirmed','status':'visual_baseline_3f_north; provisional_extension_elsewhere'},
 'light_gray_tile':{'name':'浅灰大板砖 · 回廊候选','base':[177,177,171],'roughness':.44,'repeat_m':.6,'joint_m':.0012,'evidence':'Older corridor-photo ledger records visible pale glossy tiles; exact location, module and product remain unconfirmed','status':'unassigned_comparison; 600mm module and1.2mm joint are review assumptions'},
 'esd_gray_green':{'name':'灰绿防静电地面 · 功能示意','base':[125,139,132],'roughness':.76,'repeat_m':1.2,'joint_m':0,'evidence':'Feishu mechatronics document requires electrical ESD floor; color and texture are review choices, no electrical performance validated','status':'required_function; illustrative_finish'},
 'studio_charcoal':{'name':'深灰低反光 · 录播室方案','base':[58,62,61],'roughness':.86,'repeat_m':1.2,'joint_m':0,'evidence':'Dark recording room requirement; this floor finish is a proposed visual treatment','status':'design_proposal'}
}

def clamp(v):return max(0,min(255,int(round(v))))
for id,p in profiles.items():
 color=bytearray();orm=bytearray();normal=bytearray();height=[]
 for y in range(N):
  for x in range(N):
   i=y*N+x;variation=cloud[i]*.055+grain[i]*.012;step=p['repeat_m']/N;edge=min(x+.5,y+.5,N-x-.5,N-y-.5)/N*p['repeat_m'];joint=max(0,min(1,(p['joint_m']*.5-(edge-step*.5))/step)) if p['joint_m'] else 0
   color.extend(clamp(v*(1+variation)*(1-joint*.16)) for v in p['base'])
   rough=max(.2,min(.95,p['roughness']+cloud[i]*.035+grain[i]*.02+joint*.15));orm.extend([255,clamp(rough*255),0])
   height.append(grain[i]*.00012-joint*.00030)
 step=p['repeat_m']/N
 for y in range(N):
  for x in range(N):
   dx=(height[y*N+(x+1)%N]-height[y*N+(x-1)%N])/(2*step);dy=(height[((y+1)%N)*N+x]-height[((y-1)%N)*N+x])/(2*step)
   nx,ny,nz=-dx,dy,1;length=math.sqrt(nx*nx+ny*ny+nz*nz)
   normal.extend([clamp((nx/length*.5+.5)*255),clamp((ny/length*.5+.5)*255),clamp((nz/length*.5+.5)*255)])
 p['maps']={}
 for role,data in [('color',color),('orm',orm),('normal',normal)]:
  path=OUT/(id+'_'+role+'.png');png(path,data);p['maps'][role]={'file':'materials/floors/'+path.name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'bytes':path.stat().st_size,'resolution':[N,N]}
 p['metalness']=0;p['normal_strength']=.45
catalog={'schema':1,'units':'m','uv_period_m':1.2,'default':'warm_gray_fine','profiles':profiles,'rights':'Locally authored numerical PBR maps for this project. No external scan or manufacturer sample claimed. Source photos/document rights remain with their owners.','assignment':{'3F north':'warm_gray_fine photo-based visual baseline','2F/other3F/4F common floors':'warm_gray_fine provisional material-family extension, not verified site finish','2F electrical area':'esd_gray_green functional illustration','3F recording':'studio_charcoal design proposal'},'rejected_external_reference':{'url':'https://polyhaven.com/a/concrete_floor_02','reason':'Publisher description is weathered/mossy and unsuitable for the clean photo reference; not downloaded or shipped'}}
(ROOT/'web/assets/floor_material_catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2))
print('FLOOR_MAPS',len(profiles)*3,'deterministic512px PBR maps')
