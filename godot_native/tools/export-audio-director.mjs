/** Build-time only: export the exact source catalog and manifest merge into native JSON. */
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {build} from 'esbuild';
import {sourceTones} from './audio-source-tones.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
const data=path.join(root,'src/data');
const timelineOrder=['act-one','library-finals','chapter3-canteen','chapter3-theater','chapter3-qizhen','chapter3-story','chapter4-prologue','chapter4-755','pursuit'];
const bundled=await build({stdin:{contents:'export {STORY_LINE_CATALOG} from "./src/data/storyLines.ts"; export {PRESENTATION_CUES} from "./src/data/presentation-cues.ts";',resolveDir:root,sourcefile:'native-audio-export.ts'},bundle:true,write:false,platform:'node',format:'esm',logLevel:'silent'});
const catalog=await import('data:text/javascript;base64,'+Buffer.from(bundled.outputFiles[0].text).toString('base64'));
const read=(f)=>JSON.parse(fs.readFileSync(path.join(data,f),'utf8'));
const events={};
for(const name of timelineOrder){for(const [id,beat] of Object.entries(read(name+'.audio.json').events)){events[id]={cues:[...(events[id]?.cues??[]),...beat.cues]};}}
const generated={};
const generatedFiles=fs.readdirSync(data).filter(f=>f.endsWith('.audio.generated.json')).sort();
for(const file of generatedFiles) Object.assign(generated,read(file).assets??{});
const assets={};
function visit(folder){for(const file of fs.readdirSync(folder).sort()){const full=path.join(folder,file);if(fs.statSync(full).isDirectory())visit(full);else if(file.endsWith('.mp3')) assets[file.slice(0,-4)]={path:'res://assets/audio/'+path.relative(path.join(root,'src/assets/audio'),full).split(path.sep).join('/')};}}
visit(path.join(root,'src/assets/audio'));
for(const [id,value] of Object.entries(generated)) assets[id]={...assets[id],...value,path:'res://assets/audio/'+value.path};
// Legacy VoicePlayer has four voiced lines; taunts intentionally remain text-only.
const legacy={};
for(const [key,suffix] of Object.entries(read('vo.map.json').files)) legacy[key]={cues:[{channel:'voice',asset:'vo_legacy_'+key,subtitleKey:key,subtitleSurface:catalog.STORY_LINE_CATALOG[key]?.kind==='dialogue'?'scene':'toast'}]};
legacy.wake_narration.cues[0].offsetMs=400;
legacy.wake_flash.cues.unshift({channel:'sfx',asset:'06_p01_wakeup_big_text_flash_hit',volume:.8});
legacy.xy_attack.cues.unshift({channel:'sfx',asset:'08_p14_friend_chat_shadow_screen_knock',volume:.8});
legacy.xy_laugh.cues.unshift({channel:'sfx',asset:'09_p14_friend_chat_digits_scatter_noise',volume:.8});
legacy.phone_alarm_started={cues:[{channel:'ambient',owner:'phone_alarm',asset:'05_p00_alarm_phone_vibrate_loop',volume:.8,loop:true}]};
legacy.phone_alarm_stopped={cues:[{channel:'ambient',owner:'phone_alarm',action:'stop'}]};
legacy.tower_key_turn={cues:[{channel:'sfx',asset:'21_p13_home_tower_key_turn_90deg',volume:.8}]};
legacy.tower_key_insert={cues:[]}; // Source P13 emits the sound only on rotation at650ms.
const aliases={xiaoying_attack:'xy_attack',tower_key_rotate:'tower_key_turn'};
const chapter4CueIds=[...Object.keys(read('chapter4-755.audio.json').events),...Object.keys(read('pursuit.audio.json').events).filter(x=>x.startsWith('final_chase_'))];
const chipSource=fs.readFileSync(path.join(root,'src/components/useChiptune.ts'),'utf8');
const extract=(pattern)=>{const match=chipSource.match(pattern);if(!match)throw Error('Chiptune source shape changed');return Number(match[1]);};
const chiptune={source:'src/components/useChiptune.ts',waveform:'square',melody:chipSource.match(/const melody = \[([^\]]+)\]/)[1].split(',').map(Number),gain:extract(/setValueAtTime\(([\d.]+)/),endGain:extract(/exponentialRampToValueAtTime\(([\d.]+)/),rampSeconds:extract(/exponentialRampToValueAtTime\([^,]+, ctx.currentTime \+ ([\d.]+)/),noteSeconds:extract(/osc.stop\(ctx.currentTime \+ ([\d.]+)/),stepMs:extract(/setInterval\(tick, ([\d.]+)/)};
const segmenter=new Intl.Segmenter('zh',{granularity:'grapheme'});
const textDurationMsByKey=Object.fromEntries(Object.entries(catalog.STORY_LINE_CATALOG).map(([key,line])=>[key,Math.max(2400,Math.min(6500,1600+120*[...segmenter.segment(line.subtitleZh)].filter(x=>x.segment.trim().length>0).length))]));
const procedural=await sourceTones(root);
const chapter3KeysBySubtitle=Object.fromEntries(read('chapter3-story-lines.json').lines.map(line=>[line.subtitleZh.trim().replace(/\s+/g,' '),line.key]));
const theater=read('chapter3-theater.content.json');
const theaterDialogue={};
for(const [id,lines] of Object.entries({wrong_order:theater.program.wrongDialogue,reversal_before:theater.spotlight.endingDialogue.slice(0,2),reversal_after:theater.spotlight.endingDialogue.slice(2)})){
 let elapsed=0;theaterDialogue[id]=lines.map(text=>{const spoken=text.replace(/^[^：]+：/,'');const durationMs=Math.max(2400,Math.min(6500,1600+120*[...segmenter.segment(spoken)].filter(x=>x.segment.trim().length>0).length));const cue={text,offsetMs:elapsed,durationMs,subtitleKey:chapter3KeysBySubtitle[text.trim().replace(/\s+/g,' ')]??null};elapsed+=durationMs+120;return cue;});
}
const maze=read('chapter4-three-floor-maze.layout.json');
const chapter4Audio={bakeryConveyor:maze.bakeryRuntime.targetEntities.find(x=>x.targetId==='a1_bakery_conveyor_edge').installationBounds,maintenancePushDurationMs:maze.maintenanceRuntime.repairedPush.durationMs};
const out={version:1,chiptune,procedural,chapter3KeysBySubtitle,theaterDialogue,chapter4Audio,textDurationMsByKey,sources:{timelines:timelineOrder.map(x=>x+'.audio.json'),generated:generatedFiles,catalog:'src/data/storyLines.ts'},events,legacy,aliases,assets,storyLines:catalog.STORY_LINE_CATALOG,presentation:catalog.PRESENTATION_CUES,chapter4CueIds};
const output=path.join(root,'godot_native/data/native/audio-director-source.json');
const serialized=JSON.stringify(out,null,2)+'\n';
if(process.argv.includes('--check')){if(fs.readFileSync(output,'utf8')!==serialized)throw Error('Native audio source export is stale');}
else fs.writeFileSync(output,serialized);
const missing=Object.entries(assets).filter(([,v])=>!fs.existsSync(path.join(root,'godot_native',v.path.slice(6)))).map(([k])=>k);
console.log(JSON.stringify({events:Object.keys(events).length,assets:Object.keys(assets).length,lines:Object.keys(out.storyLines).length,missing},null,2));
