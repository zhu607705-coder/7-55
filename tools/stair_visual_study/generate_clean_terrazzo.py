"""Deterministic native-asset albedo candidate. Creates a texture from parameters;
never retouches a user image. Geometry/UVs/materials remain external and unchanged.
"""
from pathlib import Path
from collections import Counter
import json, random, hashlib, argparse
from PIL import Image
import numpy as np
SOURCE_ROOT=Path(__file__).resolve().parent
parser=argparse.ArgumentParser()
parser.add_argument("--output",type=Path,default=SOURCE_ROOT)
parser.add_argument("--reference",type=Path,default=SOURCE_ROOT/"sample_asset/terrazzo_pixel_albedo.png")
args=parser.parse_args()
ROOT=args.output;ROOT.mkdir(parents=True,exist_ok=True)
SIZE=128
SEED=755
TARGET_COVERAGE=.15
PALETTE=['b7b6aa','aeb0a6','bdbcae','b1b3aa']
rng=random.Random(SEED)
rgb=[tuple(bytes.fromhex(c)) for c in PALETTE]
pixels=np.empty((SIZE,SIZE,4),dtype=np.uint8);pixels[:,:,:3]=rgb[0];pixels[:,:,3]=255
mask=np.zeros((SIZE,SIZE),dtype=bool);chips=0
while mask.mean()<TARGET_COVERAGE:
 cx,cy=rng.randrange(SIZE),rng.randrange(SIZE);rx=rng.choice([2,3,4]);ry=rng.choice([2,3]);shade=rng.choices([1,2,3],[.3,.35,.35])[0]
 # A small continuous angular aggregate, with no salt-and-pepper fill layer.
 for dy in range(-ry,ry+1):
  for dx in range(-rx,rx+1):
   if abs(dx)/rx+abs(dy)/ry<=1.1:
    yy,xx=(cy+dy)%SIZE,(cx+dx)%SIZE;pixels[yy,xx,:3]=rgb[shade];mask[yy,xx]=True
 chips+=1
path=ROOT/'terrazzo_clean_pixel_albedo.png';Image.fromarray(pixels).save(path)
def stats(img):
 a=np.array(img.convert('RGB'),dtype=float);lum=a@np.array([.2126,.7152,.0722]);counts=Counter(map(tuple,a.reshape(-1,3).astype(int)))
 return {'size':list(img.size),'palette_colors':len(counts),'largest_flat_color_fraction':max(counts.values())/lum.size,'luminance_mean_255':float(lum.mean()),'luminance_std_255':float(lum.std()),'luminance_min_255':float(lum.min()),'luminance_max_255':float(lum.max()),'luminance_range_255':float(np.ptp(lum)),'neighbor_luminance_difference_mean_255':float((np.abs(lum-np.roll(lum,1,0)).mean()+np.abs(lum-np.roll(lum,1,1)).mean())/2),'color_counts':{'#%02x%02x%02x'%col:int(n) for col,n in counts.items()}}
report={'purpose':'single-variable albedo comparison, no geometry or filter changes','file':path.name,'seed':SEED,'size':SIZE,'palette_srgb_hex':PALETTE,'target_nonbase_coverage':TARGET_COVERAGE,'actual_nonbase_coverage':float(mask.mean()),'aggregate_count':chips,'aggregate_radius_x_px':[2,3,4],'aggregate_radius_y_px':[2,3],'random_per_pixel_base_noise':False,'candidate':stats(Image.open(path)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
reference=args.reference
if reference.exists():report['original']=stats(Image.open(reference))
(ROOT/'candidate_parameters.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
