import suBuqingPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/su_buqing_v01.png";
import zhuKezhenPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/zhu_kezhen_v01.png";
import luYongxiangPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/lu_yongxiang_v01.png";
import chenJiangongPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/chen_jiangong_v01.png";
import tanJiazhenPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/tan_jiazhen_v01.png";
import chengKaijiaPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/cheng_kaijia_v01.png";
import wangGanchangPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/wang_ganchang_v01.png";
import beiShizhangPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/bei_shizhang_v01.png";
import guChaohaoPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/gu_chaohao_v01.png";
import liZhengdaoPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/li_zhengdao_v01.png";
import panYunhePortraitUrl from "../assets/rpg/portraits/chapter4/alumni/pan_yunhe_v01.png";
import hanZhenxiangPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/han_zhenxiang_v01.png";
import xiaDaoxingPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/xia_daoxing_v01.png";
import panJingfuPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/pan_jingfu_v01.png";
import wangYuanPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/wang_yuan_v01.png";
import chenYizhangPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/chen_yizhang_v01.png";
import linJundePortraitUrl from "../assets/rpg/portraits/chapter4/alumni/lin_junde_v01.png";
import tanQixiangPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/tan_qixiang_v01.png";
import zhengShusenPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/zheng_shusen_v01.png";
import yangWeiPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/yang_wei_v01.png";

export type ChapterFourAlumniFigureId =
  | "su_buqing"
  | "zhu_kezhen"
  | "lu_yongxiang"
  | "chen_jiangong"
  | "tan_jiazhen"
  | "cheng_kaijia"
  | "wang_ganchang"
  | "bei_shizhang"
  | "gu_chaohao"
  | "li_zhengdao"
  | "pan_yunhe"
  | "han_zhenxiang"
  | "xia_daoxing"
  | "pan_jingfu"
  | "wang_yuan"
  | "chen_yizhang"
  | "lin_junde"
  | "tan_qixiang"
  | "zheng_shusen"
  | "yang_wei";

export type ChapterFourAlumniTargetId =
  | "a3_alumni_su_buqing"
  | "a3_alumni_zhu_kezhen"
  | "a3_alumni_lu_yongxiang"
  | "a3_alumni_chen_jiangong"
  | "a3_alumni_tan_jiazhen"
  | "a3_alumni_cheng_kaijia"
  | "a1_alumni_wang_ganchang"
  | "a1_alumni_bei_shizhang"
  | "a1_alumni_gu_chaohao"
  | "a1_alumni_li_zhengdao"
  | "a1_alumni_pan_yunhe"
  | "a1_alumni_han_zhenxiang"
  | "a1_alumni_xia_daoxing"
  | "a1_alumni_pan_jingfu"
  | "a1_alumni_wang_yuan"
  | "a1_alumni_chen_yizhang"
  | "a1_alumni_lin_junde"
  | "a1_alumni_tan_qixiang"
  | "a1_alumni_zheng_shusen"
  | "a3_alumni_yang_wei";

export interface ChapterFourAlumniHonorWallFigure {
  id: ChapterFourAlumniFigureId;
  targetId: ChapterFourAlumniTargetId;
  name: string;
  years: string;
  role: string;
  biography: readonly string[];
  sourceLabel: string;
  sourceUrl: string;
  portraitTextureKey: string;
  portraitUrl: string;
  floor: 1 | 3;
  /** Source-pixel frame bounds measured against the floor's 1672×941 base plate. */
  frameBounds: Readonly<{ x: number; y: number; width: number; height: number }>;
  /** Source-pixel portrait matte within the existing baked gold frame. */
  imageBounds: Readonly<{ x: number; y: number; width: number; height: number }>;
  /** Three small A3 portraits are runtime frames inside one baked display case. */
  drawRuntimeFrame?: boolean;
}

/**
 * Every entry is a documented Zhejiang University historical figure.
 * The wall is presented as a school-history honor wall because two entries
 * served primarily as faculty or president rather than as degree alumni.
 */
