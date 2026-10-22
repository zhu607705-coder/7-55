import path from 'node:path';
import {repositoryRoot,outputDirectory} from './paths';
import './node_adapter';
import {writeFile} from 'node:fs/promises';
import {GLTFExporter} from 'three/examples/jsm/exporters/GLTFExporter.js';
import {sourceChaseEffects} from '../../../src/scenes/rpg/canteen-chase/ChaseThreeRenderer';
const effects=sourceChaseEffects();effects.bellRing.rotation.x=-Math.PI/2;
for(const [name,root]of Object.entries(effects)){(root as any).name='source_'+name;const glb=await new GLTFExporter().parseAsync(root as any,{binary:true,onlyVisible:false,trs:true});await writeFile(outputDirectory+path.sep+'fx_'+name+'.glb',Buffer.from(glb as ArrayBuffer));console.log('EXACT_SOURCE_EFFECT',name,glb.byteLength);}
