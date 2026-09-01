import { createInitialGameState } from "../core/GameState";
import type {
  GameState,
  GameStore,
  LibraryFinalsPhase,
  SceneId,
  ZjudingPage
} from "../core/types";
import {
  DEVELOPER_ACTIVE_KEY,
  DEVELOPER_BACKUP_KEY,
  DEVELOPER_CANTEEN_DEFENSE_START_KEY,
  DEVELOPER_CHAPTER4_PROLOGUE_OFFSET_KEY,
  DEVELOPER_CHAPTER4_TASK_CARD_CONFIRMED_KEY,
  DEVELOPER_QIZHEN_RHYTHM_SPAWN_KEY,
  DEVELOPER_SOURCE_KEY
} from "../core/StorageKeys";
import { CHAPTER_FOUR_ELEVATOR } from "./ChapterFourElevatorModel";
import {
  CHAPTER_FOUR_MAZE_CLUES,
  CHAPTER_FOUR_MAZE_TIMES
} from "./ChapterFourMazeProjection";
import { CHAPTER_FOUR_WECHAT_CLUES } from "./ChapterFourWechatModel";
import {
  ROOM204_PIECE_ORDER,
  ROOM204_SLOT_ORDER
} from "../scenes/rpg/ChapterFourRoom204Model";

const CHAPTER4_PROLOGUE_DEVELOPER_OFFSETS = {
  "c4-prologue": 0,
  "c4-prologue-lake-exit": 6708,
  "c4-prologue-arcade": 13667,
  "c4-prologue-entrance": 23542,
  "c4-prologue-lobby": 28750,
  "c4-prologue-closing": 33417,
  "c4-prologue-task-card": 43834
} as const;

type Chapter4PrologueDeveloperCheckpointId = keyof typeof CHAPTER4_PROLOGUE_DEVELOPER_OFFSETS;

export type DeveloperCheckpointId =
  | "c1-alarm" | "c1-home" | "c1-code-hunt" | "c1-dorm-card" | "c1-checkin" | "c1-narrator-block"
  | "c2-friend" | "c2-system" | "c2-inventory" | "c2-system-return"
  | "c2-name" | "c2-exercise" | "c2-triangle" | "c2-weather-water"
  | "c2-mentor-line" | "c2-arrow-assembly" | "c2-balance-shift"
  | "c2-cc98-login" | "c2-gamepad-market" | "c2-manual-movement" | "c2-reservation-briefing"
  | "c2-seat-reservation" | "c2-dorm-exit"
  | "c2-library-gate" | "c2-entrance-record" | "c2-seat-arrival"
  | "c2-occupancy-note" | "c2-catalog" | "c2-archived-rule"
  | "c2-photo-report" | "c2-nonperson-stamp" | "c2-seat-receipt"
  | "c2-tiyi-proof" | "c2-cc98-upload" | "c2-bd-rise"
  | "c2-recovery-form" | "c2-pass-generate" | "c2-pass-apply"
  | "c2-seat-sit" | "c2-seat-dialogue" | "c2-chapter-exit"
  | "campus-canteen-entry"
  | "canteen-hunt" | "c3-canteen-entry" | "c3-canteen-drinks" | "c3-canteen-menu" | "c3-canteen-pickup"
  | "c3-canteen-block" | "c3-canteen-block-2" | "c3-canteen-block-3"
  | "c3-canteen-bike" | "c3-canteen-chase" | "c3-canteen-theater"
  | "c3-theater-entry" | "c3-theater-ticket-request" | "c3-theater-ticket-accepted"
  | "c3-theater-ticket-first-wave" | "c3-theater-ticket-first-wave-won"
  | "c3-theater-ticket-delivered" | "c3-theater-code" | "c3-theater-program"
  | "c3-theater-prop" | "c3-theater-spotlight" | "c3-theater-spotlight-round" | "c3-theater-complete"
  | "c3-qizhen-transition" | "c3-qizhen-location" | "c3-qizhen-map" | "c3-qizhen-gate"
  | "c3-qizhen-dock" | "c3-qizhen-rain-hold" | "c3-qizhen-rescue-dorm" | "c3-qizhen-hair-dryer"
  | "c3-qizhen-weather-control" | "c3-qizhen-overcast"
  | "c3-qizhen-boarding" | "c3-qizhen-open-water"
  | "c3-qizhen-rhythm-key" | "c3-qizhen-rhythm-net" | "c3-qizhen-rhythm-fish" | "c3-qizhen-rhythm-paper"
  | "c3-qizhen-tool-chain" | "c3-qizhen-swan" | "c3-qizhen-paper"
  | "c3-qizhen-chase" | "c3-qizhen-complete"
  | "c3-interlude-reboot" | "c3-interlude-journal" | "c3-interlude-photos"
  | "c3-interlude-voice" | "c3-interlude-network" | "c3-interlude-timeline" | "c3-interlude-destination" | "c3-interlude-replay"
  | "c4-755-opening" | "c4-755-hall-clock" | "c4-755-bakery-1225"
  | "c4-755-classrooms-1850" | "c4-755-elevator-history" | "c4-755-room204-1850" | "c4-755-a2-field-records" | "c4-755-maintenance-2245"
  | "c4-755-blackout-0754" | "c4-755-chase" | "c4-755-final-minute"
  | "c4-755-return-clock" | "c4-755-checkin" | "c4-755-closure"
  | Chapter4PrologueDeveloperCheckpointId
  | "c4-prologue-done" | "c4-arrival" | "c4-airflow" | "c4-main-elevator"
  | "c4-wechat-notice" | "c4-wechat-elevator-audio" | "c4-elevator-aligned"
  | "c4-a2-arrival" | "c4-wechat-student-route" | "c4-a2-schedule-observed"
  | "c4-a3-wayfinding" | "c4-wechat-wayfinding" | "c4-a2-return-window"
  | "c4-stair-echo" | "c4-clock-intro" | "c4-clock-coarse" | "c4-clock-precision" | "c4-clock-release";

type LegacyDeveloperCheckpointId =
  | "c2-movement" | "c2-seat-022" | "c2-evidence"
  | "c2-top-ten" | "c2-recovery" | "c2-pass"
  | "c3-intro" | "c3-congestion" | "c3-sprint" | "c3-result"
  | "c3-qizhen-reflection" | "c3-qizhen-signs" | "c3-qizhen-decoy"
  | "c3-qizhen-mist" | "c3-qizhen-release" | "c4-clock-calibration"
  | "c4-755-light-grid" | "c4-755-complete"
  | "c4-prologue-done" | "c4-arrival" | "c4-airflow" | "c4-main-elevator"
  | "c4-wechat-notice" | "c4-wechat-elevator-audio" | "c4-elevator-aligned"
  | "c4-a2-arrival" | "c4-wechat-student-route" | "c4-a2-schedule-observed"
  | "c4-a3-wayfinding" | "c4-wechat-wayfinding" | "c4-a2-return-window"
  | "c4-stair-echo" | "c4-clock-intro" | "c4-clock-coarse"
  | "c4-clock-precision" | "c4-clock-release";

type DeveloperCheckpointRequestId = DeveloperCheckpointId | LegacyDeveloperCheckpointId;
type LibraryDeveloperCheckpointId = Extract<DeveloperCheckpointId, `c2-${string}`>;
type CanteenDeveloperCheckpointId = Extract<DeveloperCheckpointId, "canteen-hunt" | `c3-canteen-${string}`>;
type TheaterDeveloperCheckpointId = Extract<DeveloperCheckpointId, `c3-theater-${string}`>;
type QizhenDeveloperCheckpointId = Extract<DeveloperCheckpointId, `c3-qizhen-${string}`>;
type ChapterThreeInterludeDeveloperCheckpointId = Extract<DeveloperCheckpointId, `c3-interlude-${string}`>;
type ChapterFour755DeveloperCheckpointId = Extract<DeveloperCheckpointId, `c4-755-${string}`>;
export interface DeveloperCheckpoint {
  id: DeveloperCheckpointId;
  chapter: "第一章" | "第二章" | "第三章" | "3.5章" | "第四章";
  label: string;
  detail: string;
}

