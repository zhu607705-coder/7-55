import { spawn } from "node:child_process";

const children = [];
let stopping = false;
function stop(code = 0) {
  if (stopping) return;
  stopping = true;
  process.exitCode = code;
  for (const child of children) {
    if (!child.pid) continue;
    if (process.platform === "win32") child.kill();
    else {
      try {
        process.kill(-child.pid, "SIGTERM");
      } catch {}
    }
  }
}
for (const workspace of ["@755/api", "@755/web"]) {
  const child = spawn(
    process.platform === "win32" ? "npm.cmd" : "npm",
    ["run", "dev", "-w", workspace],
    {
      stdio: "inherit",
      detached: process.platform !== "win32",
      env: { ...process.env, SERVE_WEB: "false" },
    },
  );
  children.push(child);
  child.on("error", () => stop(1));
  child.on("exit", (code) => {
    if (!stopping) stop(code || 1);
  });
}
for (const signal of ["SIGINT", "SIGTERM"]) process.on(signal, () => stop());
