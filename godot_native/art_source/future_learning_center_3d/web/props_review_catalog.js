/** Source notes are design provenance, not manufacturer CAD certification. */
export const REVIEW_ASSETS = Object.freeze([
 {id:'caliper_150',family:'small_props',name:'数显卡尺',dimensions:'长 233 mm；量爪厚 3.5 mm',source:'沿用 asset_catalog 和 build_scene.py 的尺寸参照；不是厂家 CAD。',note:'空白 LCD；静态样板，不表示测量结果。'},
 {id:'screwdriver_3x100',family:'small_props',name:'一字螺丝刀',dimensions:'长 204 mm；柄径 23 mm；刀头 3 × 0.5 mm',source:'沿用 asset_catalog 和 build_scene.py 的尺寸参照。',note:'配色不表示绝缘性能或电气认证。'},
 {id:'display_tray',family:'small_props',name:'展示托盘',dimensions:'420 × 320 × 40 mm（宽 × 深 × 高）',source:'沿用 Bottle group display tray 场景设计，非厂家或现场实测。',note:'静态展示托盘，无新增交互含义。'},
 {id:'printer_enclosure_study',family:'lab_tools',name:'封闭打印设备方案',dimensions:'492 × 514 × 626 mm（宽 × 深 × 高）',source:'沿用 H2C 尺寸；2026-11-02 复核规格文字。外观来自现有场景方案，不是型号精确复刻。',note:'内部导轨和床板为示意；屏幕空白，无工作状态。'},
 {id:'laser_enclosure_study',family:'lab_tools',name:'封闭激光设备方案',dimensions:'1000 × 639 × 268 mm（宽 × 深 × 高）',source:'沿用 asset_catalog 的 P2S 尺寸摘录；本轮厂家 wiki 超时，外观未核实。',note:'仅封闭机壳方案；不模拟激光或安全联锁。'},
 {id:'bench_power_supply',family:'lab_tools',name:'台式电源方案',dimensions:'300 × 250 × 280 mm（宽 × 深 × 高）',source:'沿用 electronics_lab 台面设计；没有品牌或现场尺寸断言。',note:'端子未接线，屏幕空白；无额定参数、极性或操作功能。'}
].map(a=>Object.freeze({...a,base:`./assets/models/${a.family}/${a.id}/`,doc:`../sources/${a.family==='small_props'?'small_props':'lab_tools'}_batch_20261102.md`})));
export function reviewLevel(pixels){return pixels>=150?0:pixels>=55?1:2;}
