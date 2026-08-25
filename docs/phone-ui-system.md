# 手机应用 UI 与交互合同

## 目标

手机端继续使用唯一 `430×860` 逻辑视口。`PhoneShell` 负责外框、缩放、全局状态栏、任务、道具、控制中心和 Toast。应用内部统一使用 `PhoneAppUi` 组件，应用只提供品牌颜色、内容和领域动作。

## 层级

```text
PhoneShell
├── StatusBar 40px
└── PhoneAppScaffold
    ├── PhoneAppHeader 64px
    ├── PhoneAppContent
    └── PhoneAppBottomNav 64px（可选）

PhoneActionSheet
└── 在当前手机场景上方显示，负责焦点循环、Escape 和焦点恢复
```

## 共享组件

| 组件 | 统一内容 | 应用可调整内容 |
|---|---|---|
| `PhoneAppScaffold` | 状态栏安全区、填充、滚动边界 | 页面背景和内容布局 |
| `PhoneAppHeader` | 返回命中区、标题层级、右侧槽位 | 品牌色、标题内容 |
| `PhoneAppBottomNav` | 选中态、按钮语义、锁定静态槽位 | 图标、标签、强调色 |
| `PhoneActionSheet` | 遮罩、Tab 循环、Escape、焦点恢复 | 表单和操作内容 |
| `PhoneListRow` | 行高、标题/说明/尾部层级、焦点反馈 | 行内图标和业务状态 |
| `PhoneSegmentedControl` | 单选语义、按压态、焦点态 | 选项内容 |
| `PhoneAppFeedback` | `aria-live`、信息/成功/警告/错误层级 | 反馈文本 |
| `PhoneStateView` | 加载、空、错误、离线页面结构 | 图标、说明和动作 |

## 主题变量

应用可以在根元素覆盖下列变量：

```css
--phone-app-bg
--phone-app-surface
--phone-app-ink
--phone-app-muted
--phone-app-line
--phone-app-action
--phone-app-accent
--phone-app-danger
--phone-app-shadow
```

应用不得修改：

- `--phone-width`
- `--phone-height`
- `--phone-scale`
- `--phone-statusbar-h`
- `--phone-nav-hit`

## 反馈规则

| 场景 | 组件或入口 |
|---|---|
| 短暂成功、普通系统提示 | `ToastLayer` / `kit.flags.toast` |
| 表单校验、筛选结果、区块内失败 | `PhoneAppFeedback` |
| 页面离线、空、错误、加载 | `PhoneStateView` |
| 选项列表 | `PhoneActionSheet` |
| 会推进控制器状态的确认 | 领域页面确认弹层；提交仍调用 Controller |

每个可操作控件必须产生可见结果。禁用、锁定和业务拒绝需要使用不同语义：

- `disabled`：控件存在，但当前条件不足。
- 锁定功能：保持图标、名称和位置，输出静态元素，不生成按钮、焦点或 Toast。
- 业务拒绝：控件可操作，由控制器返回原因，页面显示下一步。

## 状态边界

- `FeatureAccess` 继续决定功能是否开放。
- `GameState`、Controller 和 `SaveStore` 继续决定剧情、物品、钱包、任务和正式业务结果。
- 页面筛选、卡片展开和普通预览使用组件局部状态。
- 会话草稿可以使用带版本号的 `sessionStorage` 键，并明确显示“本机草稿、尚未正式提交”。
- UI 不直接写剧情事实、物品、钱包或控制器阶段。

## 当前迁移

- 浙大钉：页面头、底栏、操作面板、信息列表和反馈接入共享组件；应用目录使用稳定英文 ID。
- 照片：第三章半相簿接入共享页面骨架和标题栏；旧照筛选接入共享分段控件。
- 其他手机应用保留现状，后续按设置、天气、微信、CC98、时钟的顺序迁移。

迁移一个应用时需要验证 `430×860`、`390×844`、键盘、触控、返回链、锁定语义、弹层焦点和单文件运行。
