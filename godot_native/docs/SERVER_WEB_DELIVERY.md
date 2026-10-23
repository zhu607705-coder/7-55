# 独立 Godot Web 的服务器交付

服务器负责传送已经构建、验收的 Godot Web 文件；章节拆包和静默下载由 Godot 导出与浏览器加载器实现。仅调整 Nginx 不会把旧的 585 MB 单一 PCK 自动变成章节按需加载。

本工具不构建游戏，不修改剧情、存档或进度控制器，也不安装软件、修改 SSH 权限、防火墙、TLS、既有站点配置或自动清理旧版本。它只能交付 `build-manifest.json` 记录的独立 Godot 产物，不能将成功上传当作浏览器验收。

## 当前服务器事实

2026-10-20 只读检查 `zhuhangcheng@10.70.223.113`：22、80、443 可达；已记录的 SSH ED25519 主机钥正常匹配。服务器只接受公钥，本机 SSH agent 无身份、默认私钥不存在，因此尚未登录、上传或安装配置，CPU、内存、磁盘和真实 Nginx 配置尚未核实。

根页面现为“旧区新生 · 老旧小区改造工作台”，`/7-55/` 返回 404。TLS 证书覆盖 `laneanew.cn`、`www.laneanew.cn`；直接访问 `https://10.70.223.113/` 证书不匹配。应使用实际可达、证书匹配的 HTTPS 域名验收浏览器持久化、后台下载和缓存，不应将 `curl -k` 当作 HTTPS 验收。

缺口是可用的现有 SSH 主机别名、私钥文件路径或服务器控制台接入。不要在聊天发送私钥或密码。工具只使用 SSH agent、现有配置或 `--identity /absolute/existing/key`，强制 `BatchMode=yes` 与 `StrictHostKeyChecking=yes`；不会弹出或传送密码，也不会自动接受新主机钥。

## 隔离目录与旧页面兼容

默认交付目录为 `/srv/755/7-55`，必须由管理员提前准备为登录用户所有、可写，且 Nginx 能读取及遍历其父目录。工具不会自动建立未知的顶层目录或扩大权限。

```text
/srv/755/7-55/
  .755-delivery-root.json
  .755-deployments.jsonl
  current -> releases/<commit-12>-<artifact-digest-16>
  releases/
    <commit-12>-<artifact-digest-16>/
      .755-entry.html
      .755-release.json
      SHA256SUMS
      index.html
      build-manifest.json
      ... 本版本的引擎、首包、所有章节包与元数据
  .staging/   # 上传中，不能通过 Nginx 访问
```

`/7-55/` 只读取 `current/.755-entry.html`，随后立即跳转到 `/7-55/releases/<版本>/`。引擎、章节 manifest 和所有相对资源从该不可变版本目录加载。切换 `current` 不会改变已经打开的旧页面的目录，因此旧页面稍后静默加载时仍取得自己的章节包。回滚只切换入口，也不会删除新版本文件。

不能让游戏一直运行在可变 `/7-55/current/` 路径，也不能在部署后只保留新章节包。加载器必须使用页面相对路径，不能将章节地址硬编码为 `/7-55/chunks/`；需要用浏览器网络记录核查这一点。工具保留全部旧版本，不提供自动 GC。之后若要清理，应先定义旧页面最长支持时长及下载重试策略，再逐版本明确删除，不能仅按当前存档章节判断文件无用。

## 本地校验与计划

要求 Node.js 22、系统 `ssh`、`tar`；远端要求 Python 3、已有 Nginx。示例中的导出目录应替换为本次已验收的拆包产物。

```sh
node godot_native/tools/deploy_web_server.mjs \
  --artifact godot_native/exports/web-release \
  --dry-run
```

`--dry-run` **不连接服务器**。它检查独立 Godot production 标记、无章节捷径、首入口与引擎文件；逐一核对 manifest 中每个文件的 SHA-256、字节数和实际存在性；拒绝未登记的额外文件、重复条目、符号链接、路径穿越及特殊文件。构建元数据也重新计算摘要并纳入完整交付 inventory。拆包产物还核对 `content-manifest.json`、`content-inventory.json`、哈希章节文件名、每包摘要和文件集合，拒绝夹带未登记的全量中间 PCK。结果给出完整 artifact digest、release ID、目标路径，以及已替换路径的 Nginx 配置。

允许 `sourceDirty=true` 的候选包执行只读计划，正式 `--deploy` 则要求 manifest 的 `sourceDirty=false`、`delivery=chapter-content-packs`、完整覆盖收据及章节加载器。历史单一 PCK 可以只读检查，会明确标记 `monolithic-inspection-only`，不能通过本工具正式部署。本检查不重新运行 Godot 挂载及每个资源的覆盖证明，也不证明来源提交已经通过 CI 或章节验收；应先运行构建工具的独立引擎验证及 browser acceptance，再核对这些结果。

## 服务器预检与 Nginx 安装

