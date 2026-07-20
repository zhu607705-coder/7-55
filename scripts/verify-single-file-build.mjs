import { readdir, readFile, stat } from "node:fs/promises";
import { resolve } from "node:path";

const outputDirectory = resolve(process.cwd(), "demo");
const outputPath = resolve(outputDirectory, "index.html");

const outputFiles = (await readdir(outputDirectory, { withFileTypes: true }))
  .filter((entry) => entry.isFile())
  .map((entry) => entry.name)
  .sort();

if (outputFiles.length !== 1 || outputFiles[0] !== "index.html") {
  throw new Error(`Expected demo/index.html as the only generated file, found: ${outputFiles.join(", ") || "none"}`);
}

const outputStat = await stat(outputPath);
if (!outputStat.isFile() || outputStat.size === 0) {
  throw new Error("demo/index.html is missing or empty.");
}

const html = await readFile(outputPath, "utf8");
const scriptTags = html.match(/<script\b[^>]*>/gi) ?? [];
const styleTags = html.match(/<style\b[^>]*>/gi) ?? [];
const linkTags = html.match(/<link\b[^>]*>/gi) ?? [];
const resourceTags = html.match(/<(?:script|link|img|audio|video|source)\b[^>]*>/gi) ?? [];

if (scriptTags.length === 0 || scriptTags.every((tag) => !/\btype\s*=\s*["']module["']/i.test(tag))) {
  throw new Error("demo/index.html does not contain an inline module runtime.");
}

if (scriptTags.some((tag) => /\bsrc\s*=/i.test(tag))) {
  throw new Error("demo/index.html contains an external script reference.");
}

if (styleTags.length === 0) {
  throw new Error("demo/index.html does not contain inline styles.");
}

if (linkTags.some((tag) => /\brel\s*=\s*["']?stylesheet\b/i.test(tag) && /\bhref\s*=/i.test(tag))) {
  throw new Error("demo/index.html contains an external stylesheet reference.");
}

if (resourceTags.some((tag) => /\b(?:src|href|poster)\s*=\s*["']https?:\/\//i.test(tag))) {
  throw new Error("demo/index.html contains an HTTP-loaded resource.");
}

console.log(
  `verified single-file artifact path=demo/index.html bytes=${outputStat.size} inlineScripts=${scriptTags.length} inlineStyles=${styleTags.length}`
);
