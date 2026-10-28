import fs from 'node:fs';
import path from 'node:path';
import {spawn,execFileSync} from 'node:child_process';
const pause=ms=>new Promise(resolve=>setTimeout(resolve,ms));
function liveGroup(group) {
  if (!group) return [];
  const listing=execFileSync('ps',['-A','-o','pid=','-o','pgid=','-o','stat='],{encoding:'utf8',timeout:5000});
  return listing.trim().split('\n').map(line=>line.trim().split(/\s+/)).filter(([pid,pgid,state])=>Number(pgid)===group && !/^Z/.test(state||'')).map(([pid])=>Number(pid));
}

// Only children created here are signalled. A close/join is mandatory before
// temporary inputs are removed or any downstream success is published.
export function startValidationProcess(command,args,{cwd,env=process.env,logFile,timeoutMs=12*60*1000,strictGodot=false,spawnProcess=spawn,graceMs=3000}={}) {
  fs.mkdirSync(path.dirname(logFile),{recursive:true});
  const fd=fs.openSync(logFile,'w');let child;
  try {child=spawnProcess(command,args,{cwd,env,detached:true,stdio:['ignore',fd,fd]});}
  finally {fs.closeSync(fd);}
  const began=Date.now();let closed=false,settled=false,error,drainError,timer,force,stoppedAt;
  const signal=kind=>{if(!child.pid)return;try{process.kill(-child.pid,kind);}catch(e){if(e.code!=='ESRCH')error ||= e;}};
  const stop=reason=>{if(settled)return;error ||= Error(reason || 'Validation child cancelled');if(stoppedAt===undefined){stoppedAt=Date.now();signal('SIGTERM');force=setTimeout(()=>signal('SIGKILL'),graceMs);}};
  const drainGroup=async()=>{
    while(liveGroup(child.pid).length){
      stop('Validation child left live descendants');
      if(Date.now()-stoppedAt>graceMs+5000)throw Error(`Validation process group did not drain: ${child.pid}`);
      await pause(25);
    }
  };
  const completion=new Promise((resolve,reject)=>{
    child.once('error',value=>{error ||= value;});
    child.once('close',async(status,exitSignal)=>{
      closed=true;clearTimeout(timer);
      try {
        // The leader can exit before a SIGTERM-ignoring ffmpeg/Godot descendant.
        // Do not cancel escalation or return until the entire owned group drains.
        try {await drainGroup();}catch(value){drainError=value;signal('SIGKILL');throw value;}
        const output=fs.readFileSync(logFile,'utf8');
        if(error || status!==0 || exitSignal || (strictGodot && /(?:^|\n)\s*(?:SCRIPT ERROR|ERROR):/.test(output))) throw error || Error(`Validation child failed (${status}/${exitSignal}): ${command}; log ${logFile}`);
        resolve({status,logFile,startedAt:new Date(began).toISOString(),finishedAt:new Date().toISOString(),durationMs:Date.now()-began});
      } catch(value){reject(value);}
      finally {settled=true;clearTimeout(force);}
    });
  });
  // A sibling can fail while its owner is doing synchronous build work. Keep
  // rejection observed, but the explicit join still throws the original error.
  completion.catch(()=>{});
  timer=setTimeout(()=>stop(`Validation child timed out after ${timeoutMs}ms`),timeoutMs);
  return {completion,stop,async stopAndJoin(){if(!settled)stop();await Promise.allSettled([completion]);if(drainError)throw drainError;}};
}

export async function joinValidationProcesses(handles) {
  const results=await Promise.allSettled(handles.map(handle=>handle.completion.catch(error=>{
    for(const peer of handles)if(peer!==handle)peer.stop('Sibling validation preparation failed');throw error;
  })));
  const failed=results.find(result=>result.status==='rejected');if(failed)throw failed.reason;
  return results.map(result=>result.value);
}
