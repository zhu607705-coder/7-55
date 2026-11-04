import assert from 'node:assert/strict';
import fs from 'node:fs';
import {safeProjectLink,displayTargetFromHit,displayContent,validateDisplayAssignments,createProjectDisplay,posterDisplayId} from '../web/project_displays.js';
let checks=0;function check(value,label){assert.ok(value,label);checks++;}
const config=JSON.parse(fs.readFileSync(new URL('../web/assets/exhibition_config.json',import.meta.url)));
const deskA={userData:{spatialId:'flc/f3/object/deskA',photoLevel:0}},deskB={userData:{spatialId:'flc/f3/object/deskB',photoLevel:0}};
const entry=desk=>({desk,asset:'photo_monitor_stand',sourcePart:'Neutral screen',level:0});
const batch={userData:{deskEntries:[entry(deskA),entry(deskB)]}};
check(displayTargetFromHit({object:batch,instanceId:0}).id===deskA.userData.spatialId,'instance zero belongs to first desk');
check(displayTargetFromHit({object:batch,instanceId:1}).id===deskB.userData.spatialId,'second instance belongs to second desk');
for(const id of [undefined,-1,2,.5])check(!displayTargetFromHit({object:batch,instanceId:id}),'invalid instance cannot open unrelated content');
for(const change of [{control:true},{level:1},{asset:'photo_keyboard'},{sourcePart:'Monitor support'}]){
 const object={userData:{deskEntries:[{...entry(deskA),...change}]}};
 check(!displayTargetFromHit({object,instanceId:0}),'control, hidden LOD and unrelated parts do not become display targets');
}
for(const sourcePart of ['Screen','Screen.001','Monitor frame']){
 check(displayTargetFromHit({object:{userData:{deskEntries:[{desk:deskA,sourcePart}]}},instanceId:0})?.id===deskA.userData.spatialId,'authored fallback monitor works');
}
check(!displayTargetFromHit({object:{userData:{deskEntries:[{desk:deskA,sourcePart:'Desk top'}]}},instanceId:0}),'desktop retains inspection behavior');
const poster={id:posterDisplayId('seminar_1'),kind:'poster'};
check(displayTargetFromHit({object:{userData:{reviewPoster:true,displayId:poster.id}}}).id===poster.id,'poster stable identity');
check(!displayTargetFromHit({object:{userData:{kind:'wall'}}}),'nearer wall cannot open display behind it');
check(displayContent(config,poster).id==='exhibit/office-corridor-poster','poster shows existing source content');
check(displayContent(config,{id:deskA.userData.spatialId,kind:'monitor'}).status==='unconfigured','unknown project does not fabricate an exhibit');
check(!config.exhibits.some(x=>x.url),'shipping config invents no project URLs');
const catalog={objects:{a:{id:deskA.userData.spatialId,kind:'desk'}},floors:{4:{rooms:[1,2,3].map(i=>({sourceRoomId:'seminar_'+i}))}}};
check(validateDisplayAssignments(config,catalog),'existing poster assignments validate');
for(const assignment of [{targetId:'unknown',exhibitId:config.exhibits[0].id},{targetId:deskA.userData.spatialId,exhibitId:'unknown'}]){
 assert.throws(()=>validateDisplayAssignments({...config,displayAssignments:[assignment]},catalog));checks++;
}
assert.throws(()=>validateDisplayAssignments({...config,displayAssignments:[config.displayAssignments[0],config.displayAssignments[0]]},catalog));checks++;
const original=JSON.stringify(config);
const replaced={...config,displayAssignments:[{targetId:deskA.userData.spatialId,exhibitId:'exhibit/lab-introduction'}]};
check(displayContent(replaced,{id:deskA.userData.spatialId,kind:'monitor'}).id==='exhibit/lab-introduction','object binding resolves existing exhibit');
check(JSON.stringify(config)===original,'content projection never mutates config');
for(const bad of [null,'','javascript:alert(1)','data:text/html,x','file:///tmp/a','http://example.org','//example.org','https://user:pass@example.org',' https://example.org','https://example.org/\n','./../private','./a\\b','./%2f%2fevil']){
 check(safeProjectLink(bad)===null,'unsafe destination rejected '+bad);
}
check(safeProjectLink('https://example.org/project')?.external,'fixture HTTPS external supported');
check(safeProjectLink('./project.html?id=1')?.external===false,'fixture local internal supported');
class Element{
 constructor(tag){this.tagName=tag;this.children=[];this.listeners={};this.open=false;this.modalCount=0;}
 addEventListener(type,fn){this.listeners[type]=fn;}
 append(...items){this.children.push(...items);}
 replaceChildren(...items){this.children=items;}
 replaceWith(value){this.replacement=value;}
 showModal(){this.open=true;this.modalCount++;}
 close(){this.open=false;this.listeners.close?.();}
}
const nodes=new Map();const doc={getElementById:id=>{if(!nodes.has(id))nodes.set(id,new Element('div'));return nodes.get(id);},createElement:tag=>new Element(tag),createTextNode:text=>({textContent:text})};
let opens=0,closes=0;
const ui=createProjectDisplay({config,document:doc,onOpen:()=>opens++,onClose:()=>closes++});
ui.open(poster);const dialog=nodes.get('project-display-dialog'),content=nodes.get('project-display-content');
check(dialog.open&&opens===1,'modal shown independently of hidden walk overlay');
check(content.children.every(n=>n.tagName!=='a'),'no link rendered without verified destination');
ui.open(poster);check(dialog.modalCount===1&&opens===2,'repeat open updates one modal without showModal exception');
ui.close();check(!dialog.open&&ui.active===null&&closes===1,'close clears active target and invokes input/focus restoration');
ui.open({id:deskA.userData.spatialId,kind:'monitor'});check(dialog.open&&dialog.modalCount===2,'close and reopen works');
ui.close();
const linked={...config,exhibits:[{id:'fixture',title:'Fixture',body:'Fixture',url:'https://example.org/project',image:'./assets/exhibits/test.png'}],displayAssignments:[{targetId:poster.id,exhibitId:'fixture'}]};
const linkedUI=createProjectDisplay({config:linked,document:doc});linkedUI.open(poster);
const anchor=content.children.find(n=>n.tagName==='a');
check(anchor.target==='_blank'&&anchor.rel==='noopener noreferrer','external link has safe new-tab relationship');
const img=content.children.find(n=>n.tagName==='img');img.listeners.error();check(img.replacement.textContent.includes('文字仍可阅读'),'image failure keeps usable text');
const viewer=fs.readFileSync(new URL('../web/viewer.js',import.meta.url),'utf8');
check(viewer.indexOf('const display=displayTargetFromHit(hit)')<viewer.indexOf("if(state.mode==='overview'&&hit.object.userData.deskEntries"),'screen content takes priority over broad desk inspection');
check(viewer.includes("if(document.querySelector('dialog[open]'))return;if(e.key==='Escape')"),'Escape closes modal before scene navigation');
check(viewer.includes('onOpen:stopInput,onClose:()=>{stopInput();canvas.focus'),'modal resets input without changing camera or walk state');
check(viewer.includes('sourcePart:mesh.userData.name||mesh.name'),'fallback source part identity survives instancing');
check(viewer.includes('if(entry?.control){toggleDesk(entry.desk);return;}'),'desk controller retains lift behavior');
console.log(JSON.stringify({passed:checks,scope:'Pure routing, URL/config and DOM-lifecycle stubs; not real browser or GLB acceptance'},null,2));

