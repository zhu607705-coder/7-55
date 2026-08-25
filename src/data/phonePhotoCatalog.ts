import libraryTakeoutSoyUrl from "../assets/ui/photo-evidence/library-roll/library_roll_01_takeout_soy.webp";
import libraryDormMealUrl from "../assets/ui/photo-evidence/library-roll/library_roll_02_dorm_meal.webp";
import libraryRainyBreakfastUrl from "../assets/ui/photo-evidence/library-roll/library_roll_03_rainy_breakfast.webp";
import librarySnackUrl from "../assets/ui/photo-evidence/library-roll/library_roll_04_library_snack.webp";
import libraryCanteenTakeoutUrl from "../assets/ui/photo-evidence/library-roll/library_roll_05_canteen_takeout.webp";
import librarySeat022ClueUrl from "../assets/ui/photo-evidence/library-roll/library_roll_06_seat_022_clue.webp";
import campusGateUrl from "../assets/ui/photo-evidence/campus-life/campus_zijingang_gate_cloudy.webp";
import qizhenDockUrl from "../assets/ui/photo-evidence/campus-life/campus_qizhen_dock_morning.webp";
import crescentAfterRainUrl from "../assets/ui/photo-evidence/campus-life/campus_crescent_after_rain.webp";
import studyRoomSnackUrl from "../assets/ui/photo-evidence/campus-life/life_study_room_late_snack.webp";
import bikeBasketRaincoatUrl from "../assets/ui/photo-evidence/campus-life/life_bike_basket_raincoat.webp";
import canteenQueueUrl from "../assets/ui/photo-evidence/campus-life/life_canteen_queue.webp";

export type PhonePhotoAlbumId = "library_roll" | "campus_life";
export type PhonePhotoStoryRole = "decorative" | "library_clue";

export interface PhonePhotoEntry {
  id: string;
  albumId: PhonePhotoAlbumId;
  storyRole: PhonePhotoStoryRole;
  title: string;
  file: string;
  imageUrl: string;
  detail: string;
  capturedAt: string;
  location: string;
  sourceNote: "checked_in_original" | "generated_from_public_campus_facts";
}

export const LIBRARY_CLUE_PHOTO_ID = "seat_022_clue";

/**
 * One catalog keeps decorative photos separate from controller-owned evidence.
 * Only the stable `library_clue` entry may unlock the existing item report flow.
 */
