// Mechanical registration only. The changing door shapes were drawn in ChatGPT web.
// Requires ImageMagick. Never redraws or warps the existing source artwork.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { execFileSync } from 'node:child_process';
import crypto from 'node:crypto';
const root=path.resolve(import.meta.dirname,'../..');
const output=path.join(root,'assets/native/dorm_cabinet');
const plate=process.argv[2]||path.join(root,'assets/rpg/interiors/dorm_hub.png');
const source=path.join(output,'web_atlas_source.png');
const scratch=fs.mkdtempSync(path.join(os.tmpdir(),'dorm-frame-registration-'));
const magick=(...args)=>execFileSync('magick',args.map(String),{stdio:'pipe'});
const plateHash=crypto.createHash('sha256').update(fs.readFileSync(plate)).digest('hex');
if(plateHash!=='361f857e028b5d03defdaba9befd1e3ac0462133ca48a73f4e24c623a8db7519')throw Error('Unexpected dorm source plate');
const cells=[];
// The generated 1774x887 atlas has half-pixel cell boundaries. Round boundaries,
// then normalize only one-pixel cell-origin differences before one UNIFORM 0.5 scale.
const offsets=[[0,0],[1,0],[1,0],[-1,0],[0,1],[1,1],[0,1],[-1,1]];
// Only the generated door tips can cover the original sill; all other shell pixels stay original.
// These polygons select generated pixels. They are not replacement drawn door geometry.
const tips=[null,
 [[61,180,120,180,120,184],[138,180,193,180,138,184]],
 [[61,180,111,180,111,187],[143,180,193,180,143,187]],
 [[61,180,94,180,94,190],[161,180,193,180,161,190]],
 [[61,180,84,180,84,191],[169,180,193,180,169,191]],
 [[61,180,82,180,82,191],[170,180,193,180,170,191]],
 [[61,180,73,180,73,191],[180,180,193,180,180,191]],
 [[61,180,66,180,66,191,61,191],[188,180,193,180,193,191,188,191]]
];
for(let i=0;i<8;i++){
 const c=i%4,r=Math.floor(i/4),x=Math.round(c*1774/4),xe=Math.round((c+1)*1774/4),y=Math.round(r*887/2),ye=Math.round((r+1)*887/2);
 const raw=path.join(scratch,`${i}-raw.png`),aligned=path.join(scratch,`${i}-aligned.png`),mask=path.join(scratch,`${i}-mask.png`),frame=path.join(scratch,`${i}-frame.png`);
 if(i===0){
  magick(plate,'-crop','256x256+360+208','+repage',aligned);
 }else{
  magick(source,'-crop',`${xe-x}x${ye-y}+${x}+${y}`,'+repage',raw);
  const [dx,dy]=offsets[i];
  magick(raw,'-background','none','-gravity','northwest','-extent',`448x448${-dx>=0?'+':''}${-dx}${-dy>=0?'+':''}${-dy}`,'-filter','point','-resize','50%','-background','none','-gravity','northwest','-extent','256x256-16+3',aligned);
 }
 const draw=['rectangle 61,41 192,180'];
 for(const p of tips[i]||[])draw.push(`polygon ${p.join(',')}`);
 magick('-size','256x256','xc:black','-fill','white','-draw',draw.join(' '),mask);
 // Hard opaque interior avoids any alpha leak of the old closed doors. The rest is transparent.
 magick(aligned,'-alpha','off',mask,'-compose','CopyOpacity','-composite',frame);
 cells.push(frame);
}
magick('montage',...cells,'-tile','4x2','-geometry','256x256+0+0','-background','none',path.join(output,'cabinet_opening_frames.png'));
const manifest={version:1,sourcePlateSha256:plateHash,generationMethod:'ChatGPT web image generation',generationDate:'2026-10-09',webAtlasSha256:crypto.createHash('sha256').update(fs.readFileSync(source)).digest('hex'),webAtlasSize:[1774,887],atlasSize:[1024,512],cellSize:[256,256],frames:8,cropOrigin:[360,208],aperture:[61,41,132,140],uniformScale:.5,cellOriginCorrections:offsets,closedFrame:'Original source pixels, not generated',shell:'Original plate remains visible outside aperture and physical leaf-tip occlusion',durationMs:260,angles:'Authored progressive poses from closed to near edge-on; exact angle values are not measured'};
fs.writeFileSync(path.join(output,'provenance.json'),JSON.stringify(manifest,null,2)+'\n');
console.log('Registered 8 exact-size frames with original closed pose.');
