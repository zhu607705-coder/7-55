import fs from 'node:fs';
import path from 'node:path';
const root=path.resolve(import.meta.dirname,'..');
const assets='res://assets/native/library_object_depth_20261104/';
const instances=[];
function add(id,asset,bounds,footprints=[],targets=[],extra={}){
 instances.push({id,asset,bounds,footprints,targets,...extra});
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
 const x=firstStack.left+Math.round(column*pitch);
 addStack(column===5?'north_display_shelf':'row_shelf_'+column,'shelf_row',x,firstStack.top,column===5);
 instances.at(-1).shelfNumber=column+1;
}
const divider=sourceBox.reading_divider_shelf;
addStack(divider.id,'shelf_divider',divider.left,divider.top);
const chairFeet=[[.12,.75,.76,.25]];
for(const [index,x,y] of [[1,1000,149],[2,1216,149],[3,1002,355],[4,1215,355]]){
 const id='reading_table_'+index;
 const width=index%2===0?156:126;
 const [tw,th]=normalized.assets.table_oblique.size;
 const height=width*th/tw;
 // Register each tabletop at the existing notebook, paper and backpack level.
 const top=y+66-height*.36;
 add(id,'table_oblique',[x,top,width,height],[[.06,.65,.88,.35]],[],{chamfer:4});
 const chairWidth=27;
 for(const [slot,fraction] of [['left',1/3],['right',2/3]]) {
  const left=x+Math.round(width*fraction-chairWidth/2);
  add(id+'_north_'+slot,'chair_south',[left,top-29,chairWidth,49],chairFeet);
  add(id+'_south_'+slot,'chair_north',[left,top+height-37,chairWidth,41],chairFeet,index===4&&slot==='right'?['seat_022_chair']:index===1&&slot==='left'?['library_study_chair']:[]);
 }
 // Both side seats are at the same height; their inner edges tuck under the table.
 const sideHeight=48;
 for(const [side,asset] of [['west','chair_east'],['east','chair_west']]) {
  const [assetWidth,assetHeight]=normalized.assets[asset].size;
  const sideWidth=sideHeight*assetWidth/assetHeight;
  const left=side==='west'?x+5-sideWidth:x+width-5;
  add(id+'_'+side,asset,[left,top+3,sideWidth,sideHeight],chairFeet);
 }
 add(id+'_lamp','lamp',[x+50,top-12,20,32],[],[],{depthOwner:id});
 add(id+'_book','open_book',[x+85,top+5,27,18],[],[],{depthOwner:id});
}
// Match the outside faces and the two chamfered front corners. Leaving an
// inset around either arm allows the player's feet into the painted cabinet.
const counterFeet=[[0,.20,.115,.67],[.885,.20,.115,.67],[.075,.82,.85,.18]];
for(const [x,y,width,height] of [[.015,.87,.105,.06],[.04,.93,.08,.04],[.065,.97,.055,.03]]) {
 counterFeet.push([x,y,width,height],[1-x-width,y,width,height]);
}
add('front_desk_counter','counter',[153,497,334,169],counterFeet,['front_desk','identity_machine']);
add('desk_terminal','terminal',[190,565,55,54],[],['front_desk'],{depthOwner:'front_desk_counter'});
// One full-size case meets the rear wall and the counter's eastern boundary.
const deskBackWidth=219;
const [caseWidth,caseHeight]=normalized.assets.low_bookcase.size;
add('desk_back_1','low_bookcase',[270,435,deskBackWidth,deskBackWidth*caseHeight/caseWidth],[[.02,.50,.96,.50]]);
for(const [id,r] of [['catalog_back_1',[597,424,124,82]],['catalog_back_2',[720,424,124,82]]])add(id,'low_bookcase',r,[[.02,.50,.96,.50]]);
add('catalog_desk','table',[613,516,133,97],[[.06,.60,.88,.40]],['catalog_terminal'],{chamfer:4});
add('catalog_terminal','terminal',[625,510,71,65],[],['catalog_terminal'],{depthOwner:'catalog_desk'});
add('catalog_terminal_chair','chair_north',[646,594,35,52],chairFeet,['catalog_terminal']);
add('printer','printer',[788,510,77,104],[[.08,.64,.84,.36]],['printer'],{chamfer:3});
add('backpack','backpack',[1238,383,34,49],[],['backpack','bag_photo','backpack_pass'],{dynamic:'backpack',depthOwner:'reading_table_4'});
for(const [i,x] of [667,737,807].entries())add('entrance_turnstile_'+i,'turnstile',[x,762,28,110],[[.05,.05,.90,.95]]);
for(const [i,r] of [[71,713,53,77],[83,423,50,90],[28,151,57,82],[920,401,59,99],[1386,434,59,94],[462,704,58,138],[982,706,59,136],[1095,522,47,57],[1235,520,47,59],[1370,648,58,104],[945,20,52,76],[1365,23,45,65],[99,23,35,59],[333,28,31,50],[607,28,31,50],[867,28,31,50]].entries())add('plant_'+i,'plant',r,[[.29,.81,.42,.19]]);
for(const [i,x] of [1090,1202,1314].entries())add('south_rail_'+i,'rail',[x,534,114,28],[[0,.68,1,.32]]);
add('diagonal_rail','diagonal_rail',[925,480,64,65],[],[],{diagonalSolid:true});
add('water_dispenser','water_dispenser',[111,696,48,92],[[.08,.81,.84,.19]]);
add('notice_board','notice_board',[184,403,85,104],[[.08,.85,.84,.15]]);
// Tile uniform panes over the exact original fixed-glass bodies, including
// their inner edges. A padded fit must never leave an invisible wall strip.
const [glassWidth,glassHeight]=normalized.assets.glass_panel.size;
const paneWidth=143*glassWidth/glassHeight;
for(const [side,width] of [[515,140],[845,141]])for(let pane=0;pane<4;pane++)add('fixed_glass_'+side+'_'+pane,'glass_panel',[side+pane*(width-paneWidth)/3,682,paneWidth,143],[]);
const families=[...new Set(instances.map(row=>row.asset))];
const config={schema:'native-library-object-scene-v2',worldSize:[1500,900],cleanPlate:assets+'clean_plate.png',families:Object.fromEntries(families.map(id=>[id,assets+id+'.png'])),instances,contract:{projection:'orthographic oblique top-down; uniform scale only',ground:'shared fixed player foot rectangle; source-pixel furniture footprints',depth:'each physical object baseline is its own ground-contact edge; desk items inherit desk depth',story:'controller and saves unchanged; shelf sprite is shared with every ordinary row shelf'}};
fs.writeFileSync(path.join(root,'data/native/library-objects-v2.json'),JSON.stringify(config,null,2)+'\n');
console.log('LIBRARY_OBJECT_PLAN',families.length,'families',instances.length,'instances');
