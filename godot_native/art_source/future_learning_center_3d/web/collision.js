export function inPolygon(x,z,poly) {
  let inside=false;
  for(let i=0,j=poly.length-1;i<poly.length;j=i++) {
    const [a,b]=poly[i], [c,d]=poly[j];
    if((b>z)!==(d>z) && x<(c-a)*(z-b)/(d-b)+a) inside=!inside;
  }
  return inside;
}
export function segmentDistance(x,z,a,b) {
  const dx=b[0]-a[0],dz=b[1]-a[1],den=dx*dx+dz*dz;
  const t=den?Math.max(0,Math.min(1,((x-a[0])*dx+(z-a[1])*dz)/den)):0;
  return Math.hypot(x-a[0]-t*dx,z-a[1]-t*dz);
}
export function canStand(layout,floor,x,z,r=layout.radius) {
  if(!Number.isFinite(x)||!Number.isFinite(z)||x<r||z<r||x>layout.width-r||z>layout.length-r)return false;
  const f=layout.floors[floor];if(!f)return false;
  for(const poly of f.voids) {
    if(inPolygon(x,z,poly))return false;
    for(let i=0;i<poly.length;i++)if(segmentDistance(x,z,poly[i],poly[(i+1)%poly.length])<=r)return false;
  }
  for(const c of f.colliders) {
    if(c.segment && segmentDistance(x,z,...c.segment)<=r+c.width/2)return false;
    if(c.rect) {
      const [a,b,d,e]=c.rect, cx=Math.max(a,Math.min(d,x)),cz=Math.max(b,Math.min(e,z));
      if(Math.hypot(x-cx,z-cz)<r)return false;
    }
  }
  return true;
}
export function moveBody(layout,floor,pos,dx,dz) {
  const steps=Math.max(1,Math.ceil(Math.hypot(dx,dz)/.07));
  let x=pos[0],z=pos[1];
  for(let i=0;i<steps;i++) {
    const nx=x+dx/steps,nz=z+dz/steps;
    if(canStand(layout,floor,nx,nz)){x=nx;z=nz;continue;}
    if(canStand(layout,floor,nx,z))x=nx;
    if(canStand(layout,floor,x,nz))z=nz;
  }
  return [x,z];
}
export function nearestSafe(layout,floor,point) {
  if(canStand(layout,floor,...point))return [...point];
  for(let radius=.2;radius<8;radius+=.2)for(let i=0;i<32;i++) {
    const a=i*Math.PI/16,x=point[0]+Math.cos(a)*radius,z=point[1]+Math.sin(a)*radius;
    if(canStand(layout,floor,x,z))return [x,z];
  }
  const f=layout.floors[floor];
  for(let z=.5;z<layout.length;z+=.5)for(let x=.5;x<layout.width;x+=.5)if(canStand(layout,floor,x,z))return [x,z];
  throw Error('No reachable safe standing point');
}
