// Disposable design prototype. No production controller, storage or saves.
export const target={x:480,y:306},camera={x:480,y:443};
export const makeState=()=>({board:{x:740,y:210},hour:8,records:new Set(),hints:false,shot:null});
export const scenery=[
 {id:'cabinet',x:120,y:175,width:80,depth:35},
 {id:'desk',x:235,y:260,width:138,depth:48},
 {id:'chair_back',x:235,y:327,width:42,depth:28},
 {id:'tool_cart',x:105,y:310,width:52,depth:32},
 {id:'parts_rack',x:850,y:280,width:84,depth:38},
 {id:'desk',x:835,y:440,width:138,depth:48},
 {id:'potted_plant',x:915,y:490,width:50,depth:24}
];
export function moveBoard(s,x,y){
 const b={x:Math.max(140,Math.min(820,x)),y:Math.max(170,Math.min(470,y))};
 const fixed=scenery.concat([{x:target.x,y:322,width:138,depth:48},{x:camera.x,y:camera.y,width:57,depth:38}]);
 const from={...s.board},steps=Math.max(1,Math.ceil(Math.hypot(b.x-from.x,b.y-from.y)/8));
 for(let i=1;i<=steps;i++){
  const at={x:from.x+(b.x-from.x)*i/steps,y:from.y+(b.y-from.y)*i/steps};
  if(fixed.some(o=>at.x-72<o.x+o.width*.44&&at.x+72>o.x-o.width*.44&&at.y-14<o.y&&at.y+14>o.y-o.depth))return false;
 }
 s.board=b;s.shot=null;return true;
}
export function convex(points){const p=points.slice().sort((a,b)=>a.x-b.x||a.y-b.y),cross=(o,a,b)=>(a.x-o.x)*(b.y-o.y)-(a.y-o.y)*(b.x-o.x);const lo=[],hi=[];for(const q of p){while(lo.length>1&&cross(lo[lo.length-2],lo[lo.length-1],q)<=0)lo.pop();lo.push(q);}for(const q of p.slice().reverse()){while(hi.length>1&&cross(hi[hi.length-2],hi[hi.length-1],q)<=0)hi.pop();hi.push(q);}lo.pop();hi.pop();return lo.concat(hi);}
export function shadow(s){const b=s.board,shift={x:s.hour===8?-290:290,y:-145},p=[{x:b.x-72,y:b.y-14},{x:b.x+72,y:b.y-14},{x:b.x+72,y:b.y+14},{x:b.x-72,y:b.y+14}];return convex(p.concat(p.map(q=>({x:q.x+shift.x,y:q.y+shift.y}))));}
export function contains(p,poly){let result=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const a=poly[i],b=poly[j];if((a.y>p.y)!==(b.y>p.y)&&p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x)result=!result;}return result;}
export function assess(s){const poly=shadow(s),clear=[[-10,-8],[10,-8],[10,8],[-10,8]].every(([x,y])=>contains({x:target.x+x,y:target.y+y},poly));let blocked=false;for(let i=0;i<=50;i++){const t=i/50,x=camera.x+(target.x-camera.x)*t,y=camera.y+(target.y-camera.y)*t;if(Math.abs(x-s.board.x)<76&&Math.abs(y-s.board.y)<24){blocked=true;break;}}return {clear,blocked,success:clear&&!blocked};}
export function shoot(s){const result=assess(s);s.shot=result;if(result.success)s.records.add(s.hour);return result;}
if(typeof document!=='undefined'){
 const canvas=document.querySelector('#game'),ctx=canvas.getContext('2d'),message=document.querySelector('#message'),records=document.querySelector('#records'),sx=document.querySelector('#board-x'),sy=document.querySelector('#board-y');
 const s=makeState(),images={},manifest=await (await fetch('sprites.json')).json();let selected=false,drag=null,last=0,loaded=true;
 await Promise.all(Object.entries(manifest).map(([k,v])=>new Promise(resolve=>{const img=new Image();img.onload=()=>{images[k]=img;resolve();};img.onerror=()=>{loaded=false;message.textContent='素材未加载，请刷新页面。';resolve();};img.src=v.file;})));
 function sprite(id,x,y,width,frame=0){const img=images[id],m=manifest[id];if(!img)return;const b=m.crop,w=b[2],h=b[3],height=width*h/w;ctx.drawImage(img,b[0]+frame*w,b[1],w,h,x-width/2,y-height,width,height);}
 function polygon(p,fill){ctx.fillStyle=fill;ctx.beginPath();p.forEach((q,i)=>i?ctx.lineTo(q.x,q.y):ctx.moveTo(q.x,q.y));ctx.closePath();ctx.fill();}
 function update(){sx.value=s.board.x;sy.value=s.board.y;records.textContent='两种光向记录：'+s.records.size+' / 2';document.querySelectorAll('[data-hour]').forEach(b=>b.setAttribute('aria-pressed',+b.dataset.hour===s.hour));}
 function say(t){message.textContent=t;}
 function trial(){if(!loaded)return;const r=shoot(s);update();if(r.blocked)say('取景被白板挡住了。它挡住了光，也挡住了演示标记。');else if(!r.clear)say('试拍回放：标记仍然过亮。看一看白板投影落在哪里，再移动一点。');else if(s.records.size===2)say('记录员：两边入光都能拍清楚了！这套临时摆法有效，下一步可以把它做成小附件。');else say('记录员：这一侧拍清楚了。再换另一侧入光试一次，看看原来的摆法是否还管用。');}
 document.querySelector('#shoot').onclick=trial;
 document.querySelector('#talk').onclick=()=>say(s.records.size===2?'记录员：这次我能照着你的方法重现了。下一步去工作台，把白板的作用做进附件里。':s.shot?'记录员：先别同时改所有东西。推一点，拍一次，看问题变在了哪里。':'记录员：我需要把展品和标记都拍清楚。你帮我挪一下白板，我来试拍。');
 document.querySelector('#hint').onclick=()=>{s.hints=!s.hints;document.querySelector('#hint').textContent=s.hints?'隐藏光路':'显示光路';};
 document.querySelector('#reset').onclick=()=>{Object.assign(s,makeState());document.querySelector('#hint').textContent='显示光路';update();say('场景已重摆。先试拍，再根据画面调整白板。');};
 document.querySelectorAll('[data-hour]').forEach(b=>b.onclick=()=>{s.hour=+b.dataset.hour;s.shot=null;update();say('入光换到'+(s.hour===8?'东':'西')+'侧。白板的位置没有自动改变，重新观察投影。');});
 function move(x,y){if(!moveBoard(s,x,y))say('白板底座碰到物件了，从旁边绕过去。');selected=true;update();}
 sx.oninput=()=>move(+sx.value,s.board.y);sy.oninput=()=>move(s.board.x,+sy.value);
 const point=e=>{const b=canvas.getBoundingClientRect();return {x:(e.clientX-b.left)*960/b.width,y:(e.clientY-b.top)*540/b.height};};
 canvas.onpointerdown=e=>{const p=point(e);canvas.focus();if(p.x>s.board.x-86&&p.x<s.board.x+86&&p.y>s.board.y-155&&p.y<s.board.y+20){drag={x:p.x-s.board.x,y:p.y-s.board.y};selected=true;canvas.setPointerCapture(e.pointerId);}else if(Math.hypot(p.x-camera.x,p.y-(camera.y-50))<60)trial();else if(p.x>140&&p.x<220&&p.y>300&&p.y<430)document.querySelector('#talk').click();};
 canvas.onpointermove=e=>{if(!drag)return;const p=point(e);move(p.x-drag.x,p.y-drag.y);};
 canvas.onpointerup=canvas.onpointercancel=()=>{drag=null;};
 canvas.onkeydown=e=>{const d={ArrowLeft:[-8,0],ArrowRight:[8,0],ArrowUp:[0,-8],ArrowDown:[0,8]}[e.key];if(d){move(s.board.x+d[0],s.board.y+d[1]);e.preventDefault();}else if(e.code==='Space'){e.preventDefault();trial();}};
 function draw(now){const dt=Math.min(.1,(now-last)/1000);last=now;ctx.clearRect(0,0,960,540);ctx.fillStyle='#b1b7b8';ctx.fillRect(0,0,960,540);ctx.imageSmoothingEnabled=false;
  if(images.floor){const m=manifest.floor,im=images.floor;ctx.globalAlpha=.36;for(let y=0;y<540;y+=240)for(let x=0;x<960;x+=240)ctx.drawImage(im,250,650,240,240,x,y,240,240);ctx.globalAlpha=1;}
  const light=s.hour===8?{x:960,y:30}:{x:0,y:30};const gradient=ctx.createLinearGradient(light.x,light.y,480,540);gradient.addColorStop(0,'#ffe9ad66');gradient.addColorStop(1,'#fbe4b000');ctx.fillStyle=gradient;ctx.fillRect(0,0,960,540);
  polygon(shadow(s),'#64748955');
  ctx.fillStyle='#283e4540';ctx.fillRect(408,306,144,18);ctx.fillStyle='#ffffff30';ctx.fillRect(60,55,840,2);ctx.fillRect(60,485,840,2);
  for(const o of scenery){ctx.fillStyle='#293e4526';ctx.beginPath();ctx.ellipse(o.x,o.y-o.depth/2,o.width*.45,o.depth*.55,0,0,Math.PI*2);ctx.fill();}
  const scene=scenery.map(o=>({y:o.y,fn:()=>{sprite(o.id,o.x,o.y,o.width);if(o.id==='desk'&&o.x===235){sprite('desk_divider',o.x,o.y-50,110);sprite('monitor_front',o.x,o.y-37,45);}if(o.id==='desk'&&o.x===835)sprite('soldering_station',o.x,o.y-42,45);}}));
  scene.push({y:322,fn:()=>{sprite('desk',480,322,138);sprite('printer_3d',480,278,54);ctx.fillStyle=assess(s).clear?'#3a6779':'#fff7df';ctx.fillRect(470,298,20,16);ctx.strokeStyle='#d5e5dd';ctx.strokeRect(470,298,20,16);}},
   {y:425,fn:()=>{sprite('student',180,425,96,Math.floor(now/1800)%2);ctx.fillStyle='#1c3038';ctx.font='14px system-ui';ctx.textAlign='center';ctx.fillText('记录员',180,447);}},
   {y:camera.y,fn:()=>sprite('camera_tripod',camera.x,camera.y,57)},
   {y:s.board.y,fn:()=>{sprite('whiteboard',s.board.x,s.board.y,156);if(selected||drag){ctx.strokeStyle='#4d7e78';ctx.lineWidth=2;ctx.strokeRect(s.board.x-82,s.board.y-151,164,159);}}}
  );scene.sort((a,b)=>a.y-b.y).forEach(q=>q.fn());
  if(s.hints){ctx.setLineDash([6,6]);ctx.strokeStyle='#294e5fb0';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(camera.x,camera.y-65);ctx.lineTo(target.x,target.y);ctx.stroke();ctx.strokeStyle='#b47b40';ctx.beginPath();ctx.moveTo(light.x,180);ctx.lineTo(target.x,target.y);ctx.stroke();ctx.setLineDash([]);ctx.font='13px system-ui';ctx.fillStyle='#24404a';ctx.textAlign='left';ctx.fillText('相机取景线',505,390);ctx.fillText('展品标记',420,345);}
  ctx.font='12px system-ui';ctx.fillStyle='#40575d';ctx.textAlign='center';ctx.fillText('N ↑',480,28);ctx.fillText(s.hour===8?'东侧入光 ↙':'↘ 西侧入光',s.hour===8?850:110,65);
  if(s.shot){const box={x:716,y:62,w:210,h:114};ctx.fillStyle='#152a33e8';ctx.fillRect(box.x,box.y,box.w,box.h);ctx.strokeStyle='#9ab2a8';ctx.strokeRect(box.x,box.y,box.w,box.h);ctx.font='12px system-ui';ctx.fillStyle='#dce8df';ctx.textAlign='left';ctx.fillText('试拍回放',box.x+12,box.y+23);ctx.fillStyle=s.shot.blocked?'#879aa0':s.shot.clear?'#527c85':'#fff7e8';ctx.fillRect(box.x+58,box.y+43,90,43);ctx.fillStyle='#e5ede8';ctx.fillText(s.shot.blocked?'白板遮住了镜头':s.shot.clear?'标记清楚可见':'强光使标记过曝',box.x+12,box.y+103);}
  requestAnimationFrame(draw);
 }
 update();requestAnimationFrame(draw);
 document.querySelectorAll('[data-stair]').forEach(button=>button.onclick=()=>{
  const preview=document.querySelector('#stair-image');preview.src='stairs_'+button.dataset.stair+'.png';preview.alt=button.textContent+' · Godot 实际场景';
  document.querySelectorAll('[data-stair]').forEach(b=>b.setAttribute('aria-pressed',b===button));
 });
 document.querySelectorAll('[data-density]').forEach(button=>button.onclick=()=>{
  const id=button.dataset.density;
  const images={'workshop-room':'workshop_room.png',workbench:'workshop_running.png','workbench-result':'workshop_success.png',hall:'f2_hall.png','hall-under':'f2_hall_under.png','hall-behind':'f2_hall_behind.png',before:'density_before.png',after:'density_after.png',lab:'f2_electrical.png',pantry:'f3_pantry.png','pantry-before':'pantry_before.png',focus:'f4_focus_a.png',atrium:'f3_atrium_corridor.png'};
  const preview=document.querySelector('#density-image');preview.src=images[id];preview.alt=button.textContent+' · Godot 实际场景';
  document.querySelectorAll('[data-density]').forEach(b=>b.setAttribute('aria-pressed',b===button));
 });
}
