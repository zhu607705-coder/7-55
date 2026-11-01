import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

// The original 2F plan draws an operable frontage along the ASABE room's
// east side. The old generic room master incorrectly painted an ornate wood
// door. Keep the room's world transform; calibrate the replacement in pixels.
export function applyRoboticsFrontage(plan, assets) {
  if (plan.floor !== 2) return;
  const module = plan.modules.find(row => row.id === 'robotics');
  const master = assets.f2_robotics_glass;
  if (!module || !master || JSON.stringify(module.sourceSize) !== JSON.stringify(master.size)) {
    throw Error('Glass frontage must use the unchanged robotics source canvas');
  }
  const at = ([x,y]) => [module.at[0]+(x-module.crop[0])*module.scale,
    module.at[1]+(y-module.crop[1])*module.scale];
  const rect = ([x,y,w,h]) => [[x,y],[x+w,y],[x+w,y+h],[x,y+h]].map(at);
  module.asset = 'f2_robotics_glass';
  module.path = master.path;

  // The generated leaves end at y=625 and resume at y=724. A 60px
  // navigable band sits wholly inside that visible opening, with foot margin.
  const door = plan.doors.find(row => row.id === 'robotics_east');
  door.inside = at([1060.5,676]);
  door.outside = at([1242.3,676]);
  door.polygon = rect([1040,646,211,60]);
  door.material = 'gray aluminum / clear glass';
  door.presentation = 'folded leaves; open center passage';
  plan.ground.find(row => row.id === door.id).polygon = door.polygon;
  const threshold = plan.ground.find(row => row.id === door.id+'_threshold');
  const x = door.inside[0]-10, y = door.inside[1];
  const end = Math.max(...threshold.polygon.map(point=>point[0]));
  threshold.polygon = [[x,y-25],[end,y-25],[end,y+25],[x,y+25]];
  for (const side of ['in','out']) {
    plan.waypoints.find(row=>row.id===door.id+'_'+side).point = [...door[side==='in'?'inside':'outside']];
  }

  // Outside circulation follows the new silhouette, rather than the removed
  // wooden leaves. It must not create a second passage through closed glass.
  const outside = plan.ground.find(row=>row.id==='robotics_outside_e');
  const hallX = Math.max(...outside.polygon.map(point=>point[0]));
  const right = [];
  const bottom = module.crop[1]+module.crop[3];
  for (const [top,end,,edge] of master.outerWallStrips) {
    const lo=Math.max(top,module.crop[1]), hi=Math.min(end,bottom);
    if (hi>lo) right.push(at([edge,lo]),at([edge,hi]));
  }
  outside.polygon = [...right,[hallX,module.at[1]+module.bounds[3]],[hallX,module.at[1]]];
  plan.occluders = plan.occluders.filter(row=>row.module!=='robotics');
  plan.occluders.push(
    {module:'robotics',rect:[1060,150,126,475],baseline:625},
    {module:'robotics',rect:[1100,724,112,350],baseline:1074});
  plan.roboticsFrontage = {
    sourcePlan:'d7e9b5e4023c60de0e5fb570d3a20b09.png: west-side ASABE east frontage',
    referencePhotos:['e871c3cb99d9bd847065db6576686f4b.jpg','91d5754a95920b1fbbd12e7db8442063.jpg'],
    evidence:'Plan determines operable east frontage; photos guide gray metal frames, glazing and safety dots. Exact panel count and opening angle are presentation choices, not surveyed dimensions.',
    apertureSource:[1040,646,211,60],closedGlassSamples:[at([1120,500]),at([1155,900])],
    scope:'Only the ASABE east frontage and its threshold/outer contour; room size, furniture, other rooms and progression are retained.'
  };
  plan.roboticsReference.scope = 'Furniture grouping remains a playable review proposal. East frontage is corrected separately from the original plan and photo materials; other rooms are unchanged.';
}

if (process.argv[1] && path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  const root=path.resolve(import.meta.dirname,'..');
  const file=path.join(root,'data/floor_2.json');
  const plan=JSON.parse(fs.readFileSync(file,'utf8'));
  applyRoboticsFrontage(plan,JSON.parse(fs.readFileSync(path.join(root,'data/room_assets.json'),'utf8')));
  fs.writeFileSync(file,JSON.stringify(plan,null,2)+'\n');
}
