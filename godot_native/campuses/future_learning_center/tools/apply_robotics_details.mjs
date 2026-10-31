import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

// A room-local, idempotent furnishing pass. Run AFTER generic furniture IDs and
// wall-storage placement, so adding a part cannot renumber another room's puzzle.
export function applyRoboticsDetails(plan, assets) {
  if (plan.floor !== 2) return;
  const room = plan.rooms.find(row => row.id === 'robotics');
  const floor = plan.ground.find(row => row.id === 'robotics_floor_0').polygon;
  const north = Math.min(...floor.map(point => point[1]));
  const oldTable = plan.objects.find(row => row.id === 'robotics_workbench_30');
  if (!oldTable || !assets.robotics_assembly_table) throw Error('Robotics furnishing requires the original anchor and generated table master');
  const retained = plan.objects.filter(row => row.room !== 'robotics' || row.wallStorage);
  const rows = [];
  const y = value => north + value;
  function prop(id, asset, name, cx, base, width, depth, extra = {}) {
    const master = assets[asset];
    if (!master) throw Error('Missing robotics master: ' + asset);
    const [l,t,r,b] = master.opaqueBounds;
    const crop = [l,t,r-l,b-t], scale = width / crop[2], height = crop[3]*scale;
    const row = {id, room:'robotics', asset, name, path:master.path, crop, scale,
      bounds:[cx-width/2,base-height,width,height], footprint:[cx-width*.46,base-depth,width*.92,depth],
      baseline:base, height:65, floor, mounted:false, ...extra};
    rows.push(row); return row;
  }
  const table = prop('robotics_workbench_30','robotics_assembly_table','中央机器人装配桌',850,y(495),540,125,{height:75,cluster:'robotics_assembly'});
  // These two desks are secondary work areas, not four duplicate tall benches.
  const testBench = prop('robotics_workbench_31','worktable_white_photo','机械试装台',650,y(215),210,55);
  const electronics = prop('robotics_workbench_32','worktable_white_photo','电子调试台',1070,y(215),210,55);
  const printerDesk = prop('robotics_desk_36','worktable_white_photo','打印与备件台',1230,y(710),170,48);
  prop('robotics_printer_3d_37','printer_3d','封闭式 3D 打印机',1245,printerDesk.bounds[1]+24,65,20,
    {mounted:true,parent:printerDesk.id,baseline:printerDesk.baseline+.1,height:45});
  // Shelves share the already calibrated north-wall ground seam, not an
  // invented wall at the navigation polygon's upper edge.
  const wall = plan.objects.find(row => row.room==='robotics' && row.wallStorage);
  const rear = wall.wallStorage.rearY;
  for (const [id,cx] of [['robotics_workbench_33',550],['robotics_parts_shelf',760]]) {
    prop(id,'parts_rack_photo_v2','元件与工具收纳架',cx,rear+20,150,20,
      {height:145,cluster:'robotics_parts_storage'});
  }
  prop('robotics_tool_cart','tool_cart','移动工具车',465,y(495),72,40);
  prop('robotics_whiteboard','whiteboard','装配讨论白板',470,y(795),100,32);
  for (const [index,cx,offset,asset] of [[0,740,344,'chair_front'],[1,965,344,'chair_front'],[2,740,573,'chair_back'],[3,965,573,'chair_back']]) {
    prop('robotics_assembly_seat_'+index,asset,'装配桌工作椅',cx,y(offset),48,30);
  }
  let mounted = 0;
  function part(parent,asset,name,u,v,width) {
    return prop('robotics_component_'+(++mounted),asset,name,parent.bounds[0]+parent.bounds[2]*u,
      parent.bounds[1]+parent.bounds[3]*v,width,12,
      {mounted:true,parent:parent.id,baseline:parent.baseline+.01*mounted,height:20,cluster:'robotics_components'});
  }
  // A clear center belongs to the live delivery robot. Compact piles frame it;
  // they remain separate alpha-backed render objects, not floor decorations.
  for (const [asset,name,u,v,width] of [
    ['robotics_hardware','齿轮与紧固件盒',.12,.32,67],
    ['robotics_wheels','轮组',.31,.31,54],
    ['robotics_motors','电机与传动组件',.70,.30,58],
    ['robotics_wires','线材与插头',.88,.32,49],
    ['robotics_controller','控制板与电池',.71,.59,61],
    ['robotics_tools','装配工具',.12,.59,46],
    ['robotics_brackets','结构连接件',.30,.59,63],
    ['robotics_hardware','轴承备件盒',.88,.60,55],
  ]) part(table,asset,name,u,v,width);
  part(testBench,'robotics_chassis','试装机器人底盘',.42,.34,75);
  part(testBench,'robotics_brackets','底盘备件',.84,.34,42);
  part(electronics,'robotics_controller','调试控制板',.30,.34,52);
  part(electronics,'robotics_wires','备用线束',.78,.36,46);
  part(printerDesk,'robotics_brackets','打印配件',.22,.30,35);
  const cart=rows.find(row=>row.id==='robotics_tool_cart');
  part(cart,'robotics_tools','手工具',.5,.25,32);
  room.cameraZoom=.90;
  plan.objects=[...retained,...rows];
  plan.roboticsReference={date:'2026-10-31',bench:table.id,approach:[1188,y(350)],capture:[1188,y(350)],
    walkLoop:[[530,y(270)],[1190,y(270)],[1190,y(630)],[530,y(630)]],
    source:'User correction: central large table covered in parts; existing on-site lab photographs guide materials and storage.',
    scope:'Furniture grouping and relative scale are a playable review proposal. This pass does not author architecture; the frontage pass handles its source-plan correction.'};
  // The previous empty-room QA point is now under the solid tabletop. Only
  // migrate samples inside this room, and only if the new furniture blocks them.
  plan.openSamples=plan.openSamples.map(point=>rows.some(row=>!row.mounted &&
    point[0]>=row.footprint[0]-12 && point[0]<=row.footprint[0]+row.footprint[2]+12 &&
    point[1]>=row.footprint[1]-10 && point[1]<=row.footprint[1]+row.footprint[3]+10)
    ? [...plan.roboticsReference.approach] : point);
  plan.objectCounts=Object.fromEntries([...new Set(plan.objects.map(row=>row.asset))].map(asset=>[asset,plan.objects.filter(row=>row.asset===asset).length]));
}

if (process.argv[1] && path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  const root=path.resolve(import.meta.dirname,'..');
  const file=path.join(root,'data/floor_2.json');
  const plan=JSON.parse(fs.readFileSync(file,'utf8'));
  applyRoboticsDetails(plan,JSON.parse(fs.readFileSync(path.join(root,'data/object_assets.json'),'utf8')));
  fs.writeFileSync(file,JSON.stringify(plan,null,2)+'\n');
  console.log('Robotics room: '+plan.objects.filter(row=>row.room==='robotics').length+' independent objects; furnishing pass leaves architecture unchanged');
}
