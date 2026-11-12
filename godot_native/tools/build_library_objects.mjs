import fs from 'node:fs';
import path from 'node:path';
const root=path.resolve(import.meta.dirname,'..');
const assets='res://assets/native/library_object_depth_20261104/';
const instances=[];
const rigidSideAssets=new Set([
 'shelf_row','shelf_divider','low_bookcase','table','table_oblique','chair_north',
 'chair_south','chair_east','chair_west','turnstile','rail','notice_board','water_dispenser'
]);
function add(id,asset,bounds,footprints=[],targets=[],extra={}){
 const artSides=rigidSideAssets.has(asset)?{artSides:true}:{};
 instances.push({id,asset,bounds,footprints,targets,...artSides,...extra});
}
// Contact rectangles are measured on an undistorted native tile, in source pixels.
// Reused art keeps the same contact when fitted at a different size.
function contact(width,height,left,back,right,front) {
 return [left/width,back/height,(right-left)/width,(front-back)/height];
}
const normalized=JSON.parse(fs.readFileSync(path.join(root,'art_source/library_object_depth_20261104/normalization.json'),'utf8'));
const library=JSON.parse(fs.readFileSync(path.join(root,'data/worlds.json'),'utf8')).worlds.library_interior;
const sourceBox=Object.fromEntries(library.collisions.map(box=>[box.id,box]));
function addStack(id,asset,x,y,movable=false) {
 const master=normalized.assets[asset];
 const [width,height]=master.size.map(length=>length/5);
 const backInset=master.southFacePixels/master.size[1];
 // One source pixel inside each upright. The elevated top overhangs the rear foot.
 const base=[1/width,backInset,1-2/width,1-backInset];
 add(id,asset,[x,y,width,height],[base],movable?['library_shelf_755']:[],{movable});
}
const firstStack=sourceBox.north_shelf_01;
const lastStack=sourceBox.north_shelf_08;
const shelfWidth=normalized.assets.shelf_row.size[0]/5;
const pitch=(lastStack.right-firstStack.left-shelfWidth)/8;
for(let column=0;column<9;column++) {
 // Leave shoulder room through the reveal shelf's -2px shake and +16px slide.
 const aisleOffset=column<5?-2:column>5?17:0;
 const x=firstStack.left+Math.round(column*pitch)+aisleOffset;
 addStack(column===5?'north_display_shelf':'row_shelf_'+column,'shelf_row',x,firstStack.top,column===5);
 instances.at(-1).shelfNumber=column+1;
}
const divider=sourceBox.reading_divider_shelf;
addStack(divider.id,'shelf_divider',divider.left,divider.top);
const chairFeet={
 chair_north:[contact(35,52,1,38,34,52)],
 chair_south:[contact(27,49,0,36,27,49)],
 chair_east:[contact(22,48,0,36,17,48)],
 chair_west:[contact(23,48,5,36,22,48)]
};
// The projected seat is a short plane above the chair's four floor supports.
const northSeat={seatPoint:normalized.assets.chair_north.seatPoint};
// Surface and apron edges measured on the new full-table masters.
const readingTop={tableSurface:.630,tableCap:.722};
const catalogTop={tableSurface:.600,tableCap:.708};
// The horizontal tabletop projects down to the floor by its rise. The
// front legs give the floor edge and the tabletop lip gives the height.
const readingTableFeet=[contact(126,70,8,26,118,70)];
const catalogTableFeet=[contact(126,97,8,39,118,97)];
for(const [index,x,y] of [[1,1000,149],[2,1216,149],[3,1002,355],[4,1215,355]]){
 const id='reading_table_'+index;
 const width=index%2===0?156:126;
 const [tw,th]=normalized.assets.table_oblique.size;
 const height=width*th/tw;
 // Register each tabletop at the existing notebook, paper and backpack level.
 const top=y+66-height*.36;
 add(id,'table_oblique',[x,top,width,height],readingTableFeet,[],readingTop);
 const chairWidth=27;
 for(const [slot,fraction] of [['left',1/3],['right',2/3]]) {
  const left=x+Math.round(width*fraction-chairWidth/2);
  add(id+'_north_'+slot,'chair_south',[left,top-29,chairWidth,49],chairFeet.chair_south,[],{underTable:id});
  const southChairTop=top+height*readingTop.tableCap-5;
  add(id+'_south_'+slot,'chair_north',[left,southChairTop,chairWidth,41],chairFeet.chair_north,index===4&&slot==='right'?['seat_022_chair']:index===1&&slot==='left'?['library_study_chair']:[],{underTable:id,...northSeat});
 }
 // Both side seats are at the same height; their inner edges tuck under the table.
 const sideHeight=48;
 for(const [side,asset] of [['west','chair_east'],['east','chair_west']]) {
  const [assetWidth,assetHeight]=normalized.assets[asset].size;
  const sideWidth=sideHeight*assetWidth/assetHeight;
  const left=side==='west'?x+5-sideWidth:x+width-5;
  const sideTop=top+(height*readingTop.tableSurface-sideHeight)/2;
  add(id+'_'+side,asset,[left,sideTop,sideWidth,sideHeight],chairFeet[asset],[],{underTable:id});
 }
 add(id+'_lamp','lamp',[x+width/2-10,top+height*readingTop.tableSurface-9-32,20,32],[],[],{depthOwner:id});
 add(id+'_book','open_book',[x+width*.68,top+height*.18,27,18],[],[],{depthOwner:id});
}
const counterBounds=[153,497,334,169];
// Project the side arms down by the measured 35px rise from the front lip.
// Four-pixel bands follow the rear chamfers and the painted front toe-kick.
const counterRise=35;
const counterContact=(left,back,right,front)=>contact(330,169,left,back,right,front);
const counterFeet=[counterContact(0,59,38,140),counterContact(292,59,330,140),
 counterContact(0,140,42,144),counterContact(288,140,330,144)];
