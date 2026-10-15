#!/usr/bin/env python3
"""Reproduce reviewed registration fields. Requires Pillow and numpy; never edits PNGs."""
import sys
from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,hashlib
native=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]/'godot_native'
c=native/'campuses/buct_changping'
raw=np.array(Image.open(c/'assets/wenli_body.png')); h,w=raw.shape[:2]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
scale=0.08707916874086201; origin=[654.170110833,735.708489019]; anchor=[711,838]
y,x=np.mgrid[:h,:w]; ids=np.ones((h,w),np.uint8)
ids[(y>=660)]=5
ids[(x<290)&(y<850)]=2
ids[((x>=890)&(y<515))|((x>=793)&(y>=510)&(y<860))]=3
ids[(x>=283)&(x<=711)&(y>=410)&(y<668)]=4
ids[(x>=536)&(x<=612)&(y>=337)&(y<506)]=4
# Transparent neighbors retain deterministic face IDs, so bilinear alpha has the same support as the whole PNG.
# The alpha texture alone owns visibility; assigning a face never creates an opaque texel.
(c/'data/wenli_surfaces.r8.bin').write_bytes(ids.tobytes())
def row(points):return np.interp(np.arange(w),[p[0] for p in points],[p[1] for p in points]).tolist()
rows=[row([(282,414),(410,418),(605,438),(851,445),(898,514)]),row([(53,945),(112,943),(237,891),(291,889)]),row([(790,735),(881,865),(1107,905),(1173,927)]),row([(283,660),(490,663),(542,667),(606,667),(711,666)]),[]]
alpha=raw[:,:,3]>=247
bottom=[]
for xx in range(w):
 yy=np.where(alpha[:,xx]&(ids[:,xx]==5))[0]; bottom.append(float(yy[-1]) if len(yy) else None)
valid=[(i,v) for i,v in enumerate(bottom) if v is not None]
rows[4]=row(valid)
outer=[[674,741],[749,744],[751,749],[751,767],[751,779],[753,781],[754,809],[756,813],[757,824],[753,832],[749,835],[741,837],[735,838],[724,837],[718,835],[710,836],[705,833],[696,831],[687,832],[681,830],[677,831],[674,827],[670,823],[668,816],[667,804],[665,800],[665,792],[667,789],[667,768],[665,764],[665,750],[671,749],[674,748]]
holes=[[[693,767],[700,767],[700,770],[694,770]],[[715,776],[729,776],[729,778],[724,779],[720,795],[719,795],[717,785],[715,783]],[[687,789],[697,789],[698,791],[687,792]]]
# Source-pixel ownership is hand-reviewed, independent of generated alpha and legacy UV parts.
mask=Image.new('L',(109,110)); d=ImageDraw.Draw(mask); d.polygon([(p[0]-657,p[1]-735) for p in outer],fill=255)
for poly in holes:d.polygon([(p[0]-657,p[1]-735) for p in poly],fill=0)
# Six verified light masonry edge pixels at the central roof / east courtyard boundary.
edge_runs=[[781,715,716],[782,715,716],[783,715,717],[784,715,717]]
for yy,x0,x1 in edge_runs:
 for xx in range(x0,x1):mask.putpixel((xx-657,yy-735),255)
(c/'data/wenli_source_removal.r8.bin').write_bytes(mask.tobytes())
spans=[]
for yy,rowv in enumerate(np.array(mask)):
 xs=np.where(rowv>0)[0]
 if not len(xs):continue
 starts=np.r_[0,np.where(np.diff(xs)>1)[0]+1];ends=np.r_[starts[1:]-1,len(xs)-1]
 for a,b in zip(starts,ends):spans.append([int(yy+735),int(xs[a]+657),int(xs[b]+658)])
def xy(p):return [p[0]*scale+origin[0],p[1]*scale+origin[1]]
probes=[]
for name,sid,xx in [('north',1,650),('west',2,190),('east',3,1030),('central_low_roof',4,440),('south',5,750)]:
 probes.append({'name':name,'surface_id':sid,'world_x':xy([xx,0])[0],'world_foot_y':xy([0,rows[sid-1][xx]])[1]})
