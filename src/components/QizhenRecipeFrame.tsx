import type { CSSProperties } from "react";
import type { QizhenPhotoRecipe } from "../core/types";
import qizhenLakeChannelUrl from "../assets/rpg/interiors/qizhen_lake_channel.png";
import qizhenLakeDockUrl from "../assets/rpg/interiors/qizhen_lake_dock.png";
import qizhenLakeOpenWaterUrl from "../assets/rpg/interiors/qizhen_lake_open_water.png";
import qizhenLakeSwanCoveUrl from "../assets/rpg/interiors/qizhen_lake_swan_cove.png";
import kayakOverheadFrameUrl from "../assets/rpg/qizhen/kayak_overhead_frame_a.png";

/* ===== 配方 → 画面投影常量 =====
   湖区底图源像素 1672×941,取景框用同一宽高比,使 background-size 百分比
   同时控制宽高两个方向,投影公式在两个轴上完全对称。 */
const SOURCE_WIDTH = 1672;
const SOURCE_HEIGHT = 941;
const KAYAK_SOURCE_WIDTH = 128;
/* zoomStep 0/1/2 对应的三档放大倍率。 */
const ZOOM_SCALES: readonly [number, number, number] = [1, 1.5, 2.2];

const ZONE_BACKGROUNDS: Record<QizhenPhotoRecipe["zone"], string> = {
  dock: qizhenLakeDockUrl,
  open_water: qizhenLakeOpenWaterUrl,
  channel: qizhenLakeChannelUrl,
  swan_cove: qizhenLakeSwanCoveUrl
};

/* ===== 投影换算 =====
   设 f = cropCenter / 源图尺寸(0–1),z = 放大倍率。
   background-size 取 z×100% 后图像显示尺寸 = z × 取景框尺寸,百分比定位
   p 满足 (元素 − 图像) × p = 期望偏移,令裁切中心落在取景框正中:
     p = (0.5 − f × z) / (1 − z)   (z = 1 时图像恰好铺满,取 0.5)
   p 钳制到 [0, 1] 等价于把裁切窗口钳制在源图边界内。
   皮划艇源像素位置 (kx, ky) 的显示位置(相对取景框比例):
     u = kx × z + (1 − z) × p */

function clamp01(value: number): number {
  return Math.min(1, Math.max(0, value));
}

function zoomScaleFor(step: QizhenPhotoRecipe["zoomStep"]): number {
  return ZOOM_SCALES[step] ?? ZOOM_SCALES[0];
}

function cropPosition(fraction: number, zoom: number): number {
  if (zoom === 1) {
    return 0.5;
  }
  return clamp01((0.5 - fraction * zoom) / (1 - zoom));
}

export interface QizhenRecipeFrameProps {
  recipe: QizhenPhotoRecipe;
  /** thumb 用于帖子列表/楼层缩略图:投影公式不变,仅收敛水纹与黑天鹅剪影细节。 */
  variant?: "full" | "thumb";
  /** 提供时整帧以 role="img" 暴露该替代文本;缺省视为纯装饰(aria-hidden)。 */
  alt?: string;
}

/**
 * 按配方重建取景/冻结画面:底图裁切 + 皮划艇 + 黑天鹅剪影 + 水纹层。
 * 照片不落盘,相机、帖子主图、楼层缩略图与详情浮层共用同一投影。
 */
export function QizhenRecipeFrame({ recipe, variant = "full", alt }: QizhenRecipeFrameProps) {
  const zoom = zoomScaleFor(recipe.zoomStep);
  const posX = cropPosition(recipe.cropCenterX / SOURCE_WIDTH, zoom);
  const posY = cropPosition(recipe.cropCenterY / SOURCE_HEIGHT, zoom);

  const frameStyle: CSSProperties = {
    backgroundImage: `url(${ZONE_BACKGROUNDS[recipe.zone] ?? qizhenLakeOpenWaterUrl})`,
    backgroundPosition: `${posX * 100}% ${posY * 100}%`,
    backgroundSize: `${zoom * 100}% auto`
  };

  const kayakU =
    (recipe.kayakX / SOURCE_WIDTH) * zoom + (1 - zoom) * posX;
  const kayakV =
    (recipe.kayakY / SOURCE_HEIGHT) * zoom + (1 - zoom) * posY;
  const kayakStyle: CSSProperties = {
    left: `${kayakU * 100}%`,
    top: `${kayakV * 100}%`,
    transform: `translate(-50%, -50%) rotate(${recipe.headingBucket * 45}deg)`,
    width: `${(KAYAK_SOURCE_WIDTH / SOURCE_WIDTH) * zoom * 100}%`
  };

  const swanBucket = recipe.swanDistanceBucket;
  const rippleBucket = recipe.rippleClarityBucket;

  return (
    <div
      className={`qizhen-recipe-frame qizhen-recipe-frame--${variant}`}
      {...(alt ? { role: "img", "aria-label": alt } : { "aria-hidden": true })}
    >
      <div className="qizhen-recipe-frame-layer" style={frameStyle} aria-hidden="true" />
      {rippleBucket === "clear" || rippleBucket === "partial" ? (
        <i
          className={`qizhen-recipe-frame-ripple qizhen-recipe-frame-ripple--${rippleBucket}`}
          aria-hidden="true"
        />
      ) : null}
      {swanBucket === "near" || swanBucket === "mid" || swanBucket === "far" ? (
        <i
          className={`qizhen-recipe-frame-swan qizhen-recipe-frame-swan--${swanBucket}`}
          aria-hidden="true"
        />
      ) : null}
      <img
        alt=""
        aria-hidden="true"
        className="qizhen-recipe-frame-kayak"
        draggable={false}
        src={kayakOverheadFrameUrl}
        style={kayakStyle}
      />
    </div>
  );
}
