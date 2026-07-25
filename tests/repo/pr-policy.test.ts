import { spawnSync } from "node:child_process";
import { resolve } from "node:path";
import { test } from "node:test";
import assert from "node:assert/strict";

const verifier = resolve(process.cwd(), "scripts/verify-pr-policy.mjs");
const validBody = [
  "## 改动",
  "增加可执行的 PR 门禁与自动化测试。",
  "## 原因",
  "避免缺少验证的状态改动进入主分支。",
  "## 协作范围与依赖",
  "工作通道：D\n负责人：@tester\nPR base：main\n依赖：直接面向 main。",
  "## 验证",
  "类型检查、单元测试和构建均通过。",
  "## 风险与回滚",
  "可通过回退本次提交恢复原流程。",
  "## 未覆盖",
  "浏览器端到端测试后续补充。",
  "## 大型 PR 拆分说明",
  "不适用。"
].join("\n\n");

test("PR 规范接受合格标题与完整正文", () => {
  const result = runVerifier({
    PR_TITLE: "test(ci): 增加关键流程回归",
    PR_BODY: validBody,
    PR_CHANGED_FILES: "12",
    PR_ADDITIONS: "420",
    PR_DELETIONS: "80"
  });

  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stderr, "");
});

test("PR 规范拒绝不符合格式的标题", () => {
  const result = runVerifier({
    PR_TITLE: "增加测试",
    PR_BODY: validBody,
    PR_CHANGED_FILES: "3",
    PR_ADDITIONS: "20",
    PR_DELETIONS: "2"
  });

  assert.equal(result.status, 1);
  assert.match(result.stderr, /PR 标题需使用/);
});

test("PR 规范拒绝缺少必需章节和有效内容的正文", () => {
  const result = runVerifier({
    PR_TITLE: "fix(ui): 修正提示",
    PR_BODY: "## 改动\n\n-",
    PR_CHANGED_FILES: "1",
    PR_ADDITIONS: "4",
    PR_DELETIONS: "1"
  });

  assert.equal(result.status, 1);
  assert.match(result.stderr, /PR 正文缺少必需章节/);
  assert.match(result.stderr, /PR 正文信息不足/);
});

test("PR 规范拒绝缺少工作通道和依赖字段的协作章节", () => {
  const body = validBody.replace(
    "工作通道：D\n负责人：@tester\nPR base：main\n依赖：直接面向 main。",
    "本次由多人协作完成。"
  );
  const result = runVerifier({
    PR_TITLE: "feat(preview): 增加协作门户",
    PR_BODY: body,
    PR_CHANGED_FILES: "8",
    PR_ADDITIONS: "500",
    PR_DELETIONS: "20"
  });

  assert.equal(result.status, 1);
  assert.match(result.stderr, /缺少字段：工作通道/);
  assert.match(result.stderr, /缺少字段：负责人/);
  assert.match(result.stderr, /缺少字段：PR base/);
  assert.match(result.stderr, /缺少字段：依赖/);
});

test("大型 PR 必须提供实际拆分说明", () => {
  const result = runVerifier({
    PR_TITLE: "refactor(core): 调整状态模型",
    PR_BODY: validBody,
    PR_CHANGED_FILES: "31",
    PR_ADDITIONS: "1200",
    PR_DELETIONS: "400"
  });

  assert.equal(result.status, 1);
  assert.match(result.stderr, /必须填写“## 大型 PR 拆分说明”/);
});

function runVerifier(environment: Record<string, string>) {
  return spawnSync(process.execPath, [verifier], {
    cwd: process.cwd(),
    encoding: "utf8",
    env: {
      ...process.env,
      ...environment,
      GITHUB_STEP_SUMMARY: ""
    }
  });
}
