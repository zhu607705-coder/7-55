import type { GameState, ItemId, RpgSceneId } from "../../core/types";

export type RpgItemUseStatus = "ready" | "locked" | "passive" | "elsewhere";

export interface RpgItemUseGuidance {
  status: RpgItemUseStatus;
  title: string;
  detail: string;
  targetLabel?: string;
}

const ELSEWHERE_HINTS: Partial<Record<ItemId, string>> = {
  campusCard: "校园卡在手机应用和地图入口中读取",
  occupancyNote: "前往 CC98 搜索栏提交占座纸条",
  archivedLeaveRule: "前往 CC98 证据上传区提交旧版规定",
  bagNonPersonProof: "前往 CC98 或恢复申请页面提交证明",
  seat022Receipt: "前往 CC98 或恢复申请页面提交凭据",
  libraryPresenceProof: "前往 CC98 或恢复申请页面提交证明",
  sparklingWater: "到食堂左下角混合台倒入玻璃杯",
  lemonTea: "到食堂左下角混合台倒入玻璃杯",
  blackCoffee: "到食堂左下角混合台倒入玻璃杯",
  badDrink: "在食堂地图中拖到自己身上喝掉",
  dailySpecialSparklingWater: "到食堂第五个打饭窗口上方的宣传灯箱空杯位",
  pickupTicket0755: "靠近取餐窗口后按空格使用；纸包鸡需在深色第三窗口交票",
  canteenRealBun: "食物彩蛋，没有剧情用途",
  canteenCluelessSoyMilk: "食物彩蛋，没有剧情用途",
  canteenEdgeEgg: "食物彩蛋，没有剧情用途",
  canteenUselessCongee: "食物彩蛋，没有剧情用途",
  theaterTicketHalfA: "与另一半临时票合成，无需拖到场景",
  theaterTicketHalfB: "与另一半临时票合成，无需拖到场景",
  theaterProgramOpening: "到剧院灯光控制台打开节目单排序",
  theaterProgramSpotlight: "到剧院灯光控制台打开节目单排序",
  theaterProgramFinale: "到剧院灯光控制台打开节目单排序",
  wetProgram: "前往 CC98 或馆藏检索提交湿节目单",
  bridgeKeyword: "前往校园地图搜索栏提交地点关键词",
  reflectionKeyword: "前往校园地图搜索栏提交地点关键词",
  lakeKeyword: "前往校园地图搜索栏提交地点关键词",
  reflectionCoordinate: "坐标会在启真湖布置假纸条时自动核验"
};

const ready = (targetLabel: string, detail = "靠近目标，把道具拖到物体本身后松手。"): RpgItemUseGuidance => ({
  status: "ready",
  title: "当前可以使用",
  detail,
  targetLabel
});

const locked = (detail: string, targetLabel?: string): RpgItemUseGuidance => ({
  status: "locked",
  title: "当前使用条件未满足",
  detail,
  targetLabel
});

const passive = (detail: string): RpgItemUseGuidance => ({
  status: "passive",
  title: "无需拖动",
  detail
});

const elsewhere = (itemId: ItemId): RpgItemUseGuidance => ({
  status: "elsewhere",
  title: "本场景没有使用点",
  detail: ELSEWHERE_HINTS[itemId] ?? "保留该道具，跟随当前任务前往对应页面或场景。"
});

