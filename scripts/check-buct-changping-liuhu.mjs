import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import zlib from 'node:zlib';

const root = process.env.BUCT_REPOSITORY_ROOT ? path.resolve(process.env.BUCT_REPOSITORY_ROOT) : path.resolve(import.meta.dirname, '..');
const project = process.env.BUCT_LIUHU_PROJECT_ROOT ? path.resolve(process.env.BUCT_LIUHU_PROJECT_ROOT) : path.join(root, 'godot_native');
const read = relative => fs.readFileSync(path.join(project, relative));
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const validation = JSON.parse(fs.readFileSync(path.join(root, 'docs/BUCT_CHANGPING_LIUHU_VALIDATION.json')));
const campus = 'campuses/buct_changping/';
const profile = JSON.parse(read(campus + 'data/liuhu_water_registration.json'));
let checks = 0;
const failures = [];
function check(ok, text) { checks++; if (!ok) failures.push(text); }

// Dependency-free lossless PNG decoding for these exact 8-bit source textures.
function png(bytes) {
  if (bytes.subarray(0,8).toString('hex') !== '89504e470d0a1a0a') throw Error('PNG signature');
  let width, height, channels, depth, interlace;
  const idat = [];
  for (let p=8; p<bytes.length;) {
    const length=bytes.readUInt32BE(p), type=bytes.toString('ascii',p+4,p+8), data=bytes.subarray(p+8,p+8+length);
    if(type==='IHDR') { width=data.readUInt32BE(0);height=data.readUInt32BE(4);depth=data[8];channels=({0:1,2:3,6:4})[data[9]];interlace=data[12]; }
    if(type==='IDAT')idat.push(data);
    p+=length+12;
  }
  if(depth!==8 || !channels || interlace!==0)throw Error('Unsupported source PNG format');
  const stride=width*channels, raw=zlib.inflateSync(Buffer.concat(idat)), pixels=Buffer.alloc(height*stride);
  function paeth(a,b,c){const p=a+b-c,pa=Math.abs(p-a),pb=Math.abs(p-b),pc=Math.abs(p-c);return pa<=pb&&pa<=pc?a:pb<=pc?b:c;}
  for(let y=0;y<height;y++) {
    const filter=raw[y*(stride+1)];
    if(filter>4)throw Error('Invalid PNG row filter');
    for(let x=0;x<stride;x++) {
      const i=y*stride+x,a=x>=channels?pixels[i-channels]:0,b=y?pixels[i-stride]:0,c=y&&x>=channels?pixels[i-stride-channels]:0;
      const prediction=[0,a,b,Math.floor((a+b)/2),paeth(a,b,c)][filter];
      pixels[i]=(raw[y*(stride+1)+x+1]+prediction)&255;
    }
  }
  return {width,height,channels,pixels};
}
for(const entry of validation.unchanged_source_contracts)check(sha(read(entry.path.replace(/^godot_native\//,'')))===entry.sha256, 'Unchanged exact-base source: '+entry.path);
for(const [name,hash] of Object.entries(validation.new_asset_sha256))check(sha(read(campus+'assets/'+name))===hash,'Reviewed source-derived asset: '+name);
const source=png(read(campus+'assets/approved-changping.png'));
const water=png(read(campus+'assets/liuhu-water-source-rgba.png'));
const distance=png(read(campus+'assets/liuhu-water-distance.png'));
check(source.width===950&&source.height===1656,'Original source-sized canvas');
check(water.width===163&&water.height===108&&water.channels===4,'Small true RGBA water texture');
check(distance.width===163&&distance.height===108&&distance.channels===1,'Matching scalar shore distance');
const visibleBytes=Buffer.from(water.pixels);
for(let i=0;i<visibleBytes.length;i+=4)if(visibleBytes[i+3]===0)visibleBytes.fill(0,i,i+3);
check(sha(visibleBytes)===profile.water_visible_rgba_sha256,'Runtime validates decoded visible water bytes before cutout');
check(sha(distance.pixels)===profile.distance_r8_raw_sha256,'Runtime validates decoded distance bytes before cutout');
check(JSON.stringify(profile.crop_source_xywh)==='[317,750,163,108]','Fixed original source registration');
let count=0,rgbErrors=0,binaryErrors=0,distanceErrors=0;
for(let y=0;y<water.height;y++)for(let x=0;x<water.width;x++) {
  const i=(y*water.width+x)*4,a=water.pixels[i+3];
  if(a!==0&&a!==255)binaryErrors++;
  if(a===255){count++;const j=((750+y)*source.width+317+x)*source.channels;for(let c=0;c<3;c++)if(water.pixels[i+c]!==source.pixels[j+c])rgbErrors++;}
  else if(distance.pixels[y*water.width+x]!==0)distanceErrors++;
}
check(count===7140&&binaryErrors===0,'Exactly 7140 reviewed binary alpha pixels');
check(rgbErrors===0,'All opaque RGB bytes remain original source pixels');
check(distanceErrors===0,'Transparent dry features have zero animation distance');
for(const probe of validation.source_mask.samples){const[x,y]=probe.source_xy;const lx=x-317,ly=y-750;const hit=lx>=0&&ly>=0&&lx<163&&ly<108&&water.pixels[(ly*163+lx)*4+3]>127;check(hit===probe.expected_hit,'Alpha water/dry-feature probe '+probe.source_xy);}
const script=read(campus+'scripts/liuhu_water_surface.gd').toString();
const parent=read(campus+'scripts/playable_campus.gd').toString();
const shader=read(campus+'shaders/liuhu_water.gdshader').toString();
check(!/StaticBody2D|CollisionShape2D|CollisionPolygon2D|NavigationRegion2D/.test(script),'Water has no new physical or navigation authority');
check(script.includes('ground.material = lake.cutout_material'),'Original baked water is removed by complementary shader');
check(shader.includes('COLOR = vec4(rgb, original.a)'),'Water alpha is time-invariant');
check(shader.includes('min(min(a.a, b.a), min(c.a, d.a)) > 0.5'),'All four perturbed RGB samples remain inside water');
check(parent.includes('elif not overview and is_walkable(target):'),'Original click-to-navigation guard preserved');
check(profile.frozen_animation_border_source_pixels===2&&profile.wave_amplitude_source_pixels_max===0.30,'Two-pixel frozen edge and bounded tiny motion');
console.log(JSON.stringify({checks,failures,base_head:validation.base_head,base_tree:validation.base_tree},null,2));
if(failures.length)process.exit(1);
