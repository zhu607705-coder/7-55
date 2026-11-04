/** Browser acceptance target: object order must never imply object type. */
export function selectPhotoDesk(options, objects, desks, floor, room) {
 const visible=new Set(options),bound=new Set(desks.map(d=>d.id));
 const desk=Object.values(objects).find(o=>o.kind==='desk'&&o.floor===floor&&o.room===room&&visible.has(o.id)&&bound.has(o.id));
 if(!desk)throw new Error(`No selectable photo-bound desk in ${floor}/${room}`);
 return desk.id;
}
export function selectedDeskHasNearLod(desks,id) {
 return desks.find(d=>d.id===id)?.level===0;
}