base=json.loads((c/'data/layers.json').read_text())
ref=next(a for a in base['objects'] if a['id']=='wenli_building')
profile={'id':'wenli_building','display_name':'文理楼','source_sha256':'f92a8de6ef703bab4b2e471a49acc082dd4d128d264d99d3ed1818fdb0c93707','body_asset':'res://campuses/buct_changping/assets/wenli_body.png','body_sha256':sha(c/'assets/wenli_body.png'),'asset_provenance':'User-authorized single-image web generation from approved 109x110 source crop; exact original PNG retained by hash.','body_image_to_world':{'scale':scale,'rotation_degrees':0,'origin':origin,'raw_size':[w,h]},'source_anchor':anchor,'alpha_cutoff':0.04,'solid_alpha_threshold':0.97,'surface_id_path':'res://campuses/buct_changping/data/wenli_surfaces.r8.bin','surface_count':5,'surface_names':['north_bar','west_wing','east_wing','central_low_roof','south_front'],'surface_id_sha256':sha(c/'data/wenli_surfaces.r8.bin'),'depth_rows_raw_y':rows,'static_overlap_foot_y':[],'collision_footprints_source_xy':ref['footprints'],'transparent_probes_source_xy':[xy(p) for p in [[494,390],[650,450],[744,620],[430,645],[1200,500],[600,1240]]],'opaque_probes_source_xy':[xy(p) for p in [[600,200],[180,500],[1000,640],[414,492],[560,550],[680,1000]]],'semantic_depth_probes':probes,'high_confidence_courtyard_core_source_xy':[[697,769],[723,779],[692,791]],'central_roof_source_xy':[704,782],'registration_landmarks':{'raw_xy':[[239,90],[1068,109],[105,149],[300,889],[1179,929],[266,1120],[1090,1168],[285,409],[710,576]],'source_xy':[[674,742],[748,746],[664,750],[678,813],[755,817],[679,833],[751,838],[680,772],[715,784]],'rms_source_px':1.2579635751578,'transform_policy':'One translation and one positive uniform scale. No independent XY stretch.'},'source_removal':{'rect':[657,735,109,110],'path':'res://campuses/buct_changping/data/wenli_source_removal.r8.bin','sha256':sha(c/'data/wenli_source_removal.r8.bin'),'outer_source_xy':outer,'verified_roof_edge_runs_y_x0_x1_exclusive':edge_runs,'protected_courtyards_source_xy':holes,'spans_y_x0_x1_exclusive':spans,'changed_source_pixels':int(np.sum(np.array(mask)>0))},'foot_explanation':{'north_bar':'Visible north facade ground contacts measured on downloaded body, independent of south-front depth.','west_wing':'West upper wing contact row follows its lower edge before south-front return.','east_wing':'East lower block and side return contact row measured from actual facade edge.','central_low_roof':'Connected low roof and its short facade remain solid, with the visible low facade foot row. Transparent courtyard cores remain excluded.','south_front':'Last >=0.97 solid-alpha south-front source texel in each raw column, interpolated only across empty columns.','collision':'All three existing native StaticBody2D children and source polygons remain unchanged; visual rows never modify physics or route permission.'}}
profile['ground']={'asset':'res://campuses/buct_changping/assets/wenli_ground.png','sha256':sha(c/'assets/wenli_ground.png'),'raw_size':[1249,1260],'scale':110/600,'origin':[657-360*110/600,735-380*110/600],'sampled_plain_region_raw_xywh':[360,380,600,600],'inferred_shade_multiplier':0.75,'inferred_not_surveyed':True,'reason':'Generated border trees are excluded. Only a uniform sample of plain generated paving fills the hand-reviewed original building ownership mask; true courtyards, original trees and roads keep exact original pixels.'}
(c/'data/wenli_registration.json').write_text(json.dumps(profile,ensure_ascii=False,indent=2)+'\n')
print('prepared',w,h,'source owned pixels',profile['source_removal']['changed_source_pixels'])
