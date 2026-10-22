import {spawnSync} from 'node:child_process';
import {deflateSync} from 'node:zlib';
const crc=(b:Uint8Array)=>{let c=0xffffffff;for(const x of b){c^=x;for(let k=0;k<8;k++)c=(c>>>1)^((c&1)?0xedb88320:0);}return(c^0xffffffff)>>>0;};
function chunk(type:string,data:Uint8Array){const b=Buffer.alloc(data.length+12);b.writeUInt32BE(data.length);b.write(type,4);Buffer.from(data).copy(b,8);b.writeUInt32BE(crc(b.subarray(4,-4)),b.length-4);return b;}
class Canvas {
 width=128;height=128;data:Uint8ClampedArray;dataset={};flip=false;
 getContext(){const self=this;return {fillStyle:'#000000',font:'74px sans-serif',createImageData:(w:number,h:number)=>({data:new Uint8ClampedArray(w*h*4),width:w,height:h}),putImageData:(d:any)=>{self.data=d.data;},getImageData:()=>({data:self.data,width:self.width,height:self.height}),translate:()=>{},scale:(x:number,y:number)=>{if(y<0)self.flip=true;},drawImage:(other:any)=>{self.data=other.data;},fillRect(x:number,y:number,w:number,h:number){if(!self.data)self.data=new Uint8ClampedArray(self.width*self.height*4);const hex=this.fillStyle.replace('#','');const rgb=[parseInt(hex.slice(0,2),16),parseInt(hex.slice(2,4),16),parseInt(hex.slice(4,6),16),255];for(let yy=y;yy<y+h;yy++)for(let xx=x;xx<x+w;xx++)self.data.set(rgb,(yy*self.width+xx)*4);},fillText(text:string,x:number,y:number){
 const script=`from PIL import Image,ImageDraw,ImageFont
import sys
w,h=int(sys.argv[1]),int(sys.argv[2]); im=Image.frombytes('RGBA',(w,h),sys.stdin.buffer.read());d=ImageDraw.Draw(im);f=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',74);d.text((int(sys.argv[4]),int(sys.argv[5])),sys.argv[3],font=f,fill=sys.argv[6],anchor='mm');sys.stdout.buffer.write(im.tobytes())`;
 const r=spawnSync('python',['-c',script,String(self.width),String(self.height),text,String(x),String(y),this.fillStyle],{input:Buffer.from(self.data),maxBuffer:2000000});if(r.status!==0)throw Error(r.stderr.toString());self.data=new Uint8ClampedArray(r.stdout);
 }};}

 toBlob(callback:any){const header=Buffer.alloc(13);header.writeUInt32BE(this.width);header.writeUInt32BE(this.height,4);header[8]=8;header[9]=6;const stride=this.width*4;const raw=Buffer.alloc((stride+1)*this.height);for(let y=0;y<this.height;y++){const sy=this.flip?this.height-1-y:y;Buffer.from(this.data.buffer,this.data.byteOffset+sy*stride,stride).copy(raw,y*(stride+1)+1);}callback(new Blob([Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',header),chunk('IDAT',deflateSync(raw)),chunk('IEND',Buffer.alloc(0))])],{type:'image/png'}));}
}
(globalThis as any).window={devicePixelRatio:1,matchMedia:()=>({matches:false})};
(globalThis as any).document={createElement:()=>new Canvas()};
(globalThis as any).HTMLCanvasElement=Canvas;
(globalThis as any).FileReader=class {result:any;onloadend:any;readAsArrayBuffer(blob:Blob){blob.arrayBuffer().then(x=>{this.result=x;this.onloadend?.();});}readAsDataURL(blob:Blob){blob.arrayBuffer().then(x=>{this.result='data:'+blob.type+';base64,'+Buffer.from(x).toString('base64');this.onloadend?.();});}};
export const fakeCanvas=()=>new Canvas();
(globalThis as any).ImageData=class {data:any;width:number;height:number;constructor(data:any,width:number,height:number){this.data=data;this.width=width;this.height=height;}};