export const PHONE_PHOTO_CATALOG: readonly PhonePhotoEntry[] = [
  {
    id: "takeout_soy",
    albumId: "library_roll",
    storyRole: "decorative",
    title: "窗边豆浆",
    file: "IMG_0033.JPG",
    imageUrl: libraryTakeoutSoyUrl,
    detail: "高数草稿还摊在桌上，豆浆已经冷了。",
    capturedAt: "06月18日 08:43",
    location: "基础馆",
    sourceNote: "checked_in_original"
  },
  {
    id: "dorm_meal",
    albumId: "library_roll",
    storyRole: "decorative",
    title: "寝室晚饭",
    file: "IMG_0034.JPG",
    imageUrl: libraryDormMealUrl,
    detail: "校园卡压着充电线，桌面没有收拾。",
    capturedAt: "06月19日 19:16",
    location: "紫云宿舍",
    sourceNote: "checked_in_original"
  },
  {
    id: "rainy_breakfast",
    albumId: "library_roll",
    storyRole: "decorative",
    title: "雨后早餐",
    file: "IMG_0035.JPG",
    imageUrl: libraryRainyBreakfastUrl,
    detail: "长椅还有水迹，纸袋放在靠内侧。",
    capturedAt: "06月22日 07:28",
    location: "东区",
    sourceNote: "checked_in_original"
  },
  {
    id: "library_snack",
    albumId: "library_roll",
    storyRole: "decorative",
    title: "自习间隙",
    file: "IMG_0036.JPG",
    imageUrl: librarySnackUrl,
    detail: "面包包装拆了一半，保温杯放在右边。",
    capturedAt: "06月24日 16:02",
    location: "基础馆",
    sourceNote: "checked_in_original"
  },
  {
    id: "canteen_takeout",
    albumId: "library_roll",
    storyRole: "decorative",
    title: "食堂打包",
    file: "IMG_0037.JPG",
    imageUrl: libraryCanteenTakeoutUrl,
    detail: "餐巾纸折在盒饭旁边，桌面很干净。",
    capturedAt: "06月26日 18:51",
    location: "东区食堂",
    sourceNote: "checked_in_original"
  },
  {
    id: LIBRARY_CLUE_PHOTO_ID,
    albumId: "library_roll",
    storyRole: "library_clue",
    title: "022 旧照",
    file: "IMG_0038.JPG",
    imageUrl: librarySeat022ClueUrl,
    detail: "同一只 022 书包。侧袋里的半包纸，在 07:55 时已经存在。",
    capturedAt: "06月28日 07:55",
    location: "基础馆二楼南区",
    sourceNote: "checked_in_original"
  },
  {
    id: "campus_zijingang_gate_cloudy",
    albumId: "campus_life",
    storyRole: "decorative",
    title: "校门口的阴天",
    file: "IMG_0041.JPG",
    imageUrl: campusGateUrl,
    detail: "树荫压得很低，骑车的人都从拱门边绕过去。",
    capturedAt: "07月01日 14:32",
    location: "紫金港校区",
    sourceNote: "generated_from_public_campus_facts"
  },
  {
    id: "campus_qizhen_dock_morning",
    albumId: "campus_life",
    storyRole: "decorative",
    title: "启真湖早晨",
    file: "IMG_0042.JPG",
    imageUrl: qizhenDockUrl,
    detail: "浮桥旁有两圈新波纹，车还停在柳树下面。",
    capturedAt: "07月02日 09:12",
    location: "启真湖",
    sourceNote: "generated_from_public_campus_facts"
  },
  {
    id: "campus_crescent_after_rain",
    albumId: "campus_life",
    storyRole: "decorative",
    title: "雨后的月牙楼",
    file: "IMG_0043.JPG",
    imageUrl: crescentAfterRainUrl,
    detail: "地砖还在反光，伞已经可以收起来了。",
    capturedAt: "07月03日 16:47",
    location: "月牙楼",
    sourceNote: "generated_from_public_campus_facts"
  },
  {
    id: "life_study_room_late_snack",
    albumId: "campus_life",
    storyRole: "decorative",
    title: "晚自习加餐",
    file: "IMG_0044.JPG",
    imageUrl: studyRoomSnackUrl,
    detail: "耳机缠在本子边，饭盒还留着一点热气。",
    capturedAt: "07月05日 21:06",
    location: "学习空间",
    sourceNote: "generated_from_public_campus_facts"
  },
  {
    id: "life_bike_basket_raincoat",
    albumId: "campus_life",
    storyRole: "decorative",
    title: "车筐里的雨衣",
    file: "IMG_0045.JPG",
    imageUrl: bikeBasketRaincoatUrl,
    detail: "雨停得很快，车筐上还挂着水珠。",
    capturedAt: "07月06日 12:23",
    location: "宿舍区",
    sourceNote: "generated_from_public_campus_facts"
  },
  {
    id: "life_canteen_queue",
    albumId: "campus_life",
    storyRole: "decorative",
    title: "午饭排队",
    file: "IMG_0046.JPG",
    imageUrl: canteenQueueUrl,
    detail: "前面只剩三个人，番茄鸡蛋面先端到了。",
    capturedAt: "07月07日 11:54",
    location: "东区食堂",
    sourceNote: "generated_from_public_campus_facts"
  }
] as const;

export function selectPhonePhotos(albumId: PhonePhotoAlbumId): readonly PhonePhotoEntry[] {
  return PHONE_PHOTO_CATALOG.filter((photo) => photo.albumId === albumId);
}

export function selectLibraryRollPhotos(): readonly PhonePhotoEntry[] {
  return PHONE_PHOTO_CATALOG;
}
