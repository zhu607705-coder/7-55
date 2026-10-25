"""Deterministic cutout/palette normalization; source generation is external."""
from pathlib import Path
import argparse,json,hashlib
from PIL import Image, ImageFilter
p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);a=p.parse_args()
project=Path(__file__).resolve().parents[1];out=project/'assets/native/north_objects_20261025';out.mkdir(parents=True,exist_ok=True)
palette=json.loads((project/'docs/art/art_direction_v1.json').read_text())['palette']['colors']
pal=Image.new('P',(1,1));rgb=[int(c[i:i+2],16) for c in palette for i in (0,2,4)];pal.putpalette(rgb+[0]*(768-len(rgb)))
rows=[]
for name,crop,width in [('student_desk',None,240),('wall_face',(590,185,1532,489),557)]:
 colors=(['44332D','70503B','A1744E','C79B62','202B35','344452'] if name=='student_desk' else ['202B35','344452','526B7A','7993A1','766E63','A39B87','C5C1A9','E8E0C8'])
 rgb=[int(c[i:i+2],16) for c in colors for i in (0,2,4)];pal.putpalette(rgb+rgb[:3]*((768-len(rgb))//3))
 source=a.source/('student_desk_master.png' if name=='student_desk' else 'wall_horizontal_master.png')
 im=Image.open(source).convert('RGBA')
 alpha=im.getchannel('A').point(lambda x:255 if x>=128 else 0)
 crop=crop or alpha.getbbox();im=im.crop(crop);alpha=alpha.crop(crop)
 size=(width,round(im.height*width/im.width));im=im.resize(size,Image.Resampling.NEAREST);alpha=alpha.resize(size,Image.Resampling.NEAREST)
 im=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).filter(ImageFilter.ModeFilter(3)).convert('RGBA');im.putalpha(alpha)
 canvas=Image.new('RGBA',(size[0]+2,size[1]+2));canvas.paste(im,(1,1));target=out/(name+'.png');canvas.save(target)
 rows.append({'id':name,'source':source.name,'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'sourceCrop':crop,'size':canvas.size,'visibleRect':[1,1,*size],'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
(out/'provenance.json').write_text(json.dumps({'tool':'OpenAI image_gen','generatedAt':'2026-10-24','normalizedAt':'2026-10-25','reference':'src/assets/rpg/interiors/finale/chapter4-755/base/a1.png','style':'orthographic oblique, warm plaster, blue-grey trim, restrained wood grain, transparent cutouts','palette':'755-campus-morning-32','normalization':'alpha threshold128; nearest uniform resize; material subset of shared palette without dithering; 3px modal color cleanup with original alpha retained; one transparent border','sourceArchive':str(a.source),'assets':rows},ensure_ascii=False,indent=2)+'\n')
print(json.dumps(rows,ensure_ascii=False))
