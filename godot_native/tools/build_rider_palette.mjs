import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import crypto from 'node:crypto';
const project=path.resolve(import.meta.dirname,'..');
const direction=fs.readFileSync(path.join(project,'docs/art/art_direction_v1.json'));
const colors=JSON.parse(direction).palette.colors.map(c=>[0,2,4].map(at=>parseInt(c.slice(at,at+2),16)));
const bytes=Buffer.alloc(1024*(32*3+1));
for(let b=0;b<32;b++)for(let g=0;g<32;g++)for(let r=0;r<32;r++){
 const c=[r,g,b].map(x=>x*255/31);
 let best=0,error=Infinity;
 for(let i=0;i<colors.length;i++){
  const d=colors[i].reduce((sum,x,j)=>sum+[.26,.60,.14][j]*(x-c[j])**2,0);
  if(d<error){error=d;best=i;}
 }
 const at=(g+b*32)*97+1+r*3;colors[best].forEach((v,i)=>bytes[at+i]=v);
}
function crc(bytes){let c=0xffffffff;for(const b of bytes){c^=b;for(let i=0;i<8;i++)c=(c>>>1)^((c&1)?0xedb88320:0);}return (c^0xffffffff)>>>0;}
function chunk(name,data){const type=Buffer.from(name),size=Buffer.alloc(4),check=Buffer.alloc(4);size.writeUInt32BE(data.length);check.writeUInt32BE(crc(Buffer.concat([type,data])));return Buffer.concat([size,type,data,check]);}
const header=Buffer.alloc(13);header.writeUInt32BE(32,0);header.writeUInt32BE(1024,4);header[8]=8;header[9]=2;
const png=Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',header),chunk('IDAT',zlib.deflateSync(bytes)),chunk('IEND',Buffer.alloc(0))]);
const target=path.join(project,'assets/native_755/ride/pelican_palette_lut.png');
if(process.argv.includes('--check')){if(!fs.readFileSync(target).equals(png))throw Error('Rider palette LUT differs from art bible');}
else fs.writeFileSync(target,png);
console.log(JSON.stringify({path:target,bytes:png.length,sha256:crypto.createHash('sha256').update(png).digest('hex'),paletteColors:colors.length}));
