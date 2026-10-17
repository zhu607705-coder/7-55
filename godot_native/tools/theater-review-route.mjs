// Deterministic QA driver only. The player never receives automatic steering.
export function playTheaterRoute(m,round,attempt=0){let s=m.createTheaterShow(round,attempt),inputs=[],samples=[],leg=0,dwell=0,group=-1,phaseStart=0,events=[];
while(s.status==='running'){
 let target=m.getTheaterShowMouth(s),dash=false;
 if(round===2&&s.collected.length<6){
  const index=m.getTheaterPairs(s).findIndex(pair=>!s.collected.includes(pair[0]));const pair=m.getTheaterPairs(s)[index];
  if(group!==index){group=index;leg=0;dwell=0;phaseStart=s.tick;}
  const a=m.getTheaterFoodPosition(s,pair[0]),b=m.getTheaterFoodPosition(s,pair[1]),dx=b.x-a.x,dy=b.y-a.y,l=Math.hypot(dx,dy);
  const standA={x:a.x+dx/l*50,y:a.y+dy/l*50},standB={x:b.x-dx/l*50,y:b.y-dy/l*50};
  if(leg===0){target=standA;if(Math.hypot(s.head.x-target.x,s.head.y-target.y)<3){leg=1;dwell=0;}}
  else if(leg===1){target=standA;dwell++;if(dwell>=36){leg=2;phaseStart=s.tick;}}
  else{target=standB;if(s.tick-phaseStart<2&&s.dashCooldown<=1)dash=true;if(s.tick-phaseStart>100){leg=0;dwell=0;}}
 }else if(s.collected.length<m.THEATER_SHOW_ACTS[round].count){
  const active=m.getTheaterActiveFood(s);const foods=m.getTheaterShowFood(s).filter(p=>active.includes(p.id));
  const aim=foods.sort((a,b)=>Math.hypot(a.x-s.head.x,a.y-s.head.y)-Math.hypot(b.x-s.head.x,b.y-s.head.y))[0];target=aim;
  if(round===1){let best=Infinity;for(let i=0;i<16;i++){const angle=i*Math.PI/8,candidate={x:aim.x+Math.cos(angle)*48,y:aim.y+Math.sin(angle)*48};if(candidate.x<71||candidate.x>889||candidate.y<145||candidate.y>396||m.isTheaterFoodBlocked(s,aim.id,candidate))continue;let score=Math.hypot(candidate.x-s.head.x,candidate.y-s.head.y);for(const h of m.getTheaterShowHazards(s)){const d=Math.hypot(candidate.x-h.x,candidate.y-h.y);if(d<48)score+=1000;}if(score<best){best=score;target=candidate;}}}
  const danger=m.getTheaterShowHazards(s).some(h=>Math.hypot(h.x-s.head.x,h.y-s.head.y)<70);
  if(danger&&s.invulnerable===0&&s.dashCooldown<=1)dash=true;
 }
 let axis=m.getTheaterPointerAxis(s,target,dash);
 if(round===1&&s.invulnerable===0&&s.dashTicks===0&&!dash){for(const h of m.getTheaterShowHazards(s)){const d=Math.hypot(h.x-s.head.x,h.y-s.head.y);if(d<68){axis.x+=(s.head.x-h.x)/Math.max(1,d)*1.8;axis.y+=(s.head.y-h.y)/Math.max(1,d)*1.8;}}const n=Math.max(1,Math.hypot(axis.x,axis.y));axis.x/=n;axis.y/=n;}
 const input={...axis,dash};inputs.push(input);s=m.stepTheaterShow(s,input);
 if(['eat','prime','reset','hurt'].includes(s.lastEvent))events.push([s.tick,s.lastEvent,s.collected.join(','),s.primed,s.lives]);
 if(s.tick%5===0||s.status!=='running')samples.push({tick:s.tick,head:s.head,lives:s.lives,focus:s.focus,collected:s.collected,status:s.status,event:s.lastEvent,primed:s.primed,pairTicks:s.pairTicks,pairFailures:s.pairFailures,echo:m.getTheaterEcho(s)});
}
return {state:s,proof:{version:2,round,attempt,inputs},samples,events};}
