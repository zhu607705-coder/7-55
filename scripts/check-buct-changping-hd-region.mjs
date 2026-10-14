#!/usr/bin/env node
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import zlib from 'node:zlib';import {fileURLToPath} from 'node:url';
const root=path.resolve(process.argv[2]||path.join(path.dirname(fileURLToPath(import.meta.url)),'../godot_native'));
const c=path.join(root,'campuses/buct_changping');const read=p=>fs.readFileSync(path.join(c,p));
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');const p=JSON.parse(read('data/wenli_hd_region.json'));let count=0,failed=0;
function check(ok,name){count++;if(!ok)failed++;console.log(`${ok?'PASS':'FAIL'} ${name}`);}
function png(buf){
 const w=buf.readUInt32BE(16),h=buf.readUInt32BE(20),channels=buf[25]===6?4:3;if(buf[24]!==8||![2,6].includes(buf[25])||buf[28]!==0)throw Error('Unsupported PNG');
 const chunks=[];for(let i=8;i<buf.length;){const n=buf.readUInt32BE(i);if(buf.toString('ascii',i+4,i+8)==='IDAT')chunks.push(buf.subarray(i+8,i+8+n));i+=n+12;}
 const raw=zlib.inflateSync(Buffer.concat(chunks)),stride=w*channels,data=Buffer.alloc(w*h*channels),rgba=Buffer.alloc(w*h*4);
 const paeth=(a,b,c)=>{const v=a+b-c,aa=Math.abs(v-a),bb=Math.abs(v-b),cc=Math.abs(v-c);return aa<=bb&&aa<=cc?a:bb<=cc?b:c;};
 for(let y=0;y<h;y++){const filter=raw[y*(stride+1)];for(let x=0;x<stride;x++){const i=y*stride+x,a=x>=channels?data[i-channels]:0,b=y?data[i-stride]:0,c=y&&x>=channels?data[i-stride-channels]:0;const prediction=[0,a,b,Math.floor((a+b)/2),paeth(a,b,c)][filter];if(prediction===undefined)throw Error('PNG filter');data[i]=(raw[y*(stride+1)+1+x]+prediction)&255;}}
 for(let i=0;i<w*h;i++){data.copy(rgba,i*4,i*channels,i*channels+3);rgba[i*4+3]=channels===4?data[i*channels+3]:255;}return {w,h,rgba};
}
check(p.schema==='buct_wenli_hd_region_v1'&&p.quality_approved===true,'Approved bounded region profile');
check(JSON.stringify(p.roi_xywh)==='[630,615,240,240]'&&JSON.stringify(p.core_xywh)==='[642,627,216,216]','Declared240-square ROI and216-square core');
check(JSON.stringify(p.native_generated_size)==='[1254,1254]'&&JSON.stringify(p.runtime_size)==='[1200,1200]','Honest true native size and fixed5x runtime');
const ground=read('assets/wenli_hd_ground.png'),decoded=png(ground);
check(hash(ground)===p.ground_png_sha256&&p.ground_png_sha256==='2f1a8caa6e406cd8ad16113acf402b94a220013aeea69650f9056c7ad3e3ac63','Exact visually reviewed final ground PNG');
check(decoded.w===1200&&decoded.h===1200&&hash(decoded.rgba)===p.ground_rgba_sha256,'Independent standard-library PNG decode verifies runtime RGBA hash');
const source=read('assets/approved-changping.png'),src=png(source);
check(hash(source)===p.source_sha256&&p.source_sha256==='f92a8de6ef703bab4b2e471a49acc082dd4d128d264d99d3ed1818fdb0c93707','Original full-campus source bytes unchanged');
let collarDifferences=0;for(let y=0;y<1200;y++)for(let x=0;x<1200;x++){if(Math.min(x,y,1199-x,1199-y)>=10)continue;const a=(y*1200+x)*4,b=((615+Math.floor(y/5))*src.w+630+Math.floor(x/5))*4;for(let k=0;k<3;k++)if(decoded.rgba[a+k]!==src.rgba[b+k])collarDifferences++;}
check(collarDifferences===0,'Outermost2-source-pixel collar exactly equals original nearest RGB');
const shadow=read('data/wenli_hd_shadow.r8.bin');check(shadow.length===1440000&&hash(shadow)===p.shadow_r8_sha256,'Independent fixed R8 shadow verified');
const body=JSON.parse(read('data/wenli_registration.json'));check(hash(read('assets/wenli_body.png'))===p.body_sha256,'Immutable independent body bytes');
check(JSON.stringify(body.body_image_to_world)===JSON.stringify(p.immutable_body_transform),'Immutable body placement and scale');
check(hash(read('data/playable_route.json'))==='7042e3511177177b9db1501b587c0593376302cf707b22bf96b110d74d6fb7c6','Routes and navigation source unchanged');
const old=JSON.parse(read('data/east_road_extension.json'));const expected=['east_road_east_leaf_edge_01','east_road_east_leaf_edge_02','east_road_east_leaf_edge_03','east_road_east_leaf_edge_04','east_road_east_leaf_edge_05','east_road_east_leaf_edge_06','east_road_east_leaf_edge_07','east_road_west_leaf_edge_01','east_road_west_leaf_edge_02'];
check(p.foreground.length===9&&new Set(p.foreground.map(x=>x.id)).size===9&&p.foreground.every(x=>expected.includes(x.id)),'Exact nine unique original foreground owners');
let pixels=0,outside=0;for(const row of p.foreground){const ref=old.foliage.find(x=>x.id===row.id);const spans=ref.source_spans_y_x0_x1_exclusive;check(hash(Buffer.from(spans.map(s=>s.join(',')+';').join('')))===row.spans_sha256,'Original alpha source spans '+row.id);for(const [y,a,b] of spans)for(let x=a;x<b;x++){pixels++;if(x<630||x>=870||y<615||y>=855)outside++;}}
check(pixels===798&&outside===17,'798 original alpha pixels including17 outsideROI');
check(JSON.stringify(p.foreground.map(x=>x.baseline_y))==='[680,701,722,744,764,785,796,842,858]','All nine original foot depths retained');
const imp=read('assets/wenli_hd_ground.png.import').toString();check(imp.includes('mipmaps/generate=true')&&imp.includes('compress/mode=0')&&imp.includes('process/fix_alpha_border=false'),'Fresh imports use lossless mipmaps without alpha repair');
const dense=p.registration.dense_validation;check(dense.sample_count===1440000&&dense.maximum_displacement_source_px<=3&&dense.jacobian_min_singular>=.8&&dense.jacobian_max_singular<=1.25&&dense.jacobian_min_determinant>0,'Declared full-resolution constrained texture-only registration bounds');
const main=read('scripts/playable_campus.gd').toString();check(main.includes('enable_wenli_hd_region := true')&&main.includes('WENLI_HD_REGION.install(self)'),'Default outdoor scene enables atomic optional enhancement');
check(fs.readFileSync(path.join(root,'export_presets.cfg'),'utf8').includes('*.bin'),'Raw shadow included in existing native export policy');
check(fs.readFileSync(path.join(root,'tests/test_buct_changping_wenli.gd'),'utf8').includes('enable_wenli_hd_region = false')&&fs.readFileSync(path.join(root,'tests/capture_buct_changping_wenli.gd'),'utf8').includes('enable_wenli_hd_region = false'),'Original #138 isolation tests remain explicit and strict');
console.log(`BUCT_HD_REGION_SOURCE ${count-failed}/${count} passed`);process.exitCode=failed?1:0;