export const DEVELOPER_CHECKPOINTS: DeveloperCheckpoint[] = [
  { id: "c1-alarm", chapter: "第一章", label: "闹钟开始", detail: "07:55 闹钟振动" },
  { id: "c1-home", chapter: "第一章", label: "手机主页", detail: "散码前" },
  { id: "c1-code-hunt", chapter: "第一章", label: "签到码散落", detail: "四条线索可探索" },
  { id: "c1-dorm-card", chapter: "第一章", label: "签到页数字", detail: "本周缺勤次数中的 0" },
  { id: "c1-checkin", chapter: "第一章", label: "签到输入", detail: "0798 已集齐" },
  { id: "c1-narrator-block", chapter: "第一章", label: "错误框拦截", detail: "挡住三次后按住旁白" },
  { id: "c2-friend", chapter: "第二章", label: "朋友追问", detail: "回复签到失败" },
  { id: "c2-system", chapter: "第二章", label: "系统红圈", detail: "浙大钉名字旁" },
  { id: "c2-inventory", chapter: "第二章", label: "取得校园卡", detail: "寝室右侧个人书桌" },
  { id: "c2-system-return", chapter: "第二章", label: "校园卡首显", detail: "取得后自动放大" },
  { id: "c2-name", chapter: "第二章", label: "人物命名", detail: "黄页填写身份" },
  { id: "c2-exercise", chapter: "第二章", label: "启动锻炼", detail: "体艺开始课外锻炼" },
  { id: "c2-triangle", chapter: "第二章", label: "取得三角形", detail: "主页任务推送" },
  { id: "c2-weather-water", chapter: "第二章", label: "取得天气水滴", detail: "天气页面" },
  { id: "c2-mentor-line", chapter: "第二章", label: "释放导师竖线", detail: "水滴拖到导师头像" },
  { id: "c2-arrow-assembly", chapter: "第二章", label: "合成右移箭头", detail: "三角形加竖线" },
  { id: "c2-balance-shift", chapter: "第二章", label: "移动余额小数点", detail: "0.06 变为 6.00" },
  { id: "c2-cc98-login", chapter: "第二章", label: "CC98 首次认证", detail: "校园卡学号与象征密码" },
  { id: "c2-gamepad-market", chapter: "第二章", label: "购买游戏手柄", detail: "CC98 二手交易" },
  { id: "c2-manual-movement", chapter: "第二章", label: "首次手动移动", detail: "寝室方向控制" },
  { id: "c2-reservation-briefing", chapter: "第二章", label: "系统预约说明", detail: "首次移动后的三句说明" },
  { id: "c2-seat-reservation", chapter: "第二章", label: "预约 022", detail: "基础馆二层南区" },
  { id: "c2-dorm-exit", chapter: "第二章", label: "离开寝室", detail: "出口已开放" },
  { id: "c2-library-gate", chapter: "第二章", label: "图书馆门口", detail: "校园地图入口" },
  { id: "c2-entrance-record", chapter: "第二章", label: "入馆记录", detail: "点击小屏核对两条时间" },
  { id: "c2-seat-arrival", chapter: "第二章", label: "到达 022", detail: "检查占座书包" },
  { id: "c2-occupancy-note", chapter: "第二章", label: "占座纸条", detail: "从书包取得线索" },
  { id: "c2-catalog", chapter: "第二章", label: "馆藏检索", detail: "搜索正确书籍" },
  { id: "c2-archived-rule", chapter: "第二章", label: "旧版规则", detail: "索书号拖到书架" },
  { id: "c2-photo-report", chapter: "第二章", label: "照片识别报告", detail: "调暗照片并生成报告" },
  { id: "c2-nonperson-stamp", chapter: "第二章", label: "非本人证明", detail: "报告交给前台工作人员核验盖章" },
  { id: "c2-seat-receipt", chapter: "第二章", label: "022 座位小票", detail: "箭头拖到座位缝隙" },
  { id: "c2-tiyi-proof", chapter: "第二章", label: "本人来过证明", detail: "填写 7 / 47 / 3" },
  { id: "c2-cc98-upload", chapter: "第二章", label: "上传四项证据", detail: "CC98 调查帖" },
  { id: "c2-bd-rise", chapter: "第二章", label: "BD 四位口令", detail: "数字回复推到排名 01" },
  { id: "c2-recovery-form", chapter: "第二章", label: "打开恢复申请", detail: "浙大钉材料页" },
  { id: "c2-pass-generate", chapter: "第二章", label: "生成 PASS", detail: "三项材料已提交" },
  { id: "c2-pass-apply", chapter: "第二章", label: "使用 PASS", detail: "拖到 022 书包" },
  { id: "c2-seat-sit", chapter: "第二章", label: "坐到 022", detail: "书包已清退" },
  { id: "c2-seat-dialogue", chapter: "第二章", label: "022 对话", detail: "联系异常意识" },
  { id: "c2-chapter-exit", chapter: "第二章", label: "追往东区大食堂", detail: "022 对话后沿校园脚印继续追踪" },
  { id: "campus-canteen-entry", chapter: "第二章", label: "食堂门口", detail: "普通校园探索入口" },
  { id: "canteen-hunt", chapter: "第三章", label: "东区大食堂追踪", detail: "从校园出生点沿脚印前往东区大食堂" },
  { id: "c3-canteen-entry", chapter: "第三章", label: "进入食堂", detail: "寻找三只残影餐盘" },
  { id: "c3-canteen-drinks", chapter: "第三章", label: "调配今日新品", detail: "三种饮料与插队合法化" },
  { id: "c3-canteen-menu", chapter: "第三章", label: "点餐机", detail: "浅色与深色菜单" },
  { id: "c3-canteen-pickup", chapter: "第三章", label: "0755 取餐", detail: "按暗号选择窗口" },
  { id: "c3-canteen-block", chapter: "第三章", label: "守出口·开始", detail: "完整 60 秒实时拦截" },
  { id: "c3-canteen-block-2", chapter: "第三章", label: "守出口·中段", detail: "剩余 30 秒，纸条已经加速" },
  { id: "c3-canteen-block-3", chapter: "第三章", label: "守出口·末段", detail: "剩余 10 秒，折返时自动闪路线" },
  { id: "c3-canteen-bike", chapter: "第三章", label: "解锁自行车", detail: "深色读码、擦锁并支付 2 元" },
  { id: "c3-canteen-chase", chapter: "第三章", label: "755 米 3D 追逐", detail: "A / D 三车道骑行" },
  { id: "c3-canteen-theater", chapter: "第三章", label: "抵达剧院", detail: "纸条钻进剧院" },
  { id: "c3-theater-entry", chapter: "第三章", label: "剧院检票", detail: "海报栏与取票机" },
  { id: "c3-theater-ticket-request", chapter: "第三章", label: "CC98 帮抢委托", detail: "打开帖子，等待玩家接单" },
  { id: "c3-theater-ticket-accepted", chapter: "第三章", label: "帮抢已接单", detail: "先在剧场确认 08:32 放票时间" },
  { id: "c3-theater-ticket-first-wave", chapter: "第三章", label: "第一波网速过慢", detail: "手机票务页等待第二波" },
  { id: "c3-theater-ticket-first-wave-won", chapter: "第三章", label: "第一波流量中票", detail: "手机已抢中，实体票根尚未打印" },
  { id: "c3-theater-ticket-delivered", chapter: "第三章", label: "第二波抢票成功", detail: "手机显示 0832 取票码" },
  { id: "c3-theater-code", chapter: "第三章", label: "剧场打印票根 B", detail: "手机已抢中，在取票机输入 0832" },
  { id: "c3-theater-program", chapter: "第三章", label: "节目顺序", detail: "追光、开场、谢幕" },
  { id: "c3-theater-prop", chapter: "第三章", label: "后台道具箱", detail: "票根验证与荧光粉刷" },
  { id: "c3-theater-spotlight", chapter: "第三章", label: "追光围捕", detail: "三轮路径预判" },
  { id: "c3-theater-spotlight-round", chapter: "第三章", label: "追光第一轮", detail: "观察路径终点并选择光圈" },
  { id: "c3-theater-complete", chapter: "第三章", label: "替身揭晓", detail: "假纸条与湿节目单" },
  { id: "c3-qizhen-transition", chapter: "第三章", label: "剧场到湖畔过场", detail: "湿纸、水迹和环湖道路衔接" },
  { id: "c3-qizhen-location", chapter: "第三章", label: "寻找启真湖", detail: "CC98、馆藏与微信三条线索" },
  { id: "c3-qizhen-map", chapter: "第三章", label: "地图猜谜", detail: "桥边、倒影与湖自由组合" },
  { id: "c3-qizhen-gate", chapter: "第三章", label: "启真湖入口", detail: "从校园大地图步行进入" },
  { id: "c3-qizhen-dock", chapter: "第三章", label: "小码头取装备", detail: "确认皮划艇并寻找两件临时划水工具" },
  { id: "c3-qizhen-rain-hold", chapter: "第三章", label: "雨天安全禁令", detail: "器材齐全，码头仍在下雨并禁止登船" },
  { id: "c3-qizhen-rescue-dorm", chapter: "第三章", label: "落水后回寝室", detail: "值班老师救援完成，寻找可用设备" },
  { id: "c3-qizhen-hair-dryer", chapter: "第三章", label: "取得吹风机", detail: "书桌道具已拾取，等待打开天气页" },
  { id: "c3-qizhen-weather-control", chapter: "第三章", label: "风向校准", detail: "使用寝室吹风机调整三层云带" },
  { id: "c3-qizhen-overcast", chapter: "第三章", label: "返回码头", detail: "湖区状态已更新，回码头确认" },
  { id: "c3-qizhen-boarding", chapter: "第三章", label: "上船平衡", detail: "交替左右桨与翻船安全恢复" },
  { id: "c3-qizhen-open-water", chapter: "第三章", label: "大湖倒影", detail: "深色记录、浅色取钓竿和装饵" },
  { id: "c3-qizhen-rhythm-key", chapter: "第三章", label: "节奏钓鱼·钥匙", detail: "完整教学谱面，验收 A / S / D 与失败恢复" },
  { id: "c3-qizhen-rhythm-net", chapter: "第三章", label: "节奏钓鱼·网框", detail: "三小节短谱面，保留一次长按判定" },
  { id: "c3-qizhen-rhythm-fish", chapter: "第三章", label: "节奏钓鱼·小鲤鱼", detail: "一次咬钩判定，水纹收紧时按 S" },
  { id: "c3-qizhen-rhythm-paper", chapter: "第三章", label: "节奏钓鱼·纸条", detail: "最终八小节高难谱面与追逐前紧张节奏" },
  { id: "c3-qizhen-tool-chain", chapter: "第三章", label: "湖区工具链", detail: "道具 2 和 3 待组合" },
  { id: "c3-qizhen-swan", chapter: "第三章", label: "黑天鹅交换", detail: "小鲤鱼待投喂" },
  { id: "c3-qizhen-paper", chapter: "第三章", label: "磁性钓竿", detail: "道具 7 与钓竿待组合" },
  { id: "c3-qizhen-chase", chapter: "第三章", label: "直河道追逐", detail: "黑天鹅追逐并返回码头" },
  { id: "c3-qizhen-complete", chapter: "第三章", label: "启真湖结束", detail: "磁性扣损坏，纸条逃离" },
  { id: "c3-interlude-reboot", chapter: "3.5章", label: "恢复通知", detail: "手机检测到 7 分 55 秒未同步记录" },
  { id: "c3-interlude-journal", chapter: "3.5章", label: "CC98 收尾", detail: "保存 22:37:05 离湖回复" },
  { id: "c3-interlude-photos", chapter: "3.5章", label: "恢复照片", detail: "从七帧中恢复一次连续水平移动" },
  { id: "c3-interlude-voice", chapter: "3.5章", label: "录音筛选与排序", detail: "从七段恢复录音中筛选四段，再按声场变化排列" },
  { id: "c3-interlude-network", chapter: "3.5章", label: "网络证据", detail: "保存通知、路线截图并完成三维筛选" },
  { id: "c3-interlude-timeline", chapter: "3.5章", label: "旧时间排除", detail: "四项证据齐全，逐条排除三项旧时间" },
  { id: "c3-interlude-destination", chapter: "3.5章", label: "地点判断", detail: "自动时间线已汇总，从四个地点中判断最终去向" },
  { id: "c3-interlude-replay", chapter: "3.5章", label: "恢复回放", detail: "目的地已确认，等待播放恢复回放" },
  { id: "c4-prologue", chapter: "3.5章", label: "完整回放", detail: "从启真湖离开画面开始播放 H3" },
  { id: "c4-prologue-lake-exit", chapter: "3.5章", label: "离湖", detail: "从离湖段落继续 H3" },
  { id: "c4-prologue-arcade", chapter: "3.5章", label: "街机衔接", detail: "从中段衔接画面继续 H3" },
  { id: "c4-prologue-entrance", chapter: "3.5章", label: "教学楼外", detail: "从教学楼入口段继续 H3" },
  { id: "c4-prologue-lobby", chapter: "3.5章", label: "进入大厅", detail: "从大厅段继续 H3" },
  { id: "c4-prologue-closing", chapter: "3.5章", label: "收尾", detail: "从回放收尾段继续 H3" },
  { id: "c4-prologue-task-card", chapter: "3.5章", label: "任务卡", detail: "未确认时刷新仍停在任务卡，确认后恢复 A1" },
  { id: "c4-755-opening", chapter: "第四章", label: "入楼与纸条", detail: "22:45 开场，等纸条落到公告栏" },
  { id: "c4-755-hall-clock", chapter: "第四章", label: "大厅旧钟", detail: "外部时间已驳回，可第一次拉动旧钟" },
  { id: "c4-755-bakery-1225", chapter: "第四章", label: "12:25 面包坊", detail: "检查灯与传送带，取回时针" },
  { id: "c4-755-classrooms-1850", chapter: "第四章", label: "18:50 一楼教室校验", detail: "完成 104 黑板与 105 讲台的两项时间差校验" },
  { id: "c4-755-elevator-history", chapter: "第四章", label: "18:50 电梯历史校准", detail: "三条历史轨道已读取，从轿厢重放校准" },
  { id: "c4-755-room204-1850", chapter: "第四章", label: "18:50 三楼档案与错位楼梯", detail: "从荣誉墙、301 胶片与 302 影像对齐开始，再进入空间校准" },
  { id: "c4-755-a2-field-records", chapter: "第四章", label: "18:50 二楼三处现场记录", detail: "错位楼梯完成后，校准 201、203 与开放自习区的三个独立装置" },
  { id: "c4-755-maintenance-2245", chapter: "第四章", label: "22:45 维修链", detail: "检查保洁车车轮并修复旧钟" },
  { id: "c4-755-blackout-0754", chapter: "第四章", label: "07:54 停电与配电", detail: "最后一分钟被带走，从配电箱初始状态解出灯路" },
  { id: "c4-755-chase", chapter: "第四章", label: "最终追逐", detail: "灯阵已锁定，从 A1 经主楼梯前往 202" },
  { id: "c4-755-final-minute", chapter: "第四章", label: "最后一分钟", detail: "202 门已关，取回投影中的分钟碎片" },
  { id: "c4-755-return-clock", chapter: "第四章", label: "送回最后一分钟", detail: "从 A2 的 202 安全点出发，带齐三项材料返回旧钟" },
  { id: "c4-755-checkin", chapter: "第四章", label: "07:55 签到", detail: "时间已恢复，刷卡与纸条可任意顺序提交" },
  { id: "c4-755-closure", chapter: "第四章", label: "灿若星辰正式收束", detail: "双签到已完成，播放正式分层灯光动画并写入一次性完成回执" }
];

const CHECKPOINT_IDS = new Set(DEVELOPER_CHECKPOINTS.map((checkpoint) => checkpoint.id));
const LEGACY_CHECKPOINT_ALIASES: Record<LegacyDeveloperCheckpointId, DeveloperCheckpointId> = {
  "c2-movement": "c2-name",
  "c2-seat-022": "c2-seat-arrival",
  "c2-evidence": "c2-catalog",
  "c2-top-ten": "c2-cc98-upload",
  "c2-recovery": "c2-recovery-form",
  "c2-pass": "c2-pass-apply",
  "c3-intro": "canteen-hunt",
  "c3-congestion": "canteen-hunt",
  "c3-sprint": "canteen-hunt",
  "c3-result": "canteen-hunt",
  "c3-qizhen-reflection": "c3-qizhen-open-water",
  "c3-qizhen-signs": "c3-qizhen-tool-chain",
  "c3-qizhen-decoy": "c3-qizhen-tool-chain",
  "c3-qizhen-mist": "c3-qizhen-paper",
  "c3-qizhen-release": "c3-qizhen-chase",
  "c4-clock-calibration": "c4-755-opening",
  "c4-755-light-grid": "c4-755-blackout-0754",
  "c4-755-complete": "c4-755-closure",
  "c4-prologue-done": "c4-755-opening",
  "c4-arrival": "c4-755-opening",
  "c4-airflow": "c4-755-opening",
  "c4-main-elevator": "c4-755-hall-clock",
  "c4-wechat-notice": "c4-755-hall-clock",
  "c4-wechat-elevator-audio": "c4-755-hall-clock",
  "c4-elevator-aligned": "c4-755-hall-clock",
  "c4-a2-arrival": "c4-755-room204-1850",
  "c4-wechat-student-route": "c4-755-room204-1850",
  "c4-a2-schedule-observed": "c4-755-room204-1850",
  "c4-a3-wayfinding": "c4-755-room204-1850",
  "c4-wechat-wayfinding": "c4-755-room204-1850",
  "c4-a2-return-window": "c4-755-room204-1850",
  "c4-stair-echo": "c4-755-maintenance-2245",
  "c4-clock-intro": "c4-755-maintenance-2245",
  "c4-clock-coarse": "c4-755-maintenance-2245",
  "c4-clock-precision": "c4-755-maintenance-2245",
  "c4-clock-release": "c4-755-maintenance-2245"
};

const LIBRARY_CHECKPOINT_ORDER: readonly LibraryDeveloperCheckpointId[] = [
  "c2-library-gate",
  "c2-entrance-record",
  "c2-seat-arrival",
  "c2-occupancy-note",
  "c2-catalog",
  "c2-archived-rule",
  "c2-photo-report",
  "c2-nonperson-stamp",
  "c2-seat-receipt",
  "c2-tiyi-proof",
  "c2-cc98-upload",
  "c2-bd-rise",
  "c2-recovery-form",
  "c2-pass-generate",
  "c2-pass-apply",
  "c2-seat-sit",
  "c2-seat-dialogue",
  "c2-chapter-exit"
];

function resolveCheckpointId(value: string | null): DeveloperCheckpointId | null {
  if (!value) return null;
  if (CHECKPOINT_IDS.has(value as DeveloperCheckpointId)) return value as DeveloperCheckpointId;
  return LEGACY_CHECKPOINT_ALIASES[value as LegacyDeveloperCheckpointId] ?? null;
}

function isChapter4PrologueDeveloperCheckpoint(
  id: DeveloperCheckpointId
): id is Chapter4PrologueDeveloperCheckpointId {
  return Object.prototype.hasOwnProperty.call(CHAPTER4_PROLOGUE_DEVELOPER_OFFSETS, id);
}

function createActTwoBase(phase: GameState["actOne"]["phase"]): GameState {
  const state = createInitialGameState();
  const cardRecovered = !["friend_message_required", "system_required", "inventory_required"].includes(phase);
  return {
    ...state,
    currentScene: "phone_home",
    digits: { d1: "0", d2: "7", d3: "9", d4: "8" },
    items: { ...state.items, campusCard: cardRecovered },
    flags: {
      ...state.flags,
      codeScattered: true,
      cardZeroTaken: true,
      tiyiCountTaken: true,
      gearNineTaken: true,
      flowerEightTaken: true,
      checkinDone: true
    },
    actOne: {
      ...state.actOne,
      phase,
      inventoryRecovered: cardRecovered,
      dormHubUnlocked: !["friend_message_required", "system_required"].includes(phase)
    },
    ui: {
      ...state.ui,
      zjudingPage: "hub",
      seenChapterIntros: ["chapter_one", "chapter_two"]
    }
  };
}

