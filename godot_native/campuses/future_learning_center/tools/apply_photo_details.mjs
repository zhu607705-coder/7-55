// Material/shape variants from the user's October 28 site photographs.
// Keep room geometry, object IDs, wall-placement receipts and solid footprints.
export function applyPhotoDetails(plan,assets){
 const whiteRooms=new Set(['electrical','machinery','focus_a','collab_b','flex_c','studio_1','studio_2','studio_3','studio_4']);
 for(const object of plan.objects){
  const variant=object.asset==='parts_rack'?'parts_rack_photo_v2':
   object.asset==='cabinet'&&whiteRooms.has(object.room)?'locker_photo_v2':
   object.asset==='desk'&&whiteRooms.has(object.room)?'worktable_white_photo':null;
  if(!variant)continue;
  const asset=assets[variant],b=asset.opaqueBounds,crop=[b[0],b[1],b[2]-b[0],b[3]-b[1]],old=object.bounds;
  const scale=object.asset==='desk'?old[2]/crop[2]:Math.min(old[2]/crop[2],old[3]/crop[3]);
  const width=crop[2]*scale,height=crop[3]*scale,base=old[1]+old[3];
  Object.assign(object,{photoAsset:variant,path:asset.path,crop,scale,bounds:[old[0]+old[2]/2-width/2,base-height,width,height]});
  if(object.asset==='desk'){
   for(const child of plan.objects.filter(row=>row.parent===object.id)){
    const fraction={desk_divider:.9,monitor_front:.65,monitor_back:.70,printer_3d:.64}[child.asset];
    if(fraction===undefined)continue;
    child.bounds[1]=base-height*fraction-child.bounds[3];
    // Mounted items follow the tabletop; their old decorative footprint is not solid.
    child.footprint[1]=base-height*fraction-child.footprint[3];
   }
  }
 }
 plan.photoDetailReference={date:'2026-10-28',source:'User-supplied site photographs',variants:['parts_rack_photo_v2','worktable_white_photo','locker_photo_v2'],scope:'Photo-derived furniture types and materials. Existing architectural layout and colliders retained; exact furniture counts and room assignment are review proposals, not surveyed facts.'};
}
