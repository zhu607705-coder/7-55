/** Source-pixel contract for finale_stairwell.png (1672×941). */
export interface ChaseStairPoint { x: number; y: number }
export interface ChaseStairRect extends ChaseStairPoint { width: number; height: number }
export const CHASE_STAIR_SCENE_KEY = "chapter-four-chase-stairwell";
export const CHASE_STAIR_HANDOFF_KEY = "chapter4-chase-stair-handoff";
export interface ChaseStairHandoff { attempt: number; destination: "stairwell" | "A2"; leadDistance: number }
export const CHASE_STAIR_GUARD_FOOT = { width: 20, height: 14 } as const;
export const CHASE_STAIR_SIZE = { width: 1672, height: 941 } as const;
export const CHASE_STAIR_WALKABLE: readonly ChaseStairRect[] = [
  { x: 755, y: 878, width: 157, height: 63 },
  { x: 526, y: 760, width: 552, height: 124 },
  { x: 908, y: 385, width: 161, height: 380 },
  { x: 741, y: 385, width: 328, height: 82 },
  { x: 741, y: 165, width: 125, height: 302 },
  { x: 467, y: 166, width: 399, height: 69 },
  { x: 641, y: 0, width: 160, height: 172 },
  { x: 529, y: 228, width: 183, height: 82 },
  { x: 538, y: 304, width: 161, height: 216 },
  { x: 539, y: 498, width: 326, height: 28 }
];
export const CHASE_STAIR_LANDINGS = [
  { spawn: { x: 833, y: 826 }, guard: { x: 833, y: 922 } },
  { spawn: { x: 989, y: 426 }, guard: { x: 989, y: 568 } },
  { spawn: { x: 784, y: 207 }, guard: { x: 784, y: 348 } }
] as const;
export const CHASE_STAIR_GATES = [
  { x: 922, y: 389, width: 134, height: 74 },
  { x: 743, y: 176, width: 115, height: 75 }
] as const;
export const CHASE_STAIR_EXIT: ChaseStairRect = { x: 649, y: 22, width: 144, height: 68 };
export const CHASE_STAIR_ROUTE: readonly ChaseStairPoint[] = [
  { x: 833, y: 922 }, { x: 833, y: 826 }, { x: 989, y: 826 },
  { x: 989, y: 700 }, { x: 989, y: 426 }, { x: 784, y: 426 },
  { x: 784, y: 207 }, { x: 715, y: 207 }, { x: 715, y: 57 },
  { x: 610, y: 207 }, { x: 610, y: 269 }, { x: 610, y: 481 }, { x: 610, y: 512 }, { x: 807, y: 512 }
];
const EDGES = [[0,1],[1,2],[2,3],[3,4],[4,5],[5,6],[6,7],[7,8],[7,9],[9,10],[10,11],[11,12],[12,13]] as const;
export function chaseStairInside(point: ChaseStairPoint, rect: ChaseStairRect): boolean {
  return point.x >= rect.x && point.x <= rect.x + rect.width && point.y >= rect.y && point.y <= rect.y + rect.height;
}
export function chaseStairWalkable(point: ChaseStairPoint): boolean {
  return CHASE_STAIR_WALKABLE.some(rect => chaseStairInside(point, rect));
}
export function chaseStairFootOpen(point: ChaseStairPoint, halfWidth = CHASE_STAIR_GUARD_FOOT.width / 2, halfHeight = CHASE_STAIR_GUARD_FOOT.height / 2): boolean {
  return [-halfWidth, 0, halfWidth].every(x => [-halfHeight, 0, halfHeight].every(y => chaseStairWalkable({ x: point.x + x, y: point.y + y })));
}
export function chaseStairLineOpen(a: ChaseStairPoint, b: ChaseStairPoint): boolean {
  const steps = Math.max(1, Math.ceil(Math.hypot(b.x-a.x,b.y-a.y)/6));
  for (let i=0;i<=steps;i++) if (!chaseStairFootOpen({ x: a.x+(b.x-a.x)*i/steps, y:a.y+(b.y-a.y)*i/steps })) return false;
  return true;
}
/** Exact rectangle-complement decomposition, without an approximate collision grid. */
export function chaseStairBlockedRects(): ChaseStairRect[] {
  const xs = [...new Set([0, CHASE_STAIR_SIZE.width, ...CHASE_STAIR_WALKABLE.flatMap(r=>[r.x,r.x+r.width])])].sort((a,b)=>a-b);
  const ys = [...new Set([0, CHASE_STAIR_SIZE.height, ...CHASE_STAIR_WALKABLE.flatMap(r=>[r.y,r.y+r.height])])].sort((a,b)=>a-b);
  const blocks: ChaseStairRect[]=[];
  for(let row=0;row<ys.length-1;row++) {
    let start: number|null=null;
    for(let col=0;col<xs.length-1;col++) {
      const solid=!chaseStairWalkable({x:(xs[col]+xs[col+1])/2,y:(ys[row]+ys[row+1])/2});
      if(solid&&start===null)start=xs[col];
      if(start!==null&&(!solid||col===xs.length-2)) {
        const right=solid?xs[col+1]:xs[col];
        blocks.push({x:start,y:ys[row],width:right-start,height:ys[row+1]-ys[row]});start=null;
      }
    }
  }
  return blocks;
}
/** Dynamic endpoints connect only through body-clear sight lines to the authored graph. */
function navigationAnchor(point: ChaseStairPoint): ChaseStairPoint {
  if(chaseStairFootOpen(point))return point;
  // Player and guard foot boxes differ slightly. A wall-hugging player remains
  // catchable from an adjacent clear point rather than disconnecting the graph.
  for(const radius of [1,2,4])for(const [x,y] of [[1,0],[-1,0],[0,1],[0,-1],[1,1],[-1,1],[1,-1],[-1,-1]]) {
    const candidate={x:point.x+x*radius,y:point.y+y*radius};
    if(chaseStairFootOpen(candidate))return candidate;
  }
  return point;
}
export function chaseStairPath(from: ChaseStairPoint, to: ChaseStairPoint): ChaseStairPoint[] {
  from=navigationAnchor(from);to=navigationAnchor(to);
  if(chaseStairLineOpen(from,to))return [to];
  const nodes=[...CHASE_STAIR_ROUTE,from,to],source=nodes.length-2,target=nodes.length-1;
  const adjacent=nodes.map(()=>[] as number[]);
  for(const [a,b] of EDGES) if(chaseStairLineOpen(nodes[a],nodes[b])){adjacent[a].push(b);adjacent[b].push(a);}
  for(let i=0;i<CHASE_STAIR_ROUTE.length;i++)for(const end of [source,target])if(chaseStairLineOpen(nodes[i],nodes[end])){adjacent[i].push(end);adjacent[end].push(i);}
  const dist=nodes.map(()=>Infinity),previous=nodes.map(()=>-1),open=new Set(nodes.map((_,i)=>i));dist[source]=0;
  while(open.size){
    let current=-1;for(const i of open)if(current<0||dist[i]<dist[current])current=i;
    if(current<0||!Number.isFinite(dist[current]))break;
    open.delete(current);if(current===target)break;
    for(const n of adjacent[current]){const cost=dist[current]+Math.hypot(nodes[n].x-nodes[current].x,nodes[n].y-nodes[current].y);if(cost<dist[n]){dist[n]=cost;previous[n]=current;}}
  }
  if(previous[target]<0)return [];
  const path: ChaseStairPoint[]=[];for(let cursor=target;cursor!==source;cursor=previous[cursor]){if(cursor<0)return [];path.unshift(nodes[cursor]);}
  return path;
}
export function chaseStairDistance(from: ChaseStairPoint,to: ChaseStairPoint): number {
  const path=chaseStairPath(from,to);let last=from,total=0;
  for(const point of path){total+=Math.hypot(point.x-last.x,point.y-last.y);last=point;}
  return path.length?total:120;
}