function withMovementFacts(
  state: GameState,
  patch: Partial<GameState["actOne"]>,
  items: Partial<GameState["items"]> = {}
): GameState {
  const actOne = { ...state.actOne, ...patch };
  actOne.identityVerified = actOne.characterNamed;
  actOne.movementEnabled = actOne.characterNamed && actOne.exerciseStarted && actOne.controlsInstalled;
  return { ...state, actOne, items: { ...state.items, ...items } };
}

function createMovementCheckpointState(id: DeveloperCheckpointId): GameState {
  let state = withMovementFacts(createActTwoBase("movement_required"), {
    inventoryRecovered: true,
    characterPromptSeen: true
  }, { campusCard: true });

  if (id === "c2-name") {
    return { ...state, currentScene: "zjuding", ui: { ...state.ui, zjudingPage: "directory" } };
  }
  state = withMovementFacts(state, { characterNamed: true });
  if (id === "c2-exercise") return { ...state, currentScene: "tiyi", networkMode: "cellular" };
  state = withMovementFacts(state, { exerciseStarted: true });
  if (id === "c2-triangle") return state;
  state = withMovementFacts(state, { pushTriangleTapCount: 3, pushTriangleTaken: true }, { pushTriangle: true });
  if (id === "c2-weather-water") return { ...state, currentScene: "weather" };
  state = withMovementFacts(state, { weatherWaterTaken: true }, { weatherWater: true });
  if (id === "c2-mentor-line") {
    return {
      ...state,
      currentScene: "wechat",
      ui: { ...state.ui, inventoryOpen: true, selectedItem: "weatherWater" }
    };
  }
  state = withMovementFacts(state, { mentorLineReleased: true }, { weatherWater: false, mentorLine: true });
  if (id === "c2-arrow-assembly") {
    return { ...state, ui: { ...state.ui, inventoryOpen: true } };
  }
  state = withMovementFacts(state, { rightArrowAssembled: true }, {
    pushTriangle: false,
    mentorLine: false,
    rightArrow: true
  });
  if (id === "c2-balance-shift") {
    return {
      ...state,
      currentScene: "campus_card",
      ui: { ...state.ui, inventoryOpen: true, selectedItem: "rightArrow" }
    };
  }
  state = {
    ...withMovementFacts(state, { balanceShifted: true }),
    wallet: { ...state.wallet, campusCardCents: 600 }
  };
  if (id === "c2-cc98-login") return { ...state, currentScene: "cc98" };
  state = {
    ...state,
    actOne: {
      ...state.actOne,
      cc98Login: {
        ...state.actOne.cc98Login,
        studentIdDiscovered: true,
        revealedHintCount: 3,
        authenticated: true,
        lockUntilMs: null
      }
    }
  };
  if (id === "c2-gamepad-market") return { ...state, currentScene: "cc98" };
  state = {
    ...withMovementFacts(state, { gamepadPurchased: true }, { gamepad: true }),
    wallet: { ...state.wallet, campusCardCents: 0 }
  };
  if (id === "c2-manual-movement") {
    return { ...state, runtimeMode: "rpg", rpgScene: "dorm_hub", rpgCheckpoint: "dorm_spawn" };
  }
  state = withMovementFacts(state, {
    phase: "reservation_briefing_required",
    controlsInstalled: true,
    manualControlTested: true,
    canLeaveDorm: false
  }, { gamepad: false });
  if (id === "c2-reservation-briefing") {
    return { ...state, runtimeMode: "phone", currentScene: "zjuding", ui: { ...state.ui, zjudingPage: "hub" } };
  }
  state = withMovementFacts(state, { phase: "reservation_required" });
  if (id === "c2-seat-reservation") {
    return { ...state, runtimeMode: "phone", currentScene: "zjuding", ui: { ...state.ui, zjudingPage: "hub" } };
  }
  const reservedState = withMovementFacts(state, {
      phase: "movement_ready",
      canLeaveDorm: true
    });
  return {
    ...reservedState,
    runtimeMode: "rpg",
    rpgScene: "dorm_hub",
    rpgCheckpoint: "dorm_spawn",
    ui: {
      ...reservedState.ui,
      librarySelectedSeat: "022",
      librarySeatReserved: true
    }
  };
}

function createCompletedMovementState(): GameState {
  const state = withMovementFacts(createActTwoBase("complete"), {
    inventoryRecovered: true,
    characterPromptSeen: true,
    characterNamed: true,
    exerciseStarted: true,
    pushTriangleTapCount: 3,
    pushTriangleTaken: true,
    weatherWaterTaken: true,
    mentorLineReleased: true,
    rightArrowAssembled: true,
    balanceShifted: true,
    gamepadPurchased: true,
    cc98Login: {
      studentIdDiscovered: true,
      revealedHintCount: 3,
      failureCount: 0,
      authenticated: true,
      lockUntilMs: null
    },
    controlsInstalled: true,
    manualControlTested: true,
    canLeaveDorm: true
  }, {
    campusCard: true,
    rightArrow: true,
    gamepad: false
  });
  return {
    ...state,
    wallet: { ...state.wallet, campusCardCents: 0 },
    ui: {
      ...state.ui,
      librarySelectedSeat: "022",
      librarySeatReserved: true
    }
  };
}

function libraryPhaseFor(id: LibraryDeveloperCheckpointId): LibraryFinalsPhase {
  if (id === "c2-library-gate") return "library_route_unlocked";
  if (id === "c2-entrance-record" || id === "c2-seat-arrival") return "library_entered";
  if (id === "c2-occupancy-note") return "occupied_seat_found";
  if (["c2-catalog", "c2-archived-rule", "c2-photo-report", "c2-nonperson-stamp", "c2-seat-receipt", "c2-tiyi-proof", "c2-cc98-upload"].includes(id)) return "evidence_gathering";
  if (id === "c2-bd-rise") return "bd_briefing";
  if (id === "c2-recovery-form" || id === "c2-pass-generate") return "recovery_application";
  if (id === "c2-pass-apply") return "pass_ready";
  if (id === "c2-seat-sit") return "backpack_removed";
  if (id === "c2-seat-dialogue") return "seat_recovered";
  return "friend_contacted";
}

function createLibraryCheckpointState(id: LibraryDeveloperCheckpointId): GameState {
  let state = createCompletedMovementState();
  const stage = LIBRARY_CHECKPOINT_ORDER.indexOf(id);
  const reached = (checkpoint: LibraryDeveloperCheckpointId) => stage >= LIBRARY_CHECKPOINT_ORDER.indexOf(checkpoint);
  const puzzle = { ...state.ui.libraryFinalsPuzzle };
  const items = { ...state.items };

  if (reached("c2-entrance-record")) puzzle.libraryVisitedPoints = ["entrance"];
  if (reached("c2-seat-arrival")) {
    puzzle.entranceRecordRead = true;
    puzzle.libraryVisitedPoints = ["entrance", "seat_022"];
    puzzle.clueIds = ["arrival_7_minutes"];
  }
  if (reached("c2-occupancy-note")) puzzle.backpackInspected = true;
  if (reached("c2-catalog")) {
    puzzle.occupancyNoteCollected = true;
    puzzle.investigationOpened = true;
    puzzle.catalogUnlocked = true;
    puzzle.clueIds = [...puzzle.clueIds, "occupancy_note", "public_notice_floor_47"];
    items.occupancyNote = false;
  }
  if (reached("c2-archived-rule")) {
    puzzle.catalogSearchCompleted = true;
    puzzle.callNumberCollected = true;
    puzzle.clueIds = [...puzzle.clueIds, "call_number_755"];
    items.callNumber755 = true;
  }
  if (reached("c2-photo-report")) {
    puzzle.archivedRuleCollected = true;
    puzzle.archivedRuleRead = true;
    puzzle.archivedRuleBriefingSeen = true;
    puzzle.frontDeskProofRequestSeen = true;
    puzzle.libraryVisitedPoints = [...new Set([...puzzle.libraryVisitedPoints, "catalog_terminal", "shelf_755"])] as GameState["ui"]["libraryFinalsPuzzle"]["libraryVisitedPoints"];
    puzzle.clueIds = [...puzzle.clueIds, "archived_leave_rule"];
    items.callNumber755 = false;
    items.archivedLeaveRule = true;
  }
  if (reached("c2-nonperson-stamp")) {
    puzzle.photoCaptured = true;
    puzzle.photoDimmed = true;
    puzzle.itemReportGenerated = true;
    puzzle.lostFoundStage = "ready";
    items.itemRecognitionReport = true;
  }
  if (reached("c2-seat-receipt")) {
    puzzle.lostFoundStage = "stamped";
    puzzle.nonPersonProofStamped = true;
    items.itemRecognitionReport = false;
    items.bagNonPersonProof = true;
  }
  if (reached("c2-tiyi-proof")) {
    puzzle.seatReceiptCollected = true;
    items.rightArrow = false;
    items.seat022Receipt = true;
  }
  if (reached("c2-cc98-upload")) {
    puzzle.auditAttemptCount = 1;
    puzzle.auditArrivalMinutes = 7;
    puzzle.auditPublicNoticeFloor = 47;
    puzzle.auditProofCount = 3;
    puzzle.presenceProofCollected = true;
    items.libraryPresenceProof = true;
  }
  if (reached("c2-bd-rise")) {
    puzzle.cc98UploadedEvidenceIds = [
      "archived_leave_rule",
      "bag_non_person_proof",
      "seat_022_receipt",
      "library_presence_proof"
    ];
    items.archivedLeaveRule = false;
  }
  if (reached("c2-recovery-form")) {
    puzzle.preBdBriefingSeen = true;
    puzzle.bdCount = 3;
    puzzle.appliedBdReplyIds = ["reply-seat-ticket", "reply-visit-proof", "reply-bag-nonperson"];
    puzzle.bdSelectedPostIds = ["bd-rule-count", "bd-identity-zero", "bd-seat-tail", "bd-arrival-minutes"];
    puzzle.bdPasswordAttemptCount = 1;
  }
  if (reached("c2-pass-generate")) {
    puzzle.recoverySubmittedEvidenceIds = ["bag_non_person_proof", "seat_022_receipt", "library_presence_proof"];
    items.bagNonPersonProof = false;
    items.seat022Receipt = false;
    items.libraryPresenceProof = false;
  }
  if (reached("c2-pass-apply")) {
    puzzle.evictionPassGenerated = true;
    puzzle.passBriefingSeen = true;
    items.seatReleasePass = true;
  }
  if (reached("c2-seat-sit")) {
    puzzle.backpackEvicted = true;
    items.seatReleasePass = false;
  }
  if (reached("c2-seat-dialogue")) puzzle.playerSeated = true;
  if (reached("c2-chapter-exit")) {
    puzzle.nextQuestId = "chapter_three_canteen_hunt";
    puzzle.clueIds = [...puzzle.clueIds, "borrowed_attendance_record"];
  }

  const rpgCheckpoints: Partial<Record<LibraryDeveloperCheckpointId, GameState["rpgCheckpoint"]>> = {
    "c2-library-gate": "campus_library_gate",
    "c2-entrance-record": "library_entrance",
    "c2-seat-arrival": "library_seat_022",
    "c2-occupancy-note": "library_seat_022",
    "c2-archived-rule": "library_shelf_755",
    "c2-nonperson-stamp": "library_front_desk",
    "c2-seat-receipt": "library_seat_022",
    "c2-pass-apply": "library_seat_022",
    "c2-seat-sit": "library_seat_022",
    "c2-seat-dialogue": "library_seat_022",
    "c2-chapter-exit": "campus_spawn"
  };
  const rpgCheckpoint = rpgCheckpoints[id];
  const runtimeMode = rpgCheckpoint ? "rpg" : "phone";
  const currentSceneByCheckpoint: Partial<Record<LibraryDeveloperCheckpointId, SceneId>> = {
    "c2-catalog": "zjuding",
    "c2-photo-report": "photos",
    "c2-tiyi-proof": "tiyi",
    "c2-cc98-upload": "cc98",
    "c2-bd-rise": "cc98",
    "c2-recovery-form": "zjuding",
    "c2-pass-generate": "zjuding",
    "c2-chapter-exit": "phone_home"
  };
  const zjudingPage: ZjudingPage = id === "c2-catalog"
    ? "library_catalog"
    : id === "c2-recovery-form" || id === "c2-pass-generate"
      ? "library_recovery"
      : "hub";

  state = {
    ...state,
    networkMode: id === "c2-tiyi-proof" ? "cellular" : state.networkMode,
    runtimeMode,
    rpgScene: id === "c2-library-gate" || id === "c2-chapter-exit" ? "campus_bootstrap" : rpgCheckpoint ? "library_interior" : state.rpgScene,
    rpgCheckpoint: rpgCheckpoint ?? state.rpgCheckpoint,
    currentScene: currentSceneByCheckpoint[id] ?? state.currentScene,
    items,
    canteenHunt: reached("c2-chapter-exit")
      ? {
          ...state.canteenHunt,
          active: true,
          phase: "tracking",
          mode: "light",
          entryPaperEscaped: false,
          trayTaskStarted: false,
          carriedTrayIds: [],
          identifiedTrayIds: [],
          returnedTrayIds: [],
          drinkShelfRead: false,
          drinkMixSequence: [],
          drinkMixAttemptCount: 0,
          queueChallengeSeen: false,
          promoDrinkPlaced: false,
          queueGapOpened: false,
          menuDarkClueRead: false,
          pickupTimeErrorSeen: false,
          pickupDarkClueRead: false,
          defenseDrinkUsed: false,
          identifiedExitIds: [],
          orderAttemptCount: 0,
          pickupAttemptCount: 0,
          blockHits: 0,
          bikeCodeRead: false,
          bikeLockCleaned: false,
          bikePaid: false,
          chaseCompleted: false,
          chaseAttemptCount: 0,
          chaseBestDistance: 0,
          chaseBestLives: 0,
          chaseCollisions: 0
        }
      : state.canteenHunt,
    ui: {
      ...state.ui,
      brightness: id === "c2-photo-report" ? 33 : state.ui.brightness,
      inventoryOpen: false,
      selectedItem: null,
      zjudingPage,
      librarySelectedSeat: "022",
      librarySeatReserved: true,
      libraryFinalsPhase: libraryPhaseFor(id),
      libraryFinalsPuzzle: puzzle
    }
  };
  return state;
}

