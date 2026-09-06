export interface GuardPoint { x: number; y: number }
export interface GuardWall extends GuardPoint { width: number; height: number }
/** A* against the same source-pixel rectangles as Arcade; never cuts a furniture corner. */
export function createGuardNavigation(walls: readonly GuardWall[], width=1672, height=941) {
  const size=14, cols=Math.ceil(width/size), rows=Math.ceil(height/size);
  const free=(p:GuardPoint)=>p.x>=12&&p.y>=10&&p.x<=width-12&&p.y<=height-10&&!walls.some(r=>p.x>r.x-10&&p.x<r.x+r.width+10&&p.y>r.y-7&&p.y<r.y+r.height+7);
  const point=(id:number)=>({x:(id%cols+.5)*size,y:(Math.floor(id/cols)+.5)*size});
  const open=Uint8Array.from({length:cols*rows},(_,id)=>Number(free(point(id))));
  const line=(a:GuardPoint,b:GuardPoint)=>{const count=Math.ceil(Math.hypot(a.x-b.x,a.y-b.y)/5);for(let i=0;i<=count;i++){const t=count?i/count:0;if(!free({x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t}))return false}return true};
  const nearest=(p:GuardPoint)=>{let best=-1,distance=Infinity;for(let id=0;id<open.length;id++){if(!open[id])continue;const q=point(id),d=Math.hypot(q.x-p.x,q.y-p.y);if(d<distance&&line(p,q)){best=id;distance=d}}return best};
  return (from:GuardPoint,to:GuardPoint):GuardPoint[]=>{
    if(line(from,to))return [to];
    const start=nearest(from),goal=nearest(to);if(start<0||goal<0)return [];
    const costs=new Map<number,number>([[start,0]]),previous=new Map<number,number>(),closed=new Set<number>(),queue=[start];
    const h=(id:number)=>Math.hypot(point(id).x-point(goal).x,point(id).y-point(goal).y);
    while(queue.length){queue.sort((a,b)=>(costs.get(b)!+h(b))-(costs.get(a)!+h(a)));const current=queue.pop()!;if(current===goal){const ids=[current];while(previous.has(ids[0]))ids.unshift(previous.get(ids[0])!);const path=ids.map(point);path.push(to);while(path.length>1&&line(from,path[1]))path.shift();return path}
      if(closed.has(current))continue;closed.add(current);const x=current%cols,y=Math.floor(current/cols);
      for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1],[1,1],[1,-1],[-1,1],[-1,-1]]){const nx=x+dx,ny=y+dy,n=ny*cols+nx;if(nx<0||nx>=cols||ny<0||ny>=rows||!open[n]||closed.has(n)||!line(point(current),point(n)))continue;const c=costs.get(current)!+Math.hypot(dx,dy)*size;if(c<(costs.get(n)??Infinity)){costs.set(n,c);previous.set(n,current);queue.push(n)}}
    }return [];
  };
}
