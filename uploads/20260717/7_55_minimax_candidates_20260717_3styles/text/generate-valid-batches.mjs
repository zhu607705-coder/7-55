import { createHash } from "node:crypto";
import { mkdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const outDir = join(root, "valid");
const reports = join(root, "../reports");
mkdirSync(outDir, { recursive: true });

const common = "只输出严格JSON，不要Markdown代码围栏，不要解释，不要乱码，不要真实个人信息。";
const batches = [
  ["chapter_one_dialogue.json", `${common}为7:55第一章写2条男旁白和2条女系统对白。男旁白低沉诙谐自嘲，女系统冷幽默克制；每项含voiceTextEn和subtitleZh。不要泄露签到数字。格式{\"maleNarrator\":[],\"femaleSystem\":[]}`],
  ["chapter_two_movement_dialogue.json", `${common}为7:55第二章移动段写2条男旁白和2条女系统对白，覆盖身份、体艺、天气或手柄。每项含voiceTextEn和subtitleZh，不能写精确操作顺序。格式{\"maleNarrator\":[],\"femaleSystem\":[]}`],
  ["chapter_two_library_dialogue.json", `${common}为7:55图书馆调查写2条男旁白和2条女系统对白，覆盖入馆记录、022、纸质证据或CC98。每项含voiceTextEn和subtitleZh，不能说谜底。格式{\"maleNarrator\":[],\"femaleSystem\":[]}`],
  ["chapter_three_dialogue.json", `${common}为7:55第三章写2条男旁白和2条女系统对白，主题是追踪被借走的签到记录，保留留白。每项含voiceTextEn和subtitleZh。格式{\"maleNarrator\":[],\"femaleSystem\":[]}`],
  ["chapter_one_tasks.json", `${common}为7:55第一章写3个当前下一步任务标题和3条渐进提示，只指向应用、物品或区域，不泄露数字答案。格式{\"taskTitles\":[],\"hints\":[]}`],
  ["chapter_two_movement_tasks.json", `${common}为7:55第二章移动段写3个当前下一步任务标题和3条渐进提示，只指向浙大钉、天气、微信、体艺或道具，不列未来步骤。格式{\"taskTitles\":[],\"hints\":[]}`],
  ["chapter_two_library_tasks.json", `${common}为7:55第二章图书馆调查写3个当前下一步任务标题和3条渐进提示，只指向图书馆、纸质证据、馆藏或CC98，不写答案。格式{\"taskTitles\":[],\"hints\":[]}`],
  ["chapter_three_tasks.json", `${common}为7:55第三章写3个当前下一步任务标题和3条渐进提示，只指向馆藏检索或借阅痕迹，不写书名和答案。格式{\"taskTitles\":[],\"hints\":[]}`],
  ["cc98_posts_a.json", `${common}为7:55校园论坛写3个普通帖子，主题为图书馆学习、天气和占座争议，前期不泄露谜底。每项含id,title,author,time,body,tags,visibilityStage。格式{\"posts\":[]}`],
  ["cc98_posts_b.json", `${common}为7:55校园论坛写3个调查帖，主题为022座位、占座书包和缺失记录，语气像真实校园论坛。每项含id,title,author,time,body,tags,visibilityStage。阶段只能evidence_gathering或proofs_ready。格式{\"posts\":[]}`],
  ["cc98_replies.json", `${common}为7:55写4条CC98回复，包含普通回复、冷幽默、证据型和一次有效bd。每项含author,text,tone,visibilityStage，不提前说谜底。格式{\"replies\":[]}`],
  ["cc98_attachments.json", `${common}为7:55写4条论坛附件说明，覆盖占座纸条、旧规则、识别报告和座位凭据。每项含id,caption,evidenceType,safeForEarlyStage，caption不写答案。格式{\"attachments\":[]}`],
  ["cc98_moderation.json", `${common}为7:55写4条版务/系统提示，覆盖搜索、上传阶段、重复材料和排名反馈。每项含text,visibilityStage,tone。格式{\"moderation\":[]}`],
  ["items_a.json", `${common}为7:55写4个物品候选：校园卡、手柄、天气水滴、右移箭头。每项含id,title,source,intro，intro只写客观用途线索。格式{\"items\":[]}`],
  ["items_b.json", `${common}为7:55写4个物品候选：占座纸条、索书号755、旧版离座规定、物品识别报告。每项含id,title,source,intro，不写未解答案。格式{\"items\":[]}`],
  ["items_c.json", `${common}为7:55写4个物品候选：书包非本人证明、022小票、本人来过证明、离座清退PASS。每项含id,title,source,intro，不写未解答案。格式{\"items\":[]}`],
  ["documents_a.json", `${common}为7:55写2份可展开纸质道具正文：占座纸条、索书号755。每项含title,source,body,fields；body只写可核验信息，不写谜底。格式{\"documents\":[]}`],
  ["documents_b.json", `${common}为7:55写2份可展开纸质道具正文：旧版离座规定、物品识别报告。每项含title,source,body,fields；body只写可核验信息。格式{\"documents\":[]}`],
  ["documents_c.json", `${common}为7:55写2份可展开纸质道具正文：书包非本人证明、022小票。每项含title,source,body,fields；body只写可核验信息。格式{\"documents\":[]}`],
  ["documents_d.json", `${common}为7:55写2份可展开纸质道具正文：本人来过证明、离座清退PASS。每项含title,source,body,fields；body只写可核验信息。格式{\"documents\":[]}`],
  ["ui_phone.json", `${common}为7:55写8条手机页面短标签，覆盖主页、浙大钉、CC98、图书馆和天气。短、自然、可放进像素界面。格式{\"phone\":[]}`],
  ["ui_quest.json", `${common}为7:55写8条任务栏短文案，覆盖章节、当前任务、当前进度、下一步目标、三档提示和返回。只写当前下一步，不剧透。格式{\"quest\":[]}`],
  ["ui_toasts.json", `${common}为7:55写8条无配音中文操作吐槽，覆盖签到、道具、搜索、上传和移动。每项含text,voice=none,durationMs且durationMs在2400到6500。格式{\"toasts\":[]}`],
  ["ui_accessibility.json", `${common}为7:55写8条无障碍描述，覆盖任务键、天气通知、纸质道具、上传槽、地图和返回按钮。每项含target,label,description。格式{\"accessibility\":[]}`],
  ["ui_feedback.json", `${common}为7:55写8条按钮或错误反馈，覆盖错误道具、重复上传、未开放、成功使用和关闭抽屉。每项含id,text,tone。格式{\"feedback\":[]}`]
];

function parseJson(value) {
  const cleaned = value.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/i, "").trim();
  const firstObject = Math.min(...[cleaned.indexOf("{"), cleaned.indexOf("[")].filter((index) => index >= 0));
  const lastObject = Math.max(cleaned.lastIndexOf("}"), cleaned.lastIndexOf("]"));
  if (firstObject < 0 || lastObject < firstObject) throw new Error("no complete JSON boundary");
  return JSON.parse(cleaned.slice(firstObject, lastObject + 1));
}