function createCanteenCheckpointState(id: CanteenDeveloperCheckpointId): GameState {
  const state = createLibraryCheckpointState("c2-chapter-exit");
  const identifiedTrayIds = ["tray_blue_01", "tray_blue_02", "tray_blue_03"];
  // Tray work is deliberately independent from the paper chase. Keep every
  // checkpoint before the bike unpaid so the deferred-return path stays testable.
  const afterTrayStage = ["c3-canteen-bike", "c3-canteen-chase", "c3-canteen-theater"].includes(id);
  const afterDrinkStage = !["canteen-hunt", "c3-canteen-entry", "c3-canteen-drinks"].includes(id);
  const afterMenuStage = ["c3-canteen-pickup", "c3-canteen-block", "c3-canteen-block-2", "c3-canteen-block-3", "c3-canteen-bike", "c3-canteen-chase", "c3-canteen-theater"].includes(id);
  const afterPickupStage = ["c3-canteen-block", "c3-canteen-block-2", "c3-canteen-block-3", "c3-canteen-bike", "c3-canteen-chase", "c3-canteen-theater"].includes(id);
  const afterBlockingStage = ["c3-canteen-bike", "c3-canteen-chase", "c3-canteen-theater"].includes(id);
  const beforeEntryPaperEscape = ["canteen-hunt", "c3-canteen-entry"].includes(id);
  const phase: GameState["canteenHunt"]["phase"] = id === "canteen-hunt"
    ? "tracking"
    : id === "c3-canteen-entry"
      ? "tray_search"
      : id === "c3-canteen-drinks"
        ? "drink_mix"
      : id === "c3-canteen-menu"
        ? "menu_order"
        : id === "c3-canteen-pickup"
          ? "pickup_search"
          : ["c3-canteen-block", "c3-canteen-block-2", "c3-canteen-block-3"].includes(id)
            ? "exit_blocking"
            : id === "c3-canteen-bike"
              ? "chase_ready"
              : id === "c3-canteen-chase"
                ? "chasing"
                : "theater_reached";
  const inCanteen = ["c3-canteen-entry", "c3-canteen-drinks", "c3-canteen-menu", "c3-canteen-pickup", "c3-canteen-block", "c3-canteen-block-2", "c3-canteen-block-3"].includes(id);

  return {
    ...state,
    runtimeMode: "rpg",
    rpgScene: inCanteen ? "canteen_interior" : "campus_bootstrap",
    rpgCheckpoint: inCanteen
      ? "canteen_entrance"
      : afterBlockingStage
        ? id === "c3-canteen-theater" ? "campus_theater_junction" : "campus_canteen_gate"
        : "campus_spawn",
    themeMode: "normal",
    wallet: {
      ...state.wallet,
      cashCents: id === "c3-canteen-chase" || id === "c3-canteen-theater"
        ? 0
        : afterTrayStage
          ? 200
          : 0
    },
    items: {
      ...state.items,
      cafeteriaWages: afterTrayStage && !["c3-canteen-chase", "c3-canteen-theater"].includes(id),
      greaseTissue: afterTrayStage,
      pickupTicket0755: afterMenuStage && !afterPickupStage
    },
    canteenHunt: {
      ...state.canteenHunt,
      active: true,
      phase,
      mode: "light",
      entryPaperEscaped: !beforeEntryPaperEscape,
      trayTaskStarted: afterTrayStage,
      carriedTrayIds: [],
      identifiedTrayIds: afterTrayStage ? identifiedTrayIds : [],
      returnedTrayIds: afterTrayStage ? identifiedTrayIds : [],
      drinkShelfRead: afterDrinkStage,
      drinkMixSequence: [],
      drinkMixAttemptCount: afterDrinkStage ? 1 : 0,
      queueChallengeSeen: afterDrinkStage,
      promoDrinkPlaced: afterDrinkStage,
      // The menu checkpoint should exercise the same queue-retreat handoff as
      // normal play instead of loading directly into its final pose.
      queueGapOpened: id === "c3-canteen-menu" ? false : afterDrinkStage,
      menuDarkClueRead: afterMenuStage,
      pickupTimeErrorSeen: false,
      pickupDarkClueRead: afterPickupStage,
      defenseDrinkUsed: false,
      orderedMenuOption: afterMenuStage && !afterPickupStage ? "D" : null,
      identifiedExitIds: afterBlockingStage ? ["southeast", "steam", "west"] : [],
      orderAttemptCount: afterMenuStage ? 1 : 0,
      pickupAttemptCount: afterPickupStage ? 1 : 0,
      blockHits: afterBlockingStage ? 3 : 0,
      bikeCodeRead: ["c3-canteen-chase", "c3-canteen-theater"].includes(id),
      bikeLockCleaned: ["c3-canteen-chase", "c3-canteen-theater"].includes(id),
      bikePaid: ["c3-canteen-chase", "c3-canteen-theater"].includes(id),
      chaseCompleted: id === "c3-canteen-theater",
      chaseAttemptCount: id === "c3-canteen-theater" ? 1 : 0,
      chaseBestDistance: id === "c3-canteen-theater" ? 755 : 0,
      chaseBestLives: id === "c3-canteen-theater" ? 2 : 0,
      chaseCollisions: id === "c3-canteen-theater" ? 1 : 0
    },
    ui: {
      ...state.ui,
      inventoryOpen: false,
      selectedItem: null,
      seenChapterIntros: ["chapter_one", "chapter_two", "chapter_three"]
    }
  };
}

function createTheaterCheckpointState(id: TheaterDeveloperCheckpointId): GameState {
  const base = createCanteenCheckpointState("c3-canteen-theater");
  const ticketRequestCheckpoint = id === "c3-theater-ticket-request";
  const ticketAcceptedCheckpoint = id === "c3-theater-ticket-accepted";
  const ticketFirstWaveCheckpoint = id === "c3-theater-ticket-first-wave";
  const ticketFirstWaveWonCheckpoint = id === "c3-theater-ticket-first-wave-won";
  const ticketDeliveredCheckpoint = id === "c3-theater-ticket-delivered";
  const phoneTicketCheckpoint = ticketRequestCheckpoint || ticketAcceptedCheckpoint || ticketFirstWaveCheckpoint || ticketFirstWaveWonCheckpoint || ticketDeliveredCheckpoint;
  const reachedCode = ["c3-theater-ticket-first-wave", "c3-theater-ticket-first-wave-won", "c3-theater-ticket-delivered", "c3-theater-code", "c3-theater-program", "c3-theater-prop", "c3-theater-spotlight", "c3-theater-spotlight-round", "c3-theater-complete"].includes(id);
  const admitted = ["c3-theater-program", "c3-theater-prop", "c3-theater-spotlight", "c3-theater-spotlight-round", "c3-theater-complete"].includes(id);
  const programSolved = ["c3-theater-prop", "c3-theater-spotlight", "c3-theater-spotlight-round", "c3-theater-complete"].includes(id);
  const propSolved = ["c3-theater-spotlight", "c3-theater-spotlight-round", "c3-theater-complete"].includes(id);
  const complete = id === "c3-theater-complete";
  const phase: GameState["theaterHunt"]["phase"] = complete
    ? "complete"
    : id === "c3-theater-spotlight-round"
      ? "spotlight_hunt"
    : id === "c3-theater-spotlight"
      ? "spotlight_ready"
      : id === "c3-theater-prop"
        ? "prop_setup"
        : id === "c3-theater-program"
          ? "program_search"
          : "entry_ticket";
  return {
    ...base,
    runtimeMode: phoneTicketCheckpoint ? "phone" : "rpg",
    currentScene: ticketFirstWaveCheckpoint ? "phone_home" : phoneTicketCheckpoint ? "cc98" : base.currentScene,
    networkMode: ticketFirstWaveWonCheckpoint || ticketDeliveredCheckpoint ? "cellular" : base.networkMode,
    rpgScene: "theater_interior",
    rpgCheckpoint: programSolved ? "theater_stage" : admitted ? "theater_auditorium" : "theater_lobby",
    items: {
      ...base.items,
      greaseTissue: !reachedCode,
      theaterTicketHalfA: reachedCode && !admitted,
      theaterTicketHalfB: false,
      temporaryTheaterTicket: admitted && !propSolved,
      theaterProgramOpening: admitted && !programSolved,
      theaterProgramSpotlight: admitted && !programSolved,
      theaterProgramFinale: admitted && !programSolved,
      spotlightRemote: programSolved && !["c3-theater-spotlight-round", "c3-theater-complete"].includes(id),
      fluorescentBrush: false,
      decoyPaper: complete,
      wetProgram: complete
    },
    theaterHunt: {
      ...base.theaterHunt,
      active: true,
      phase,
      mode: id === "c3-theater-spotlight-round" ? "dark" : "light",
      cc98TicketCommissionPhase: ticketRequestCheckpoint
        ? "posted"
        : ticketAcceptedCheckpoint
          ? "accepted"
          : ticketFirstWaveCheckpoint
            ? "first_wave_failed"
            : ticketFirstWaveWonCheckpoint
              ? "delivered"
          : reachedCode || admitted
            ? "delivered"
            : "posted",
      cc98TicketClaimedWave: ticketFirstWaveWonCheckpoint ? 1 : ticketDeliveredCheckpoint || id === "c3-theater-code" || admitted ? 2 : null,
      posterCleaned: reachedCode,
      ticketCodeRead: reachedCode,
      ticketCodeAttempts: admitted ? 1 : 0,
      admitted,
      collectedProgramIds: admitted ? ["opening", "spotlight", "finale"] : [],
      programOrder: programSolved ? ["spotlight", "opening", "finale"] : [],
      propGhostRead: programSolved,
      managerHintRead: programSolved,
      propBoxOpened: propSolved,
      paperDusted: propSolved,
      spotlightRound: complete ? 3 : 0,
      decoyRevealed: complete
    }
  };
}

