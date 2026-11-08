# 7:55 移动端适配与开发

当前移动端入口是 `godot_native/` 的 Godot 4.7.1 网页导出。仓库已有 Web、Linux 和 Windows 导出预设。Android APK、Google Play AAB 和 iOS Xcode 工程按下面的步骤另建预设和验收。

## 画面与触控

| 界面 | 方向 | 自适应规则 |
| --- | --- | --- |
| 游戏内手机、馆藏检索、CC98 | 竖向画面 | 保持 `430 × 860` 逻辑尺寸，按安全区等比缩放。横持时画面直接切为竖向构图，竖起手机后回到正向显示。 |
| 地图和横向场景 | 横屏 | 保持 `960 × 540` 地图视口并按安全区缩放。馆内自由探索时，宽屏且可用高度充足，镜头会等比拉远；短横屏保持常规视角。触屏浏览器会尝试使用进入场景的手势进入全屏。 |

场景方向由当前可见界面决定。触屏网页通过 Godot 视口变换直接切换绘制方向，触点沿同一变换回到逻辑坐标。浏览器允许时，`scene_orientation.js` 使用进入场景的手势请求全屏和横向锁定。网页安全区以 CSS 像素读取并映射到实际方向，原生以 Godot 映射后的显示安全区为准。 [Godot 视口变换](https://docs.godotengine.org/en/stable/classes/class_viewport.html#class-viewport-property-global-canvas-transform) · [Godot 显示安全区](https://docs.godotengine.org/en/stable/classes/class_displayserver.html#class-displayserver-method-get-display-safe-area) · [Fullscreen API](https://developer.mozilla.org/en-US/docs/Web/API/Fullscreen_API)

原生包接方向切换时，把请求放在手机和场景切换处。手机用 `DisplayServer.SCREEN_PORTRAIT`，场景用 `DisplayServer.SCREEN_SENSOR_LANDSCAPE`。收到窗口尺寸变化后重排安全区和触控坐标。iOS 要将项目的 `Display > Window > Handheld > Orientation` 设为 `Sensor`，并在 Xcode 检查支持的方向。启动默认方向和首次进入场景需要分别在真机确认。 [Godot 原生方向接口](https://docs.godotengine.org/en/stable/classes/class_displayserver.html#class-displayserver-method-screen-set-orientation)

## Android 与 iPhone 网页调试

从仓库根目录构建并启动本地预览，`GODOT_BIN` 指向已安装的 Godot 4.7.1。初次构建安装同版导出模板，确保 `ffmpeg` 和 `ffprobe` 可执行。

```sh
GODOT_BIN=/path/to/Godot node godot_native/tools/build_web.mjs \
  --output=godot_native/exports/mobile-review
node godot_native/tools/serve_web.mjs \
  --directory=godot_native/exports/mobile-review --port=8641
```

- **Android**。开启 USB 调试，运行 `adb devices -l` 和 `adb reverse tcp:8641 tcp:8641`，手机浏览器打开 `http://127.0.0.1:8641/`。Chrome 可在电脑端打开 `chrome://inspect/#devices` 检查页面。vivo 等系统浏览器单独测真实点击、全屏和系统返回。 [Chrome Android 远程调试](https://developer.chrome.com/docs/devtools/remote-debugging)
- **iPhone / iPad**。用同一局域网，将预览服务的 `--host` 设为开发机的局域网地址，手机 Safari 打开该地址和端口。启用 iPhone 的 Web Inspector 后，在 Mac Safari 的「开发」菜单选中已配对设备和页面。最终复测使用发布环境的 HTTPS 链接。 [Safari 真机检查](https://developer.apple.com/documentation/safari-developer-tools/inspect-apps-and-devices)

每个平台记录设备型号、系统和浏览器版本、构建摘要、方向以及 CSS 视口。用独立测试存档检查这条链路：竖屏开局、横屏进馆、门禁确认、点地绕障、椅侧入座、点显示器切回竖屏、再进馆、抽书、切后台返回、保存并重载。比较短横屏和宽横屏的取景和触点，确认刘海或灵动岛、手势栏和软键盘都不会遮住操作。Android 与 iOS 的浏览器结果分别记录，模拟器结果单列。 [Web 发布与验收](GODOT_WEB_RELEASE.md)

## 原生 Android

1. 安装 Godot 4.7.1 与同版导出模板、OpenJDK 17 和 Android Studio SDK。按 Godot 导出文档安装该版本需要的 SDK 组件。在 Godot 的 Editor Settings 填 `Java SDK Path` 与 `Android SDK Path`。 [Godot Android 导出](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
2. 打开 `godot_native/project.godot`，在 Project → Export 添加 Android 预设，配置包名、版本号和导出目录。用 debug APK 跑 `adb install -r /path/to/7-55-debug.apk`，在设备上检查竖横切换、读写存档、音视频和系统返回。
3. 用正式包名和签名配置制作 AAB，先用 Google Play 内测轨道验收升级和存档。上传密钥由发布配置管理。 [Android 签名与 AAB](https://developer.android.com/studio/publish/app-signing)

## 原生 iOS

1. 在 macOS 安装 Xcode、Godot 4.7.1 和同版导出模板。在 Project → Export 添加 iOS 预设，填 Apple Team ID 和唯一 Bundle ID，导出到空目录。 [Godot iOS 导出](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)
2. 在 Xcode 打开导出的工程，选择签名 Team，配对 iPhone 并启用 Developer Mode。用 Xcode Run 安装开发版，确认进入地图、回到竖屏手机、软键盘、音频中断和存档重载。 [Apple 真机开发模式](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)
3. 通过 Xcode Archive 生成待分发构建，先跑 TestFlight 内测，再评估 App Store 交付。单独核对原生包里的资源、加载和持久化行为。网页分包、浏览器存储和 Safari 调试记录属于网页验收。
