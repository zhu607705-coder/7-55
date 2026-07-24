# Standalone demos

- 每个入口只作为生产运行时的薄宿主；地图、碰撞、相机、人物和交互逻辑继续从正式 `src/scenes/rpg/` 导入。
- 演示状态必须在内存中创建，不能读取或写入正式 `SaveStore`。
- 每个入口有自己的根 HTML 文件和 `build:<demo>` / `verify:<demo>` 脚本，产物进入被忽略的 `demo/`。
- 新增独立演示时，保留 `window.render_game_to_text()`，并在修改后运行对应单文件构建与浏览器验收。
