/** Visitor-only content projection. No DOM HTML injection, accounts or geometry writes. */
export function safeExhibitImage(value){return typeof value==='string'&&/^\.\/assets\/exhibits\/[a-zA-Z0-9_./-]+\.(png|jpg|jpeg|webp)$/.test(value)&&!value.includes('..')?value:null;}
export function projectExhibitionConfig(config,spaceId){
 const assignments=config.roomAssignments.filter(a=>a.spaceId===spaceId),exhibitIds=new Set(assignments.flatMap(a=>a.exhibitIds||[])),teamIds=new Set(assignments.flatMap(a=>a.teamIds||[]));
 return {exhibits:config.exhibits.filter(e=>exhibitIds.has(e.id)),teams:config.teams.filter(t=>teamIds.has(t.id))};
}
export function createSpatialOverlay({catalog,config,onObject}){
 const $=id=>document.getElementById(id),select=$('spatial-object');let current;
 select.addEventListener('change',()=>{if(select.value)onObject(select.value);});
 function content(exhibits,teams=[]){
  const target=$('exhibit-content');target.replaceChildren();
  if(teams.length){const p=document.createElement('p');p.textContent='当前展陈关联团队：'+teams.map(t=>t.name||t.id).join('、')+'（不改变空间身份）';target.append(p);}
  for(const item of exhibits){const heading=document.createElement('h3');heading.textContent=item.title;const body=document.createElement('p');body.textContent=item.body;target.append(heading,body);const src=safeExhibitImage(item.image);if(src){const image=document.createElement('img');image.src=src;image.alt=item.title;image.addEventListener('error',()=>{image.replaceWith(document.createTextNode('图片未能加载，原资料仍可阅读。'));},{once:true});target.append(image);}else{const placeholder=document.createElement('p');placeholder.className='exhibit-placeholder';placeholder.textContent='图片位 · 待提供已核准图片';target.append(placeholder);}}
  if(!exhibits.length){const p=document.createElement('p');p.textContent=config.unavailable?'展陈配置暂不可用；空间查看仍可使用。':'此空间尚未配置展陈。团队与展品可独立替换，不改变空间编号。';target.append(p);}
 }
 return {
  update(state,{mode,objects}){
   current=state;const floor=catalog.floors[state.floor],room=floor.rooms.find(r=>r.sourceRoomId===state.room),object=objects[state.object];
   $('spatial-path').textContent=[catalog.building.name,state.scope==='building'?'四层展开':floor.name,room?.name,object?.name].filter(Boolean).join(' / ');
   $('spatial-note').textContent=state.expanded?'选择任一楼层继续；1F 仅为待核准占位，2–4F 沿用已有模型。':state.floor==='1'?'预留层不含已核准几何；边框只用于层级示意。':state.floor==='4'?'仅看办公轮廓与走廊海报位；原办公室模型保留。海报图片及位置待核准。':state.room==='xlab'?'沿用已有实验空间与工位。软硬件分区、设备清单及成果内容待核准。':'按原场景查看；空间不绑定团队，展陈可通过独立配置替换。';
   $('spatial-panel').hidden=mode==='walk';
   select.replaceChildren(new Option('选择对象',''));
   for(const o of Object.values(objects).filter(o=>o.floor===state.floor&&(!state.room||o.room===state.room))){select.add(new Option(o.name+' · '+o.sourceNodeName,o.id));}
   select.value=state.object;select.disabled=select.options.length===1||state.floor==='4'||state.expanded;
   const projected=projectExhibitionConfig(config,room?.id||floor.id);content(projected.exhibits,projected.teams);
  },
  showExhibit(id){const item=config.exhibits.find(e=>e.id===id);if(!item)return;content([item]);$('spatial-details').open=true;}
 };
}
