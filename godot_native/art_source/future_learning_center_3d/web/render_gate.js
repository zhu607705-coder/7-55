/** Keep input/time updates running; submit WebGL work only after visible changes. */
export function createRenderGate(){
 let dirty=true;
 return {invalidate(){dirty=true;},consume(active=false){if(!dirty&&!active)return false;dirty=false;return true;},get pending(){return dirty;}};
}
