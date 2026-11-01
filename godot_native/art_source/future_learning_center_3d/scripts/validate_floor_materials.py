"""Inspect generated PBR bytes and actual GLB material contracts without Blender."""
from pathlib import Path
import json,struct,zlib,hashlib,statistics
ROOT=Path(__file__).resolve().parents[1];catalog=json.loads((ROOT/'web/assets/floor_material_catalog.json').read_text());rows=[]
def check(value,label,details=None):
 rows.append({'pass':bool(value),'label':label,'details':details})
 if not value:print('FAIL',label,details)
def read_png(data):
 assert data[:8]==b'\x89PNG\r\n\x1a\n';offset=8;compressed=b'';w=h=None
 while offset<len(data):
  size=struct.unpack_from('>I',data,offset)[0];tag=data[offset+4:offset+8];body=data[offset+8:offset+8+size];crc=struct.unpack_from('>I',data,offset+8+size)[0];assert zlib.crc32(tag+body)&0xffffffff==crc
  if tag==b'IHDR':w,h,depth,color,*_=struct.unpack('>IIBBBBB',body);assert depth==8 and color==2
  if tag==b'IDAT':compressed+=body
  offset+=size+12
 raw=zlib.decompress(compressed);pixels=bytearray()
 for y in range(h):
  row=raw[y*(w*3+1):(y+1)*(w*3+1)];assert row[0]==0;pixels.extend(row[1:])
 return w,h,pixels
for id,p in catalog['profiles'].items():
 for role,info in p['maps'].items():
  data=(ROOT/'web/assets'/info['file']).read_bytes();w,h,pixels=read_png(data)
  check(hashlib.sha256(data).hexdigest()==info['sha256'],id+' '+role+' source hash')
  check([w,h]==[512,512],id+' '+role+' valid RGB PNG dimensions')
  if role=='color':check(.003<statistics.pstdev(pixels[0::3])/max(1,statistics.mean(pixels[0::3]))<.05,id+' restrained non-flat base color',statistics.pstdev(pixels[0::3]))
  elif role=='orm':check(max(pixels[2::3])==0 and min(pixels[0::3])==255 and abs(statistics.mean(pixels[1::3])/255-p['roughness'])<.02,id+' nonmetal roughness/occlusion channels')
  else:check(statistics.mean(pixels[2::3])>250 and abs(statistics.mean(pixels[0::3])-127.5)<1,id+' tangent normal direction remains near flat surface')
b=(ROOT/'web/assets/building.glb').read_bytes();n=struct.unpack_from('<I',b,12)[0];gltf=json.loads(b[20:20+n]);materials=[m for m in gltf['materials'] if m.get('name','').startswith('FLC floor ')]
check(len(materials)==3,'GLB contains baseline, electrical and recording finishes',len(materials))
for mat in materials:
 pbr=mat.get('pbrMetallicRoughness',{});check('baseColorTexture' in pbr and 'metallicRoughnessTexture' in pbr and 'normalTexture' in mat,mat['name']+' exports all three PBR channels')
report={'checks':len(rows),'failures':sum(not r['pass'] for r in rows),'rows':rows};(ROOT/'review/floor_material_asset_validation.json').write_text(json.dumps(report,indent=2));print('Floor assets:',report['checks'],'checks,',report['failures'],'failures')
if report['failures']:raise SystemExit(1)
