# 《7:55》共创平台源码与运行指南

这是《7:55》的玩家社区和建议投递网站。当前版本有两个入口：

- **玩家社区**：发布帖子、评论、点赞，交流游戏体验。标题选填，支持匿名和剧透折叠。
- **建议投递**：填写标题、类型和具体建议；每个账号每份建议一票，可取消，按票数排行。主创团队后续与同学沟通，不设置自动采纳门槛，也不展示采纳/制作流程。

首屏移除章节侧栏、三类投稿入口、统计条、星级评分及处理状态。账号菜单保留自己的内容和昵称设置；运营账号仍能隐藏/恢复内容、删除不当评论。原有帖子、权限记录、评分和处理接口保留兼容，旧内容在社区中按原有可见范围显示，不自动改写为正式建议。

游戏与平台沿用同一个 Authing 玩家账号和云存档服务。本次更新在本机预览；公网域名、服务器和真实登录服务的上线状态需另行确认。

## 本地启动

需要 Node.js 22.12+（22 系列）、npm 10、PostgreSQL 17。以下命令在 `platform/` 执行：

```bash
npm ci
cp .env.example .env
npm run build
npm run db:up
npm run db:migrate
npm run dev
```

`db:up` 用 Docker Compose 启动开发库；已有 PostgreSQL 时修改 DATABASE_URL 并跳过此步。打开 http://127.0.0.1:5174 ，浏览器地址必须精确匹配 PUBLIC_ORIGIN。用 localhost、换端口或换域名时同步更新配置与 Authing 回调地址。

Authing 三项配置留空时可以浏览和写草稿。配置登录方式与回调的步骤见 [Authing 配置指南](docs/authing-setup.md)。首次登录后，可从账号菜单修改公开昵称。平台不读取 Authing 的邮箱、手机号或学号。

生产预览：

```bash
npm run build
npm run db:migrate
NODE_ENV=production SERVE_WEB=true PUBLIC_ORIGIN=http://127.0.0.1:3001 npm start
```

此时使用 http://127.0.0.1:3001 ，Authing 的登录/登出回调也需对应 3001。开发服务器使用 5174，两种预览的回调不能混用。

## 目录与任务边界

| 目录 | 负责内容 |
|---|---|
| `apps/web/src/app` | 页面组合、账号状态、筛选与详情导航 |
| `apps/web/src/features/community` | 发帖和建议表单、评论、草稿及内容管理 |
| `apps/api/src/modules/auth` | Authing 标准协议、验证回调与身份 |
| `apps/api/src/modules/community` | 会话、权限、请求来源检查、限流、投稿与运营接口 |
| `apps/api/src/modules/game-saves` | 本人云存档与附件 HTTP 接口 |
| `packages/contracts` | 前后端共享的字段、范围和运行时校验 |
| `packages/database` | 数据权限过滤、持久化、并发约束和追加式迁移 |
| `tests` | Node 内置测试、签名身份服务测试、真实 PostgreSQL 验收 |
| `deploy` / `docs` | 独立部署与交接说明 |

平台云存档模块保存原生存档封装与附件，只做存储格式与归属校验；不导入游戏运行代码或剧情源码，不控制游戏进度。展示素材是独立复制的公开图片和字体，带来源和许可。根目录游戏工程、依赖和发布管线不属于平台运行时。

## 当前交互与旧版兼容

以下涉及“本章说”、改编授权、星级评分、制作状态的条款用于既有数据和接口兼容，不再作为当前玩家界面的入口。新建议不因投票自动改变状态。评论存于独立数据库表，每页 30 条；游客可读，登录后可评论，作者或运营可删除。剧透帖子未展开时不下发评论，隐藏和撤回会同步阻止公开访问。


