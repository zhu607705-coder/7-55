#!/usr/bin/env node
/** Compile only the original, pure save-normalization functions into closed data.
 * Runtime does not load TypeScript, JavaScript, Node, or user-supplied instructions.
 * Unsupported syntax is a build error, never an implicit approximation.
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import ts from 'typescript';
import { build } from 'esbuild';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const sourcePath = 'src/core/SaveStore.ts';
const source = fs.readFileSync(path.join(root, sourcePath), 'utf8');
const start = '      const isVersionedEnvelope =';
const end = '      return hydrated;';
if (source.split(start).length !== 2 || source.split(end).length !== 2) throw new Error('SaveStore extraction anchors changed');
const pure = source.slice(0, source.indexOf('export class SaveStore'))
  + 'export function normalizeBrowserSave(parsed: unknown, initial: GameState): GameState | null { if (!isRecord(parsed)) return null;\n'
  + source.slice(source.indexOf(start), source.indexOf(end) + end.length) + '\n}\n'
  + source.slice(source.indexOf('interface QizhenNormalizationResult'))
  + '\nexport { createPersistentSnapshot };\n';
const bundled = await build({stdin: {contents: pure, resolveDir: path.join(root, 'src/core'), sourcefile: 'save-normalizer-generated.ts', loader: 'ts'}, bundle: true, write: false, format: 'esm', platform: 'neutral', treeShaking: true, metafile: true});
const text = bundled.outputFiles[0].text;
const sf = ts.createSourceFile('normalizer.js', text, ts.ScriptTarget.Latest, true, ts.ScriptKind.JS);
const bad = node => {throw new Error(`Unsupported ${ts.SyntaxKind[node.kind]}: ${node.getText(sf).slice(0, 140)}`);};
const name = n => ts.isIdentifier(n) || ts.isStringLiteral(n) || ts.isNumericLiteral(n) ? n.text : bad(n);
function constant(n) {
  if (ts.isStringLiteral(n) || ts.isNoSubstitutionTemplateLiteral(n)) return {value:n.text};
  if (ts.isNumericLiteral(n)) return {value:Number(n.text)};
  if (n.kind===ts.SyntaxKind.TrueKeyword) return {value:true};
  if (n.kind===ts.SyntaxKind.FalseKeyword) return {value:false};
  if (n.kind===ts.SyntaxKind.NullKeyword) return {value:null};
  if (ts.isPrefixUnaryExpression(n) && n.operator===ts.SyntaxKind.MinusToken) {const v=constant(n.operand); if(v && typeof v.value==='number') return {value:-v.value};}
  if (ts.isArrayLiteralExpression(n)) {const a=n.elements.map(constant); if(a.every(Boolean)) return {value:a.map(x=>x.value)};}
  if (ts.isObjectLiteralExpression(n)) {const out={}; for(const p of n.properties) {if(!ts.isPropertyAssignment(p) || ts.isComputedPropertyName(p.name)) return null; const v=constant(p.initializer); if(!v)return null; out[name(p.name)]=v.value;} return {value:out};}
  return null;
}
function params(n) {return n.parameters.map(p=>[name(p.name),p.initializer ? expr(p.initializer):['undefined']]);}
function expr(n) {
  if (!n) return ['undefined'];
  const lit=constant(n); if(lit)return ['literal',lit.value];
  if (ts.isIdentifier(n)) return ['name',n.text];
  if (ts.isParenthesizedExpression(n)) return expr(n.expression);
  if (ts.isPropertyAccessExpression(n)) return ['get',expr(n.expression),['literal',n.name.text],Boolean(n.questionDotToken)];
  if (ts.isElementAccessExpression(n)) return ['get',expr(n.expression),expr(n.argumentExpression),Boolean(n.questionDotToken)];
  if (ts.isConditionalExpression(n)) return ['conditional',expr(n.condition),expr(n.whenTrue),expr(n.whenFalse)];
  if (ts.isBinaryExpression(n)) {const op=n.operatorToken.getText(sf);if(!['=','===','!==','<','<=','>','>=','&&','||','??','+','-'].includes(op))return bad(n);return ['binary',op,expr(n.left),expr(n.right)];}
  if (ts.isPrefixUnaryExpression(n)) {const op=ts.tokenToString(n.operator);if(!['!','+','-'].includes(op))return bad(n);return ['unary',op,expr(n.operand)];}
  if (ts.isTypeOfExpression(n)) return ['typeof',expr(n.expression)];
  if (ts.isCallExpression(n)) return ['call',expr(n.expression),n.arguments.map(expr)];
  if (ts.isNewExpression(n)) {if (!['Set','Error'].includes(n.expression.getText(sf)))return bad(n); return ['new',n.expression.getText(sf),(n.arguments||[]).map(expr)];}
  if (ts.isArrowFunction(n)) return ['function',params(n),ts.isBlock(n.body)?stmt(n.body):['return',expr(n.body)]];
  if (ts.isArrayLiteralExpression(n)) return ['array',n.elements.map(v=>ts.isSpreadElement(v)?['spread',expr(v.expression)]:expr(v))];
  if (ts.isObjectLiteralExpression(n)) return ['object',n.properties.map(p=>ts.isSpreadAssignment(p)?['spread',expr(p.expression)]:ts.isShorthandPropertyAssignment(p)?['property',['literal',p.name.text],expr(p.name)]:ts.isPropertyAssignment(p)?['property',ts.isComputedPropertyName(p.name)?expr(p.name.expression):['literal',name(p.name)],expr(p.initializer)]:bad(p))];
  if (ts.isTemplateExpression(n)) return ['template',n.head.text,n.templateSpans.map(s=>[expr(s.expression),s.literal.text])];
  return bad(n);
}
function stmt(n) {
  if (ts.isBlock(n) || ts.isSourceFile(n)) return ['block',n.statements.filter(s=>!ts.isExportDeclaration(s)).map(stmt)];
  if (ts.isVariableStatement(n)) return ['variables',n.declarationList.declarations.map(d=>[name(d.name),expr(d.initializer)])];
  if (ts.isFunctionDeclaration(n)) return ['declare',name(n.name),params(n),stmt(n.body)];
  if (ts.isReturnStatement(n)) return ['return',expr(n.expression)];
  if (ts.isExpressionStatement(n)) return ['expression',expr(n.expression)];
  if (ts.isIfStatement(n)) return ['if',expr(n.expression),stmt(n.thenStatement),n.elseStatement?stmt(n.elseStatement):['empty']];
  if (ts.isForOfStatement(n)) {if(!ts.isVariableDeclarationList(n.initializer)||n.initializer.declarations.length!==1) return bad(n); return ['for',name(n.initializer.declarations[0].name),expr(n.expression),stmt(n.statement)];}
  if (ts.isContinueStatement(n)) return ['continue'];
  if (ts.isThrowStatement(n)) return ['throw',expr(n.expression)];
  if (ts.isEmptyStatement(n)) return ['empty'];
  return bad(n);
}
const dependencies = [sourcePath,...Object.keys(bundled.metafile.inputs).filter(p=>!p.includes('save-normalizer-generated.ts')).map(p=>path.relative(root,path.resolve(p)))].sort();
const hashes = Object.fromEntries(dependencies.map(p=>[p,crypto.createHash('sha256').update(fs.readFileSync(path.join(root,p))).digest('hex')]));
const program = {format:'7-55-native-normalization-ir',version:1,sourceSaveVersion:35,sourceHashes:hashes,program:stmt(sf)};
const target = path.join(root,'godot_native/data/native/save_normalizer.json');
const output = JSON.stringify(program)+'\n';
if(process.argv.includes('--check')) {if(fs.readFileSync(target,'utf8')!==output)throw new Error('Normalizer data is stale; run node godot_native/tools/build-save-normalizer.mjs');console.log('Save normalizer data matches source');}
else {fs.writeFileSync(target,output);console.log(`Generated ${output.length} bytes from ${dependencies.length} source files`);}
