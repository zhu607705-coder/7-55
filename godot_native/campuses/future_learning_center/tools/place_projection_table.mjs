// A gameplay staging prop, not a claim of surveyed furniture placement.
// Validated against native complete-foot navigation, including the existing
// xlab_box_door ground polygon. Never alter the doorway or room geometry.
export function placeProjectionTable(plan,assets){
 if(plan.floor!==3)return;
 const id='xlab_box_projection_table';
 if(plan.objects.some(object=>object.id===id))return;
 const floor=plan.ground.find(region=>region.id==='xlab_box')?.polygon;
 if(!floor)throw Error('Projection station requires the existing X-Lab small room');
 const art=assets.desk,b=art.opaqueBounds,crop=[b[0],b[1],b[2]-b[0],b[3]-b[1]];
 const width=140/.88,scale=width/crop[2],height=crop[3]*scale;
 plan.objects.push({id,room:'xlab_box',asset:'desk',name:'便携透光展示台',path:art.path,crop,scale,
  bounds:[4690-width/2,5850-height,width,height],footprint:[4620,5780,140,70],
  baseline:5850,height:65,floor,mounted:false,gameplayStaging:true});
 plan.projectionReference={table:id,approaches:[[4550,5815],[4830,5815],[4690,5710],[4690,5920]],
  doorSweep:[[4276,5938],[4460,5938]],scope:'White-model gameplay staging; native complete-foot paths verified, not surveyed placement'};
 if(plan.objectCounts)plan.objectCounts.desk=(plan.objectCounts.desk||0)+1;
}