function createQizhenCheckpointState(id: QizhenDeveloperCheckpointId): GameState {
  const base = createTheaterCheckpointState("c3-theater-complete");
  const rhythmKey = id === "c3-qizhen-rhythm-key";
  const rhythmNet = id === "c3-qizhen-rhythm-net";
  const rhythmFish = id === "c3-qizhen-rhythm-fish";
  const rhythmPaper = id === "c3-qizhen-rhythm-paper";
  const rhythmCheckpoint = rhythmKey || rhythmNet || rhythmFish || rhythmPaper;
  const rainSafetyCheckpoint = id === "c3-qizhen-rain-hold";
  const rescueDormCheckpoint = id === "c3-qizhen-rescue-dorm";
  const hairDryerCheckpoint = id === "c3-qizhen-hair-dryer";
  const weatherControlCheckpoint = id === "c3-qizhen-weather-control";
  const rainRecoveryCheckpoint = rescueDormCheckpoint || hairDryerCheckpoint || weatherControlCheckpoint;
  const overcastCheckpoint = id === "c3-qizhen-overcast";
  const inLake = [
    "c3-qizhen-dock",
    "c3-qizhen-rain-hold",
    "c3-qizhen-weather-control",
    "c3-qizhen-overcast",
    "c3-qizhen-boarding",
    "c3-qizhen-open-water",
    "c3-qizhen-rhythm-key",
    "c3-qizhen-rhythm-net",
    "c3-qizhen-rhythm-fish",
    "c3-qizhen-rhythm-paper",
    "c3-qizhen-tool-chain",
    "c3-qizhen-swan",
    "c3-qizhen-paper",
    "c3-qizhen-chase",
    "c3-qizhen-complete"
  ].includes(id);
  const phase: GameState["qizhenLake"]["phase"] = id === "c3-qizhen-transition" || id === "c3-qizhen-location" || id === "c3-qizhen-map"
    ? "location_search"
    : id === "c3-qizhen-gate"
      ? "lake_unlocked"
      : id === "c3-qizhen-dock"
        ? "dock_outfitting"
        : rainSafetyCheckpoint
          ? "boarding_tutorial"
          : rainRecoveryCheckpoint
            ? "rain_recovery"
            : overcastCheckpoint || id === "c3-qizhen-boarding"
              ? "boarding_tutorial"
          : id === "c3-qizhen-open-water"
            ? "lake_exploration"
            : rhythmKey || rhythmNet || rhythmFish
              ? "tool_chain"
              : rhythmPaper
                ? "paper_capture"
            : id === "c3-qizhen-tool-chain"
              ? "tool_chain"
              : id === "c3-qizhen-swan"
                ? "swan_exchange"
                : id === "c3-qizhen-paper"
                  ? "paper_capture"
                  : id === "c3-qizhen-chase"
                    ? "swan_chase"
                    : "complete";
  const locationSourcesCompleted = !["c3-qizhen-transition", "c3-qizhen-location"].includes(id);
  const locationSolved = !["c3-qizhen-transition", "c3-qizhen-location", "c3-qizhen-map"].includes(id);
  const boardingReady = rhythmCheckpoint || [
    "c3-qizhen-rain-hold", "c3-qizhen-rescue-dorm", "c3-qizhen-hair-dryer",
    "c3-qizhen-weather-control", "c3-qizhen-overcast", "c3-qizhen-boarding",
    "c3-qizhen-open-water", "c3-qizhen-tool-chain", "c3-qizhen-swan",
    "c3-qizhen-paper", "c3-qizhen-chase", "c3-qizhen-complete"
  ].includes(id);
  const weatherAdjustmentRequested = rainRecoveryCheckpoint || overcastCheckpoint || rhythmCheckpoint || [
    "c3-qizhen-boarding", "c3-qizhen-open-water", "c3-qizhen-tool-chain", "c3-qizhen-swan",
    "c3-qizhen-paper", "c3-qizhen-chase", "c3-qizhen-complete"
  ].includes(id);
  const rainSafetyCleared = overcastCheckpoint || rhythmCheckpoint || [
    "c3-qizhen-boarding", "c3-qizhen-open-water", "c3-qizhen-tool-chain", "c3-qizhen-swan",
    "c3-qizhen-paper", "c3-qizhen-chase", "c3-qizhen-complete"
  ].includes(id);
  const rainRescueCompleted = rainRecoveryCheckpoint || rainSafetyCleared;
  const onWater = rhythmCheckpoint || ["c3-qizhen-open-water", "c3-qizhen-tool-chain", "c3-qizhen-swan", "c3-qizhen-paper", "c3-qizhen-chase"].includes(id);
  const toolChain = rhythmCheckpoint || ["c3-qizhen-tool-chain", "c3-qizhen-swan", "c3-qizhen-paper", "c3-qizhen-chase", "c3-qizhen-complete"].includes(id);
  const swanReached = ["c3-qizhen-swan", "c3-qizhen-paper", "c3-qizhen-chase", "c3-qizhen-complete"].includes(id);
  const paperReached = ["c3-qizhen-paper", "c3-qizhen-chase", "c3-qizhen-complete"].includes(id);
  const chaseReached = ["c3-qizhen-chase", "c3-qizhen-complete"].includes(id);
  const completed = id === "c3-qizhen-complete";
  const zone: GameState["qizhenLake"]["zone"] = id === "c3-qizhen-swan" || id === "c3-qizhen-paper" || rhythmPaper
    ? "swan_cove"
    : rhythmNet
      ? "channel"
    : id === "c3-qizhen-chase"
      ? "channel"
      : id === "c3-qizhen-open-water" || id === "c3-qizhen-tool-chain" || rhythmKey || rhythmNet || rhythmFish
        ? "open_water"
        : "dock";

  return {
    ...base,
    runtimeMode: id === "c3-qizhen-location" || id === "c3-qizhen-map" || weatherControlCheckpoint ? "phone" : "rpg",
    currentScene: id === "c3-qizhen-location"
      ? "cc98"
      : id === "c3-qizhen-map"
        ? "zjuding"
        : weatherControlCheckpoint
          ? "weather"
          : base.currentScene,
    rpgScene: inLake
      ? "qizhen_lake"
      : rescueDormCheckpoint || hairDryerCheckpoint
        ? "dorm_hub"
      : id === "c3-qizhen-transition" || id === "c3-qizhen-gate"
        ? "campus_qizhen_loop"
        : base.rpgScene,
    rpgCheckpoint: id === "c3-qizhen-transition"
      ? "campus_theater_junction"
      : id === "c3-qizhen-gate"
        ? "campus_qizhen_gate"
        : rescueDormCheckpoint || hairDryerCheckpoint
          ? "dorm_spawn"
        : rhythmNet
          ? "qizhen_channel"
        : id === "c3-qizhen-open-water" || id === "c3-qizhen-tool-chain" || rhythmKey || rhythmFish
          ? "qizhen_open_water"
          : id === "c3-qizhen-swan" || id === "c3-qizhen-paper" || rhythmPaper
            ? "qizhen_swan_cove"
            : id === "c3-qizhen-chase"
              ? "qizhen_chase"
              : id === "c3-qizhen-complete"
                ? "qizhen_complete"
                : inLake
                  ? "qizhen_dock"
                  : base.rpgCheckpoint,
    items: {
      ...base.items,
      wetProgram: !locationSourcesCompleted,
      decoyPaper: locationSolved && !toolChain,
      bridgeKeyword: false,
      reflectionKeyword: false,
      lakeKeyword: id === "c3-qizhen-map" && !locationSolved,
      reflectionCoordinate: false,
      hairDryer: hairDryerCheckpoint || weatherControlCheckpoint,
      fishingRod: (id === "c3-qizhen-open-water" || toolChain || swanReached || paperReached) && !chaseReached && !rhythmPaper,
      rustedLockerKey: false,
      nylonCord: id === "c3-qizhen-tool-chain" || rhythmNet,
      brokenNetFrame: id === "c3-qizhen-tool-chain",
      improvisedDipNet: false,
      sealedFeedTin: false,
      fishFeedPellets: rhythmFish,
      smallCarp: id === "c3-qizhen-swan",
      swanMagnet: id === "c3-qizhen-paper",
      magneticFishingRod: id === "c3-qizhen-chase" || rhythmPaper
    },
    qizhenLake: {
      ...base.qizhenLake,
      active: true,
      phase,
      mode: "light",
      zone,
      vehicle: onWater ? "kayak" : "on_foot",
      safeSpawnId: id === "c3-qizhen-chase"
        ? "channel_chase"
        : zone === "swan_cove"
          ? "swan_cove_entry"
          : zone === "channel"
            ? "channel_entry"
          : zone === "open_water"
            ? "open_water_entry"
            : id === "c3-qizhen-boarding" ? "dock_kayak" : "dock_entry",
      locationBriefingSeen: !["c3-qizhen-transition", "c3-qizhen-location"].includes(id),
      bridgeClueFound: !["c3-qizhen-transition", "c3-qizhen-location"].includes(id),
      reflectionClueFound: !["c3-qizhen-transition", "c3-qizhen-location"].includes(id),
      lakeClueFound: !["c3-qizhen-transition", "c3-qizhen-location"].includes(id),
      mapClueIds: id === "c3-qizhen-transition" || id === "c3-qizhen-location"
        ? []
        : id === "c3-qizhen-map"
          ? ["bridge", "reflection"]
          : ["bridge", "reflection", "lake"],
      introSeen: inLake || rainRecoveryCheckpoint,
      kayakEquipped: boardingReady,
      leftPaddleEquipped: boardingReady,
      rightPaddleEquipped: boardingReady,
      weatherAdjustmentRequested,
      rainWarningSeen: rainRescueCompleted,
      rainRescueCompleted,
      rainSafetyCleared,
      boardingStrokeCount: onWater || completed ? 4 : 0,
      boardingLastSide: onWater || completed ? "right" : null,
      boardingTutorialCompleted: onWater || swanReached || paperReached || chaseReached || completed,
      rodFound: id === "c3-qizhen-open-water" || toolChain || swanReached || paperReached || chaseReached || completed,
      decoyBaitAttached: toolChain || swanReached || paperReached || chaseReached || completed,
      reflectionLocationObserved: id === "c3-qizhen-open-water" || toolChain || swanReached || paperReached || chaseReached || completed,
      observedFishingSpotIds: rhythmKey
        ? ["locker_key"]
        : rhythmNet
          ? ["net_frame"]
          : rhythmFish
            ? ["fish"]
            : rhythmPaper
              ? ["paper"]
              : id === "c3-qizhen-open-water"
        ? ["locker_key", "paper"]
        : toolChain || swanReached || paperReached || chaseReached || completed
          ? ["locker_key", "net_frame", "fish", "paper"]
          : [],
      lockerOpened: !rhythmKey && (toolChain || swanReached || paperReached || chaseReached || completed),
      netCombined: rhythmFish || swanReached || paperReached || chaseReached || completed,
      feedTinRetrieved: rhythmFish || swanReached || paperReached || chaseReached || completed,
      feedTinOpened: rhythmFish || swanReached || paperReached || chaseReached || completed,
      fishCaught: swanReached || paperReached || chaseReached || completed,
      swanFed: rhythmPaper || paperReached || chaseReached || completed,
      magneticRodCombined: rhythmPaper || chaseReached || completed,
      paperCaptured: chaseReached || completed,
      swanReleased: chaseReached || completed,
      chaseDistance: completed ? 1000 : 0,
      chaseBestDistance: completed ? 1000 : 0,
      chaseAttempts: chaseReached ? 1 : 0,
      magneticAttachmentBroken: completed,
      transitionReady: completed,
      paperReleased: chaseReached || completed
    },
    ui: {
      ...base.ui,
      zjudingPage: id === "c3-qizhen-map" ? "campus_map" : "hub",
      inventoryOpen: false,
      selectedItem: null
    }
  };
}

function createChapterThreeInterludeCheckpointState(id: ChapterThreeInterludeDeveloperCheckpointId): GameState {
  const base = createQizhenCheckpointState("c3-qizhen-complete");
  const journalReady = id !== "c3-interlude-reboot" && id !== "c3-interlude-journal";
  const photosReady = [
    "c3-interlude-voice", "c3-interlude-network", "c3-interlude-timeline", "c3-interlude-destination", "c3-interlude-replay"
  ].includes(id);
  const voiceReady = ["c3-interlude-network", "c3-interlude-timeline", "c3-interlude-destination", "c3-interlude-replay"].includes(id);
  const networkReady = ["c3-interlude-timeline", "c3-interlude-destination", "c3-interlude-replay"].includes(id);
  const destinationChoiceReady = id === "c3-interlude-destination" || id === "c3-interlude-replay";
  const replayReady = id === "c3-interlude-replay";
  const currentScene: SceneId = id === "c3-interlude-reboot"
    ? "phone_home"
    : id === "c3-interlude-journal"
      ? "cc98"
      : id === "c3-interlude-photos"
        ? "photos"
        : id === "c3-interlude-voice"
          ? "voice_memos"
          : "timeline_recovery";
  const evidenceIds: GameState["chapterThreeInterlude"]["evidenceIds"] = [
    ...(journalReady ? ["journal_start" as const] : []),
    ...(photosReady ? ["photo_direction" as const] : []),
    ...(networkReady ? ["network_destination" as const] : []),
    ...(voiceReady ? ["broadcast_end" as const] : [])
  ];
  return {
    ...base,
    runtimeMode: "phone",
    currentScene,
    chapterThreeInterlude: {
      ...base.chapterThreeInterlude,
      phase: replayReady
        ? "destination_verified"
        : networkReady
          ? "timeline_assembly"
          : id === "c3-interlude-reboot"
            ? "reboot"
            : id === "c3-interlude-journal"
              ? "journal_closeout"
              : "evidence_collection",
      rebootSeen: id !== "c3-interlude-reboot",
      recoveryOpened: id !== "c3-interlude-reboot",
      photoFrameIds: photosReady ? ["paper_left", "paper_middle", "paper_right"] : [],
      photoSequenceSolved: photosReady,
      voiceClipOrder: voiceReady ? ["lake", "stone", "lobby", "broadcast"] : [],
      voiceSequenceSolved: voiceReady,
      officialNoticeSaved: networkReady,
      routeScreenshotSaved: networkReady,
      networkRecordRead: networkReady,
      evidenceIds,
      timelineOrder: destinationChoiceReady ? ["journal_start", "photo_direction", "network_destination", "broadcast_end"] : [],
      rejectedDecoyIds: destinationChoiceReady ? ["canteen_0755", "theater_0832", "status_clock_075523"] : [],
      statusClockMarkedUntrusted: destinationChoiceReady,
      destinationId: replayReady ? "duan_yongping_a1" : null,
      replayUnlocked: false,
      completed: false
    },
    qizhenLake: {
      ...base.qizhenLake,
      journal: journalReady
        ? { ...base.qizhenLake.journal, status: "archived", summaryChoice: "details_withheld", summaryPublished: true }
        : base.qizhenLake.journal
    },
    ui: { ...base.ui, controlCenterOpen: false, inventoryOpen: false, selectedItem: null }
  };
}

function createChapterFourBaseState(prologueSeen: boolean): GameState {
  const base = createQizhenCheckpointState("c3-qizhen-complete");
  return {
    ...base,
    chapterThreeInterlude: {
      ...base.chapterThreeInterlude,
      phase: prologueSeen ? "complete" : "replay_ready",
      rebootSeen: true,
      recoveryOpened: true,
      photoFrameIds: ["paper_left", "paper_middle", "paper_right"],
      photoSequenceSolved: true,
      voiceClipOrder: ["lake", "stone", "lobby", "broadcast"],
      voiceSequenceSolved: true,
      officialNoticeSaved: true,
      routeScreenshotSaved: true,
      networkRecordRead: true,
      evidenceIds: ["journal_start", "photo_direction", "network_destination", "broadcast_end"],
      timelineOrder: ["journal_start", "photo_direction", "network_destination", "broadcast_end"],
      rejectedDecoyIds: ["canteen_0755", "theater_0832", "status_clock_075523"],
      statusClockMarkedUntrusted: true,
      destinationId: "duan_yongping_a1",
      replayUnlocked: true,
      completed: prologueSeen
    }
  };
}

const CHAPTER_FOUR_755_OPENING_FACTS = [
  "opening_paper_at_noticeboard",
  "opening_paper_caught",
  "external_time_rejected",
  "hall_clock_inspected"
] as const satisfies readonly GameState["chapter4"]["factIds"][number][];

const CHAPTER_FOUR_755_BAKERY_FACTS = [
  ...CHAPTER_FOUR_755_OPENING_FACTS,
  "bakery_conveyor_lamp_inspected",
  "bakery_conveyor_direction_observed",
  "bakery_tool_location_observed",
  "bakery_hour_hand_exposed",
  "bakery_hour_hand_collected",
  "hour_hand_installed"
] as const satisfies readonly GameState["chapter4"]["factIds"][number][];

const CHAPTER_FOUR_755_CLASSROOM_FACTS = [
  ...CHAPTER_FOUR_755_BAKERY_FACTS,
  "classroom_104_chalk_residual_observed",
  "classroom_105_terminal_replay_checked"
] as const satisfies readonly GameState["chapter4"]["factIds"][number][];

