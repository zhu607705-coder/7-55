"""Arrange unchanged CPU renders side-by-side with labels; no image enhancement."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
root=Path(__file__).resolve().parents[1]/'review/prop_refinement'
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',28)
small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',23)
for asset in ['printer_enclosure_study','laser_enclosure_study']:
 a=Image.open(root/'64'/f'{asset}.png').convert('RGB');b=Image.open(root/'512'/f'{asset}.png').convert('RGB')
 assert a.size==b.size==(1200,1000)
 panel=Image.new('RGB',(2400,1120),'#fafafa');panel.paste(a,(0,120));panel.paste(b,(1200,120));d=ImageDraw.Draw(panel)
 d.text((24,12),asset+' | Blender Cycles CPU | NOT a browser capture',font=font,fill='#111111')
 d.text((24,56),'64 max samples / no denoising',font=font,fill='#111111');d.text((1224,56),'512 max samples / no denoising',font=font,fill='#111111')
 d.text((24,92),'Same source, glass, camera, lights, exposure and seed. Static design study, not an exact manufacturer replica.',font=small,fill='#333333')
 panel.save(root/f'{asset}_CPU_64_vs_512.png')
# Numerical aid only: fixed glass crops, spatial high-frequency residual.
# This includes scene detail and is not an unbiased Monte Carlo variance estimate.
import json
import numpy as np
from PIL import ImageFilter
metrics=[]
for asset,box in [('printer_enclosure_study',(370,450,470,550)),('laser_enclosure_study',(450,350,550,450))]:
 values={}
 for count in [64,512]:
  patch=Image.open(root/str(count)/f'{asset}.png').convert('L').crop(box)
  original=np.asarray(patch,dtype=float);low=np.asarray(patch.filter(ImageFilter.GaussianBlur(2)),dtype=float)
  values[str(count)]=float(np.sqrt(np.mean((original-low)**2)))
 metrics.append({'asset':asset,'cropPixelsXYXY':box,'gray8HighFrequencyRMS':values,'reductionFraction':1-values['512']/values['64']})
(root/'glass_patch_metrics.json').write_text(json.dumps({'method':'RMS(gray8 - GaussianBlur(radius=2)) on fixed glass crop. Spatial residual includes detail; not unbiased Monte Carlo variance or physical material validation. Images themselves are unchanged.','records':metrics},indent=2)+'\n')
