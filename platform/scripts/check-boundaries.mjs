import ts from "typescript";
import { readdirSync, readFileSync, existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../", import.meta.url));
const groups = [
  "apps/web",
  "apps/api",
  "packages/contracts",
  "packages/database",
];
const allowed = {
  "apps/web": new Set(["apps/web", "packages/contracts"]),
  "apps/api": new Set(["apps/api", "packages/contracts", "packages/database"]),
  "packages/contracts": new Set(["packages/contracts"]),
  "packages/database": new Set(["packages/database", "packages/contracts"]),
};
const failures = [];
function walk(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    if (["dist", "node_modules", ".git"].includes(entry.name)) return [];
    const full = path.join(directory, entry.name);
    return entry.isDirectory()
      ? walk(full)
      : /\.(?:ts|tsx|js|mjs|css)$/.test(full)
        ? [full]
        : [];
  });
}
for (const group of groups) {
  const pkg = JSON.parse(
    readFileSync(path.join(root, group, "package.json"), "utf8"),
  );
  for (const [name, value] of Object.entries({
    ...pkg.dependencies,
    ...pkg.devDependencies,
  })) {
    if (/^(?:file|link):/.test(value) || ["phaser", "three"].includes(name))
      failures.push(`${group}: forbidden dependency ${name}`);
    if (name.startsWith("@755/")) {
      const target = `packages/${name.slice(5)}`;
      if (!allowed[group].has(target))
        failures.push(`${group}: forbidden package ${name}`);
    }
  }
  for (const file of walk(path.join(root, group))) {
    const source = ts.createSourceFile(
      file,
      readFileSync(file, "utf8"),
      ts.ScriptTarget.Latest,
      true,
    );
    function check(specifier) {
      if (!specifier.startsWith(".")) {
        if (
          specifier.startsWith("@755/") &&
          !allowed[group].has(`packages/${specifier.slice(5).split("/")[0]}`)
        )
          failures.push(`${file}: ${specifier}`);
        if (
          (group === "apps/web" || group === "packages/contracts") &&
          /^(node:|pg$|fastify$)/.test(specifier)
        )
          failures.push(`${file}: server-only import ${specifier}`);
        if (
          specifier.startsWith("/") ||
          ["phaser", "three"].includes(specifier)
        )
          failures.push(`${file}: forbidden import ${specifier}`);
        return;
      }
      const target = path.resolve(path.dirname(file), specifier);
      const relative = path.relative(path.join(root, group), target);
      if (relative.startsWith("..") || path.isAbsolute(relative))
        failures.push(`${file}: cross-boundary relative import ${specifier}`);
    }
    function visit(node) {
      if (
        (ts.isImportDeclaration(node) || ts.isExportDeclaration(node)) &&
        node.moduleSpecifier &&
        ts.isStringLiteral(node.moduleSpecifier)
      )
        check(node.moduleSpecifier.text);
      if (
        ts.isCallExpression(node) &&
        (node.expression.kind === ts.SyntaxKind.ImportKeyword ||
          node.expression.getText(source) === "require")
      ) {
        const argument = node.arguments[0];
        if (argument && ts.isStringLiteral(argument)) check(argument.text);
        else failures.push(`${file}: dynamic import target must be explicit`);
      }
      ts.forEachChild(node, visit);
    }
    visit(source);
  }
}
if (!existsSync(path.join(root, "package-lock.json")))
  failures.push("Missing platform lock file");
if (failures.length) {
  console.error(failures.join("\n"));
  process.exitCode = 1;
} else
  console.log(
    "Platform imports and workspace dependencies stay within their product boundaries.",
  );
