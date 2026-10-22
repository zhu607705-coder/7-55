# 昌平完整地图正式入口

来自已验收独立 `buct-changping-student-map`，以 #125 的精确远端提交 `88a4f2c45a70d3a7d052fd6f66bc30c27bba1d47` 为父基线。该入口依赖尚未合并的 #124/#125；本次不包含室内。

## 本轮范围

- 正式启动选择页：继续《7:55》、朝阳、海淀、昌平四个独立入口
- 昌平原图950×1656完整呈现，81个既有铺装区域、41个路线点和南门/第一教学楼/图书馆3个POI保持原坐标
- 共享 `buct_shared/student` 真透明四向学生，不再复制人物素材。显示18源像素、脚圆半径3、步速88、步幅46.8不变
- 地图仍含53个旧UV登记组（49个画面校内建筑/构筑物分组＋4个归属未核外景）；不称53栋真实独立建筑。本入口新增真实RGBA建筑数0
- WASD/方向键与点击或触摸步道寻路；桌面不增方向按钮。信息卡可滚动，全图完整等比容纳，地标按钮避开学生
- Esc依次关闭信息/全图，再返回入口。返回幂等，专属 `buct_changping_*` 输入只清理自建动作。失焦释放按键、路径与导览
- 不访问故事State或存档。退出释放地图、学生、所有登记对象、地影、树冠和补底视口；不修改全局窗口比例

## 准确的道路边界

“完整地图”指完整950×1656画面已进入正式入口。当前81区域/41点只覆盖原南門—第一教学楼—图书馆主线，不能代表所有画面可见道路均可行走。本PR不扩大道路，以免把地理/通行变化混入入口回归。

下一阶段按实图逐区核验后开放公共人行路，优先南门/一教前广场支路、一教至柳湖两岸合法步道、图书馆外广场接续；随后核验西侧宿舍与实验楼之间可见道路、两处运动场外围和北侧校园路。水体、屋顶、封闭中庭、围栏及未建规划地块不因“看起来有路”而开放。每区需要原图依据、脚圆净空、真实碰撞与连接回归；当前不承诺这些区域已可达。

## 测试与来源

`provenance.json`保存原图、原图层数据、原路网数据逐字节SHA。`tests/verify_buct_changping_source.mjs`只作静态来源与入口检查；实际入口、学生与释放检查由集成测试执行。地图中旧qa.manual_action仍保留原来源字段，正式动作命名空间由场景安装并由入口测试直接验证。

测试必须使用workspace内TMP/TEMP/TMPDIR和XDG data/config/cache/state，隔离测试存档。轻量校园stage使用 `BUCT_ENTRY_CAMPUS_ONLY=1` 会显式跳过故事画面恢复，只检查真实State数据与存档字节隔离；完整故事恢复须在完整依赖工程/CI中另外通过。


## Default Wenli high-detail outdoor region

The Changping entry now enables the bounded Wenli ground/canopy replacement by default. Source ROI `[630,615,240,240]` covers 3.66% of the original map; full-detail core is 216×216. Genuine generated masters are 1254×1254 and the runtime texture is 1200×1200, not whole-campus 4K. Nine original foreground alpha masks, student, roads and physics remain unchanged. The old surrounding map remains visible, with a discernible clarity transition. Missing/invalid resources atomically restore the #138 visuals. See [scope, provenance, limits and validation](../../../docs/BUCT_CHANGPING_WENLI_HD_REGION.md).
