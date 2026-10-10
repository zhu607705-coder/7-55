"""Validate embedded GLB materials/ownership and transparent inspection outputs."""
import hashlib,json,pathlib,struct,sys
from PIL import Image
root=pathlib.Path(sys.argv[1] if len(sys.argv)>1 else pathlib.Path(__file__).resolve().parents[1])
specs=[('upper/upper_rotating_stair.glb','b_upper_stair',172,'upper/upper_stair'),('platforms/mid_lift_platform.glb','b_mid_lift',1,'platforms/mid_lift_platform'),('platforms/exit_slide_platform.glb','b_exit_slide',1,'platforms/exit_slide_platform')]
report={'assets':{},'renders':{},'checks':0}
for asset,owner,meshes,prefix in specs:
 p=root/asset;b=p.read_bytes();magic,version,size=struct.unpack_from('<4sII',b);assert magic==b'glTF' and version==2 and size==len(b)
 length,typ=struct.unpack_from('<II',b,12);assert typ==0x4e4f534a;g=json.loads(b[20:20+length])
 assert len(g['meshes'])==meshes
 assert not g.get('animations') and not g.get('cameras')
 assert any(n.get('name')==owner and not any(k in n for k in ['matrix','translation','rotation','scale']) for n in g['nodes'])
 assert all('bufferView' in i and i.get('mimeType')=='image/png' for i in g['images'])
 assert all(s['magFilter']==9728 and s['minFilter'] in [9728,9984] for s in g['samplers'])
 assert all('pbrMetallicRoughness' in m for m in g['materials'])
 assert all('KHR_materials_unlit' not in m.get('extensions',{}) for m in g['materials'])
 report['assets'][asset]={'bytes':len(b),'meshes':meshes,'embedded_images':len(g['images']),'materials':len(g['materials']),'samplers':g['samplers'],'sha256':hashlib.sha256(b).hexdigest()};report['checks']+=8
 for view in ['threequarter','reverse','bottom']:
  name=prefix+'_'+view+'_rgba.png';im=Image.open(root/name);assert im.mode=='RGBA' and im.size==(1024,1024)
  alpha=im.getchannel('A');hist=alpha.histogram();bbox=alpha.getbbox();assert hist[0]>400000 and hist[255]>50000
  assert bbox and bbox[0]>0 and bbox[1]>0 and bbox[2]<1024 and bbox[3]<1024
  report['renders'][name]={'mode':im.mode,'size':im.size,'transparent_pixels':hist[0],'opaque_pixels':hist[255],'edge_pixels':sum(hist[1:255]),'bbox':bbox,'sha256':hashlib.sha256((root/name).read_bytes()).hexdigest()};report['checks']+=3
textures=[root/'upper/terrazzo_pixel_albedo.png',root/'platforms/terrazzo_pixel_albedo.png']
pixel_data=[Image.open(p).convert('RGBA').tobytes() for p in textures]
assert pixel_data[0]==pixel_data[1];report['checks']+=1;report['texture_pixels_sha256']=hashlib.sha256(pixel_data[0]).hexdigest()
(root/'artifact_validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('MOVING_ARTIFACTS_OK',report['checks'],'checks;',len(report['assets']),'GLBs;',len(report['renders']),'RGBA views')
