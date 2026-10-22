#!/usr/bin/env node
/** Build-time source enum inventory. Runtime consumes JSON only, never TS/JS. */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import ts from 'typescript';
const root=path.resolve(import.meta.dirname,'../..');
const input='src/core/SaveStore.ts';
const source=fs.readFileSync(path.join(root,input),'utf8');
const ast=ts.createSourceFile(input,source,ts.ScriptTarget.Latest,true,ts.ScriptKind.TS);
const sets={};
for(const statement of ast.statements){
 if(!ts.isVariableStatement(statement))continue;
 for(const declaration of statement.declarationList.declarations){
  const name=declaration.name.getText(ast), init=declaration.initializer;
  if(!/^(VALID_|LEGACY_)/.test(name)||!init||!ts.isNewExpression(init)||init.expression.getText(ast)!=='Set')continue;
  const argument=init.arguments?.[0];
  if(!argument||!ts.isArrayLiteralExpression(argument))throw Error('Unsupported source set '+name);
  sets[name]=argument.elements.map(element=>{
   if(ts.isStringLiteral(element))return element.text;
   if(ts.isNumericLiteral(element))return Number(element.text);
   throw Error('Nonliteral source enum '+name+': '+element.getText(ast));
  });
 }
}
const result=JSON.stringify({format:'7-55-save-domains',version:1,source:input,sourceSha256:crypto.createHash('sha256').update(source).digest('hex'),sets},null,2)+'\n';
const output=path.join(root,'godot_native/data/native/save-domains.json');
if(process.argv.includes('--check')){if(fs.readFileSync(output,'utf8')!==result)throw Error('Native save domain inventory is stale');}
else fs.writeFileSync(output,result);
console.log(`Source save domains: ${Object.keys(sets).length} exact enum sets`);
