# 域名与正式部署

本轮实现了部署配置，没有购买域名、修改 DNS、开放本机端口或部署公网。Docker 配置尚未在本机执行，不等于已上线验收。

## 准备

2026-11-02 共用账号交付优先采用 [游戏与平台同站点](shared-player-account.md)：在专属域名根路径运行平台，/game/ 挂载独立验证过的游戏导出，叠加 deploy/compose.game.yml。设置 GAME_EXPORT_DIR（含本轮原生按钮与 player-account.js 的重新构建产物）、GAME_URL 由该覆盖文件生成。该方案不能直接覆盖已有其他项目的站点根目录。本机已挂载完整游戏并验收，公网仍未部署。上线前另按 [云存档交接](game-cloud-save.md) 备份、迁移 004，再部署对应游戏包。

下方单平台部署仍可单独运行；保留独立 GitHub Pages 游戏地址时，普通链接不等于共用本站登录会话。

使用支持 Docker Compose 的 Linux 主机。为平台选择独立域名或子域名，例如 `ideas.example.com`，将 A/AAAA 记录指向服务器，开放 TCP 80/443。游戏的 GitHub Pages 地址独立保留。

`deploy/compose.production.yml` 运行 PostgreSQL（数据库）、应用、一次性迁移和 Caddy（接收公网请求并自动申请 HTTPS 证书）。数据库和应用不映射公网端口。网页和接口使用同一域名，分享链接随当前域名生成。

在 `platform/deploy/` 新建被 Git 忽略的 `.env`：

```dotenv
DOMAIN=ideas.example.com
POSTGRES_PASSWORD=替换为随机的64位十六进制字符串
AUTHING_ISSUER=https://实际认证域名/oidc
AUTHING_CLIENT_ID=实际应用编号
AUTHING_CLIENT_SECRET=实际应用密钥
OPERATOR_SUBJECTS=实际运营用户ID
GAME_URL=
```

可用 `openssl rand -hex 32` 生成数据库口令。这里要求十六进制，是为了安全嵌入数据库连接地址；不要用示例文字、开发密码或包含 URL 保留字符的密码。不要提交 `.env`。

## 首次启动

在 `platform/deploy/` 执行：

```bash
docker compose --env-file .env -f compose.production.yml up -d --build
docker compose --env-file .env -f compose.production.yml ps
```

数据库健康后运行迁移；迁移成功才启动应用；应用就绪后启动 Caddy。生产配置要求 `PUBLIC_ORIGIN=https://实际域名`，必须与浏览器地址精确一致；Compose 自动从 DOMAIN 生成。`TRUST_PROXY=1` 仅适用于当前应用端口不公开、前面只有一个可信代理的配置，不要直接用于暴露公网的 Node 服务。

验收 `https://实际域名/api/ready` 返回 200，再用两个真实账号检查注册、退出、重登、投稿、支持/取消支持、评分修改与排行榜；从另一台设备打开单条建议的分享链接。按 [Authing 指南](authing-setup.md) 配置正式登录/登出回调及 RS256 签名，再确认浏览器登录 Cookie 带 Secure、HttpOnly 和 SameSite，证书有效。

## 更新与备份

先保存备份，再构建并显式执行新迁移；不要在进程启动时偷偷修改数据库。

```bash
mkdir -p backups
docker compose --env-file .env -f compose.production.yml exec -T db pg_dump -U platform -d platform -Fc > "backups/platform-$(date +%Y%m%d-%H%M%S).dump"
docker compose --env-file .env -f compose.production.yml build
docker compose --env-file .env -f compose.production.yml run --rm migrate
docker compose --env-file .env -f compose.production.yml up -d app gateway
```

备份应另存到服务器以外的位置，并在独立测试库验证恢复；它包含身份关联、授权与处理记录及用户内容，应限制读取权限。版本回退之前检查数据库迁移兼容性，不要运行 `down -v` 删除数据卷。域名切换时同步更改 DOMAIN/PUBLIC_ORIGIN，并重新验收登录及分享。

## 当前产品范围

Authing 托管注册、登录、邮箱验证和密码找回，平台不再接受本地密码。应用配置缺失时可以浏览，投稿登录会明确提示尚未配置；存在三个配置变量不代表 Authing 连通，请实际完成登录回调、邮箱验证、找回和退出验收。正式域名更换时同步更新 Authing 两个回调与 PUBLIC_ORIGIN。

三类投稿、匿名、授权署名、制作前撤稿、运营处理、版本链接、点赞评分和分享已写入平台。阅读进度当前由玩家自设，没有读取游戏的可信存档，不用于奖励。没有默认运营账号，需配置 OPERATOR_SUBJECTS。

当前没有 Authing 管理端封禁/改密的即时平台会话撤销、举报工单、站内消息或抽奖奖金结算。真实运营安排、内容授权范围与维护负责人需由项目团队落实。完整范围见 project-requirements.md。

技术参考：[Authing 普通 Web 应用](https://docs.authing.cn/v2/en/guides/basics/platform-guide/integrate-with-regular-web-app.html)、[openid-client 官方示例](https://github.com/panva/openid-client/blob/main/examples/oidc.ts)。本地协议与 PostgreSQL 测试不等于真实 Authing 或公网部署已验收。
