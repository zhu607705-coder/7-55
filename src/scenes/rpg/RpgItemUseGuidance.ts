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
  sparklingWater: "到食堂右上饮料区混合台倒入玻璃杯",
  lemonTea: "到食堂右上饮料区混合台倒入玻璃杯",
  blackCoffee: "到食堂右上饮料区混合台倒入玻璃杯",
  badDrink: "在食堂地图中拖到自己身上喝掉",
  dailySpecialSparklingWater: "先放到食堂第三个餐口宣传板，守出口时还可减速纸条一次",
  pickupTicket0755: "按取餐单前往对应窗口；纸包鸡需在深色第三窗口拖票",
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

const ready = (targetLabel: string, detail = "拖到场景中的高亮区域，并在框内松手。"): RpgItemUseGuidance => ({
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
  if (runtimeScene === "dorm_hub" && itemId === "gamepad") {
    if (state.actOne.movementEnabled) return passive("手柄已经连接，使用方向键完成第一次手动移动。");
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
        ? ready("前台工作人员", "把物品识别报告拖到信息台工作人员和柜台之间的高亮区域。")
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
      return locked("取餐号只在取餐阶段使用。先完成当前食堂任务。", "1–5号取餐窗口");
    }
    const option = state.canteenHunt.orderedMenuOption;
    const optionWindow = { A: "1", B: "2", C: "4", D: "3", E: "5" }[option ?? "D"];
    if (option !== "D") {
      return locked(
        `站到${optionWindow}号窗口前的数字标记，按空格交出取餐号。普通餐会正常出餐。`,
        `${optionWindow}号取餐窗口`
      );
    }
    if (!state.canteenHunt.pickupTimeErrorSeen) {
      return locked("先在浅色走到3号窗口前，按空格交票并看完时间报错。", "3号取餐窗口");
    }
    if (state.canteenHunt.mode !== "dark") {
      return locked("时间报错已经出现。切到深色观察，再检查3号窗口的残影阿姨。", "3号取餐窗口");
    }
    if (!state.canteenHunt.pickupDarkClueRead) {
      return locked("站到3号窗口前的数字标记，按空格确认残影阿姨的验票提示。", "3号取餐窗口");
    }
    return ready("3号窗口验票框", "人物站进3号数字标记后，把0755取餐号拖进窗口上方发光验票框。");
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
      return ready("右上饮料区混合台", "靠近右上混合台打开调配窗口，再点击对应饮料倒入大玻璃杯。");
    }
    if (
      itemId === "dailySpecialSparklingWater"
      && !state.canteenHunt.promoDrinkPlaced
      && !state.canteenHunt.queueGapOpened
    ) {
      return ready("第三个餐口宣传板空杯位", "先靠近第三个餐口宣传板，再把今日新品气泡水拖进发光空杯位。");
    }
    if (itemId === "badDrink") {
      return ready("玩家自己", "把难喝饮料拖到人物身上可以喝掉，但不会推进剧情。");
    }
  }

  if (
    runtimeScene === "canteen_interior"
    && itemId === "dailySpecialSparklingWater"
    && state.canteenHunt.phase === "exit_blocking"
  ) {
    if (state.canteenHunt.defenseDrinkUsed) return passive("气泡减速已经使用，本轮不会再次生效。");
    if (state.canteenHunt.mode !== "light") {
      return locked("切回浅色操作，再把今日新品拖进食堂地图。", "食堂地面");
    }
    return ready("食堂地面", "把今日新品拖进食堂地图任意地面，产生两秒气泡并减速纸条一次。");
  }

  if (runtimeScene === "campus_bootstrap" && state.canteenHunt.phase === "chase_ready") {
    if (itemId === "greaseTissue") {
      if (state.canteenHunt.bikeLockCleaned) return passive("车锁已经擦净，接下来使用 2 元现金付款。");
      if (state.canteenHunt.mode === "dark") return locked("切回浅色模式后再清洁车锁。", "共享单车车锁");
      if (!state.canteenHunt.bikeCodeRead) return locked("先在深色模式检查车锁二维码，再切回浅色模式。", "共享单车车锁");
      return ready("共享单车车锁");
    }
    if (itemId === "cafeteriaWages") {
      if (!state.canteenHunt.bikeCodeRead) return locked("先在深色模式读取二维码。", "共享单车");
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
      return ready("入口海报玻璃", "先走到海报右侧的蓝色站位，再把油渍纸巾拖进海报玻璃上的高亮框。");
    }
    if (itemId === "temporaryTheaterTicket") {
      if (theater.phase === "entry_ticket" && !theater.admitted) {
        if (theater.mode !== "light") {
          return locked("深色模式只读取异常；切回浅色操作后再把票拖入读票器。", "检票闸机右侧读票器");
        }
        return ready(
          "检票闸机右侧读票器",
          "先让人物站进读票器前的蓝色站位，再把票拖进发光的「验票」槽内松手。"
        );
      }
      if (theater.phase === "prop_setup") {
        if (theater.propBoxOpened) return passive("票据扫描已经完成，临时观演票已从道具栏移除。");
        if (!theater.managerHintRead) {
          return locked("先切到深色模式检查道具箱并读完管理员提示。", "道具箱旁票据扫描器");
        }
        if (theater.mode !== "light") {
          return locked("管理员提示已经取得；切回浅色模式后才能扫描票据。", "道具箱旁票据扫描器");
        }
        return ready(
          "道具箱旁票据扫描器",
          "人物站进扫描器前的蓝色站位后，把票拖进发光的扫描口内松手。"
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
      return ready("后台通风口", "人物站到通风口前的蓝色站位后，把荧光粉刷拖进通风口高亮框。");
    }
    if (itemId === "spotlightRemote") {
      if (theater.phase !== "spotlight_ready" || !theater.paperDusted) {
        return locked("先完成后台纸屑显影，灯光控制台随后开放。", "灯光控制台");
      }
      if (theater.mode !== "light") {
        return locked("深色模式只观察追光残影；切回浅色操作后启动灯光控制台。", "灯光控制台");
      }
      return ready("灯光控制台", "人物站进控制台下方的蓝色站位后，把追光灯遥控器拖进控制台高亮框。");
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
      if (!lake.observedFishingSpotIds.includes("paper")) {
        return locked("先在深色观察中记录纸条倒影。", "纸条倒影装饵框");
      }
      return requireLight("纸条倒影装饵框")
        ?? ready("纸条倒影装饵框", "把假纸条拖进纸条倒影的发光框，系统会将它固定到鱼钩。");
    }

    if (itemId === "fishingRod") {
      if (lake.phase === "paper_capture" && state.items.swanMagnet) {
        if (lake.zone !== "swan_cove") {
          return locked("先划到黑天鹅围栏区。", "船头磁吸组合位");
        }
        return requireLight("工具装配框")
          ?? ready("工具装配框", "把钓鱼竿拖到道具 7 所在的装配框。");
      }
      if (lake.zone !== "open_water") {
        return locked("当前抛竿点位于大湖，先划回大湖。", "已观察的抛竿点");
      }
      if (!lake.decoyBaitAttached) {
        return locked("先把假纸条拖到钓鱼竿装饵框。", "钓鱼竿装饵框");
      }
      return requireLight("已观察的抛竿点")
        ?? ready("已观察的抛竿点", "拖到倒影坐标的高亮水纹。直接钓纸条会显示失败原因。");
    }

    if (itemId === "rustedLockerKey") {
      return lake.lockerOpened
        ? passive("码头储物柜已经打开。")
        : lake.zone !== "dock"
          ? locked("返回小码头，储物柜锁孔只在码头区域开放。", "码头储物柜")
        : requireLight("码头储物柜")
          ?? ready("码头储物柜", "返回小码头，靠近柜门站位后把钥匙拖入锁孔。");
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
          ?? ready("浮排系绳下方", "进入直河道，靠近浮排交互位后把抄网拖入高亮框。");
    }

    if (itemId === "sealedFeedTin") {
      return lake.feedTinOpened
        ? passive("饲料盒已经打开。")
        : lake.zone !== "channel"
          ? locked("返回浮排直河道，开盒位在浮排上缘。", "浮排开盒位")
        : requireLight("浮排开盒位")
          ?? ready("浮排开盒位", "把密封饲料盒拖入标有「开启」的高亮框。");
    }

    if (itemId === "fishFeedPellets") {
      if (lake.zone !== "open_water") {
        return locked("回到大湖的鱼群水纹位置。", "鱼群水纹");
      }
      return requireLight("已观察的鱼群水纹")
        ?? (lake.observedFishingSpotIds.includes("fish")
          ? ready("鱼群水纹", "把饲料颗粒拖入已记录的鱼群坐标。")
          : locked("先切到深色观察，记录鱼群水纹。", "鱼群水纹"));
    }

    if (itemId === "smallCarp") {
      return requireLight("黑天鹅投喂区")
        ?? (lake.zone === "swan_cove"
          ? ready("黑天鹅投喂区", "靠近围栏前站位，把小鲤鱼拖入投喂框。")
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
        ?? (lake.observedFishingSpotIds.includes("paper")
          ? ready("纸条本体水纹", "把磁性钓鱼竿拖入已记录的纸条坐标。")
          : locked("先在深色观察中记录纸条本体坐标。", "纸条本体水纹"));
    }
  }

  return elsewhere(itemId);
}
