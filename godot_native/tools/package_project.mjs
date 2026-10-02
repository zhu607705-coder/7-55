import fs from 'node:fs';import path from 'node:path';import {spawnSync} from 'node:child_process';
const root=path.resolve(import.meta.dirname,'..');const target=path.resolve(process.argv[2]||path.join(root,'exports/7-55-godot-native-source.zip'));
for(const entry of ['project.godot','assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf','data/source/items.config.json'])if(!fs.existsSync(path.join(root,entry)))throw Error('Missing '+entry+'; synchronize source first');
fs.mkdirSync(path.dirname(target),{recursive:true});
const r=spawnSync('zip',['-q','-r',target,'.','-x','.godot/*','.screenshots/*','exports/*','*.log','*/.DS_Store','assets/*.import','assets/**/*.import','script_templates/*','text_editor_themes/*','export_templates/*','feature_profiles/*'],{cwd:root,stdio:'inherit'});
if(r.status!==0)throw Error('Archive failed');console.log(target+' '+fs.statSync(target).size+' bytes');