```sh
node godot_native/tools/deploy_web_server.mjs \
  --artifact godot_native/exports/web-release \
  --host zhuhangcheng@10.70.223.113 \
  --remote-root /srv/755/7-55 \
  --preflight
```

可指定 `--host 已有别名`、`--identity /absolute/existing/key`、`--port 22`。预检只读取机器 CPU 数、物理内存、空闲磁盘、路径所有者/权限、现有 current 链接及 `nginx -T` 的结果；为避免泄露其他项目配置，不输出完整 `nginx -T`。SSH 认证失败时不会上传或改变权限。

管理员需要将 dry-run 输出的 `nginxConfiguration`，或替换 [Nginx 示例](../deploy/nginx-755.conf.example) 的两个路径占位符后，**原样 include 到正确的既有 HTTPS `server {}` 内**。示例只定义 `/7-55/` 及其 releases 路由，保留现有根站、TLS 和上游。它配置 WebAssembly MIME、已核验的静态 gzip 协商、入口 `no-store`、HTML/JSON `no-cache`、不可变版本资源长期缓存，以及缺少资源返回 404。入口关闭 open-file cache，避免 current 切换后继续发送旧入口；独立缺失资源 handler 阻止既有 SPA 的 `error_page 404` 回退到 HTML，并给失败请求 `no-store`，不把 404 缓存一年。路由和文件检查语义参见 [Nginx core 文档](https://nginx.org/en/docs/http/ngx_http_core_module.html#try_files)，压缩类型参见 [Nginx gzip 文档](https://nginx.org/en/docs/http/ngx_http_gzip_module.html#gzip_types)。需要目标 Nginx 提供 [`http_gzip_static_module`](https://nginx.org/en/docs/http/ngx_http_gzip_static_module.html)；构建只为达到至少 4 KiB 且 10% 节省的文件生成 `.gz`，并在 `build-manifest.json.transportCompression` 登记原件与 gzip 的长度、摘要。没有伴随文件的资源仍提供原件；未启用 Brotli。

配置安装与 `nginx -t`、reload 由管理员明确执行，本工具不执行。正式部署要求同一用户的只读 `nginx -T` 成功，且包含与 dry-run 完全匹配的隔离配置，避免无法证明路由归属时覆盖既有站点。若此用户无读取测试所需权限，应由管理员准备可读的安全配置/日志路径或使用已有合适管理身份，不应直接扩大整个 `/etc/nginx` 的权限。

根目录若包含未识别文件、foreign current 链接、其他项目目录、非本工具 ownership marker、非用户所有目录，预检会拒绝部署。首次目录必须为空。已有站点的 `/`、其他路径和配置不能为了游戏直接替换。

## 上传、校验与原子启用

```sh
node godot_native/tools/deploy_web_server.mjs \
  --artifact godot_native/exports/web-release \
  --host zhuhangcheng@10.70.223.113 \
  --remote-root /srv/755/7-55 \
  --deploy
```

正式上传再次预检并取得互斥锁，写入独立 `.staging` 目录。远端 Python 拒绝未登记的 tar 成员、链接、重复文件和大小差异；流式计算全部 SHA-256 并逐个 `fsync`。全部核验通过后，才将 staging 在同一文件系统改名为不可变 release，重新核对版本收据，最后以 `os.replace` 原子替换 `current` 符号链接并记录前后版本。相同 ID 的已有 release 必须逐文件完全相同，绝不覆盖。

上传、断线或摘要错误不会让半个版本变为入口。异常退出留下的 `.755-deploy-lock` 不会自动破解，应先确认无部署进程后由维护者检查；不要盲目删除正在使用的锁。已上传且验证的完整 release 保留，便于重试和回滚。目录切换后若存储同步或日志写入报错，应先读取 current 与交付日志确认实际激活状态，再决定重试。

## 回滚

```sh
node godot_native/tools/deploy_web_server.mjs \
  --rollback <之前输出的commit-12-artifact-digest-16> \
  --host zhuhangcheng@10.70.223.113 \
  --remote-root /srv/755/7-55 \
  --preflight

node godot_native/tools/deploy_web_server.mjs \
  --rollback <同一个完整版本ID> \
  --host zhuhangcheng@10.70.223.113 \
  --remote-root /srv/755/7-55 \
  --deploy
```

回滚不上传、不重建、不修改存档：先重新验证已保留版本的完整 inventory、文件 SHA 与版本入口，再原子切换 current；所有其他版本继续可访问。

## 线上验收必须另做

- 用证书匹配的实际 HTTPS 域名访问 `/7-55/`，确认跳转到本次 release；原有根站继续正常。
- 验证 `index.wasm` 的 `application/wasm`、实际首包与章节包的 HTTP SHA、缓存头；缺失章节返回真实 404，不能回 HTML。
- 限速冷启动确认只下载引擎与首章必要包；进入后续章节前已静默预取，断网/恢复、下载失败重试不推进剧情或丢失物品。
- 保持旧版本页打开后部署新版本，再让旧页请求一个此前未缓存的章节；仍应来自旧 release 并成功。回滚后同样验证新页仍能完成其下载。
- 按正式 browser acceptance 覆盖真实输入、章节衔接、便携存档导入导出、IndexedDB 刷新恢复、音视频后台暂停和三视口布局。

从 GitHub Pages 迁移到服务器是浏览器 origin 变化，浏览器不会将旧 origin 的 IndexedDB/localStorage 自动交给新站。使用游戏现有的普通存档导出/导入流程迁移；不要尝试跨域读取或静默改写旧站存档。

2026-10-23 的示例还为 `releases/<release-id>/boot/index-wasm-<序号>-<摘要>.bin` 精确路由设置 `application/wasm`，使现有 gzip 类型规则覆盖实际启动块；PCK 块和其他 `.bin` 不匹配。38 个实际 WASM 块的本机 level-1 gzip 测量为39.51 → 11.48 MB。配置已做离线匹配/负控与 dry-run 检查，仍须目标主机 `nginx -t` 和实际传输验收；本轮未部署服务器。

## 静态 gzip 与本机验收（2026-10-23）

`tools/web_precompress.mjs` 生成 gzip level 6 伴随文件，并逐项验证解压字节与原件一致。`tools/serve_web.mjs` 启动时核验构建收据，然后根据 `Accept-Encoding` 协商；响应保留原始 MIME，给出实际传输长度、`Content-Encoding: gzip`、`Vary: Accept-Encoding` 和按表示区分的 ETag。未声明 gzip 的客户端继续使用原件。不能把 `.gz` 文件大小当作解压后的 Godot 资源大小。

```sh
node godot_native/tools/serve_web.mjs --directory=godot_native/exports/<verified-export> --port=5241
```

默认只绑定 `127.0.0.1`。指定 `--host` 才会更改监听地址。带 gzip 的 Range 请求返回完整 200，加载器按既有逻辑丢弃旧前缀后校验完整字节；未压缩的视频保留 Range/206 寻址。Nginx 示例仅对启动块、PCK、脚本等传输路由使用 [`max_ranges 0`](https://nginx.org/en/docs/http/ngx_http_core_module.html#max_ranges)，不改变视频路由。

真实本机 HTTP 对 38 个当前 Godot 4.7.1 WASM 块的验证结果为 39,513,091 → 10,216,700 字节；解压后每块长度与 SHA-256 均匹配原构建。此结果衡量传输字节，不代表所有网络或设备的启动时间。工具另有 49 项 HTTP/损坏收据/路径保护验收：`node godot_native/tools/test_web_precompress.mjs`。

GitHub Pages 不提供项目自定义的 gzip 伴随文件协商规则，上传 `.gz` 不等于网站会使用它。原始文件继续保证 Pages 可用，但这次压缩收益以本机 Node 服务或配置了静态 gzip 的服务器为准。生产 Nginx 仍须目标主机 `nginx -t` 和实际 HTTP 检查；本次没有连接或修改远端服务器。

## 本次工具验证的范围

2026-10-20，Node 22.23.3 语法检查通过。隔离的本地 SSH/Nginx fixture 完成 14 个机制场景：只读计划/预检、首次上传、第二版本切换、旧章节保留、回滚、同一版本复用、损坏保留文件拒绝回滚、本地 SHA 差异拒绝、传输中被改字节拒绝且 current 不变、上传被提前拒绝时终止 32 MB tar 管道、夹带已登记全量中间 PCK 拒绝、系统路径/外来目录/不匹配路由拒绝。fixture 只证明部署机制，不是实际 Nginx 语法或浏览器运行验收；没有联系真实服务器写文件。

旧大包与先前拆包尝试只保留为历史证据，不作为本轮最终产物收据；此前 dirty 发布负控已证明调用 SSH 前即拒绝。真实服务器只读 preflight 返回 `Permission denied (publickey)`，没有上传。详细本地证据保存在被忽略的 `godot_native/exports/verification/server_delivery_20261020/`。本机没有 Nginx，示例仍需在目标主机以实际 `nginx -t` 验证并由管理员安装；脚本会保留这道阻断。

v4 拆包候选 `godot_native/exports/web-streaming-20261020` 已完成只读离线 dry-run，证据为 `split-v4-dry-run.json`：39 个交付文件（含构建证明）全部 SHA 一致，artifact digest 为 `6ee0a5c92939182186832865ef8d72450c671d915932b3b8997a5473a68cc4de`。首包 PCK 53,693,300 字节，25 个延迟包共 485,775,160 字节，完整资源覆盖为 2,656 条；运行文件总量 580,124,840 字节，首载运行文件 93,541,854 字节。源输入摘要为 `9a33ef0d283f513dcb5eb279d8382166b7a8e67978af43d76be5cf2823bd8e7f`。这份本地候选的 `sourceDirty=true` 如实保留，计划 release ID 不代表该产物已属于 HEAD 或上线；正式交付须提交后干净重建并核对相应摘要。实际浏览器证据另见 [验收摘要](../verification/web_streaming_20261020/browser_summary.json)。本轮服务器仍无可用 SSH 身份，没有上传或安装 Nginx 配置。
