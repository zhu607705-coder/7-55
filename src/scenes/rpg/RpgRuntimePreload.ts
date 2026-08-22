type RpgGameHostModule = typeof import("./RpgGameHost");

let rpgGameHostModulePromise: Promise<RpgGameHostModule> | null = null;

/**
 * 复用同一份动态导入 Promise，让手机侧可以在切换 runtimeMode 前完成 RPG 模块求值。
 * 单文件 WebKit 对大型延迟模块的同步切换开销较高，因此恢复回放入口会先等待本函数完成。
 */
export function preloadRpgGameHost(): Promise<RpgGameHostModule> {
  if (!rpgGameHostModulePromise) {
    rpgGameHostModulePromise = import("./RpgGameHost").catch((error: unknown) => {
      rpgGameHostModulePromise = null;
      throw error;
    });
  }
  return rpgGameHostModulePromise;
}
