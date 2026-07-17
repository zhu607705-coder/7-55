import { createHash } from "node:crypto";
import { mkdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const outDir = join(root, "valid");
const reports = join(root, "../reports");
mkdirSync(outDir, { recursive: true });
const batches = [
  ["cc98_post_clean_a.json", "只输出JSON。写1条校园论坛帖子，主题是图书馆座位争议。字段id,title,author,time,body,tags,visibilityStage。所有字符串必须单行，不要换行，body只写一句，不泄露谜底。格式{\"posts\":[]}"],
  ["cc98_post_clean_b.json", "只输出JSON。写1条校园论坛帖子，主题是缺失签到记录。字段id,title,author,time,body,tags,visibilityStage。所有字符串必须单行，不要换行，body只写一句，不泄露谜底。格式{\"posts\":[]}"],
  ["cc98_post_clean_c.json", "只输出JSON。写1条校园论坛帖子，主题是旧版离座规定。字段id,title,author,time,body,tags,visibilityStage。所有字符串必须单行，不要换行，body只写一句，不泄露谜底。格式{\"posts\":[]}"],
  ["cc98_reply_clean.json", "只输出JSON。写1条CC98冷幽默回复。字段author,text,tone,visibilityStage。所有字符串必须单行，不要换行。格式{\"replies\":[]}"],
  ["document_022_clean.json", "只输出JSON。写1份022小票纸质道具正文。字段title,source,body,fields。所有字符串必须单行，不要换行，body只写可核验信息。格式{\"documents\":[]}"],
  ["document_presence_clean.json", "只输出JSON。写1份本人来过证明纸质道具正文。字段title,source,body,fields。所有字符串必须单行，不要换行，body只写可核验信息。格式{\"documents\":[]}"],
  ["cc98_post_clean_d.json", "只输出JSON。写1条校园论坛普通帖子，主题是雨天去图书馆。字段id,title,author,time,body,tags,visibilityStage。所有字符串必须单行，不要换行。格式{\"posts\":[]}"]
];
function parse(value){const s=value.trim();const a=Math.min(...[s.indexOf("{"),s.indexOf("[")].filter(n=>n>=0));const b=Math.max(s.lastIndexOf("}"),s.lastIndexOf("]"));if(a<0||b<a)throw new Error("no json");return JSON.parse(s.slice(a,b+1));}
const manifest=[];
for(const [name,prompt] of batches){const r=spawnSync("mmx",["text","chat","--model","MiniMax-M2.5","--message",prompt,"--max-tokens","1100","--temperature","0.65","--output","text","--timeout","90","--non-interactive","--no-color"],{encoding:"utf8",maxBuffer:4*1024*1024});const p=join(outDir,name);let status="failed",error=r.stderr?.trim()||"";try{writeFileSync(p,`${JSON.stringify(parse(r.stdout||""),null,2)}\n`);status="generated";}catch(e){writeFileSync(p,`${(r.stdout||"").trim()}\n`);error=`${error}${error?"; ":""}${e.message}`;}manifest.push({path:`text/valid/${name}`,status,bytes:statSync(p).size,sha256:createHash("sha256").update(readFileSync(p)).digest("hex"),error:error||undefined});process.stdout.write(`${name}\t${status}\t${statSync(p).size} bytes\n`);}
writeFileSync(join(reports,"clean-text-manifest.json"),`${JSON.stringify({generatedAt:new Date().toISOString(),model:"MiniMax-M2.5",assets:manifest},null,2)}\n`);
