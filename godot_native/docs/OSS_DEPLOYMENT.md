# 《7:55》OSS 持续部署

GitHub Pages 发布成功后，main 的工作流使用同一次运行生成的公开前两章产物。文件校验通过后上传到独立版本目录，外网读取校验通过后才写入 Bucket 根目录的 `index.html`。这个入口跳到新版本首页并保留链接参数。玩家使用 [755.zjuxlab.com](https://755.zjuxlab.com/)。

## OSS 一次性配置

- 游戏 Bucket 为 `proj-flc-gaming`，地域为 `cn-hangzhou`。游戏域名 `755.zjuxlab.com` 直接绑定 Bucket 并托管匹配的 HTTPS 证书。SDK 通过该域名上传并校验文件。
- Bucket 的静态网站默认首页设为 `index.html`。仅允许访客读取公开入口 `index.html` 和 `releases/*`，操作为 `oss:GetObject`。部署身份还需上述对象的 `oss:PutObject`。正式域名根路径和版本文件需要允许匿名访问。

## GitHub 一次性配置

在仓库 Settings → Secrets and variables → Actions 中设置以下任一认证方式。凭证应指向只拥有游戏发布所需权限的部署身份。

| 认证方式 | 需要填写 |
|---|---|
| OIDC（默认） | Variables 中添加 `ALIYUN_OIDC_PROVIDER_ARN` 和 `ALIYUN_OSS_ROLE_ARN`。RAM 角色信任 GitHub OIDC，限制到本仓库的 main 分支。GitHub 默认的不可变主体为 `repo:zhu607705-coder@225790103/7-55@1303827917:ref:refs/heads/main`，受众为 `sts.aliyuncs.com`。 |
| AccessKey | Variables 中把 `OSS_AUTH_METHOD` 设为 `access-key`。在 Secrets 中添加 `ALIYUN_OSS_ACCESS_KEY_ID` 和 `ALIYUN_OSS_ACCESS_KEY_SECRET`。 |

最后在 Variables 中设置 `OSS_DEPLOY_ENABLED=true`，再手动从 main 运行一次 **Deploy Godot Web to GitHub Pages**。之后 main 的公开版通过验收时自动上传。同一个版本的文件保留在独立目录中。回退时，把根目录 `index.html` 的目标改到仍可访问的旧版入口，并保留根文件的 `Cache-Control: no-store`。如需暂停自动发布，把 `OSS_DEPLOY_ENABLED` 改为 `false`。

本地可运行 `node --test godot_native/tests/publish_oss.test.mjs` 检查包校验、压缩传输和发布入口的切换顺序。