const manifest = [];
if (process.argv.includes("--manifest-only")) {
  for (const filename of batches.map(([name]) => name)) {
    const outputPath = join(outDir, filename);
    if (!statSync(outputPath, { throwIfNoEntry: false })) continue;
    const bytes = statSync(outputPath).size;
    manifest.push({ path: `text/valid/${filename}`, status: bytes > 10 ? "existing" : "failed", bytes, sha256: createHash("sha256").update(readFileSync(outputPath)).digest("hex") });
  }
  writeFileSync(join(reports, "valid-text-manifest.json"), `${JSON.stringify({ generatedAt: new Date().toISOString(), model: "MiniMax-M2.5", assets: manifest }, null, 2)}\n`);
  process.stdout.write(`manifest assets=${manifest.length}\n`);
  process.exit(0);
}
for (const [filename, prompt] of batches) {
  const result = spawnSync("mmx", ["text", "chat", "--model", "MiniMax-M2.5", "--message", prompt, "--max-tokens", "1800", "--temperature", "0.75", "--output", "text", "--timeout", "90", "--non-interactive", "--no-color"], { encoding: "utf8", maxBuffer: 8 * 1024 * 1024 });
  const outputPath = join(outDir, filename);
  const stdout = result.stdout || "";
  let status = "failed";
  let error = result.stderr?.trim() || "";
  try {
    const parsed = parseJson(stdout);
    writeFileSync(outputPath, `${JSON.stringify(parsed, null, 2)}\n`);
    status = "generated";
    error = "";
  } catch (parseError) {
    writeFileSync(outputPath, `${stdout.trim()}\n`);
    error = `${error}${error ? "; " : ""}${parseError instanceof Error ? parseError.message : String(parseError)}`;
  }
  const bytes = statSync(outputPath).size;
  manifest.push({ path: `text/valid/${filename}`, status, bytes, sha256: createHash("sha256").update(readFileSync(outputPath)).digest("hex"), error: error || undefined, prompt });
  process.stdout.write(`${filename}\t${status}\t${bytes} bytes${error ? `\t${error.slice(0, 100)}` : ""}\n`);
}
writeFileSync(join(reports, "valid-text-manifest.json"), `${JSON.stringify({ generatedAt: new Date().toISOString(), model: "MiniMax-M2.5", assets: manifest }, null, 2)}\n`);