for (const [row,left,right] of [[0,21,308],[4,17,313],[8,13,317],[12,9,321],[16,5,325],[20,1,329]]) {
 const back=row+counterRise;
 counterFeet.push(counterContact(left,back,38,back+4),counterContact(292,back,right,back+4));
}
for (const [row,left,right] of [[144,0,330],[148,4,326],[152,9,322],[156,13,317],[160,17,313],[164,21,309],[168,25,306]]) {
 counterFeet.push(counterContact(left,row,right,Math.min(row+4,169)));
}
// Usable front work surface inside the inner and outer trim of the U-shaped counter.
const counterSurface=[.12,.66,.76,.12];
add('front_desk_counter','counter',counterBounds,counterFeet,['front_desk','identity_machine'],{surfaceRect:counterSurface,frontSideRow:144});
const deskTerminalHeight=54;
const counterTop=counterBounds[1]+counterBounds[3]*counterSurface[1];
const terminalTop=Math.round(counterTop+3-deskTerminalHeight*.75);
add('desk_terminal','terminal',[190,terminalTop,55,deskTerminalHeight],[],['front_desk'],{depthOwner:'front_desk_counter'});
// One full-size case meets the rear wall and the counter's eastern boundary.
const deskBackWidth=219;
const [caseWidth,caseHeight]=normalized.assets.low_bookcase.size;
const bookcaseFeet=[contact(219,112,1,76,218,112)];
add('desk_back_1','low_bookcase',[270,435,deskBackWidth,deskBackWidth*caseHeight/caseWidth],bookcaseFeet);
for(const [id,r] of [['catalog_back_1',[597,424,124,82]],['catalog_back_2',[720,424,124,82]]])add(id,'low_bookcase',r,bookcaseFeet);
add('catalog_desk','table',[613,516,133,97],catalogTableFeet,['catalog_terminal'],catalogTop);
const terminalBounds=[625,516+97*catalogTop.tableSurface-5-59,64.45,59];
const catalogChairWidth=35;
add('catalog_terminal','terminal',terminalBounds,[],['catalog_terminal'],{depthOwner:'catalog_desk'});
add('catalog_terminal_chair','chair_north',[Math.round(terminalBounds[0]+(terminalBounds[2]-catalogChairWidth)/2),594,catalogChairWidth,52],chairFeet.chair_north,['catalog_terminal'],{underTable:'catalog_desk',...northSeat});
// Restore the original printer ground contact, including its rear bevel.
add('printer','printer',[788,510,77,104],[[.08,.64,.84,.36]],['printer'],{chamfer:3});
add('backpack','backpack',[1238,383,34,49],[],['backpack','bag_photo','backpack_pass'],{dynamic:'backpack',depthOwner:'reading_table_4'});
const entrance=JSON.parse(fs.readFileSync(path.join(root,'data/native/library-entrance-geometry.json'),'utf8'));
// The light top ends at row 36 and the cabinet stands 52px above its base.
const turnstileFeet=[contact(19,88,0,52,19,88)];
for(const [i,bounds] of entrance.cabinetBounds.entries())add('entrance_turnstile_'+i,'turnstile',bounds,turnstileFeet);
const plantFeet=[contact(59,94,17,84,44,94)];
const plantPlacements=[
 [60,681,53,77], // Beside the water dispenser, inside the southwest wall step.
 [51,407,50,90], // Inside the blue alcove, away from the counter-side aisle.
 [28,151,57,82],[920,401,59,99],[1386,434,59,94],[462,704,58,138],[982,706,59,136],[1095,522,47,57],[1235,520,47,59],[1370,648,58,104],[945,20,52,76],[1365,23,45,65],[99,23,35,59],[333,28,31,50],[607,28,31,50],[867,28,31,50]
];
for(const [i,r] of plantPlacements.entries())add('plant_'+i,'plant',r,plantFeet);
for(const [i,x] of [1090,1202,1314].entries())add('south_rail_'+i,'rail',[x,534,114,28],[contact(114,17,0,13,114,17)]);
// Bottom contacts of the two posts in the transparent rail sprite.
add('diagonal_rail','diagonal_rail',[925,480,64,65],[],[],{diagonalSolid:true,depthLine:[[.10,.42],[.91,1]]});
add('water_dispenser','water_dispenser',[111,696,48,92],[contact(39,92,1,84,38,92)]);
add('notice_board','notice_board',[184,403,85,104],[contact(66,104,3,96,63,104)]);
const families=[...new Set(instances.map(row=>row.asset))];
const config={schema:'native-library-object-scene-v2',worldSize:[1500,900],cleanPlate:assets+'clean_plate.png',families:Object.fromEntries(families.map(id=>[id,assets+id+'.png'])),instances,contract:{projection:'orthographic oblique top-down; uniform scale only',ground:'shared fixed player foot rectangle; source-pixel furniture footprints',depth:'each physical object baseline is its own ground-contact edge; desk items inherit desk depth',story:'controller and saves unchanged; shelf sprite is shared with every ordinary row shelf'}};
fs.writeFileSync(path.join(root,'data/native/library-objects-v2.json'),JSON.stringify(config,null,2)+'\n');
console.log('LIBRARY_OBJECT_PLAN',families.length,'families',instances.length,'instances');
