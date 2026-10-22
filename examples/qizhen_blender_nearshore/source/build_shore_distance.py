"""Bake local water-depth styling from the exact runtime shore (not a measured depth map)."""
from pathlib import Path
import json,re,numpy as np
from PIL import Image
base=Path(__file__).resolve().parents[1]
src=(base/'preview/scripts/games/lake_geometry.gd').read_text()
poly=np.array(json.loads(re.search(r'lake_cache=polygon\((\[.*?\])\)',src).group(1)),dtype=np.float32)
poly=(poly-np.array([690,290]))*50
# Local sample region only: 2px-ish texels.
x,y=np.meshgrid(np.linspace(5100,7100,1024),np.linspace(2000,4500,1024));dist=np.full_like(x,1.e8)
for a,b in zip(poly,np.roll(poly,-1,axis=0)):
 d=b-a;t=np.clip(((x-a[0])*d[0]+(y-a[1])*d[1])/(d@d),0,1)
 ds=np.hypot(x-a[0]-t*d[0],y-a[1]-t*d[1]);dist=np.minimum(dist,ds)
im=Image.fromarray(np.uint8(np.clip(dist/300,0,1)*255),'L');im.save(base/'preview/assets/blender/shore_distance.png')
print('SHORE_STYLE_DISTANCE_OK',im.size)
