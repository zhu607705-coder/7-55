import { ScenePlaceholder, type SceneComponentProps } from "../../components/ScenePlaceholder";
import type { SceneId } from "../../core/types";
import { AlarmScene } from "./P00_Alarm";
import { WakeScene } from "./P01_Desktop";
import { CampusCardScene } from "./P04_CampusCard";
import { Cc98Scene } from "./P02_CC98";
import { TiyiScene } from "./P06_Tiyi";
import { WeatherScene } from "./P07_Weather";
import { BonsaiScene } from "./P10_Bonsai";
import { CheckinScene } from "./P11_Checkin";
import { EndingScene } from "./P12_Ending";
import { PhoneHomeScene } from "./P13_PhoneHome";
import { WechatScene } from "./P14_Wechat";
import { ZjudingScene } from "./P15_Zjuding";
import { BikeArcadeScene } from "./P16_BikeArcade";
import { ChapterTransitionScene } from "./P17_ChapterTransition";
import { PhotosScene } from "./P18_Photos";

const SCENE_META: Record<SceneId, { label: string; contract: string }> = {
  alarm: {
    label: "P00 闹钟",
    contract: "07:55 闹钟，振动+音效，关闭后进入起床场景。"
  },
  desktop: {
    label: "P01 起床",
    contract: "再睡5分钟 → 旁白 → 起床蠢货！！！ → 手机主界面。"
  },
  phone_home: {
    label: "P13 手机主界面",
    contract: "主屏：设置齿轮/塔楼钥匙孔/天气水滴/盆栽入口/微信弹窗。"
  },
  wechat: {
    label: "P14 微信",
    contract: "朋友聊天触发小影散码；列表中朋友头像藏斜线谜题（P03）。"
  },
  cc98: {
    label: "P02 CC98",
    contract: "仅校园网可进入；热门话题列表与剧情帖子内容保存到本机。"
  },
  zjuding: {
    label: "P15 浙大钉",
    contract: "仅校园网可进入；承载系统入口、图书馆预约和移动图书馆证据流程。"
  },
  tiyi: {
    label: "P06 浙大体艺",
    contract: "仅流量可进入；先开启课外锻炼，图书馆阶段再核对 7 / 47 / 3 到馆材料。"
  },
  weather: {
    label: "P07 天气",
    contract: "第二章天气页：收集水滴并用于松开导师头像上的竖线。"
  },
  photos: {
    label: "P18 照片",
    contract: "IMG_0755.JPG 亮度识别；亮度不高于 20% 时生成物品识别报告。"
  },
  campus_card: {
    label: "P04 校园卡余额",
    contract: "第二章取得校园卡后显示余额，并接受右移箭头。"
  },
  bike_arcade: {
    label: "P16 求是潮 755",
    contract: "独立竖屏三车道骑行小游戏；躲避拥堵，抵达 755 米。"
  },
  chapter_transition: {
    label: "P17 章节过渡",
    contract: "第三章完成后的稳定出口；显示完成记录并承接下一章。"
  },
  checkin: {
    label: "P11 校务签到",
    contract: "校园网输入 0798 → 短暂成功 → 经度与纬度错误 → 红闪和七秒黑屏。"
  },
  bonsai: {
    label: "P10 盆栽",
    contract: "浇水/照光/施肥三步平行 → 开花 → 点花得 d4=8。"
  },
  ending: {
    label: "P12 序章结算",
    contract: "移动错误框拦截三次旁白路径，完成长按锁定和系统对话后返回手机主页。"
  }
};

const REAL_SCENES: Partial<Record<SceneId, (props: SceneComponentProps) => JSX.Element>> = {
  alarm: AlarmScene,
  desktop: WakeScene,
  phone_home: PhoneHomeScene,
  wechat: WechatScene,
  cc98: Cc98Scene,
  zjuding: ZjudingScene,
  tiyi: TiyiScene,
  weather: WeatherScene,
  photos: PhotosScene,
  campus_card: CampusCardScene,
  bike_arcade: BikeArcadeScene,
  chapter_transition: ChapterTransitionScene,
  checkin: CheckinScene,
  bonsai: BonsaiScene,
  ending: EndingScene
};

export function getPhoneScene(sceneId: SceneId) {
  const realScene = REAL_SCENES[sceneId];
  if (realScene) {
    return realScene;
  }

  const meta = SCENE_META[sceneId];

  return function PhoneScene(props: SceneComponentProps) {
    return <ScenePlaceholder {...props} sceneId={sceneId} label={meta.label} contract={meta.contract} />;
  };
}

export const phoneSceneIds = Object.keys(SCENE_META) as SceneId[];
