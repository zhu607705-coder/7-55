# 《7:55》OSS 持续部署

GitHub Pages 发布成功后，main 的工作流使用同一次运行生成的公开前两章产物。文件校验通过后上传到独立版本目录，外网读取校验通过后才写入 Bucket 根目录的 `index.html`。根目录直接提供游戏首页，游戏资源仍从对应版本目录加载，地址栏保留根域名和链接参数。玩家使用 [755.zjuxlab.com](https://755.zjuxlab.com/)。

## OSS 一次性配置

- 游戏 Bucket 为 `proj-flc-gaming`，地域为 `cn-hangzhou`。游戏域名 `755.zjuxlab.com` 直接绑定 Bucket 并托管匹配的 HTTPS 证书。SDK 通过该域名上传并校验文件。
- Bucket 的静态网站默认首页设为 `index.html`。仅允许访客读取公开入口 `index.html` 和 `releases/*`，操作为 `oss:GetObject`。部署身份还需上述对象的 `oss:PutObject`。正式域名根路径和版本文件需要允许匿名访问。

## GitHub 一次性配置

在仓库 Settings → Secrets and variables → Actions 中设置以下任一认证方式。凭证应指向只拥有游戏发布所需权限的部署身份。

| 认证方式 | 需要填写 |
|---|---|
| OIDC（默认） | Variables 中添加 `ALIYUN_OIDC_PROVIDER_ARN` 和 `ALIYUN_OSS_ROLE_ARN`。RAM 角色信任 GitHub OIDC，限制到本仓库的 main 分支。GitHub 默认的不可变主体为 `repo:zhu607705-coder@225790103/7-55@1303827917:ref:refs/heads/main`，受众为 `sts.aliyuncs.com`。 |
| AccessKey | Variables 中把 `OSS_AUTH_METHOD` 设为 `access-key`。在 Secrets 中添加 `ALIYUN_OSS_ACCESS_KEY_ID` 和 `ALIYUN_OSS_ACCESS_KEY_SECRET`。 |

最后在 Variables 中设置 `OSS_DEPLOY_ENABLED=true`，再手动从 main 运行一次 **Deploy Godot Web to GitHub Pages**。之后 main 的公开版通过验收时自动上传。同一个版本的文件保留在独立目录中。回退时，取旧版本的 `index.html`，在 `<head>` 内插入指向该版本目录的 `<base href="/releases/旧版本目录/">`，再上传为根目录的 `index.html`，保留 `Cache-Control: no-store`。如需暂停自动发布，把 `OSS_DEPLOY_ENABLED` 改为 `false`。

上传、入口 HEAD 和外网读取遇到暂时性超时、连接重置或 HTTP 408/429/500/502/503/504 时，最多尝试三次，重试前分别等待 1 秒、2 秒。对象 PUT 每次最多等待 180 秒，始终使用同一个版本路径和相同内容。OSS 已收到文件但响应丢失时，重复 PUT 不会引入另一套资源身份。

HTTP 400/403、文件摘要不符或入口内容不符会立即终止。资源上传或验证未完成时不切换根入口；所有版本资源上传及既有外网校验通过后才发布首页。重试根入口 PUT 只重复同一份已验证页面。旧版本目录继续保留，供已打开的页面加载后续章节。

本地可运行 `node --test godot_native/tests/publish_oss.test.mjs` 检查包校验、压缩传输、瞬时故障重试和发布入口的切换顺序。