const CHAPTER_FOUR_755_ROOM_FACTS = [
  ...CHAPTER_FOUR_755_CLASSROOM_FACTS,
  "elevator_history_observed",
  "elevator_history_calibrated",
  "a1_time_route_compared",
  "elevator_a2_call_record_observed",
  "elevator_a3_arrival_record_observed",
  "elevator_stop_chain_reconstructed",
  "a1_duty_board_reconstructed",
  "a3_archive_film_retrieved",
  "a3_media_alignment_completed",
  "a3_reference_observed",
  "a3_identity_context_observed",
  "misaligned_stair_solved",
  "room204_residual_observed",
  "room204_restored",
  "room204_projection_completed",
  "room204_projection_composite_completed",
  "room202_endpoint_inferred",
  "maintenance_incident_linked",
  "positioning_plate_collected",
  "a2_positioning_plate_calibrated",
  "a2_power_topology_recovered",
  "a2_evacuation_route_confirmed",
  "positioning_plate_installed"
] as const satisfies readonly GameState["chapter4"]["factIds"][number][];

const CHAPTER_FOUR_755_MAINTENANCE_FACTS = [
  ...CHAPTER_FOUR_755_ROOM_FACTS,
  "cart_wheel_inspected",
  "cart_wheel_cover_opened",
  "cart_wheel_repaired",
  "clock_gear_repaired"
] as const satisfies readonly GameState["chapter4"]["factIds"][number][];

const CHAPTER_FOUR_755_BLACKOUT_FACTS = [
  ...CHAPTER_FOUR_755_MAINTENANCE_FACTS,
  "paper_temporarily_out_of_inventory"
] as const satisfies readonly GameState["chapter4"]["factIds"][number][];

const CHAPTER_FOUR_755_CHASE_FACTS = [
  ...CHAPTER_FOUR_755_BLACKOUT_FACTS,
  "light_grid_locked",
  "powered_route_confirmed",
  "canruo_star_lamp_primed"
] as const satisfies readonly GameState["chapter4"]["factIds"][number][];

const CHAPTER_FOUR_755_RETURN_CLOCK_FACTS = [
  ...CHAPTER_FOUR_755_CHASE_FACTS,
  "room202_route_reached",
  "final_minute_recovered",
  "attendance_record_recovered"
] as const satisfies readonly GameState["chapter4"]["factIds"][number][];

const CHAPTER_FOUR_755_CHECKIN_FACTS = [
  ...CHAPTER_FOUR_755_RETURN_CLOCK_FACTS,
  "final_minute_installed"
] as const satisfies readonly GameState["chapter4"]["factIds"][number][];

const CHAPTER_FOUR_755_COMPLETE_WAIT_FACTS = [
  ...CHAPTER_FOUR_755_CHECKIN_FACTS,
  "checkin_card_accepted",
  "checkin_paper_accepted",
  "checkin_identity_verified"
] as const satisfies readonly GameState["chapter4"]["factIds"][number][];

const CHAPTER_FOUR_755_CANONICAL_ROOM204 = ROOM204_PIECE_ORDER.map((pieceId, index) => ({
  pieceId,
  slotId: ROOM204_SLOT_ORDER[index],
  orientation: "up" as const
}));

function createChapterFour755CheckpointState(id: ChapterFour755DeveloperCheckpointId): GameState {
  const base = createChapterFourBaseState(true);
  const common: GameState = {
    ...base,
    currentScene: "phone_home",
    runtimeMode: "rpg",
    rpgScene: "duan_yongping_temporal_maze",
    rpgCheckpoint: "c4_a1_lobby",
    items: {
      ...base.items,
      campusCard: true,
      attendanceRecordPaper: false,
      oldClockHourHand: false,
      clockPositioningPlate: false,
      shortPryBar: false,
      universalLubricatingOil: false,
      finalMinute: false
    },
    chapter4: {
      ...base.chapter4,
      prologueSeen: true,
      phase: "opening_handoff",
      mode: "light",
      building: "A",
      floor: "A1",
      roomId: "a1_lobby",
      timeAuthority: "external_evidence",
      timeState: "2245_opening",
      worldTimeSeconds: 81900,
      phoneStatusTimeSeconds: 28523,
      phoneStatusTimeTrusted: false,
      factIds: [],
      room204Placements: [],
      lightGrid: { mask: 14, locked: false },
      guardMode: "absent",
      chaseAttempt: 0,
      chaseRestartCheckpoint: null,
      checkinCardAccepted: false,
      checkinPaperAccepted: false,
      exteriorClosureAcknowledged: false,
      completed: false,
      buildingTimeSeconds: 81900,
      solvedPuzzleIds: [],
      clueIds: []
    },
    ui: {
      ...base.ui,
      controlCenterOpen: false,
      inventoryOpen: false,
      selectedItem: null,
      zjudingPage: "hub"
    }
  };

  const withChapter = (
    patch: Partial<GameState["chapter4"]>,
    itemPatch: Partial<GameState["items"]> = {},
    checkpoint: GameState["rpgCheckpoint"] = "c4_a1_lobby"
  ): GameState => {
    const zhuQuestionsAnswered = patch.factIds?.includes("zhu_two_questions_answered") ?? false;
    return {
      ...common,
      rpgCheckpoint: checkpoint,
      items: { ...common.items, ...itemPatch },
      chapter4: {
        ...common.chapter4,
        ...patch,
        ...(zhuQuestionsAnswered && patch.zhuQuestionAnswers === undefined
          ? { zhuQuestionAnswers: { purpose: "seek_truth", person: "responsible" } }
          : {})
      }
    };
  };

  if (id === "c4-755-opening") return common;
  if (id === "c4-755-hall-clock") {
    return withChapter({
      phase: "hall_clock_inspection",
      roomId: "a1_hall_clock",
      factIds: [...CHAPTER_FOUR_755_OPENING_FACTS]
    }, { attendanceRecordPaper: true });
  }
  if (id === "c4-755-bakery-1225") {
    return withChapter({
      phase: "bakery_hour_hand",
      roomId: "a1_bakery",
      timeAuthority: "hall_clock",
      timeState: "1225_bakery",
      worldTimeSeconds: 44700,
      phoneStatusTimeSeconds: 44700,
      phoneStatusTimeTrusted: true,
      buildingTimeSeconds: 44700,
      factIds: [...CHAPTER_FOUR_755_OPENING_FACTS]
    }, { attendanceRecordPaper: true });
  }
  if (id === "c4-755-classrooms-1850") {
    return withChapter({
      phase: "room204_restore",
      floor: "A1",
      roomId: "a1_hall_clock",
      timeAuthority: "hall_clock",
      timeState: "1850_evening",
      worldTimeSeconds: 67800,
      phoneStatusTimeSeconds: 67800,
      phoneStatusTimeTrusted: true,
      buildingTimeSeconds: 67800,
      factIds: [...CHAPTER_FOUR_755_BAKERY_FACTS]
    }, { attendanceRecordPaper: true });
  }
  if (id === "c4-755-elevator-history") {
    return withChapter({
      phase: "room204_restore",
      floor: "A1",
      roomId: "a1_main_elevator",
      mode: "light",
      timeAuthority: "hall_clock",
      timeState: "1850_evening",
      worldTimeSeconds: 67800,
      phoneStatusTimeSeconds: 67800,
      phoneStatusTimeTrusted: true,
      buildingTimeSeconds: 67800,
      factIds: [...CHAPTER_FOUR_755_CLASSROOM_FACTS, "elevator_history_observed"]
    }, { attendanceRecordPaper: true }, "c4_a1_main_elevator");
  }
  if (id === "c4-755-room204-1850") {
    return withChapter({
      phase: "room204_restore",
      floor: "A3",
      roomId: "a3_reference_classroom",
      timeAuthority: "hall_clock",
      timeState: "1850_evening",
      worldTimeSeconds: 67800,
      phoneStatusTimeSeconds: 67800,
      phoneStatusTimeTrusted: true,
      buildingTimeSeconds: 67800,
      factIds: [
        ...CHAPTER_FOUR_755_CLASSROOM_FACTS,
        "elevator_history_observed",
        "elevator_history_calibrated",
        "elevator_a3_arrival_record_observed",
        "a1_duty_board_reconstructed",
        "a3_reference_observed"
      ]
    }, { attendanceRecordPaper: true }, "c4_a3_wayfinding");
  }
  if (id === "c4-755-a2-field-records") {
    return withChapter({
      phase: "room204_restore",
      floor: "A2",
      roomId: "a2_corridor",
      mode: "dark",
      timeAuthority: "hall_clock",
      timeState: "1850_evening",
      worldTimeSeconds: 67800,
      phoneStatusTimeSeconds: 67800,
      phoneStatusTimeTrusted: true,
      buildingTimeSeconds: 67800,
      factIds: [
        ...CHAPTER_FOUR_755_CLASSROOM_FACTS,
        "elevator_history_observed",
        "elevator_history_calibrated",
        "elevator_a3_arrival_record_observed",
        "a1_duty_board_reconstructed",
        "a3_archive_film_retrieved",
        "a3_media_alignment_completed",
        "a3_reference_observed",
        "zhu_two_questions_answered",
        "misaligned_stair_solved"
      ]
    }, { attendanceRecordPaper: true }, "c4_a2_corridor");
  }
  if (id === "c4-755-maintenance-2245") {
    return withChapter({
      phase: "maintenance_repair",
      roomId: "a1_lobby",
      timeAuthority: "hall_clock",
      timeState: "2245_maintenance",
      worldTimeSeconds: 81900,
      phoneStatusTimeSeconds: 81900,
      phoneStatusTimeTrusted: true,
      buildingTimeSeconds: 81900,
      factIds: [...CHAPTER_FOUR_755_ROOM_FACTS],
      room204Placements: [...CHAPTER_FOUR_755_CANONICAL_ROOM204],
      guardMode: "patrol"
    }, { attendanceRecordPaper: true });
  }
  if (id === "c4-755-blackout-0754") {
    return withChapter({
      phase: "blackout_light_grid",
      roomId: "a1_power_panel",
      timeAuthority: "hall_clock",
      timeState: "0754_blackout",
      worldTimeSeconds: 28440,
      phoneStatusTimeSeconds: 28440,
      phoneStatusTimeTrusted: true,
      buildingTimeSeconds: 28440,
      factIds: [...CHAPTER_FOUR_755_BLACKOUT_FACTS],
      room204Placements: [...CHAPTER_FOUR_755_CANONICAL_ROOM204],
      lightGrid: { mask: 14, locked: false },
      guardMode: "absent"
    });
  }
  if (id === "c4-755-chase") {
    return withChapter({
      phase: "final_chase",
      roomId: "a1_lobby",
      timeAuthority: "hall_clock",
      timeState: "0754_blackout",
      worldTimeSeconds: 28440,
      phoneStatusTimeSeconds: 28440,
      phoneStatusTimeTrusted: true,
      buildingTimeSeconds: 28440,
      factIds: [...CHAPTER_FOUR_755_CHASE_FACTS],
      room204Placements: [...CHAPTER_FOUR_755_CANONICAL_ROOM204],
      lightGrid: { mask: 13, locked: true },
      guardMode: "chase",
      chaseRestartCheckpoint: "c4_a1_lobby"
    });
  }
  if (id === "c4-755-final-minute") {
    return withChapter({
      phase: "final_minute_recovery",
      floor: "A2",
      roomId: "a2_room_202",
      timeAuthority: "hall_clock",
      timeState: "0754_blackout",
      worldTimeSeconds: 28440,
      phoneStatusTimeSeconds: 28440,
      phoneStatusTimeTrusted: true,
      buildingTimeSeconds: 28440,
      factIds: [...CHAPTER_FOUR_755_CHASE_FACTS],
      room204Placements: [...CHAPTER_FOUR_755_CANONICAL_ROOM204],
      lightGrid: { mask: 13, locked: true },
      guardMode: "absent",
      chaseRestartCheckpoint: "c4_a1_lobby"
    }, {}, "c4_a2_room202");
  }
  if (id === "c4-755-return-clock") {
    return withChapter({
      phase: "return_to_clock",
      floor: "A2",
      roomId: "a2_room_202",
      timeAuthority: "hall_clock",
      timeState: "0754_blackout",
      worldTimeSeconds: 28440,
      phoneStatusTimeSeconds: 28440,
      phoneStatusTimeTrusted: true,
      buildingTimeSeconds: 28440,
      factIds: [...CHAPTER_FOUR_755_RETURN_CLOCK_FACTS],
      room204Placements: [...CHAPTER_FOUR_755_CANONICAL_ROOM204],
      lightGrid: { mask: 13, locked: true },
      guardMode: "absent",
      chaseRestartCheckpoint: "c4_a1_lobby"
    }, {
      attendanceRecordPaper: true,
      finalMinute: true
    }, "c4_a2_room202");
  }
  if (id === "c4-755-checkin") {
    return withChapter({
      phase: "morning_checkin",
      roomId: "a1_checkin",
      timeAuthority: "hall_clock",
      timeState: "0755_morning",
      worldTimeSeconds: 28500,
      phoneStatusTimeSeconds: 28500,
      phoneStatusTimeTrusted: true,
      buildingTimeSeconds: 28500,
      factIds: [...CHAPTER_FOUR_755_CHECKIN_FACTS],
      room204Placements: [...CHAPTER_FOUR_755_CANONICAL_ROOM204],
      lightGrid: { mask: 13, locked: true },
      guardMode: "absent"
    }, { attendanceRecordPaper: true });
  }
  if (id === "c4-755-closure") {
    return withChapter({
      phase: "exterior_closure",
      roomId: "a1_exterior",
      timeAuthority: "hall_clock",
      timeState: "0755_morning",
      worldTimeSeconds: 28500,
      phoneStatusTimeSeconds: 28500,
      phoneStatusTimeTrusted: true,
      buildingTimeSeconds: 28500,
      factIds: [...CHAPTER_FOUR_755_COMPLETE_WAIT_FACTS],
      room204Placements: [...CHAPTER_FOUR_755_CANONICAL_ROOM204],
      lightGrid: { mask: 13, locked: true },
      guardMode: "absent",
      checkinCardAccepted: true,
      checkinPaperAccepted: true,
      exteriorClosureAcknowledged: false,
      completed: false
    }, { attendanceRecordPaper: true });
  }
  throw new Error(`unhandled_chapter4_755_checkpoint:${id}`);
}

