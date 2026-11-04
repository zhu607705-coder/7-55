/** Renderer-independent cache; injected loaders make failure/lifetime tests executable without WebGL.
 * Ownership: clones borrow resources. Only store.dispose() destroys GPU resources.
 */
export function createReviewStore({assets,loadScene,loadManifest}){
 const cache=new Map(),owned=new Set(),released=new WeakSet();let disposed=false;
 const release=root=>{const resources=new Set();root.traverse(o=>{if(o.geometry)resources.add(o.geometry);for(const m of Array.isArray(o.material)?o.material:o.material?[o.material]:[]){resources.add(m);for(const v of Object.values(m))if(v?.isTexture)resources.add(v);}});resources.forEach(r=>{if(!released.has(r)){released.add(r);r.dispose();}});};
 function load(id){
  if(disposed)return Promise.reject(new Error('Review store disposed'));
  const asset=assets.find(a=>a.id===id);if(!asset)return Promise.reject(new Error('Unknown review asset: '+id));
  if(cache.has(id))return cache.get(id);
  const promise=(async()=>{
   const manifest=await loadManifest(asset.base+'manifest.json');
   if(disposed)throw new Error('Review store disposed');
   if(!Array.isArray(manifest?.source?.size)||manifest.source.size.length!==3||!manifest.source.size.every(v=>Number.isFinite(v)&&v>0)||!Array.isArray(manifest.levels)||manifest.levels.length!==3)throw new Error('Invalid review manifest');
   const levels=[],formats=[];
   // Sequential per asset avoids lost successful roots when another level rejects.
   try{
    for(let level=0;level<3;level++){
     let root;
     try{root=await loadScene(asset.base+`lod${level}.draco.glb`);formats.push('Draco');}
     catch{root=await loadScene(asset.base+`lod${level}.glb`);formats.push('plain 回退');}
     levels.push(root);
     if(disposed)throw new Error('Review store disposed');
    }
   }catch(error){levels.forEach(release);throw error;}
   levels.forEach(r=>owned.add(r));
   return {asset,manifest,formats,create(){if(disposed)throw new Error('Review store disposed');return levels.map(root=>root.clone(true));}};
  })();
  cache.set(id,promise);promise.catch(()=>{if(cache.get(id)===promise)cache.delete(id);});return promise;
 }
 return {load,dispose(){if(disposed)return;disposed=true;owned.forEach(release);owned.clear();cache.clear();}};
}
