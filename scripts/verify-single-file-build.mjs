import { readdir, readFile, stat } from "node:fs/promises";
import { resolve } from "node:path";

const outputDirectory = resolve(process.cwd(), "demo");
const requestedArtifact = process.argv[2] ?? "index.html";
const allowedArtifacts = new Set(["index.html", "campus-map-demo.html"]);

if (!allowedArtifacts.has(requestedArtifact)) {
  throw new Error(`Unknown single-file artifact: ${requestedArtifact}`);
}

const outputFiles = (await readdir(outputDirectory, { withFileTypes: true }))
  .filter((entry) => entry.isFile())
  .map((entry) => entry.name)
  .sort();

const unexpectedFiles = outputFiles.filter((file) => !allowedArtifacts.has(file));
if (unexpectedFiles.length > 0) {
  throw new Error(`Unexpected files in demo/: ${unexpectedFiles.join(", ")}`);
}

if (!outputFiles.includes(requestedArtifact)) {
  throw new Error(`demo/${requestedArtifact} is missing.`);
}

function verifyHtmlArtifact(name, html, outputStat) {
  if (!outputStat.isFile() || outputStat.size === 0) {
    throw new Error(`demo/${name} is missing or empty.`);
  }
  const scriptTags = html.match(/<script\b[^>]*>/gi) ?? [];
  const styleTags = html.match(/<style\b[^>]*>/gi) ?? [];
  const linkTags = html.match(/<link\b[^>]*>/gi) ?? [];
  const resourceTags = html.match(/<(?:script|link|img|audio|video|source)\b[^>]*>/gi) ?? [];

  if (scriptTags.length === 0 || scriptTags.every((tag) => !/\btype\s*=\s*["']module["']/i.test(tag))) {
    throw new Error(`demo/${name} does not contain an inline module runtime.`);
  }

  if (scriptTags.some((tag) => /\bsrc\s*=/i.test(tag))) {
    throw new Error(`demo/${name} contains an external script reference.`);
  }

  if (styleTags.length === 0) {
    throw new Error(`demo/${name} does not contain inline styles.`);
  }

  if (linkTags.some((tag) => /\brel\s*=\s*["']?stylesheet\b/i.test(tag) && /\bhref\s*=/i.test(tag))) {
    throw new Error(`demo/${name} contains an external stylesheet reference.`);
  }

  if (resourceTags.some((tag) => /\b(?:src|href|poster)\s*=\s*["']https?:\/\//i.test(tag))) {
    throw new Error(`demo/${name} contains an HTTP-loaded resource.`);
  }

  return { bytes: outputStat.size, inlineScripts: scriptTags.length, inlineStyles: styleTags.length };
}

const validatedArtifacts = await Promise.all(outputFiles.map(async (name) => {
  const outputPath = resolve(outputDirectory, name);
  const [outputStat, html] = await Promise.all([stat(outputPath), readFile(outputPath, "utf8")]);
  return { name, ...verifyHtmlArtifact(name, html, outputStat) };
}));

const requested = validatedArtifacts.find((artifact) => artifact.name === requestedArtifact);
console.log(
  `verified single-file artifact path=demo/${requestedArtifact} bytes=${requested?.bytes ?? 0} inlineScripts=${requested?.inlineScripts ?? 0} inlineStyles=${requested?.inlineStyles ?? 0} validated=${validatedArtifacts.map((artifact) => artifact.name).join(",")}`
);