export function createDeveloperCheckpointState(requestedId: DeveloperCheckpointRequestId): GameState {
  const id = resolveCheckpointId(requestedId);
  if (!id) {
    throw new Error(`unknown_developer_checkpoint:${requestedId}`);
  }
  const initial = createInitialGameState();
  if (id === "c1-alarm") return initial;
  if (id === "c1-home") return { ...initial, currentScene: "phone_home" };
  if (id === "c1-code-hunt") return { ...initial, currentScene: "phone_home", flags: { ...initial.flags, codeScattered: true } };
  if (id === "c1-dorm-card") {
    return {
      ...initial,
      currentScene: "checkin",
      flags: { ...initial.flags, codeScattered: true },
      actOne: { ...initial.actOne, dormHubUnlocked: false }
    };
  }
  if (id === "c1-checkin") {
    return {
      ...initial,
      currentScene: "checkin",
      digits: { d1: "0", d2: "7", d3: "9", d4: "8" },
      flags: {
        ...initial.flags,
        codeScattered: true,
        cardZeroTaken: true,
        tiyiCountTaken: true,
        gearNineTaken: true,
        flowerEightTaken: true
      }
    };
  }
  if (id === "c1-narrator-block") {
    return {
      ...initial,
      currentScene: "ending",
      digits: { d1: "0", d2: "7", d3: "9", d4: "8" },
      flags: {
        ...initial.flags,
        codeScattered: true,
        cardZeroTaken: true,
        tiyiCountTaken: true,
        gearNineTaken: true,
        flowerEightTaken: true,
        checkinDone: true
      },
      actOne: { ...initial.actOne, inventoryRecovered: false, dormHubUnlocked: false }
    };
  }
  if (id === "c2-friend") return createActTwoBase("friend_message_required");
  if (id === "c2-system") return { ...createActTwoBase("system_required"), currentScene: "zjuding" };
  if (id === "c2-inventory") {
    return {
      ...createActTwoBase("inventory_required"),
      runtimeMode: "rpg",
      rpgScene: "dorm_hub"
    };
  }
  if (id === "c2-system-return") {
    const state = createActTwoBase("system_return_required");
    return {
      ...state,
      currentScene: "zjuding",
      runtimeMode: "rpg",
      rpgScene: "dorm_hub",
      actOne: { ...state.actOne, inventoryRecovered: true }
    };
  }
  if ([
    "c2-name", "c2-exercise", "c2-triangle", "c2-weather-water", "c2-mentor-line",
    "c2-arrow-assembly", "c2-balance-shift", "c2-cc98-login", "c2-gamepad-market", "c2-manual-movement",
    "c2-reservation-briefing", "c2-seat-reservation", "c2-dorm-exit"
  ].includes(id)) return createMovementCheckpointState(id);
  if (LIBRARY_CHECKPOINT_ORDER.includes(id as LibraryDeveloperCheckpointId)) {
    return createLibraryCheckpointState(id as LibraryDeveloperCheckpointId);
  }
  if (id === "campus-canteen-entry") {
    const state = createCompletedMovementState();
    return {
      ...state,
      runtimeMode: "rpg",
      rpgScene: "campus_bootstrap",
      rpgCheckpoint: "campus_canteen_gate",
      canteenHunt: {
        ...state.canteenHunt,
        active: false,
        phase: "tracking"
      },
      ui: {
        ...state.ui,
        inventoryOpen: false,
        selectedItem: null,
        seenChapterIntros: ["chapter_one", "chapter_two"]
      }
    };
  }
  if (id === "canteen-hunt" || id.startsWith("c3-canteen-")) {
    return createCanteenCheckpointState(id as CanteenDeveloperCheckpointId);
  }
  if (id.startsWith("c3-theater-")) {
    return createTheaterCheckpointState(id as TheaterDeveloperCheckpointId);
  }
  if (id.startsWith("c3-qizhen-")) {
    return createQizhenCheckpointState(id as QizhenDeveloperCheckpointId);
  }
  if (id.startsWith("c3-interlude-")) {
    return createChapterThreeInterludeCheckpointState(id as ChapterThreeInterludeDeveloperCheckpointId);
  }
  if (id.startsWith("c4-755-")) {
    return createChapterFour755CheckpointState(id as ChapterFour755DeveloperCheckpointId);
  }
  if (isChapter4PrologueDeveloperCheckpoint(id)) {
    // DEV 可直接预览已由第三章半解锁的恢复回放。
    return createChapterFourBaseState(false);
  }
  if (id === "c4-prologue-done") {
    // 过场后第四章起点：序幕已看，进入 A1 门厅。
    const base = createChapterFourBaseState(true);
    return {
      ...base,
      runtimeMode: "rpg",
      rpgScene: "duan_yongping_temporal_maze",
      rpgCheckpoint: "c4_a1_lobby",
      chapter4: { ...base.chapter4, prologueSeen: true, phase: "arrival" },
      ui: {
        ...base.ui,
        inventoryOpen: false,
        selectedItem: null
      }
    };
  }
  if (
    id === "c4-arrival"
    || id === "c4-airflow"
    || id === "c4-main-elevator"
    || id === "c4-wechat-notice"
    || id === "c4-wechat-elevator-audio"
  ) {
    const base = createChapterFourBaseState(true);
    const airflowObserved = id !== "c4-arrival";
    const paperGuidedToElevator = ["c4-main-elevator", "c4-wechat-notice", "c4-wechat-elevator-audio"].includes(id);
    const elevatorHistoryObserved = id === "c4-wechat-elevator-audio";
    const phoneCheckpoint = id === "c4-wechat-notice" || id === "c4-wechat-elevator-audio";
    return {
      ...base,
      currentScene: phoneCheckpoint ? "wechat" : base.currentScene,
      runtimeMode: phoneCheckpoint ? "phone" : "rpg",
      rpgScene: "duan_yongping_temporal_maze",
      rpgCheckpoint: paperGuidedToElevator ? "c4_a1_main_elevator" : "c4_a1_lobby",
      chapter4: {
        ...base.chapter4,
        prologueSeen: true,
        phase: paperGuidedToElevator ? "elevator_track_sync" : airflowObserved ? "airflow_overlay" : "arrival",
        mode: airflowObserved ? "dark" : "light",
        building: "A",
        floor: "A1",
        airflowObserved,
        paperGuidedToElevator,
        elevatorHistoryObserved,
        roomId: paperGuidedToElevator ? "a1_main_elevator" : "a1_lobby",
        clueIds: elevatorHistoryObserved
          ? [
              "a1_airflow_trace",
              "a1_elevator_history_tracks",
              CHAPTER_FOUR_WECHAT_CLUES.officialNoticeRead
            ]
          : airflowObserved ? ["a1_airflow_trace"] : [],
        solvedPuzzleIds: paperGuidedToElevator ? ["airflow_overlay"] : []
      },
      ui: { ...base.ui, controlCenterOpen: false, inventoryOpen: false, selectedItem: null }
    };
  }
  if (id === "c4-elevator-aligned") {
    const base = createChapterFourBaseState(true);
    return {
      ...base,
      runtimeMode: "rpg",
      rpgScene: "duan_yongping_temporal_maze",
      rpgCheckpoint: "c4_a1_main_elevator",
      chapter4: {
        ...base.chapter4,
        prologueSeen: true,
        phase: "elevator_track_sync",
        mode: "light",
        building: "A",
        floor: "A1",
        roomId: "a1_main_elevator",
        buildingTimeSeconds: CHAPTER_FOUR_ELEVATOR.correctReplayStartSeconds,
        airflowObserved: true,
        paperGuidedToElevator: true,
        elevatorHistoryObserved: true,
        elevatorSelectedStartSeconds: CHAPTER_FOUR_ELEVATOR.correctReplayStartSeconds,
        elevatorTrackAligned: true,
        elevatorReplayAttempts: 1,
        elevatorPlayerBoarded: false,
        solvedPuzzleIds: ["airflow_overlay"],
        clueIds: [
          "a1_airflow_trace",
          "a1_elevator_history_tracks",
          CHAPTER_FOUR_WECHAT_CLUES.officialNoticeRead,
          CHAPTER_FOUR_WECHAT_CLUES.elevatorAudioArchived
        ]
      },
      ui: { ...base.ui, controlCenterOpen: false, inventoryOpen: false, selectedItem: null }
    };
  }
  if (id === "c4-a2-arrival" || id === "c4-wechat-student-route") {
    const base = createChapterFourBaseState(true);
    const phoneCheckpoint = id === "c4-wechat-student-route";
    return {
      ...base,
      currentScene: phoneCheckpoint ? "wechat" : base.currentScene,
      runtimeMode: phoneCheckpoint ? "phone" : "rpg",
      rpgScene: "duan_yongping_temporal_maze",
      rpgCheckpoint: "c4_a2_corridor",
      chapter4: {
        ...base.chapter4,
        prologueSeen: true,
        phase: "npc_schedule_route",
        mode: "light",
        building: "A",
        floor: "A2",
        roomId: "a2_corridor",
        buildingTimeSeconds: CHAPTER_FOUR_ELEVATOR.arrivedAtSeconds,
        airflowObserved: true,
        paperGuidedToElevator: true,
        elevatorHistoryObserved: true,
        elevatorSelectedStartSeconds: CHAPTER_FOUR_ELEVATOR.correctReplayStartSeconds,
        elevatorTrackAligned: true,
        elevatorReplayAttempts: 1,
        elevatorPlayerBoarded: true,
        solvedPuzzleIds: ["airflow_overlay", "elevator_track_sync"],
        clueIds: [
          "a1_airflow_trace",
          "a1_elevator_history_tracks",
          "A2_ELEVATOR",
          CHAPTER_FOUR_WECHAT_CLUES.officialNoticeRead,
          CHAPTER_FOUR_WECHAT_CLUES.elevatorAudioArchived
        ]
      },
      ui: { ...base.ui, controlCenterOpen: false, inventoryOpen: false, selectedItem: null }
    };
  }
  if (id === "c4-a2-schedule-observed") {
    const base = createChapterFourBaseState(true);
    return {
      ...base,
      runtimeMode: "rpg",
      rpgScene: "duan_yongping_temporal_maze",
      rpgCheckpoint: "c4_a2_corridor",
      chapter4: {
        ...base.chapter4,
        prologueSeen: true,
        phase: "corridor_bay_reconstruction",
        mode: "dark",
        building: "A",
        floor: "A2",
        roomId: "a2_corridor",
        buildingTimeSeconds: CHAPTER_FOUR_ELEVATOR.arrivedAtSeconds,
        airflowObserved: true,
        paperGuidedToElevator: true,
        elevatorHistoryObserved: true,
        elevatorSelectedStartSeconds: CHAPTER_FOUR_ELEVATOR.correctReplayStartSeconds,
        elevatorTrackAligned: true,
        elevatorReplayAttempts: 1,
        elevatorPlayerBoarded: true,
        solvedPuzzleIds: ["airflow_overlay", "elevator_track_sync", "npc_schedule_route"],
        clueIds: [
          "a1_airflow_trace",
          "a1_elevator_history_tracks",
          "A2_ELEVATOR",
          CHAPTER_FOUR_WECHAT_CLUES.officialNoticeRead,
          CHAPTER_FOUR_WECHAT_CLUES.elevatorAudioArchived,
          CHAPTER_FOUR_WECHAT_CLUES.studentRouteSaved,
          CHAPTER_FOUR_MAZE_CLUES.scheduleObserved
        ]
      },
      ui: { ...base.ui, controlCenterOpen: false, inventoryOpen: false, selectedItem: null }
    };
  }
  if (id === "c4-a3-wayfinding" || id === "c4-wechat-wayfinding") {
    const base = createChapterFourBaseState(true);
    const phoneCheckpoint = id === "c4-wechat-wayfinding";
    return {
      ...base,
      currentScene: phoneCheckpoint ? "wechat" : base.currentScene,
      runtimeMode: phoneCheckpoint ? "phone" : "rpg",
      rpgScene: "duan_yongping_temporal_maze",
      rpgCheckpoint: "c4_a3_wayfinding",
      chapter4: {
        ...base.chapter4,
        prologueSeen: true,
        phase: "wayfinding_fragment_board",
        mode: "dark",
        building: "A",
        floor: "A3",
        roomId: "a3_wayfinding",
        buildingTimeSeconds: CHAPTER_FOUR_MAZE_TIMES.thirdFloorHistorySeconds,
        airflowObserved: true,
        paperGuidedToElevator: true,
        elevatorHistoryObserved: true,
        elevatorSelectedStartSeconds: CHAPTER_FOUR_ELEVATOR.correctReplayStartSeconds,
        elevatorTrackAligned: true,
        elevatorReplayAttempts: 1,
        elevatorPlayerBoarded: true,
        solvedPuzzleIds: [
          "airflow_overlay",
          "elevator_track_sync",
          "npc_schedule_route",
          "corridor_bay_reconstruction"
        ],
        clueIds: [
          "a1_airflow_trace",
          "a1_elevator_history_tracks",
          "A2_ELEVATOR",
          CHAPTER_FOUR_WECHAT_CLUES.officialNoticeRead,
          CHAPTER_FOUR_WECHAT_CLUES.elevatorAudioArchived,
          CHAPTER_FOUR_WECHAT_CLUES.studentRouteSaved,
          CHAPTER_FOUR_MAZE_CLUES.scheduleObserved,
          CHAPTER_FOUR_MAZE_CLUES.partitionWestReconfigured,
          CHAPTER_FOUR_MAZE_CLUES.partitionEastReconfigured,
          CHAPTER_FOUR_MAZE_CLUES.fragmentWestCollected,
          CHAPTER_FOUR_MAZE_CLUES.fragmentEastCollected,
          ...(phoneCheckpoint ? [CHAPTER_FOUR_MAZE_CLUES.oldSignageObserved] : [])
        ]
      },
      ui: { ...base.ui, controlCenterOpen: false, inventoryOpen: false, selectedItem: null }
    };
  }
  if (id === "c4-a2-return-window") {
    const base = createChapterFourBaseState(true);
    return {
      ...base,
      runtimeMode: "rpg",
      rpgScene: "duan_yongping_temporal_maze",
      rpgCheckpoint: "c4_a2_corridor",
      chapter4: {
        ...base.chapter4,
        prologueSeen: true,
        phase: "bridge_floor_discrimination",
        mode: "light",
        building: "A",
        floor: "A2",
        roomId: "a2_corridor",
        buildingTimeSeconds: CHAPTER_FOUR_MAZE_TIMES.secondFloorReturnSeconds,
        airflowObserved: true,
        paperGuidedToElevator: true,
        elevatorHistoryObserved: true,
        elevatorSelectedStartSeconds: CHAPTER_FOUR_ELEVATOR.correctReplayStartSeconds,
        elevatorTrackAligned: true,
        elevatorReplayAttempts: 1,
        elevatorPlayerBoarded: true,
        solvedPuzzleIds: [
          "airflow_overlay",
          "elevator_track_sync",
          "npc_schedule_route",
          "corridor_bay_reconstruction",
          "wayfinding_fragment_board",
          "bridge_floor_discrimination"
        ],
        clueIds: [
          "a1_airflow_trace",
          "a1_elevator_history_tracks",
          "A2_ELEVATOR",
          CHAPTER_FOUR_MAZE_CLUES.scheduleObserved,
          CHAPTER_FOUR_MAZE_CLUES.partitionWestReconfigured,
          CHAPTER_FOUR_MAZE_CLUES.partitionEastReconfigured,
          CHAPTER_FOUR_MAZE_CLUES.fragmentWestCollected,
          CHAPTER_FOUR_MAZE_CLUES.fragmentEastCollected,
          CHAPTER_FOUR_MAZE_CLUES.oldSignageObserved,
          CHAPTER_FOUR_MAZE_CLUES.bridgeHistoryObserved,
          CHAPTER_FOUR_MAZE_CLUES.wayfindingAligned,
          CHAPTER_FOUR_MAZE_CLUES.secondFloorReturnWindowOpen
        ]
      },
      ui: { ...base.ui, controlCenterOpen: false, inventoryOpen: false, selectedItem: null }
    };
  }
  if (id === "c4-stair-echo") {
    const base = createChapterFourBaseState(true);
    return {
      ...base,
      runtimeMode: "rpg",
      rpgScene: "duan_yongping_temporal_maze",
      rpgCheckpoint: "c4_b3_landing",
      chapter4: {
        ...base.chapter4,
        prologueSeen: true,
        phase: "stair_echo_direction",
        mode: "dark",
        building: "B",
        floor: "B3",
        roomId: "b3_landing",
        airflowObserved: true,
        paperGuidedToElevator: true,
        stairEchoObserved: false,
        stairRotationQuarterTurns: 0,
        stairAlignmentSolved: false,
        solvedPuzzleIds: [
          "airflow_overlay", "elevator_track_sync", "npc_schedule_route",
          "corridor_bay_reconstruction", "wayfinding_fragment_board",
          "bridge_floor_discrimination"
        ],
        clueIds: ["a1_airflow_trace"]
      },
      ui: { ...base.ui, inventoryOpen: false, selectedItem: null }
    };
  }
  if (id === "c4-clock-intro" || id === "c4-clock-coarse" || id === "c4-clock-precision" || id === "c4-clock-release") {
    // 第三章完成态 + 第四章 clockCalibration 分阶段快照，直接进入时钟页检查四段流程。
    const base = createChapterFourBaseState(true);
    const seededClock = { ...createInitialGameState().clockCalibration };
    if (id === "c4-clock-coarse") {
      seededClock.phase = "calibrating";
      seededClock.step = "coarse_time";
      seededClock.selectedTargetSeconds = seededClock.targetSeconds;
      seededClock.archiveClueIds = ["room_b2_04", "schedule_0800", "attendance_open"];
      seededClock.displayedSeconds = 28523;
    } else if (id === "c4-clock-precision") {
      seededClock.phase = "calibrating";
      seededClock.step = "seconds_trim";
      seededClock.selectedTargetSeconds = seededClock.targetSeconds;
      seededClock.archiveClueIds = ["room_b2_04", "schedule_0800", "attendance_open"];
      seededClock.coarseLockIds = ["hour", "minute"];
      seededClock.displayedSeconds = 28823;
    } else if (id === "c4-clock-release") {
      seededClock.phase = "release_ready";
      seededClock.step = "phase_lock";
      seededClock.selectedTargetSeconds = seededClock.targetSeconds;
      seededClock.archiveClueIds = ["room_b2_04", "schedule_0800", "attendance_open"];
      seededClock.coarseLockIds = ["hour", "minute"];
      seededClock.driftCorrectedChannelIds = ["gate", "elevator", "room"];
      seededClock.displayedSeconds = seededClock.targetSeconds;
      seededClock.phaseLockHits = 0;
      seededClock.phaseLockAttempts = 0;
    }
    return {
      ...base,
      runtimeMode: "phone",
      currentScene: "clock",
      clockCalibration: seededClock,
      chapter4: {
        ...base.chapter4,
        prologueSeen: true,
        phase: "clock_phase_lock",
        cycle: 2,
        floor: "B2",
        building: "B",
        roomId: "b2_04",
        solvedPuzzleIds: [
          "airflow_overlay", "elevator_track_sync", "npc_schedule_route",
          "corridor_bay_reconstruction", "wayfinding_fragment_board",
          "bridge_floor_discrimination", "stair_echo_direction", "multicam_video_edit",
          "echo_action_record", "dual_lift_logistics", "warm_air_balance", "route_schedule"
        ]
      },
      ui: {
        ...base.ui,
        inventoryOpen: false,
        selectedItem: null
      }
    };
  }

  throw new Error(`unhandled_developer_checkpoint:${id}`);
}

