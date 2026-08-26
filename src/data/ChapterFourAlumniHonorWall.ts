import suBuqingPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/su_buqing_v01.png";
import zhuKezhenPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/zhu_kezhen_v01.png";
import luYongxiangPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/lu_yongxiang_v01.png";
import chenJiangongPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/chen_jiangong_v01.png";
import tanJiazhenPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/tan_jiazhen_v01.png";
import chengKaijiaPortraitUrl from "../assets/rpg/portraits/chapter4/alumni/cheng_kaijia_v01.png";

export type ChapterFourAlumniFigureId =
  | "su_buqing"
  | "zhu_kezhen"
  | "lu_yongxiang"
  | "chen_jiangong"
  | "tan_jiazhen"
  | "cheng_kaijia";

export type ChapterFourAlumniTargetId =
  | "a3_alumni_su_buqing"
  | "a3_alumni_zhu_kezhen"
  | "a3_alumni_lu_yongxiang"
  | "a3_alumni_chen_jiangong"
  | "a3_alumni_tan_jiazhen"
  | "a3_alumni_cheng_kaijia";

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
  /** Source-pixel frame bounds measured against the 1672×941 A3 base plate. */
  frameBounds: Readonly<{ x: number; y: number; width: number; height: number }>;
  /** Source-pixel portrait matte within the existing baked gold frame. */
  imageBounds: Readonly<{ x: number; y: number; width: number; height: number }>;
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
      "1931 年回国后任浙江大学数学系副教授、教授及系主任。",
      "与陈建功共同形成有影响力的“陈苏学派”，培养了一批数学人才。",
      "抗战时期随浙江大学西迁，在艰苦条件下继续教学与研究。"
    ],
    sourceLabel: "浙江大学·求是大家",
    sourceUrl: "https://www.zju.edu.cn/2021/0611/c41533a2386590/pagem.htm",
    portraitTextureKey: "chapter4-alumni-su-buqing",
    portraitUrl: suBuqingPortraitUrl,
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
      "1936—1949 年任浙江大学校长，领导学校完成西迁并坚持办学。",
      "任内学校由 3 个学院、16 个系发展为 7 个学院、27 个系。",
      "他在新生入学时提出两个问题，要求学生思考求学目的与成人方向。"
    ],
    sourceLabel: "浙江大学国际联合学院·竺老两问",
    sourceUrl: "https://www.intl.zju.edu.cn/zh-hans/news/17289",
    portraitTextureKey: "chapter4-alumni-zhu-kezhen",
    portraitUrl: zhuKezhenPortraitUrl,
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
      "1964 年毕业于浙江大学机械系，后留校任教并长期从事流体传动与控制研究。",
      "1988—1995 年任浙江大学校长，推动学校教育、科研与管理改革。",
      "1991 年当选中国科学院学部委员，1994 年当选中国工程院院士。"
    ],
    sourceLabel: "浙江大学·历任校长",
    sourceUrl: "https://www.zju.edu.cn/2016/0728/c32708a1512243/pagem.htm",
    portraitTextureKey: "chapter4-alumni-lu-yongxiang",
    portraitUrl: luYongxiangPortraitUrl,
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
      "1929 年起在浙江大学任教，主持数学系建设与人才培养。",
      "与苏步青共同培育了中国现代数学的重要学术群体。",
      "西迁时期坚持教学和研究，奠定了浙大数学学科的早期基础。"
    ],
    sourceLabel: "浙江大学档案馆·俊彩星驰长廊",
    sourceUrl: "https://acv.zju.edu.cn/site/wszt_jcxc.html",
    portraitTextureKey: "chapter4-alumni-chen-jiangong",
    portraitUrl: chenJiangongPortraitUrl,
    frameBounds: { x: 574, y: 108, width: 38, height: 60 },
    imageBounds: { x: 580, y: 114, width: 26, height: 46 }
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
    frameBounds: { x: 616, y: 108, width: 38, height: 60 },
    imageBounds: { x: 622, y: 114, width: 26, height: 46 }
  },
  {
    id: "cheng_kaijia",
    targetId: "a3_alumni_cheng_kaijia",
    name: "程开甲",
    years: "1918—2018",
    role: "核物理学家、人民科学家",
    biography: [
      "1937 级浙江大学物理系校友，1941 年毕业。",
      "是我国核武器研究的领导者之一，也是核试验事业的开拓者。",
      "获两弹一星功勋奖章、国家最高科学技术奖、八一勋章与人民科学家国家荣誉称号。"
    ],
    sourceLabel: "浙江大学·程开甲先生诞辰 105 周年纪念会",
    sourceUrl: "https://www.zju.edu.cn/2023/0804/c32862a2787683/pagem.htm",
    portraitTextureKey: "chapter4-alumni-cheng-kaijia",
    portraitUrl: chengKaijiaPortraitUrl,
    frameBounds: { x: 658, y: 108, width: 38, height: 60 },
    imageBounds: { x: 664, y: 114, width: 26, height: 46 }
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