- 三类投稿分别筛选；卡点反馈不要求通关。一句话即可，标题选填，由正文开头生成。
- 游客可浏览非剧透内容、在当前标签页写草稿；投稿、点赞和评分时登录。草稿保留 2 小时，登录前的操作续接保留 10 分钟；不保存密码或第三方令牌，主动退出会清除草稿。
- Authing 负责注册、验证、密码找回；平台按 `issuer + subject` 关联业务身份，绝不按邮箱自动合并。随机 Cookie 会话最长 8 小时，服务端只存摘要，退出即时撤销当前平台会话并前往 Authing 登出页。
- 公开昵称与认证身份分离；匿名投稿的公开响应不含原作者 ID。对游戏署名另选匿名、平台昵称或自定义名称。只有作者能变更自己的授权与署名。
- 收录不等于入选。状态为已收录、待讨论、制作中、可试玩、已发布、暂缓处理；运营更新必须写具体回复。试玩/发布需有 HTTPS 链接和版本说明。
- 经历/故事未授权不能进入制作。进入过制作后，即使状态退回讨论，也不允许自动撤稿或直接取消授权，需要与团队协商。制作前可以自行撤稿；撤稿为停止公开，保留内部记录。
- 本章说按玩家自设的阅读进度在服务端过滤，未读章节不出现在列表、详情、搜索、处理记录和互动中。这是防剧透偏好，不是已经接通游戏的通关验证；不用于成就或奖励。卡点反馈不受它限制。
- 剧透标题、正文及团队回复默认不下发，读者主动展开才加载。运营可审核完整内容；私密章节、撤回和隐藏的内容不会进入公开查询。
- 每账号每条投稿一个赞、一个评分，可改分或撤回；唯一键和事务处理重复、并发请求。榜单只反映意见，不保证“一人一号”，也不自动决定选题。
- 运营账号来自服务器的明确用户 ID 列表，无默认管理员、注册提权或前端自报角色。隐藏/恢复保留内部原因，进度更新检查版本，避免多人覆盖。

## 接口

业务路径以 `/api/v1` 开头；写请求要求精确 Origin 和 `X-Requested-With: 755-platform`。响应按共享契约校验。

| 路径 | 用途 |
|---|---|
| `GET /api/health` / `/api/ready` | 存活 / 数据库迁移就绪 |
| `GET /chapters` / `/stats` | 公开目录 / 当前阅读范围内统计 |
| `GET /auth/config` / `/session` | 登录是否配置、游戏链接 / 当前身份 |
| `POST /auth/start` / `GET /auth/callback` / `POST /auth/logout` | Authing 登录发起 / 验证回调 / 退出 |
| `PUT /profile` | 公开昵称和自设阅读进度 |
| `GET /ideas` | section=community/suggestions、q、mine、sort、page；兼容旧 channel/status/chapterId；每页 12 条 |
| `GET/POST /ideas/:id/comments` | 分页读取评论 / 登录后发表评论（1–2000 字） |
| `DELETE /ideas/:id/comments/:commentId` | 作者或运营删除评论 |
| `POST /ideas` / `GET /ideas/:id` / `DELETE /ideas/:id` | 投稿 / 详情 / 制作前本人撤稿 |
| `GET /ideas/:id/updates` | 团队处理记录；剧透展开使用 `?reveal=true` |
| `PUT /ideas/:id/like` / `/rating` / `/permissions` | 支持 / 评分 / 本人授权署名 |
| `GET /operator/ideas` | 运营筛选队列，含被隐藏内容 |
| `POST /operator/ideas/:id/updates` | 运营回复、状态、版本和链接 |
| `PUT /operator/ideas/:id/moderation` | 运营隐藏 / 恢复，必填内部原因 |

原本地 `/auth/register`、`/auth/login`、`/auth/password` 已移除。迁移 003 撤销旧本地会话、删除旧密码摘要，保留投稿；旧本地身份不会被未经确认地合并到新的 Authing 账号。

## 验证与上线

```bash
npm run validate
TEST_DATABASE_URL=postgresql://platform:platform_local@127.0.0.1:55432/platform npm run test:database
```

测试只创建并清理自己的随机 schema。协议测试使用测试目录里的回环身份服务，真实签名与验签、授权码交换和防重放均执行，不访问 Authing，也不产生正式账号。

[项目需求与后续边界](docs/project-requirements.md) · [Authing 配置指南](docs/authing-setup.md) · [独立域名部署](docs/domain-deployment.md) · [当前实现记录](docs/progress.md)
