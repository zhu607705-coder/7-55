/** Evidence-limited tabletop finish. Apply only to a photo-bound desktop mesh.
 * Photo shows pale warm wood; this is a colour/material approximation, not a
 * sampled private texture or a claim about wood species. Keep all geometry.
 */
export const PHOTO_DESK_TOP_NAME=/^Height-adjustable desktop(?:\.\d+)?$/;
const cache=new WeakMap();
export function photoDeskTopMaterial(source){
 if(cache.has(source))return cache.get(source);
 const material=source.clone();material.name='Photo pale warm wood tabletop';
 // Linear RGB. The original paper-like material was [.81,.81,.76].
 material.color.setRGB(.62,.43,.27);material.metalness=0;material.roughness=.72;
 material.userData={...material.userData,photoFinish:'warm pale wood; colour approximation'};
 cache.set(source,material);return material;
}
