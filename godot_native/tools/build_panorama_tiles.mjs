#!/usr/bin/env node
/** Lossless source-pixel tiling. No engine import, resize or source rewrite. */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {inflateSync,deflateSync} from 'node:zlib';
import {fileURLToPath} from 'node:url';

const project=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const source=path.resolve(project,'../src/assets/rpg/campus/zijingang_campus_loop_panorama.png');
const output=path.join(project,'assets/rpg/campus/zijingang_campus_loop_panorama_tiles');
const manifestPath=path.join(project,'data/native/campus-loop-panorama-tiles.json');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const crc=b=>{let c=0xffffffff;for(const x of b){c^=x;for(let k=0;k<8;k++)c=(c>>>1)^((c&1)?0xedb88320:0);}return(c^0xffffffff)>>>0;};
function chunk(type,data){const b=Buffer.alloc(data.length+12);b.writeUInt32BE(data.length);b.write(type,4);data.copy(b,8);b.writeUInt32BE(crc(b.subarray(4,-4)),b.length-4);return b;}
function decode(b){
 if(!b.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])))throw Error('Not PNG');
 let header,idat=[];
 for(let p=8;p<b.length;){const n=b.readUInt32BE(p),type=b.toString('ascii',p+4,p+8),data=b.subarray(p+8,p+8+n);if(crc(b.subarray(p+4,p+8+n))!==b.readUInt32BE(p+8+n))throw Error(`CRC ${type}`);if(type==='IHDR')header=data;if(type==='IDAT')idat.push(data);p+=n+12;}
 const w=header.readUInt32BE(0),h=header.readUInt32BE(4),type=header[9],channels=type===2?3:type===6?4:0;
 if(header[8]!==8||!channels||header[10]||header[11]||header[12])throw Error('Expected non-interlaced 8-bit RGB/RGBA source');
 const raw=inflateSync(Buffer.concat(idat)),stride=w*channels,data=Buffer.alloc(stride*h);
 if(raw.length!==(stride+1)*h)throw Error('Unexpected PNG stride');
 const paeth=(a,b,c)=>{const p=a+b-c,pa=Math.abs(p-a),pb=Math.abs(p-b),pc=Math.abs(p-c);return pa<=pb&&pa<=pc?a:pb<=pc?b:c;};
 for(let y=0;y<h;y++){const f=raw[y*(stride+1)];if(f>4)throw Error('PNG filter');for(let x=0;x<stride;x++){const a=x>=channels?data[y*stride+x-channels]:0,b=y?data[(y-1)*stride+x]:0,c=y&&x>=channels?data[(y-1)*stride+x-channels]:0;const pred=f===0?0:f===1?a:f===2?b:f===3?Math.floor((a+b)/2):paeth(a,b,c);data[y*stride+x]=(raw[y*(stride+1)+1+x]+pred)&255;}}
 return {w,h,channels,type,data};
}
function encode(im){
 const head=Buffer.alloc(13);head.writeUInt32BE(im.w);head.writeUInt32BE(im.h,4);head[8]=8;head[9]=im.type;
 const stride=im.w*im.channels,raw=Buffer.alloc((stride+1)*im.h);
 for(let y=0;y<im.h;y++){raw[y*(stride+1)]=1;for(let x=0;x<stride;x++)raw[y*(stride+1)+1+x]=(im.data[y*stride+x]-(x>=im.channels?im.data[y*stride+x-im.channels]:0))&255;}
 return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',head),chunk('IDAT',deflateSync(raw,{level:9})),chunk('IEND',Buffer.alloc(0))]);
}
const bytes=fs.readFileSync(source),im=decode(bytes),coreWidth=2046,gutter=1,tiles=[];
if(im.w!==13668||im.h!==1084)throw Error('Original source dimensions changed; recalibration required');
const rebuilt=Buffer.alloc(im.data.length);fs.mkdirSync(output,{recursive:true});
for(let x=0,index=0;x<im.w;x+=coreWidth,index++){
 const width=Math.min(coreWidth,im.w-x),tile={w:width+2,h:im.h+2,channels:im.channels,type:im.type,data:Buffer.alloc((width+2)*(im.h+2)*im.channels)};
 for(let yy=0;yy<tile.h;yy++){const sy=Math.max(0,Math.min(im.h-1,yy-1));for(let xx=0;xx<tile.w;xx++){const sx=Math.max(0,Math.min(im.w-1,x+xx-1));im.data.copy(tile.data,(yy*tile.w+xx)*im.channels,(sy*im.w+sx)*im.channels,(sy*im.w+sx+1)*im.channels);}}
 const name=`tile_${String(index).padStart(2,'0')}.png`,encoded=encode(tile),target=path.join(output,name),decoded=decode(encoded);
 if(decoded.w>2048||decoded.h>2048||!decoded.data.equals(tile.data))throw Error('Tile bound or roundtrip failure');
 for(let y=0;y<im.h;y++)decoded.data.copy(rebuilt,(y*im.w+x)*im.channels,((y+1)*decoded.w+1)*im.channels,((y+1)*decoded.w+1+width)*im.channels);
 if(process.argv.includes('--check')){if(!fs.existsSync(target)||!fs.readFileSync(target).equals(encoded))throw Error(`Stale tile ${name}`);}else fs.writeFileSync(target,encoded);
 tiles.push({path:`res://assets/rpg/campus/zijingang_campus_loop_panorama_tiles/${name}`,sourceRect:[x,0,width,im.h],textureRegion:[1,1,width,im.h],textureSize:[tile.w,tile.h],sha256:sha(encoded),decodedPixelSha256:sha(tile.data)});
}
if(!rebuilt.equals(im.data))throw Error('Lossless source reconstruction failed');
const manifest={schema:'source-pixel-tiled-texture-v1',sourceAsset:'res://assets/rpg/campus/zijingang_campus_loop_panorama.png',sourceFile:'src/assets/rpg/campus/zijingang_campus_loop_panorama.png',sourceSha256:sha(bytes),sourceSize:[im.w,im.h],channels:im.channels,coreWidth,gutter,maxPhysicalDimension:2048,filter:'inherit_canvas_no_mipmaps',gutterPolicy:'One neighboring source pixel on each side; clamp only at outer source boundary. Draw core region with clip_uv=false.',decodedSourceSha256:sha(im.data),reconstructedPixelSha256:sha(rebuilt),tiles};
const content=JSON.stringify(manifest,null,2)+'\n';
if(process.argv.includes('--check')){if(fs.readFileSync(manifestPath,'utf8')!==content)throw Error('Stale manifest');}else fs.writeFileSync(manifestPath,content);
console.log(JSON.stringify({sourceSha256:manifest.sourceSha256,tiles:tiles.length,maxTexture:Math.max(...tiles.flatMap(t=>t.textureSize)),lossless:true,checkOnly:process.argv.includes('--check'),manifest:manifestPath}));