export function selectRpgItemUseGuidance(
  state: GameState,
  runtimeScene: RpgSceneId,
  itemId: ItemId
): RpgItemUseGuidance {
  if (runtimeScene === "duan_yongping_temporal_maze") {
    const chapter = state.chapter4;
    if (itemId === "campusCard") {
      if (chapter.phase === "morning_checkin" && !chapter.checkinCardAccepted) {
        return ready("签到校园卡读卡器");
      }
      return elsewhere(itemId);
    }
    if (itemId === "attendanceRecordPaper") {
      if (chapter.phase === "morning_checkin" && !chapter.checkinPaperAccepted) {
        return ready("签到记录纸槽");
      }
      if (chapter.phase === "return_to_clock" && !chapter.factIds.includes("final_minute_installed")) {
        return locked("先把黄铜分针组件装回大厅旧钟，再去签到口。", "大厅旧钟表盘");
      }
      if (chapter.phase === "blackout_light_grid" && !chapter.factIds.includes("paper_temporarily_out_of_inventory")) {
        return passive("旧钟接近 07:55 时，这张纸会被剧情自动带走。");
      }
      return elsewhere(itemId);
    }
    if (itemId === "oldClockHourHand") {
      return chapter.phase === "bakery_hour_hand" && !chapter.factIds.includes("hour_hand_installed")
        ? ready("旧钟时针插槽")
        : elsewhere(itemId);
    }
    if (itemId === "clockPositioningPlate") {
      return chapter.phase === "room204_restore" && !chapter.factIds.includes("positioning_plate_installed")
        ? ready("旧钟定位盘插槽")
        : elsewhere(itemId);
    }
    if (itemId === "shortPryBar") {
      if (chapter.phase !== "maintenance_repair") return elsewhere(itemId);
      if (!chapter.factIds.includes("cart_wheel_inspected")) {
        return locked("先靠近保洁车检查卡住的车轮。", "清洁车车轮");
      }
      return !chapter.factIds.includes("cart_wheel_cover_opened")
        ? ready("清洁车轮罩")
        : elsewhere(itemId);
    }
    if (itemId === "universalLubricatingOil") {
      if (chapter.phase !== "maintenance_repair") return elsewhere(itemId);
      if (!chapter.factIds.includes("cart_wheel_repaired")) {
        return ready("清洁车车轮", "先把润滑油拖到清洁车车轮，修好后仍会保留半瓶。");
      }
      if (!chapter.factIds.includes("clock_gear_repaired")) {
        return ready("旧钟齿轮", "把剩下的半瓶润滑油拖到旧钟齿轮。");
      }
      return passive("润滑油的剧情用途已经完成。");
    }
    if (itemId === "finalMinute") {
      return chapter.phase === "return_to_clock" && !chapter.factIds.includes("final_minute_installed")
        ? ready("大厅旧钟表盘", "靠近旧钟，把黄铜分针组件拖到可见表盘内松手。")
        : elsewhere(itemId);
    }
  }

  if (runtimeScene === "dorm_hub" && itemId === "gamepad") {
    if (state.actOne.movementEnabled) return passive("手柄已经连接并等待方向输入校验。");
    if (!state.actOne.characterNamed) return locked("先在部门黄页完成角色命名。", "角色");
    if (!state.actOne.exerciseStarted) return locked("先在浙大体艺开始课外锻炼。", "角色");
    if (!state.actOne.gamepadPurchased) return locked("先在 CC98 完成手柄购买。", "角色");
    return ready("角色", "把手柄拖到角色身体范围内，并在人物轮廓内松手。");
  }

  if (runtimeScene === "library_interior") {
    const puzzle = state.ui.libraryFinalsPuzzle;
    if (itemId === "callNumber755") {
      return state.ui.libraryFinalsPhase === "evidence_gathering"
        && puzzle.callNumberCollected
        && !puzzle.archivedRuleCollected
        ? ready("文学书架 755 段")
        : locked("先完成馆藏检索并取得索书号 755。", "文学书架 755 段");
    }
    if (itemId === "itemRecognitionReport") {
      if (puzzle.lostFoundStage === "scanning") return passive("前台正在人工核验并盖章，等待流程完成。");
      return state.ui.libraryFinalsPhase === "evidence_gathering"
        && puzzle.itemReportGenerated
        && puzzle.lostFoundStage === "ready"
        && !puzzle.nonPersonProofStamped
        ? ready("前台工作人员", "靠近前台，把物品识别报告拖到工作人员与盖章台之间。")
        : locked("先在照片页面生成物品识别报告。", "前台工作人员");
    }
    if (itemId === "rightArrow") {
      return !puzzle.seatReceiptCollected
        ? ready("022 桌面夹缝")
        : passive("022 座位凭据已经取出，右移箭头已完成最后用途。");
    }
    if (itemId === "seatReleasePass") {
      return state.ui.libraryFinalsPhase === "pass_ready"
        && puzzle.evictionPassGenerated
        && !puzzle.backpackEvicted
        ? ready("022 占座书包")
        : locked("先完成公开公示和三项恢复材料，取得清退 PASS。", "022 占座书包");
    }
  }

  if (runtimeScene === "canteen_interior" && itemId === "pickupTicket0755") {
    if (state.canteenHunt.phase !== "pickup_search") {
      return locked("取餐号只在取餐阶段使用。先完成当前食堂任务。", "1、2、3号取餐窗口验票槽");
    }
    return ready("取餐窗口", "不需要拖拽或站位。浅色操作可在对应窗口交票；深色观察可补充查看窗口残影。");
  }

  if (
    runtimeScene === "canteen_interior"
    && state.canteenHunt.active
    && ["tray_search", "drink_mix", "menu_order", "pickup_search"].includes(state.canteenHunt.phase)
  ) {
    if (
      !state.canteenHunt.promoDrinkPlaced
      && !state.canteenHunt.queueGapOpened
      && ["sparklingWater", "lemonTea", "blackCoffee"].includes(itemId)
    ) {
      return ready("左下角混合台", "靠近混合台打开调配窗口，再点击对应饮料倒入大玻璃杯。");
    }
    if (
      itemId === "dailySpecialSparklingWater"
      && !state.canteenHunt.promoDrinkPlaced
      && !state.canteenHunt.queueGapOpened
    ) {
      return ready("第五个打饭窗口下方的宣传板空杯位", "先靠近宣传板，再把今日新品气泡水拖进发光的空杯位。");
    }
    if (itemId === "badDrink") {
      return ready("玩家自己", "把难喝饮料拖到人物身上可以喝掉，但不会推进剧情。");
    }
  }

  if (runtimeScene === "campus_bootstrap" && state.canteenHunt.phase === "chase_ready") {
    if (itemId === "greaseTissue") {
      if (state.canteenHunt.bikeLockCleaned) return passive("车锁已经擦净，2 元现金可以用于付款。");
      if (state.canteenHunt.mode === "dark") return locked("切回浅色模式后再清洁车锁。", "共享单车车锁");
      return ready("共享单车车锁");
    }
    if (itemId === "cafeteriaWages") {
      if (!state.canteenHunt.bikeLockCleaned) return locked("先用纸巾清洁车锁。", "共享单车");
      if (state.canteenHunt.mode === "dark") return locked("切回浅色模式后付款。", "共享单车");
      if (state.wallet.cashCents < 200) return locked("现金余额不足 2 元。回食堂完成收餐盘，领取 2 元和油渍纸巾。", "共享单车");
      return ready("共享单车", "把 2 元现金拖到共享单车范围内，并在车身上松手。");
    }
  }

  if (runtimeScene === "theater_interior") {
    const theater = state.theaterHunt;
    if (itemId === "greaseTissue") {
      if (theater.posterCleaned) return passive("海报玻璃已经擦净。");
      if (theater.phase !== "entry_ticket") return locked("擦拭海报只在剧院入口取票阶段开放。", "入口海报");
      if (theater.mode !== "light") return locked("切回浅色模式后擦拭海报玻璃。", "入口海报");
      return ready("入口海报玻璃", "从海报右侧靠近，把油渍纸巾拖到玻璃污渍上。");
    }
    if (itemId === "temporaryTheaterTicket") {
      if (theater.phase === "entry_ticket" && !theater.admitted) {
        if (theater.mode !== "light") {
          return locked("深色模式只读取异常；切回浅色操作后再把票拖入读票器。", "检票闸机右侧读票器");
        }
        return ready(
          "检票闸机右侧读票器",
          "靠近读票器，把票拖到右侧验票槽内松手。"
        );
      }
      if (theater.phase === "prop_setup") {
        if (theater.propBoxOpened) return passive("票据扫描已经完成，临时观演票已从道具栏移除。");
        if (theater.mode !== "light") {
          return locked("深色模式可查看道具箱残影；切回浅色模式后扫描票据。", "道具箱旁票据扫描器");
        }
        return ready(
          "道具箱旁票据扫描器",
          "靠近道具箱旁的扫描器，把票拖到扫描口内松手。"
        );
      }
      if (theater.admitted && ["program_search"].includes(theater.phase)) {
        return passive("入场核验已完成。票会在后台道具箱阶段再次使用，先完成当前节目单任务。");
      }
      return passive("当前流程不需要再次拖动临时观演票。");
    }
    if (itemId === "fluorescentBrush") {
      if (theater.paperDusted) return passive("后台纸屑已经显影，荧光粉刷已从道具栏移除。");
      if (theater.phase !== "prop_setup" || !theater.propBoxOpened) {
        return locked("先在后台完成票据扫描并打开道具箱，取得荧光粉刷。", "后台通风口");
      }
      if (theater.mode !== "light") {
        return locked("切回浅色操作后，把荧光粉刷拖入通风口。", "后台通风口");
      }
      return ready("后台通风口", "靠近通风口，把荧光粉刷拖到栅格上。");
    }
    if (itemId === "spotlightRemote") {
      if (theater.phase !== "spotlight_ready" || !theater.paperDusted) {
        return locked("先完成后台纸屑显影，灯光控制台随后开放。", "灯光控制台");
      }
      if (theater.mode !== "light") {
        return locked("深色模式只观察追光残影；切回浅色操作后启动灯光控制台。", "灯光控制台");
      }
      return ready("灯光控制台", "从下方靠近控制台，把追光灯遥控器拖到控制面板上。");
    }
    if (["theaterProgramOpening", "theaterProgramSpotlight", "theaterProgramFinale"].includes(itemId)) {
      return passive("靠近灯光控制台打开节目单排序，无需把节目单拖到控制台。");
    }
  }

  if (runtimeScene === "qizhen_lake") {
    const lake = state.qizhenLake;
    const requireLight = (targetLabel: string): RpgItemUseGuidance | null => lake.mode === "light"
      ? null
      : locked("深色观察只记录坐标。切回浅色操作后使用道具。", targetLabel);

    if (itemId === "decoyPaper") {
      if (lake.decoyBaitAttached) return passive("假纸条已经固定到鱼钩上并从道具栏移除。");
      if (!["lake_exploration", "tool_chain"].includes(lake.phase) || !lake.rodFound || !state.items.fishingRod) {
        return locked("先在大湖浮排边找到钓鱼竿。", "纸条倒影装饵框");
      }
      if (lake.zone !== "open_water") {
        return locked("先划回大湖，再寻找纸条倒影装饵框。", "纸条倒影装饵框");
      }
      return requireLight("纸条倒影装饵框")
        ?? ready("纸条倒影水纹", "把船划到纸条倒影附近，再把假纸条拖到对应水纹。");
    }

    if (itemId === "fishingRod") {
      if (lake.phase === "paper_capture" && state.items.swanMagnet) {
        if (lake.zone !== "swan_cove") {
          return locked("先划到黑天鹅围栏区。", "船头磁吸组合位");
        }
        return requireLight("工具装配框")
          ?? ready("船头工具区", "让船头对准工具区，把钓鱼竿拖到天鹅磁扣旁。");
      }
      if (lake.zone !== "open_water") {
        return locked("当前抛竿点位于大湖，先划回大湖。", "可用抛竿点");
      }
      if (!lake.decoyBaitAttached) {
        return locked("先把假纸条拖到钓鱼竿装饵框。", "钓鱼竿装饵框");
      }
      return requireLight("可用抛竿点")
        ?? ready("可用抛竿点", "把船划到目标水纹附近后抛竿。深色观察可补充记录位置，直接钓纸条会显示失败原因。");
    }

    if (itemId === "rustedLockerKey") {
      return lake.lockerOpened
        ? passive("码头储物柜已经打开。")
        : lake.zone !== "dock"
          ? locked("返回小码头，储物柜锁孔只在码头区域开放。", "码头储物柜")
        : requireLight("码头储物柜")
          ?? ready("码头储物柜", "返回小码头，靠近柜门，把钥匙拖到锁孔。");
    }

    if (itemId === "nylonCord" || itemId === "brokenNetFrame") {
      if (lake.netCombined) return passive("两件道具已组合为临时抄网。");
      const counterpart = itemId === "nylonCord" ? "brokenNetFrame" : "nylonCord";
      if (!state.items[counterpart]) {
        return locked("先取得另一个组合部件。", "工具装配框");
      }
      if (lake.zone !== "open_water") {
        return locked("回到大湖的浮标组合位。", "工具装配框");
      }
      return requireLight("工具装配框")
        ?? ready("工具装配框", "把尼龙绳或破损网框拖入装配框。");
    }

    if (itemId === "improvisedDipNet") {
      return lake.feedTinRetrieved
        ? passive("密封饲料盒已经取回。")
        : lake.zone !== "channel"
          ? locked("进入浮排直河道，再靠近浮排系绳。", "浮排系绳下方")
        : requireLight("浮排系绳下方")
          ?? ready("浮排系绳下方", "进入直河道，让船头对准浮排下方，把抄网拖到密封饲料盒上。");
    }

    if (itemId === "sealedFeedTin") {
      return lake.feedTinOpened
        ? passive("饲料盒已经打开。")
        : lake.zone !== "channel"
          ? locked("返回浮排直河道，开盒位在浮排上缘。", "浮排开盒位")
        : requireLight("浮排开盒位")
          ?? ready("浮排硬边", "让船头对准浮排硬边，把密封饲料盒拖到边缘上开启。");
    }

    if (itemId === "fishFeedPellets") {
      if (lake.zone !== "open_water") {
        return locked("回到大湖的鱼群水纹位置。", "鱼群水纹");
      }
      return requireLight("鱼群水纹")
        ?? ready("鱼群水纹", "把饲料颗粒拖入鱼群水纹；深色观察可补充记录位置。");
    }

    if (itemId === "smallCarp") {
      return requireLight("黑天鹅投喂区")
        ?? (lake.zone === "swan_cove"
          ? ready("黑天鹅", "让船头对准黑天鹅，把小鲤鱼拖到天鹅面前。")
          : locked("划到黑天鹅围栏区。", "黑天鹅投喂区"));
    }

    if (itemId === "swanMagnet") {
      if (lake.zone !== "swan_cove") {
        return locked("划到黑天鹅围栏区的船头装配位。", "工具装配框");
      }
      return state.items.fishingRod
        ? requireLight("工具装配框")
          ?? ready("工具装配框", "把磁性扣拖到钓鱼竿所在的装配框。")
        : locked("钓鱼竿当前不在道具栏。", "工具装配框");
    }

    if (itemId === "magneticFishingRod") {
      if (lake.paperCaptured) return passive("纸条已经被固定，进入返航追逐。");
      if (lake.zone !== "swan_cove") {
        return locked("纸条本体水纹位于黑天鹅围栏区。", "纸条本体水纹");
      }
      return requireLight("纸条本体水纹")
        ?? ready("纸条本体水纹", "把磁性钓鱼竿拖入纸条本体水纹；深色观察可补充记录位置。");
    }
  }

  return elsewhere(itemId);
}
