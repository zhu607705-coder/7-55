import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {mkdirSync} from 'node:fs';
export const repositoryRoot=process.env.CANTEEN_SOURCE_ROOT ?? path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
export const nativeRoot=process.env.CANTEEN_NATIVE_ROOT ?? path.join(repositoryRoot,'godot_native');
export const outputDirectory=path.join(nativeRoot,'.chase-source-export');
mkdirSync(outputDirectory,{recursive:true});