export const CHAPTER_FOUR_ALUMNI_HONOR_WALL = Object.freeze([
  {
    id: "su_buqing",
    targetId: "a3_alumni_su_buqing",
    name: "苏步青",
    years: "1902—2003",
    role: "数学家、教育家",
    biography: [
      "1931年回国后任浙江大学数学系副教授、教授及系主任。",
      "与陈建功共同形成有影响力的“陈苏学派”，培养了一批数学人才。",
      "抗战时期随浙江大学西迁，在艰苦条件下继续教学与研究。"
    ],
    sourceLabel: "浙江大学·求是大家",
    sourceUrl: "https://www.zju.edu.cn/2021/0611/c41533a2386590/pagem.htm",
    portraitTextureKey: "chapter4-alumni-su-buqing",
    portraitUrl: suBuqingPortraitUrl,
    floor: 3,
    frameBounds: { x: 748, y: 583, width: 43, height: 62 },
    imageBounds: { x: 755, y: 589, width: 29, height: 48 }
  },
  {
    id: "zhu_kezhen",
    targetId: "a3_alumni_zhu_kezhen",
    name: "竺可桢",
    years: "1890—1974",
    role: "气象学家、地理学家、教育家",
    biography: [
      "1936—1949年任浙江大学校长，领导学校完成西迁并坚持办学。",
      "任内学校由 3 个学院、16 个系发展为 7 个学院、27 个系。",
      "他在新生入学时提出两个问题，要求学生思考求学目的与成人方向。"
    ],
    sourceLabel: "浙江大学国际联合学院·竺老两问",
    sourceUrl: "https://www.intl.zju.edu.cn/zh-hans/news/17289",
    portraitTextureKey: "chapter4-alumni-zhu-kezhen",
    portraitUrl: zhuKezhenPortraitUrl,
    floor: 3,
    frameBounds: { x: 812, y: 583, width: 43, height: 62 },
    imageBounds: { x: 819, y: 589, width: 29, height: 48 }
  },
  {
    id: "lu_yongxiang",
    targetId: "a3_alumni_lu_yongxiang",
    name: "路甬祥",
    years: "1942—",
    role: "流体传动与控制学家、教育家",
    biography: [
      "1964年毕业于浙江大学机械系，后留校任教并长期从事流体传动与控制研究。",
      "1988—1995年任浙江大学校长，推动学校教育、科研与管理改革。",
      "1991年当选中国科学院学部委员，1994年当选中国工程院院士。"
    ],
    sourceLabel: "浙江大学·历任校长",
    sourceUrl: "https://www.zju.edu.cn/2016/0728/c32708a1512243/pagem.htm",
    portraitTextureKey: "chapter4-alumni-lu-yongxiang",
    portraitUrl: luYongxiangPortraitUrl,
    floor: 3,
    frameBounds: { x: 877, y: 583, width: 43, height: 62 },
    imageBounds: { x: 884, y: 589, width: 29, height: 48 }
  },
  {
    id: "chen_jiangong",
    targetId: "a3_alumni_chen_jiangong",
    name: "陈建功",
    years: "1893—1971",
    role: "数学家、教育家",
    biography: [
      "1929年起在浙江大学任教，主持数学系建设与人才培养。",
      "与苏步青共同培育了中国现代数学的重要学术群体。",
      "西迁时期坚持教学和研究，奠定了浙大数学学科的早期基础。"
    ],
    sourceLabel: "浙江大学档案馆·俊彩星驰长廊",
    sourceUrl: "https://acv.zju.edu.cn/site/wszt_jcxc.html",
    portraitTextureKey: "chapter4-alumni-chen-jiangong",
    portraitUrl: chenJiangongPortraitUrl,
    floor: 3,
    frameBounds: { x: 574, y: 108, width: 38, height: 60 },
    imageBounds: { x: 580, y: 114, width: 26, height: 46 },
    drawRuntimeFrame: true
  },
  {
    id: "tan_jiazhen",
    targetId: "a3_alumni_tan_jiazhen",
    name: "谈家桢",
    years: "1909—2008",
    role: "遗传学家、教育家",
    biography: [
      "曾任浙江大学生物系教授，在西迁途中继续组织遗传学教学与实验。",
      "在缺少自来水、电灯和专业设备的条件下，带领学生用简易器材坚持研究。",
      "后长期推动中国现代遗传学的学科建设与人才培养。"
    ],
    sourceLabel: "浙江大学·求是精神薪火相传",
    sourceUrl: "https://www.zju.edu.cn/2021/0611/c59196a2386352/pagem.htm",
    portraitTextureKey: "chapter4-alumni-tan-jiazhen",
    portraitUrl: tanJiazhenPortraitUrl,
    floor: 3,
    frameBounds: { x: 616, y: 108, width: 38, height: 60 },
    imageBounds: { x: 622, y: 114, width: 26, height: 46 },
    drawRuntimeFrame: true
  },
  {
    id: "cheng_kaijia",
    targetId: "a3_alumni_cheng_kaijia",
    name: "程开甲",
    years: "1918—2018",
    role: "核物理学家、人民科学家",
    biography: [
      "1937级浙江大学物理系校友，1941年毕业。",
      "是我国核武器研究的领导者之一，也是核试验事业的开拓者。",
      "获两弹一星功勋奖章、国家最高科学技术奖、八一勋章与人民科学家国家荣誉称号。"
    ],
    sourceLabel: "浙江大学·程开甲先生诞辰 105 周年纪念会",
    sourceUrl: "https://www.zju.edu.cn/2023/0804/c32862a2787683/pagem.htm",
    portraitTextureKey: "chapter4-alumni-cheng-kaijia",
    portraitUrl: chengKaijiaPortraitUrl,
    floor: 3,
    frameBounds: { x: 658, y: 108, width: 38, height: 60 },
    imageBounds: { x: 664, y: 114, width: 26, height: 46 },
    drawRuntimeFrame: true
  },
  {
    id: "wang_ganchang",
    targetId: "a1_alumni_wang_ganchang",
    name: "王淦昌",
    years: "1907—1998",
    role: "核物理学家、两弹一星功勋科学家",
    biography: [
      "1936年起任浙江大学物理系教授，并随学校西迁坚持教学与研究。",
      "长期从事核物理研究，是我国核科学与核武器研制的重要开拓者之一。",
      "1999年获追授两弹一星功勋奖章。"
    ],
    sourceLabel: "浙江大学·求是大家",
    sourceUrl: "https://www.zju.edu.cn/2021/0511/c41533a2359881/pagem.htm",
    portraitTextureKey: "chapter4-alumni-wang-ganchang",
    portraitUrl: wangGanchangPortraitUrl,
    floor: 1,
    frameBounds: { x: 104, y: 65, width: 40, height: 56 },
    imageBounds: { x: 110, y: 71, width: 28, height: 44 }
  },
  {
    id: "bei_shizhang",
    targetId: "a1_alumni_bei_shizhang",
    name: "贝时璋",
    years: "1903—2009",
    role: "生物学家、生物物理学奠基人",
    biography: [
      "1930年在浙江大学创建生物学系，并在西迁时期持续组织教学与研究。",
      "1958年参与创建中国科学院生物物理研究所并任首任所长。",
      "长期推动我国细胞学、实验生物学与生物物理学发展。"
    ],
    sourceLabel: "浙江大学·求是大家",
    sourceUrl: "https://www.zju.edu.cn/2021/0618/c61624a2396272/pagem.htm",
    portraitTextureKey: "chapter4-alumni-bei-shizhang",
    portraitUrl: beiShizhangPortraitUrl,
    floor: 1,
    frameBounds: { x: 181, y: 65, width: 40, height: 56 },
    imageBounds: { x: 187, y: 71, width: 28, height: 44 }
  },
  {
    id: "gu_chaohao",
    targetId: "a1_alumni_gu_chaohao",
    name: "谷超豪",
    years: "1926—2012",
    role: "数学家、教育家",
    biography: [
      "1943年进入浙江大学龙泉分校，后在数学系学习并任教。",
      "在偏微分方程、微分几何和数学物理等领域取得系统成果。",
      "2009年获国家最高科学技术奖。"
    ],
    sourceLabel: "浙江大学·求是大家",
    sourceUrl: "https://www.zju.edu.cn/2022/0105/c41533a2469070/pagem.htm",
    portraitTextureKey: "chapter4-alumni-gu-chaohao",
    portraitUrl: guChaohaoPortraitUrl,
    floor: 1,
    frameBounds: { x: 259, y: 65, width: 40, height: 56 },
    imageBounds: { x: 265, y: 71, width: 28, height: 44 }
  },
  {
    id: "li_zhengdao",
    targetId: "a1_alumni_li_zhengdao",
    name: "李政道",
    years: "1926—2024",
    role: "物理学家、诺贝尔物理学奖获得者",
    biography: [
      "1943年进入迁至湄潭的浙江大学物理系学习。",
      "求学期间受到束星北、王淦昌等先生指导，奠定理论物理基础。",
      "长期支持中国基础科学研究与青年人才培养。"
    ],
    sourceLabel: "浙江大学·李政道纪念",
    sourceUrl: "https://www.zju.edu.cn/2025/0805/c79822a3073114/page.htm",
    portraitTextureKey: "chapter4-alumni-li-zhengdao",
    portraitUrl: liZhengdaoPortraitUrl,
    floor: 1,
    frameBounds: { x: 340, y: 65, width: 40, height: 56 },
    imageBounds: { x: 346, y: 71, width: 28, height: 44 }
  },
  {
    id: "pan_yunhe",
    targetId: "a1_alumni_pan_yunhe",
    name: "潘云鹤",
    years: "1946—",
    role: "计算机应用专家、教育家",
    biography: [
      "1981年在浙江大学获得硕士学位后留校任教。",
      "1995—2006年任浙江大学校长，参与推动四校合并后的学科建设。",
      "长期研究人工智能、计算机美术与智能城市。"
    ],
    sourceLabel: "浙江大学·历任校长",
    sourceUrl: "https://www.zju.edu.cn/2016/0728/c32708a1512167/pagem.htm",
    portraitTextureKey: "chapter4-alumni-pan-yunhe",
    portraitUrl: panYunhePortraitUrl,
    floor: 1,
    frameBounds: { x: 427, y: 65, width: 40, height: 56 },
    imageBounds: { x: 433, y: 71, width: 28, height: 44 }
  },
  {
    id: "han_zhenxiang",
    targetId: "a1_alumni_han_zhenxiang",
    name: "韩祯祥",
    years: "1930—2024",
    role: "电力系统专家、教育家",
    biography: [
      "1951年毕业于浙江大学电机系并留校任教。",
      "1984—1988年任浙江大学校长，推动教学、科研与国际交流。",
      "长期从事电力系统稳定、控制与人才培养。"
    ],
    sourceLabel: "浙江大学·韩祯祥院士纪念",
    sourceUrl: "https://www.zju.edu.cn/2020/0509/c50658a2094505/pagem.htm",
    portraitTextureKey: "chapter4-alumni-han-zhenxiang",
    portraitUrl: hanZhenxiangPortraitUrl,
    floor: 1,
    frameBounds: { x: 512, y: 65, width: 40, height: 56 },
    imageBounds: { x: 518, y: 71, width: 28, height: 44 }
  },
  {
    id: "xia_daoxing",
    targetId: "a1_alumni_xia_daoxing",
    name: "夏道行",
    years: "1930—",
    role: "数学家",
    biography: [
      "1952年进入浙江大学数学系攻读研究生，师从陈建功先生。",
      "在泛函分析、广义函数和数学物理等领域作出重要贡献。",
      "1980年当选中国科学院学部委员。"
    ],
    sourceLabel: "浙江大学·求是大家",
    sourceUrl: "https://www.zju.edu.cn/2018/1026/c33007a1511678/pagem.htm",
    portraitTextureKey: "chapter4-alumni-xia-daoxing",
    portraitUrl: xiaDaoxingPortraitUrl,
    floor: 1,
    frameBounds: { x: 596, y: 65, width: 40, height: 56 },
    imageBounds: { x: 602, y: 71, width: 28, height: 44 }
  },
  {
    id: "pan_jingfu",
    targetId: "a1_alumni_pan_jingfu",
    name: "潘镜芙",
    years: "1930—2023",
    role: "船舶设计专家",
    biography: [
      "1952年毕业于浙江大学电机系。",
      "长期主持我国导弹驱逐舰研制，推动舰船总体设计与系统集成发展。",
      "1995年当选中国工程院院士。"
    ],
    sourceLabel: "浙江大学档案馆·潘镜芙",
    sourceUrl: "https://acv.zju.edu.cn/site/bgxw_view.html?id=2707",
    portraitTextureKey: "chapter4-alumni-pan-jingfu",
    portraitUrl: panJingfuPortraitUrl,
    floor: 1,
    frameBounds: { x: 1170, y: 65, width: 40, height: 56 },
    imageBounds: { x: 1176, y: 71, width: 28, height: 44 }
  },
  {
    id: "wang_yuan",
    targetId: "a1_alumni_wang_yuan",
    name: "王元",
    years: "1930—2021",
    role: "数学家",
    biography: [
      "1952年毕业于浙江大学数学系。",
      "在数论、数值分析与组合设计等领域取得重要成果。",
      "与华罗庚共同发展的数论方法被称为华—王方法。"
    ],
    sourceLabel: "浙江大学·求是大家",
    sourceUrl: "https://www.zju.edu.cn/2018/1026/c33007a1511685/pagem.htm",
    portraitTextureKey: "chapter4-alumni-wang-yuan",
    portraitUrl: wangYuanPortraitUrl,
    floor: 1,
    frameBounds: { x: 1245, y: 65, width: 40, height: 56 },
    imageBounds: { x: 1251, y: 71, width: 28, height: 44 }
  },
  {
    id: "chen_yizhang",
    targetId: "a1_alumni_chen_yizhang",
    name: "陈宜张",
    years: "1927—",
    role: "神经生理学家、医学教育家",
    biography: [
      "1952年毕业于浙江大学医学院，是学院首届毕业生之一。",
      "长期研究神经生理学与神经内分泌调控。",
      "曾任浙江医科大学校长并推动医学教育发展。"
    ],
    sourceLabel: "浙江大学·陈宜张",
    sourceUrl: "https://www.zju.edu.cn/2016/0505/c32861a1520708/page.htm",
    portraitTextureKey: "chapter4-alumni-chen-yizhang",
    portraitUrl: chenYizhangPortraitUrl,
    floor: 1,
    frameBounds: { x: 1320, y: 65, width: 40, height: 56 },
    imageBounds: { x: 1326, y: 71, width: 28, height: 44 }
  },
  {
    id: "lin_junde",
    targetId: "a1_alumni_lin_junde",
    name: "林俊德",
    years: "1938—2012",
    role: "爆炸力学与核试验工程专家",
    biography: [
      "1960年毕业于浙江大学机械系。",
      "扎根大漠五十余年，参加我国全部核试验并负责关键测试技术。",
      "1993年当选中国工程院院士，2018年被列入全军挂像英模。"
    ],
    sourceLabel: "浙江大学·林俊德院士纪念",
    sourceUrl: "https://www.zju.edu.cn/2021/0525/c58319a2377991/pagem.htm",
    portraitTextureKey: "chapter4-alumni-lin-junde",
    portraitUrl: linJundePortraitUrl,
    floor: 1,
    frameBounds: { x: 1396, y: 65, width: 40, height: 56 },
    imageBounds: { x: 1402, y: 71, width: 28, height: 44 }
  },
  {
    id: "tan_qixiang",
    targetId: "a1_alumni_tan_qixiang",
    name: "谭其骧",
    years: "1911—1992",
    role: "历史地理学家",
    biography: [
      "1940—1950年在浙江大学史地系任教。",
      "在历史地理、疆域沿革与人口迁移研究方面影响深远。",
      "主持编绘《中国历史地图集》，推动现代历史地理学科建设。"
    ],
    sourceLabel: "浙江大学档案馆·俊彩星驰长廊",
    sourceUrl: "https://acv.zju.edu.cn/site/wszt_jcxc.html",
    portraitTextureKey: "chapter4-alumni-tan-qixiang",
    portraitUrl: tanQixiangPortraitUrl,
    floor: 1,
    frameBounds: { x: 1472, y: 65, width: 40, height: 56 },
    imageBounds: { x: 1478, y: 71, width: 28, height: 44 }
  },
  {
    id: "zheng_shusen",
    targetId: "a1_alumni_zheng_shusen",
    name: "郑树森",
    years: "1950—",
    role: "器官移植专家",
    biography: [
      "长期在浙江大学从事肝胆胰外科与器官移植临床、科研和教学。",
      "推动我国肝移植、多器官联合移植与相关技术体系发展。",
      "2001年当选中国工程院院士。"
    ],
    sourceLabel: "浙江大学个人主页·郑树森",
    sourceUrl: "https://person.zju.edu.cn/zhengshusen",
    portraitTextureKey: "chapter4-alumni-zheng-shusen",
    portraitUrl: zhengShusenPortraitUrl,
    floor: 1,
    frameBounds: { x: 1549, y: 65, width: 40, height: 56 },
    imageBounds: { x: 1555, y: 71, width: 28, height: 44 }
  },
  {
    id: "yang_wei",
    targetId: "a3_alumni_yang_wei",
    name: "杨卫",
    years: "1954—",
    role: "固体力学专家、教育家",
    biography: [
      "长期在浙江大学从事固体力学、微纳米力学与交叉力学研究。",
      "2006—2013年任浙江大学校长，推动学科交叉与工程教育发展。",
      "2003年当选中国科学院院士。"
    ],
    sourceLabel: "浙江大学个人主页·杨卫",
    sourceUrl: "https://person.zju.edu.cn/yangwei",
    portraitTextureKey: "chapter4-alumni-yang-wei",
    portraitUrl: yangWeiPortraitUrl,
    floor: 3,
    frameBounds: { x: 526, y: 627, width: 73, height: 99 },
    imageBounds: { x: 536, y: 637, width: 53, height: 79 }
  }
] as const satisfies readonly ChapterFourAlumniHonorWallFigure[]);

export const CHAPTER_FOUR_ZHU_QUESTIONS = Object.freeze([
  {
    id: "purpose",
    prompt: "第一问：到浙大来做什么？",
    options: [
      { id: "seek_truth", label: "追问事实与方法" },
      { id: "solve_real_problems", label: "用所学解决真实问题" },
      { id: "serve_public", label: "为公共需要承担责任" }
    ]
  },
  {
    id: "person",
    prompt: "第二问：将来毕业后要做什么样的人？",
    options: [
      { id: "responsible", label: "对工作和他人负责" },
      { id: "clear_minded", label: "保持独立判断与证据诚实" },
      { id: "public_service", label: "把能力放到社会需要上" }
    ]
  }
] as const);

export function getChapterFourAlumniFigureByTargetId(
  targetId: string
): ChapterFourAlumniHonorWallFigure | null {
  return CHAPTER_FOUR_ALUMNI_HONOR_WALL.find((figure) => figure.targetId === targetId) ?? null;
}
