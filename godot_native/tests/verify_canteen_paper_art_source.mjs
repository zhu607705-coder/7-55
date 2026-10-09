// Asset-free parity check. Execute the original texture generators as a draw
// command oracle, then compare all five native poses from an isolated project.
// No GUI, autoloads, asset import, new art or browser runtime is involved.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const sourceRoot=process.env.CANTEEN_SOURCE_ROOT||root;
const source=fs.readFileSync(path.join(sourceRoot,'src/scenes/rpg/CanteenInteriorScene.ts'),'utf8');
const staticStart=source.indexOf('    if (!this.textures.exists(CANTEEN_PAPER_KEY)) {');
assert.ok(staticStart>=0,'original resting-paper generator exists');
let resting=source.slice(staticStart,source.indexOf('    CANTEEN_PAPER_RUN_KEYS.forEach',staticStart));
resting=resting.replace(': Record<string, readonly string[]>','');
let running=source.slice(source.indexOf('  private generatePaperRunTexture('),source.indexOf('  private createTrays()'));
running=running.replace('private generatePaperRunTexture(key: string, frame: number): void','generatePaperRunTexture(key, frame)').replace(': number','');
const Phaser={Geom:{Point:class {constructor(x,y){this.x=x;this.y=y;}}}};
const Scene=new Function('Phaser','CANTEEN_PAPER_KEY',`return class { resting() { ${resting} } ${running} }`)(Phaser,'paper');

function commandsFor(frame){
  const commands=[];
  let fill=['000000',1],line=['000000',1,1];
  const hex=color=>color.toString(16).padStart(6,'0');
  const points=values=>values.map(p=>[p.x,p.y]);
  const g={
    fillStyle(color,alpha=1){fill=[hex(color),alpha];return this;},
    lineStyle(width,color,alpha=1){line=[hex(color),alpha,width];return this;},
    fillEllipse(x,y,w,h){commands.push(['ellipse',[x,y,w,h],...fill]);return this;},
    fillPoints(p,close){assert.equal(close,true);commands.push(['polygon',points(p),...fill]);return this;},
    strokePoints(p,close){assert.equal(close,true);commands.push(['polyline',points(p),...line]);return this;},
    lineBetween(x,y,a,b){commands.push(['line',[[x,y],[a,b]],...line]);return this;},
    fillRect(x,y,w,h){commands.push(['rect',[x,y,w,h],...fill]);return this;},
    generateTexture(key,w,h){assert.deepEqual([w,h],[64,50]);},destroy(){}
  };
  const scene=new Scene();
  scene.add={graphics:()=>g};scene.textures={exists:()=>false};
  if(frame<0)scene.resting();else scene.generatePaperRunTexture(`run${frame}`,frame);
  return commands;
}

const temp=fs.mkdtempSync(path.join(os.tmpdir(),'canteen-paper-art-'));
try{
  for(const relative of ['scripts/presentation/c3_paper_art.gd','scripts/games/canteen_defense_model.gd','tests/test_canteen_paper_art.gd']){
    const target=path.join(temp,relative);fs.mkdirSync(path.dirname(target),{recursive:true});
    fs.copyFileSync(path.join(root,'godot_native',relative),target);
  }
  fs.mkdirSync(path.join(temp,'data'));
  fs.copyFileSync(path.join(sourceRoot,'godot_native/data/worlds.json'),path.join(temp,'data/worlds.json'));
  fs.writeFileSync(path.join(temp,'project.godot'),'config_version=5\n[application]\nconfig/name="Paper art source parity"\n[threading]\nworker_pool/max_threads=1\n');
  const dump=path.join(temp,'frames.json');
  const isolatedEnv={...process.env,CANTEEN_PAPER_DUMP:dump,HOME:temp,XDG_CACHE_HOME:path.join(temp,'.cache'),XDG_DATA_HOME:path.join(temp,'.data'),XDG_CONFIG_HOME:path.join(temp,'.config')};
  const run=spawnSync(process.env.GODOT_BIN||'godot',['--headless','--path',temp,'--script','res://tests/test_canteen_paper_art.gd','--quit-after','8'],{
    encoding:'utf8',timeout:30000,env:isolatedEnv
  });
  const output=(run.stdout||'')+(run.stderr||'');
  process.stdout.write(output);
  assert.ifError(run.error);assert.equal(run.status,0);
  assert.doesNotMatch(output,/SCRIPT ERROR|Parse Error/);
  assert.match(output,/CANTEEN_PAPER_ART \d+ checks; 0 failures/,'all native geometry and draw-call checks finished');
  const frames=JSON.parse(fs.readFileSync(dump,'utf8'));
  for(const frame of [-1,0,1,2,3])assert.deepEqual(frames[frame],commandsFor(frame),`native/source draw order, coordinates, colours and opacity for frame${frame}`);

  const defense=fs.readFileSync(path.join(root,'godot_native/scripts/games/canteen_defense.gd'),'utf8');
  const paperMethod=defense.slice(defense.indexOf('func _draw_paper('),defense.indexOf('func _draw_pickup('));
  assert.match(paperMethod,/PaperArt\.draw\(canvas,model\.paper,1\.16,model\.paper_angle,model\.paper_frame,1\.0,model\.paper_flip,board_transform\)/,'live defense consumes shared model-driven art');
  assert.match(defense,/_draw_paper\(canvas,Transform2D\(0,Vector2\.ONE\*zoom,0,offset\)\)/,'all board layouts pass their own camera transform');
  assert.doesNotMatch(paperMethod,/model\.\w+\s*=(?!=)|draw_colored_polygon|draw_line/,'no duplicate body or renderer-owned gameplay');
  console.log('PASS original paper generator: resting + four run frames, exact source commands, folded-leg strides, board-camera integration and model-owned impact');
}finally{
  fs.rmSync(temp,{recursive:true,force:true});
}
