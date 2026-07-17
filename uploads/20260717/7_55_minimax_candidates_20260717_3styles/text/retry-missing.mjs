import { createHash } from "node:crypto";
import { mkdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const outDir = join(root, "valid");
const reports = join(root, "../reports");
mkdirSync(outDir, { recursive: true });
const common = "只输出严格JSON，不要Markdown，不要解释，不要乱码。";
const batches = [
  ["chapter_three_tasks_retry.json", `${common}写2个7:55第三章当前任务标题和2条提示，主题是查借阅痕迹，提示不写书名或答案。格式{\"taskTitles\":[],\"hints\":[]}`],
  ["cc98_posts_c.json", `${common}写2个校园论坛帖子，主题是图书馆座位争议，字段id,title,author,time,body,tags,visibilityStage。格式{\"posts\":[]}`],
  ["cc98_posts_d.json", `${common}写2个校园论坛帖子，主题是缺失签到记录，字段id,title,author,time,body,tags,visibilityStage。格式{\"posts\":[]}`],
  ["cc98_replies_retry.json", `${common}写2条CC98回复，一条冷幽默，一条证据型，字段author,text,tone,visibilityStage。格式{\"replies\":[]}`],
  ["documents_a_retry.json", `${common}写1份占座纸条的可展开正文，字段title,source,body,fields，正文只写可核验信息。格式{\"documents\":[]}`],
  ["documents_c_retry.json", `${common}写1份022小票的可展开正文，字段title,source,body,fields，正文只写可核验信息。格式{\"documents\":[]}`],
  ["cc98_posts_e.json", `${common}写2个校园论坛帖子，主题是旧版离座规定，字段id,title,author,time,body,tags,visibilityStage。格式{\"posts\":[]}`],
  ["cc98_replies_extra.json", `${common}写2条版务回复，覆盖上传槽未开放和重复材料，字段author,text,tone,visibilityStage。格式{\"replies\":[]}`]
];
function parse(value) {
  const cleaned = value.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/i, "").trim();
  const start = Math.min(...[cleaned.indexOf("{"), cleaned.indexOf("[")].filter((n) => n >= 0));
  const end = Math.max(cleaned.lastIndexOf("}"), cleaned.lastIndexOf("]"));
  if (start < 0 || end < start) throw new Error("missing JSON");
  return JSON.parse(cleaned.slice(start, end + 1));
}
const manifest=[];
for (const [name,prompt] of batches) {
  const r=spawnSync("mmx",["text","chat","--model","MiniMax-M2.5","--message",prompt,"--max-tokens","1300","--temperature","0.7","--output","text","--timeout","90","--non-interactive","--no-color"],{encoding:"utf8",maxBuffer:6*1024*1024});
  const p=join(outDir,name);let status="failed";let error=r.stderr?.trim()||"";
  try { writeFileSync(p,`${JSON.stringify(parse(r.stdout||""),null,2)}\n`);status="generated"; } catch(e) { writeFileSync(p,`${(r.stdout||"").trim()}\n`);error=`${error}${error?"; ":""}${e.message}`; }
  manifest.push({path:`text/valid/${name}`,status,bytes:statSync(p).size,sha256:createHash("sha256").update(readFileSync(p)).digest("hex"),error:error||undefined});
  process.stdout.write(`${name}\t${status}\t${statSync(p).size} bytes\n`);
}
writeFileSync(join(reports,"retry-text-manifest.json"),`${JSON.stringify({generatedAt:new Date().toISOString(),model:"MiniMax-M2.5",assets:manifest},null,2)}\n`);