export function applyDeveloperCheckpoint(
  store: GameStore,
  requestedId: DeveloperCheckpointRequestId,
  storage: Storage = window.sessionStorage,
  source: "panel" | "url" = "panel",
  restoreActiveSession = false
): void {
  const id = resolveCheckpointId(requestedId);
  if (!id) return;
  const resumeConfirmedTaskCard = id === "c4-prologue-task-card"
    && restoreActiveSession
    && storage.getItem(DEVELOPER_CHAPTER4_TASK_CARD_CONFIRMED_KEY) === "1";
  if (!storage.getItem(DEVELOPER_BACKUP_KEY)) {
    storage.setItem(DEVELOPER_BACKUP_KEY, JSON.stringify(store.getState()));
  }
  storage.setItem(DEVELOPER_ACTIVE_KEY, id);
  storage.setItem(DEVELOPER_SOURCE_KEY, source);
  const defenseStartMs = id === "c3-canteen-block-2"
    ? 30_000
    : id === "c3-canteen-block-3"
      ? 50_000
      : 0;
  storage.setItem(DEVELOPER_CANTEEN_DEFENSE_START_KEY, String(defenseStartMs));
  if (id.startsWith("c3-qizhen-rhythm-")) {
    storage.setItem(DEVELOPER_QIZHEN_RHYTHM_SPAWN_KEY, id.slice("c3-qizhen-rhythm-".length));
  } else {
    storage.removeItem(DEVELOPER_QIZHEN_RHYTHM_SPAWN_KEY);
  }
  if (isChapter4PrologueDeveloperCheckpoint(id)) {
    storage.setItem(DEVELOPER_CHAPTER4_PROLOGUE_OFFSET_KEY, String(CHAPTER4_PROLOGUE_DEVELOPER_OFFSETS[id]));
  } else {
    storage.removeItem(DEVELOPER_CHAPTER4_PROLOGUE_OFFSET_KEY);
  }
  if (id !== "c4-prologue-task-card" || !resumeConfirmedTaskCard) {
    storage.removeItem(DEVELOPER_CHAPTER4_TASK_CARD_CONFIRMED_KEY);
  }
  store.setState(() => resumeConfirmedTaskCard
    ? createChapterFour755CheckpointState("c4-755-opening")
    : createDeveloperCheckpointState(id));
}

export function restoreDeveloperBackup(store: GameStore, storage: Storage = window.sessionStorage): boolean {
  const raw = storage.getItem(DEVELOPER_BACKUP_KEY);
  if (!raw) return false;
  try {
    store.setState(() => JSON.parse(raw) as GameState);
  } catch {
    return false;
  }
  storage.removeItem(DEVELOPER_BACKUP_KEY);
  storage.removeItem(DEVELOPER_ACTIVE_KEY);
  storage.removeItem(DEVELOPER_SOURCE_KEY);
  storage.removeItem(DEVELOPER_CANTEEN_DEFENSE_START_KEY);
  storage.removeItem(DEVELOPER_CHAPTER4_PROLOGUE_OFFSET_KEY);
  storage.removeItem(DEVELOPER_CHAPTER4_TASK_CARD_CONFIRMED_KEY);
  storage.removeItem(DEVELOPER_QIZHEN_RHYTHM_SPAWN_KEY);
  return true;
}

export function getDeveloperCanteenDefenseStart(storage: Storage = window.sessionStorage): number {
  const stored = Number(storage.getItem(DEVELOPER_CANTEEN_DEFENSE_START_KEY) ?? 0);
  return Number.isFinite(stored) ? Math.max(0, Math.min(50_000, stored)) : 0;
}

export function getDeveloperChapter4PrologueOffset(storage: Storage = window.sessionStorage): number {
  const checkpoint = getActiveDeveloperCheckpoint(storage);
  if (!checkpoint || !isChapter4PrologueDeveloperCheckpoint(checkpoint)) return 0;
  const raw = storage.getItem(DEVELOPER_CHAPTER4_PROLOGUE_OFFSET_KEY);
  if (raw === null) return CHAPTER4_PROLOGUE_DEVELOPER_OFFSETS[checkpoint];
  const stored = Number(raw);
  return Number.isFinite(stored) && stored >= 0
    ? stored
    : CHAPTER4_PROLOGUE_DEVELOPER_OFFSETS[checkpoint];
}

export function markDeveloperChapter4PrologueTaskCardConfirmed(
  storage: Storage = window.sessionStorage
): void {
  if (getActiveDeveloperCheckpoint(storage) !== "c4-prologue-task-card") return;
  storage.setItem(DEVELOPER_CHAPTER4_TASK_CARD_CONFIRMED_KEY, "1");
}

export function getActiveDeveloperCheckpoint(storage: Storage = window.sessionStorage): DeveloperCheckpointId | null {
  return resolveCheckpointId(storage.getItem(DEVELOPER_ACTIVE_KEY));
}

export function getDeveloperCc98Mode(storage: Storage = window.sessionStorage): "exchange" | "investigation" | "theater_ticket" | null {
  const checkpoint = getActiveDeveloperCheckpoint(storage);
  if (checkpoint === "c2-gamepad-market") return "exchange";
  if (checkpoint === "c2-cc98-upload" || checkpoint === "c2-bd-rise") return "investigation";
  if (
    checkpoint === "c3-theater-ticket-request"
    || checkpoint === "c3-theater-ticket-accepted"
    || checkpoint === "c3-theater-ticket-delivered"
  ) return "theater_ticket";
  return null;
}

function checkpointFromLegacyParams(params: URLSearchParams): DeveloperCheckpointId | null {
  const scene = params.get("scene") as SceneId | null;
  const page = params.get("zjudingPage") as ZjudingPage | null;
  const phase = params.get("libraryFinalsPhase") as LibraryFinalsPhase | null;
  if (phase === "library_route_unlocked") return "c2-library-gate";
  if (phase === "library_entered") return scene === "zjuding" ? "c2-catalog" : "c2-entrance-record";
  if (phase === "occupied_seat_found") return "c2-occupancy-note";
  if (phase === "evidence_gathering") {
    if (scene === "photos") return "c2-photo-report";
    if (scene === "tiyi") return "c2-tiyi-proof";
    if (scene === "cc98") return "c2-cc98-upload";
    if (page === "library_catalog") return "c2-catalog";
    return "c2-catalog";
  }
  if (phase === "bd_briefing" || phase === "top_ten_rising") return "c2-bd-rise";
  if (phase === "top_ten_reached") return "c2-recovery-form";
  if (phase === "recovery_application") return "c2-pass-generate";
  if (phase === "pass_ready") return "c2-pass-apply";
  if (phase === "backpack_removed") return "c2-seat-sit";
  if (phase === "seat_recovered") return "c2-seat-dialogue";
  if (phase === "friend_contacted") return "c2-chapter-exit";
  if (scene === "photos") return "c2-photo-report";
  if (scene === "tiyi") return "c2-exercise";
  if (scene === "cc98") return "c2-gamepad-market";
  if (scene === "zjuding") return page === "library_recovery" ? "c2-recovery-form" : page === "library_catalog" ? "c2-catalog" : "c2-system";
  if (scene === "phone_home") return "c1-code-hunt";
  if (scene === "ending") return "c1-narrator-block";
  return null;
}

export function applyDeveloperCheckpointFromUrl(
  store: GameStore,
  location: Location,
  storage: Storage = window.sessionStorage
): DeveloperCheckpointId | null {
  const params = new URLSearchParams(location.search);
  if (params.get("dev") === "0") {
    return null;
  }
  const explicitCheckpoint = params.get("devCheckpoint");
  if (explicitCheckpoint !== null) {
    const requested = resolveCheckpointId(explicitCheckpoint);
    if (!requested) return null;
    const restoreActiveSession = getActiveDeveloperCheckpoint(storage) === requested;
    applyDeveloperCheckpoint(store, requested, storage, "url", restoreActiveSession);
    return requested;
  }
  const requested = checkpointFromLegacyParams(params);
  if (requested) {
    const restoreActiveSession = getActiveDeveloperCheckpoint(storage) === requested;
    applyDeveloperCheckpoint(store, requested, storage, "url", restoreActiveSession);
    return requested;
  }
  const active = getActiveDeveloperCheckpoint(storage);
  if (active) {
    const source = storage.getItem(DEVELOPER_SOURCE_KEY);
    applyDeveloperCheckpoint(store, active, storage, source === "url" ? "url" : "panel", true);
  }
  return requested;
}
