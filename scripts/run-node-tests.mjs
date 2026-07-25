import { readdir, rm, writeFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";

const projectRoot = process.cwd();
const outputDirectory = resolve(projectRoot, ".test-dist");
const typeScriptCli = resolve(projectRoot, "node_modules/typescript/bin/tsc");

await rm(outputDirectory, { recursive: true, force: true });

const compile = spawnSync(
  process.execPath,
  [typeScriptCli, "--project", resolve(projectRoot, "tsconfig.tests.json")],
  { cwd: projectRoot, stdio: "inherit" }
);

if (compile.error) {
  throw compile.error;
}
if (compile.status !== 0) {
  process.exit(compile.status ?? 1);
}

await writeFile(
  resolve(outputDirectory, "package.json"),
  `${JSON.stringify({ type: "commonjs" }, null, 2)}\n`,
  "utf8"
);

const compiledTests = await collectTestFiles(resolve(outputDirectory, "tests"));
if (compiledTests.length === 0) {
  throw new Error("No compiled test files were found in .test-dist/tests.");
}

const run = spawnSync(
  process.execPath,
  ["--test", "--test-reporter=spec", ...compiledTests],
  { cwd: projectRoot, stdio: "inherit" }
);

if (run.error) {
  throw run.error;
}
process.exit(run.status ?? 1);

async function collectTestFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const path = resolve(directory, entry.name);
    if (entry.isDirectory()) {
      files.push(...await collectTestFiles(path));
    } else if (entry.isFile() && entry.name.endsWith(".test.js")) {
      files.push(path);
    }
  }
  return files.sort();
}
