import { createHash } from "node:crypto";
import { mkdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const reports = join(root, "../reports");
mkdirSync(reports, { recursive: true });

const batches = [
  ["chapter_one_narrator.json", "只输出JSON。为7:55第一章写3条男旁白，每项含voiceTextEn与subtitleZh，低沉、诙谐、自嘲，关于07:55起床和签到，不能泄露答案。格式{\"maleNarrator\":[]}"],
  ["chapter_one_system.json", "只输出JSON。为7:55第一章写3条女系统对白，每项含voiceTextEn与subtitleZh，冷幽默、克制，指向手机签到和当前操作，不给数字答案。格式{\"femaleSystem\":[]}"],
  ["chapter_one_quest.json", "只输出JSON。为7:55第一章写4个当前下一步任务标题和6条三档提示，提示只指向应用、物品或界面区域，不泄露数字。格式{\"taskTitles\":[],\"hints\":[]}"],
  ["chapter_one_taunts.json", "只输出JSON。为7:55第一章写4条无配音中文操作吐槽，轻微自嘲，每项含text、voice=none、durationMs且在2400到6500。格式{\"taunts\":[]}"],
  ["chapter_two_movement.json", "只输出JSON。为7:55第二章移动段写3条男旁白、3条女系统对白、4个当前任务标题和6条渐进提示，覆盖身份、体艺、天气、微信和手柄；对白含voiceTextEn与subtitleZh，提示不写精确顺序。格式{\"maleNarrator\":[],\"femaleSystem\":[],\"taskTitles\":[],\"hints\":[]}"],
  ["chapter_two_movement_taunts.json", "只输出JSON。为7:55第二章移动段写5条无配音中文吐槽，覆盖锻炼、余额、购买手柄和首次移动，每项含text、voice=none、durationMs在2400到6500。格式{\"taunts\":[]}"],
  ["chapter_two_library.json", "只输出JSON。为7:55第二章图书馆调查写4条男旁白、4条女系统对白、5个当前任务标题和8条渐进提示，覆盖入馆记录、022、纸质证据、馆藏和CC98；对白含voiceTextEn与subtitleZh，提示不写谜底、数字顺序或正确字母。格式{\"maleNarrator\":[],\"femaleSystem\":[],\"taskTitles\":[],\"hints\":[]}"],
  ["chapter_two_library_taunts.json", "只输出JSON。为7:55第二章图书馆调查写5条无配音中文吐槽，覆盖纸条、旧规则、证明上传和恢复申请，每项含text、voice=none、durationMs在2400到6500。格式{\"taunts\":[]}"],
  ["chapter_three.json", "只输出JSON。为7:55第三章写3条男旁白、3条女系统对白、4个当前任务标题和6条提示，主题是寻找借走签到记录的书，保留留白，不写书名或答案。对白含voiceTextEn与subtitleZh。格式{\"maleNarrator\":[],\"femaleSystem\":[],\"taskTitles\":[],\"hints\":[]}"],
  ["cc98_posts.json", "只输出JSON。为7:55生成8条校园论坛候选帖子，主题是图书馆座位、占座书包和缺失记录，前期不泄露谜底。每项含id、title、author、time、body、tags、visibilityStage，阶段只能chapter_two_start、evidence_gathering、proofs_ready、upload_complete、ranking。不要真实个人信息。格式{\"posts\":[]}"],
  ["cc98_replies.json", "只输出JSON。为7:55生成10条CC98回复和8条附件说明、6条版务提示。回复含author、text、tone、visibilityStage；附件含id、caption、evidenceType、safeForEarlyStage；轻微灌水和冷幽默，不提前说谜底。格式{\"replies\":[],\"attachments\":[],\"moderation\":[]}"],
  ["ui_items_documents.json", "只输出JSON。为7:55生成12条物品短描述和8类纸质道具正文，覆盖校园卡、手柄、天气水滴、占座纸条、索书号755、旧规则、识别报告、非本人证明、022小票、本人来过证明、清退PASS。物品含id、title、source、intro；文档含title、source、body、fields；不能给未解答案。格式{\"items\":[],\"documents\":[]}"],
  ["ui_microcopy.json", "只输出JSON。为7:55生成20条手机标签、24条任务栏标签、20条无配音吐槽、12条无障碍描述和12条按钮反馈。任务只暴露当前下一步；吐槽含voice=none和durationMs在2400到6500；中文自然不乱码。格式{\"phone\":[],\"quest\":[],\"toasts\":[],\"accessibility\":[],\"feedback\":[]}"],
];

const manifest = [];
for (const [filename, prompt] of batches) {
  const outputPath = join(root, filename);
  const result = spawnSync("mmx", ["text", "chat", "--model", "MiniMax-M2.5", "--message", prompt, "--max-tokens", "2200", "--temperature", "0.8", "--output", "text", "--timeout", "90", "--non-interactive", "--no-color"], { encoding: "utf8", maxBuffer: 12 * 1024 * 1024 });
  const stdout = (result.stdout || "").trim();
  const stderr = (result.stderr || "").trim();
  writeFileSync(outputPath, `${stdout}\n`);
  if (stderr) writeFileSync(`${outputPath}.stderr.log`, `${stderr}\n`);
  manifest.push({
    path: `text/${filename}`,
    status: result.status === 0 && stdout.length > 10 ? "generated" : "failed",
    bytes: statSync(outputPath).size,
    sha256: createHash("sha256").update(readFileSync(outputPath)).digest("hex"),
    prompt
  });
  process.stdout.write(`${filename}\t${manifest.at(-1).status}\t${statSync(outputPath).size} bytes\n`);
}
writeFileSync(join(reports, "text-manifest.json"), `${JSON.stringify({ generatedAt: new Date().toISOString(), model: "MiniMax-M2.5", assets: manifest }, null, 2)}\n`);
