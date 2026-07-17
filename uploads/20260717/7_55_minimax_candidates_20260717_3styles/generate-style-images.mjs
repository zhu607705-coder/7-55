import { existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const matrixPath = join(root, "style-matrix.json");
const matrix = JSON.parse(readFileSync(matrixPath, "utf8"));
const targetStyles = process.argv.filter((arg) => arg.startsWith("--style=")).map((arg) => arg.slice(8));
const styles = targetStyles.length ? targetStyles : ["paper_archive", "rainy_scanline"];
const concurrency = Number(process.env.MINIMAX_IMAGE_CONCURRENCY || 3);
const manifestPath = join(root, "reports/style-image-manifest.json");
const jobs = [];

function runMmx(args, label) {
  return new Promise((resolve, reject) => {
    const child = spawn("mmx", [...args, "--timeout", "180", "--non-interactive", "--quiet"], { cwd: root });
    let stderr = "";
    let stdout = "";
    child.stdout?.on("data", (chunk) => { stdout += chunk.toString(); });
    child.stderr?.on("data", (chunk) => { stderr += chunk.toString(); });
    child.on("error", (error) => reject(new Error(`${label}: ${error.message}`)));
    child.on("close", (code) => {
      if (code === 0) resolve(stdout);
      else reject(new Error(`${label}: exit ${code}; ${(stderr || stdout).trim().slice(-1800)}`));
    });
  });
}

for (const concept of matrix.visual) {
  for (const style of styles) {
    const variant = concept.variants[style];
    if (!variant || !variant.prompt) continue;
    jobs.push({ concept, style, variant });
  }
}

async function generate(job) {
  const { concept, style, variant } = job;
  const output = join(root, variant.path);
  if (existsSync(output) && statSync(output).size > 0) {
    variant.status = "existing";
    return { path: variant.path, style, status: "existing", bytes: statSync(output).size };
  }
  mkdirSync(dirname(output), { recursive: true });
  const [width, height] = concept.dimensions;
  try {
    await runMmx([
      "image", "generate", "--prompt", variant.prompt,
      "--width", String(width), "--height", String(height),
      "--response-format", "url", "--out", output
    ], `image ${variant.path}`);
    variant.status = "generated";
    return { path: variant.path, style, status: "generated", bytes: statSync(output).size };
  } catch (error) {
    variant.status = "failed";
    variant.error = error instanceof Error ? error.message : String(error);
    return { path: variant.path, style, status: "failed", error: variant.error };
  }
}

const results = [];
let cursor = 0;
async function worker() {
  while (cursor < jobs.length) {
    const job = jobs[cursor++];
    process.stdout.write(`[${job.style}] ${job.variant.path}\n`);
    results.push(await generate(job));
  }
}
await Promise.all(Array.from({ length: Math.min(concurrency, jobs.length) }, () => worker()));

matrix.generatedAt = new Date().toISOString();
writeFileSync(matrixPath, `${JSON.stringify(matrix, null, 2)}\n`);
writeFileSync(manifestPath, `${JSON.stringify({ generatedAt: matrix.generatedAt, styles, concurrency, results }, null, 2)}\n`);
const counts = results.reduce((acc, result) => { acc[result.status] = (acc[result.status] || 0) + 1; return acc; }, {});
process.stdout.write(`completed ${results.length} image variants ${JSON.stringify(counts)}\n`);
