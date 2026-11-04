/** Object-to-content bindings only. No team, geometry, movement or save ownership. */
import {safeExhibitImage} from './spatial_overlay.js';

export function safeProjectLink(value){
 if(typeof value!=='string'||!value||value!==value.trim()||/[\\\\\u0000-\u0020\u007f]/.test(value))return null;
 // Relative paths stay inside this viewer; absolute destinations must use HTTPS.
 if(/^\.\/[a-zA-Z0-9_/-]+(?:\.html)?(?:[?#][a-zA-Z0-9_=&%./~-]*)?$/.test(value)&&!value.includes('..'))return {href:value,external:false};
 try{const url=new URL(value);if(url.protocol!=='https:'||url.username||url.password)return null;return {href:url.href,external:true};}catch{return null;}
}
export function posterDisplayId(sourceRoomId){return 'flc/f4/poster/'+encodeURIComponent(sourceRoomId);}
export function validateDisplayAssignments(config,catalog){
 if(config.displayAssignments===undefined)return true;
 if(!Array.isArray(config.displayAssignments))throw Error('Invalid display assignments');
 const targets=new Set([...Object.values(catalog.objects).filter(o=>o.kind==='desk').map(o=>o.id),...catalog.floors['4'].rooms.filter(r=>/^seminar_/.test(r.sourceRoomId)).map(r=>posterDisplayId(r.sourceRoomId))]);
 const exhibits=new Set(config.exhibits.map(e=>e.id)),seen=new Set();
 for(const a of config.displayAssignments){
  if(!targets.has(a.targetId)||seen.has(a.targetId)||!exhibits.has(a.exhibitId))throw Error('Invalid or duplicate display assignment');
  seen.add(a.targetId);
 }
 return true;
}
/** Called only with the nearest visible ray hit, so walls remain authoritative. */
export function displayTargetFromHit(hit){
 if(!hit?.object)return null;
 const data=hit.object.userData||{};
 if(data.reviewPoster&&data.displayId)return {id:data.displayId,kind:'poster'};
 const entry=Number.isInteger(hit.instanceId)?data.deskEntries?.[hit.instanceId]:null;
 if(!entry||entry.control||!entry.desk?.userData.spatialId)return null;
 if(entry.level!==undefined&&entry.level!==entry.desk.userData.photoLevel)return null;
 const screen=entry.asset==='photo_monitor_stand'&&/^(Monitor bezel|Neutral screen)(?:\.|$)/.test(entry.sourcePart||'');
 const original=!entry.asset&&/^(Screen|Monitor frame)(?:\.\d+)?$/.test(entry.sourcePart||'');
 return screen||original?{id:entry.desk.userData.spatialId,kind:'monitor'}:null;
}
export function displayContent(config,target){
 const assignment=(config.displayAssignments||[]).find(a=>a.targetId===target.id);
 const exhibit=assignment&&config.exhibits.find(e=>e.id===assignment.exhibitId);
 return exhibit||{title:target.kind==='poster'?'海报展示位':'工位电脑',body:config.unavailable?'展陈配置暂不可用，空间仍可查看。':'此对象尚未配置项目内容。空间编号与团队归属保持独立。',status:'unconfigured'};
}
export function createProjectDisplay({config,onOpen=()=>{},onClose=()=>{},document:doc=document}){
 const dialog=doc.getElementById('project-display-dialog'),content=doc.getElementById('project-display-content');
 let active=null;
 dialog.addEventListener('close',()=>{active=null;onClose();});
 return {
  open(target){
   const item=displayContent(config,target);active=target.id;content.replaceChildren();
   const heading=doc.getElementById('project-display-title');heading.textContent=item.title;
   const body=doc.createElement('p');body.textContent=item.body||'';content.append(body);
   const imagePath=safeExhibitImage(item.image);
   if(imagePath){const img=doc.createElement('img');img.src=imagePath;img.alt=item.title;img.addEventListener('error',()=>img.replaceWith(doc.createTextNode('图片未能加载，文字仍可阅读。')),{once:true});content.append(img);}
   const link=safeProjectLink(item.url);
   if(link){const a=doc.createElement('a');a.href=link.href;a.textContent=link.external?'打开项目链接（新标签页）':'进入项目';if(link.external){a.target='_blank';a.rel='noopener noreferrer';}content.append(a);}
   else{const note=doc.createElement('p');note.className='muted';note.textContent='尚无已核准的项目链接。';content.append(note);}
   onOpen();if(!dialog.open)dialog.showModal();
  },
  close(){if(dialog.open)dialog.close();},
  get active(){return active;}
 };
}

