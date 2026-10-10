/** Deterministic rules for 追光灯辞职以后. No Phaser, DOM, assets or save writes. */
export const THEATER_SHOW_STEP_MS = 50;
export const THEATER_SHOW_MAX_TICKS = 1600;
export const THEATER_SHOW_BOUNDS = { left: 58, right: 902, top: 132, bottom: 409 } as const;
export const THEATER_SHOW_ACTS = [
  { title: "椅子申请当月亮", subtitle: "追上游走的逗号。预判轨迹，绕开走动的椅子。", glyph: "，", color: 0xffcf68, count: 4 },
  { title: "你的影子迟到了", subtitle: "两枚问号成一组。先点亮任一枚，及时把光接到另一枚。", glyph: "？", color: 0x94f3d0, count: 5 },
  { title: "观众席正在退潮", subtitle: "先在一端留光，再赶到另一端。三秒前的光影会替你接光。", glyph: "！", color: 0xff94bc, count: 6 }
] as const;
export interface TheaterShowPoint { x: number; y: number }
export interface TheaterShowInput { x: number; y: number; dash: boolean }
export interface TheaterSpotlightAttempt {
  version: 2;
  round: number;
  attempt: number;
  inputs: TheaterShowInput[];
}
export interface TheaterShowState {
  round: number;
  attempt: number;
  tick: number;
  status: "running" | "won" | "lost";
  head: TheaterShowPoint;
  trail: TheaterShowPoint[];
  history: TheaterShowPoint[];
  collected: number[];
  focus: number[];
  primed: number;
  pairTicks: number;
  pairFailures: number;
  lives: number;
  invulnerable: number;
  dashTicks: number;
  dashCooldown: number;
  dashHeld: boolean;
  lastDirection: TheaterShowPoint;
  lastEvent: "none" | "eat" | "hurt" | "dash" | "exit" | "prime" | "reset";
}
export interface TheaterShowHazard extends TheaterShowPoint { id: string; radius: number; kind: "chair" | "shadow" | "eye" }
const FOOD_POINTS: readonly TheaterShowPoint[] = [
  { x: 300, y: 193 }, { x: 515, y: 341 }, { x: 738, y: 187 },
  { x: 800, y: 361 }, { x: 346, y: 344 }, { x: 567, y: 178 }
];
export function createTheaterShow(round: number, attempt = 0): TheaterShowState {
  if (!Number.isInteger(round) || round < 0 || round >= THEATER_SHOW_ACTS.length) throw new Error("Invalid theater act");
  const head = { x: 156, y: 280 };
  return { round, attempt, tick: 0, status: "running", head, trail: [{ ...head }], history: [{ ...head }], collected: [], focus: [0,0,0,0,0,0],primed:-1,pairTicks:0,pairFailures:0,
    lives: 3, invulnerable: 0, dashTicks: 0, dashCooldown: 0, dashHeld: false, lastDirection: { x: 1, y: 0 }, lastEvent: "none" };
}
export function getTheaterFoodPosition(state: TheaterShowState, id: number): TheaterShowPoint {
  if(state.round===2)return {...FOOD_POINTS[id]};
  const t=state.tick*0.05*Math.max(0.82,1-state.attempt*0.035);
  return { x:FOOD_POINTS[id].x+Math.sin(t*(0.85+state.round*0.15+id*0.09)+id*1.4)*[35,48,60][state.round],
    y:FOOD_POINTS[id].y+Math.cos(t*(1.1+id*0.08)+id*1.7)*[18,23,29][state.round] };
}
export function getTheaterFocusTicks(state: TheaterShowState): number { return [1,20,16][state.round]; }
export function getTheaterLightRadius(state: TheaterShowState): number { return state.round===0?25:75; }
export function getTheaterPairWindow(state: TheaterShowState): number { return state.round===1?110:125; }
export function getTheaterPairs(state: TheaterShowState): number[][] { return state.round===1?[[0,2],[4,3]]:[[0,2],[4,3],[5,1]]; }
export function getTheaterPartner(state: TheaterShowState,id: number): number {
  const pair=getTheaterPairs(state).find(p=>p.includes(id));return pair?(pair[0]===id?pair[1]:pair[0]):-1;
}
export function getTheaterActiveFood(state: TheaterShowState): number[] {
  if(state.round===0)return [0,1,2,3].filter(id=>!state.collected.includes(id));
  if(state.primed>=0)return [getTheaterPartner(state,state.primed)];
  if(state.round===1&&state.collected.length===4)return [1];
  return getTheaterPairs(state).flat().filter(id=>!state.collected.includes(id));
}
export function getTheaterEcho(state: TheaterShowState): TheaterShowPoint | null {
  return state.round===2&&state.history.length>60?state.history[state.history.length-61]:null;
}
export function isTheaterFoodBlocked(state: TheaterShowState,id: number,origin: TheaterShowPoint=state.head): boolean {
  if(state.round===0)return false;
  const p=getTheaterFoodPosition(state,id),dx=p.x-origin.x,dy=p.y-origin.y;
  return getTheaterShowHazards(state).some(h=>{
    if(h.kind!=='chair')return false;
    const ratio=clamp(((h.x-origin.x)*dx+(h.y-origin.y)*dy)/Math.max(.001,dx*dx+dy*dy),0,1);
    return Math.hypot(origin.x+dx*ratio-h.x,origin.y+dy*ratio-h.y)<h.radius+5;
  });
}
function resetTheaterPair(state: TheaterShowState): void {
  if(state.primed>=0)state.pairFailures++;
  state.primed=-1;state.pairTicks=0;state.focus=[0,0,0,0,0,0];
}
export function getTheaterShowFood(state: TheaterShowState): (TheaterShowPoint & { id: number })[] {
  return FOOD_POINTS.slice(0, THEATER_SHOW_ACTS[state.round].count)
    .map((_p, id) => ({ ...getTheaterFoodPosition(state,id), id }))
    .filter(p => !state.collected.includes(p.id));
}
export function getTheaterShowMouth(state: TheaterShowState): TheaterShowPoint {
  return { x: 839, y: state.round === 2 ? 266 + Math.sin(state.tick * 0.035) * 36 : 274 };
}
export function getTheaterShowHazards(state: TheaterShowState): TheaterShowHazard[] {
  const t = state.tick * 0.05 * Math.max(0.72, 1 - state.attempt * 0.045);
  const hazards: TheaterShowHazard[] = [
    { id: "chair-0", kind: "chair", x: 421 + Math.sin(t * 0.8) * 66, y: 264 + Math.sin(t * 1.3) * 82, radius: 21 },
    { id: "chair-1", kind: "chair", x: 655 + Math.sin(t * 0.67 + 2) * 72, y: 281 + Math.cos(t * 1.1) * 78, radius: 21 }
  ];
  if (state.round === 1 && state.history.length > 60) {
    const p = state.history[state.history.length - 61];
    hazards.push({ id: "late-shadow", kind: "shadow", ...p, radius: 22 });
  }
  if (state.round === 2) hazards.push({ id: "audience-eye", kind: "eye", x: 495 + Math.cos(t * 0.9) * 125, y: 255 + Math.sin(t * 1.5) * 88, radius: 23 });
  return hazards;
}
const clamp = (value: number, min: number, max: number) => Math.max(min, Math.min(max, value));
export function getTheaterPointerAxis(state: TheaterShowState,target: TheaterShowPoint,dash=false): TheaterShowPoint {
  let nextDash=Math.max(0,state.dashTicks-1);
  if(dash && !state.dashHeld && state.dashCooldown<=1)nextDash=9;
  const distance=nextDash>0?16.5:8.3;
  const wind=state.round===2 && nextDash===0;
  const dx=(clamp(target.x,71,889)-state.head.x-(wind?Math.cos((state.tick+1)*0.019)*0.7:0))/distance;
  const dy=(clamp(target.y,145,396)-state.head.y-(wind?Math.sin((state.tick+1)*0.028)*1.5:0))/distance;
  const length=Math.max(1,Math.hypot(dx,dy));
  return {x:dx/length,y:dy/length};
}
export function stepTheaterShow(state: TheaterShowState, input: TheaterShowInput): TheaterShowState {
  if (state.status !== "running") return state;
  const next: TheaterShowState = { ...state, tick: state.tick + 1, head: { ...state.head }, collected: [...state.collected], focus: [...state.focus],
    invulnerable: Math.max(0, state.invulnerable - 1), dashTicks: Math.max(0, state.dashTicks - 1),
    dashCooldown: Math.max(0, state.dashCooldown - 1), dashHeld: input.dash, lastEvent: "none" };
  let dx = clamp(input.x, -1, 1), dy = clamp(input.y, -1, 1);
  const length = Math.hypot(dx, dy);
  if (length > 0.001) { next.lastDirection = { x: dx / length, y: dy / length }; if(length>1) { dx/=length; dy/=length; } }
  if (input.dash && !state.dashHeld && next.dashCooldown === 0) {
    next.dashTicks = 9; next.dashCooldown = 100; next.lastEvent = "dash";
  }
  const speed = next.dashTicks > 0 ? 330 : 166;
  if (next.dashTicks > 0 && length < 0.001) { dx = state.lastDirection.x; dy = state.lastDirection.y; }
  next.head.x += dx * speed * 0.05;
  next.head.y += dy * speed * 0.05;
  if (state.round === 2 && next.dashTicks === 0) {
    next.head.y += Math.sin(next.tick * 0.028) * 1.5;
    next.head.x += Math.cos(next.tick * 0.019) * 0.7;
  }
  next.head.x = clamp(next.head.x, THEATER_SHOW_BOUNDS.left + 13, THEATER_SHOW_BOUNDS.right - 13);
  next.head.y = clamp(next.head.y, THEATER_SHOW_BOUNDS.top + 13, THEATER_SHOW_BOUNDS.bottom - 13);
  next.history = [...state.history, { ...next.head }].slice(-100);
  next.trail = Math.hypot(next.head.x - state.trail[0].x, next.head.y - state.trail[0].y) > 3
    ? [{ ...next.head }, ...state.trail].slice(0, 24 + next.collected.length * 5)
    : state.trail;
  if(next.primed>=0){next.pairTicks--;if(next.pairTicks<=0){resetTheaterPair(next);next.lastEvent='reset';}}
  if(state.collected.length>=THEATER_SHOW_ACTS[next.round].count&&Math.hypot(getTheaterShowMouth(next).x-next.head.x,getTheaterShowMouth(next).y-next.head.y)<35){next.status='won';next.lastEvent='exit';return next;}
  let hurt=false;
  if (next.invulnerable === 0 && next.dashTicks === 0) {
    const hazard = getTheaterShowHazards(next).find(h => Math.hypot(h.x - next.head.x, h.y - next.head.y) < h.radius + 10);
    if (hazard) { next.lives -= 1; next.invulnerable = 36; next.lastEvent = "hurt"; hurt=true; resetTheaterPair(next); }
  }
  const eligible=getTheaterActiveFood(next);
  const selected=getTheaterShowFood(next).filter(p=>eligible.includes(p.id)&&Math.hypot(p.x-next.head.x,p.y-next.head.y)<getTheaterLightRadius(next)&&!isTheaterFoodBlocked(next,p.id))
    .sort((a,b)=>Math.hypot(a.x-next.head.x,a.y-next.head.y)-Math.hypot(b.x-next.head.x,b.y-next.head.y))[0]?.id??-1;
  if(next.round===2){
    const ghost=getTheaterEcho(next);let charged:number[]=[];
    if(!hurt&&ghost&&next.dashTicks===0){
      for(const pair of getTheaterPairs(next)){
        if(next.collected.includes(pair[0]))continue;
        for(const side of [0,1]){const own=pair[side],other=pair[1-side],a=getTheaterFoodPosition(next,own),b=getTheaterFoodPosition(next,other);
          if(Math.hypot(next.head.x-a.x,next.head.y-a.y)<getTheaterLightRadius(next)&&Math.hypot(ghost.x-b.x,ghost.y-b.y)<getTheaterLightRadius(next)&&!isTheaterFoodBlocked(next,own)&&!isTheaterFoodBlocked(next,other,ghost)){charged=pair;break;}}
        if(charged.length)break;
      }
    }
    for(const food of getTheaterShowFood(next))next.focus[food.id]=charged.includes(food.id)?next.focus[food.id]+1:0;
    if(charged.length&&next.focus[charged[0]]>=getTheaterFocusTicks(next)){next.collected.push(...charged);next.focus=[0,0,0,0,0,0];next.lastEvent='eat';}
  }else if(!hurt){
  for(const food of getTheaterShowFood(next)){
    if(food.id===next.primed)continue;
    if(food.id===selected&&(next.round===0||next.dashTicks===0))next.focus[food.id]++;
    else next.focus[food.id]=Math.max(0,next.focus[food.id]-2);
    if(next.focus[food.id]<getTheaterFocusTicks(next))continue;
    if(next.round===0||(next.round===1&&food.id===1)){next.collected.push(food.id);next.lastEvent='eat';}
    else if(next.primed<0){next.primed=food.id;next.pairTicks=getTheaterPairWindow(next);next.lastEvent='prime';}
    else{next.collected.push(next.primed,food.id);next.primed=-1;next.pairTicks=0;next.focus=[0,0,0,0,0,0];next.lastEvent='eat';}
  }
  }
  // Damage cancels new exposure on this tick. An already completed exit still wins above.
  const mouth = getTheaterShowMouth(next);
  if (next.collected.length >= THEATER_SHOW_ACTS[next.round].count && Math.hypot(mouth.x - next.head.x, mouth.y - next.head.y) < 35) {
    next.status = "won"; next.lastEvent = "exit"; return next;
  }
  if (next.lives <= 0 || next.tick >= THEATER_SHOW_MAX_TICKS) next.status = "lost";
  return next;
}
/** Replay the actual bounded movement trace; UI outcome flags are never accepted. */
export function validateTheaterSpotlightAttempt(value: unknown, round: number, attempt: number): TheaterShowState | null {
  if (!value || typeof value !== "object") return null;
  const candidate = value as Partial<TheaterSpotlightAttempt>;
  if (candidate.version !== 2 || candidate.round !== round || candidate.attempt !== attempt
    || !Array.isArray(candidate.inputs) || candidate.inputs.length < 1 || candidate.inputs.length > THEATER_SHOW_MAX_TICKS) return null;
  let state = createTheaterShow(round, attempt);
  for (const input of candidate.inputs) {
    if (state.status !== "running" || !input || typeof input.x !== "number" || typeof input.y !== "number"
      || !Number.isFinite(input.x) || !Number.isFinite(input.y) || Math.abs(input.x) > 1 || Math.abs(input.y) > 1 || typeof input.dash !== "boolean") return null;
    state = stepTheaterShow(state, input);
  }
  return state.status === "running" ? null : state;
}
