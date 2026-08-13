import * as THREE from "three";
import concreteColorUrl from "../../assets/rpg/chapter4-stair/materials/Concrete010_1K-JPG_Color.jpg";
import metalColorUrl from "../../assets/rpg/chapter4-stair/materials/Metal012_1K-JPG_Color.jpg";
import plasterColorUrl from "../../assets/rpg/chapter4-stair/materials/Plaster001_1K-JPG_Color.jpg";
import type { StairMaterialKey } from "./types";

/**
 * 第四章楼梯间三视角解谜 —— 像素画风模块。
 * 设计依据：docs/plans/2026-08-08-chapter4-monument-perspective-two-level-design.md §8。
 * 仍禁用雾、软阴影、抗锯齿与色调映射；墙面、混凝土和金属使用本地
 * CC0 颜色贴图，经 64×64 少量灰阶化后由既有色板调制。
 * 阴影一律用 createBlobShadow 的硬边色块，轮廓用 addHardOutline 的深色线框。
 */

/** 设计文档 §8.2 建议基础色板（唯一颜色来源，不要在别处硬编码色值）。 */
export const STAIR_PALETTE = Object.freeze({
  /** 深轮廓 */
  outline: "#17252D",
  /** 次级轮廓 / 灰蓝结构 */
  outlineSecondary: "#31444B",
  /** 暖墙亮面 */
  wallLit: "#E7D9B9",
  /** 暖墙侧面 */
  wallSide: "#BFAF91",
  /** 石材亮面 */
  stoneLit: "#CBD4CB",
  /** 石材背面 */
  stoneBack: "#7D908E",
  /** 有效连接（青色实线接缝） */
  seamValid: "#5FE2C2",
  /** 错误重合（橙色虚线接缝）/ 低饱和警示 */
  seamInvalid: "#D89262",
  /** 当前选择 */
  selection: "#6EB7D6",
  /** 夜窗深蓝 */
  nightGlass: "#173C5A"
} as const);

export type StairPaletteKey = keyof typeof STAIR_PALETTE;

/** types.ts 的 StairMaterialKey → 色板映射。每种结构一个离散亮度档，不做光照渐变。 */
const MATERIAL_COLORS: Record<StairMaterialKey, string> = {
  wall_lit: STAIR_PALETTE.wallLit,
  wall_side: STAIR_PALETTE.wallSide,
  stone_lit: STAIR_PALETTE.stoneLit,
  stone_back: STAIR_PALETTE.stoneBack,
  structure: STAIR_PALETTE.outlineSecondary,
  outline: STAIR_PALETTE.outline,
  night_glass: STAIR_PALETTE.nightGlass,
  warn: STAIR_PALETTE.seamInvalid
};

/**
 * 每种 key 共享一个实例：关卡内大量盒体复用同一亮度档材质，
 * 避免逐个 mesh 创建与销毁重复材质。不要对返回值调用 dispose()
 * （会波及其他使用者）；整体释放用 disposeStairMaterials()。
 */
const materialCache = new Map<StairMaterialKey, THREE.MeshBasicMaterial>();

type SurfaceFamily = "plaster" | "concrete" | "metal";

export interface StairMaterialTextureStatus {
  setId: "ambientcg_cc0_pixel";
  expected: number;
  loaded: number;
  failed: readonly string[];
  ready: boolean;
  pixelLevels: Readonly<Record<string, readonly number[]>>;
  mappedMaterials: readonly string[];
  pixelSizes: Readonly<Record<string, readonly [number, number]>>;
}

const SURFACE_MAP_URLS: Record<SurfaceFamily, string> = {
  plaster: plasterColorUrl,
  concrete: concreteColorUrl,
  metal: metalColorUrl
};

const SURFACE_FAMILY_BY_MATERIAL: Partial<Record<StairMaterialKey, SurfaceFamily>> = {
  wall_lit: "plaster",
  wall_side: "plaster",
  stone_lit: "concrete",
  stone_back: "concrete",
  structure: "metal"
};

const EXPECTED_SURFACE_TEXTURES = Object.keys(SURFACE_MAP_URLS).length;
const surfaceTextures = new Map<SurfaceFamily, THREE.Texture>();
const loadedSurfaceTextures = new Set<string>();
const failedSurfaceTextures = new Set<string>();
const surfacePixelLevels = new Map<SurfaceFamily, readonly number[]>();
let textureLoadGeneration = 0;

/**
 * 64×64 表面纹理生成最近邻 mip 层：内部画面仍按像素块输出，
 * 远处墙面和台阶不会因高频细节产生闪烁。
 */
function configureSurfaceTexture(texture: THREE.Texture): void {
  texture.wrapS = THREE.RepeatWrapping;
  texture.wrapT = THREE.RepeatWrapping;
  texture.magFilter = THREE.NearestFilter;
  texture.minFilter = THREE.NearestMipmapNearestFilter;
  texture.generateMipmaps = true;
  texture.anisotropy = 1;
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.needsUpdate = true;
}

function quantizeChannel(value: number, levels: number): number {
  const step = 255 / Math.max(1, levels - 1);
  return Math.round(value / step) * step;
}

/**
 * 把 1K 网络贴图在内存中收束为小型像素材质。仓库仍保存未经改写的来源图，
 * 运行时颜色层转为由固定色板调制的灰阶明度，避免照片色彩破坏本章配色。
 */
function createPixelSurfaceImage(
  family: SurfaceFamily,
  image: HTMLImageElement
): HTMLCanvasElement {
  const size = 64;
  const canvas = document.createElement("canvas");
  canvas.width = size;
  canvas.height = size;
  const context = canvas.getContext("2d", { willReadFrequently: true });
  if (!context) {
    return canvas;
  }
  context.imageSmoothingEnabled = true;
  context.drawImage(image, 0, 0, size, size);
  const imageData = context.getImageData(0, 0, size, size);
  const pixels = imageData.data;

  let mean = 0;
  for (let index = 0; index < pixels.length; index += 4) {
    mean += pixels[index] * 0.2126 + pixels[index + 1] * 0.7152 + pixels[index + 2] * 0.0722;
  }
  mean /= pixels.length / 4;
  const contrast = family === "plaster" ? 1 : family === "concrete" ? 2.2 : 2.1;
  const center = family === "plaster" ? 252 : 204;
  for (let index = 0; index < pixels.length; index += 4) {
    const luminance = pixels[index] * 0.2126 + pixels[index + 1] * 0.7152 + pixels[index + 2] * 0.0722;
    const normalized = Math.min(255, Math.max(132, center + (luminance - mean) * contrast));
    const quantized = family === "plaster"
      ? Math.min(255, Math.max(248, Math.round(normalized / 4) * 4))
      : quantizeChannel(normalized, 6);
    pixels[index] = quantized;
    pixels[index + 1] = quantized;
    pixels[index + 2] = quantized;
  }
  surfacePixelLevels.set(family, [...new Set(Array.from({ length: pixels.length / 4 }, (_, pixel) => pixels[pixel * 4]))].sort((a, b) => a - b));
  context.putImageData(imageData, 0, 0);
  return canvas;
}

function loadSurfaceTexture(family: SurfaceFamily, url: string): THREE.Texture {
  const id = `${family}:color`;
  const generation = textureLoadGeneration;
  const fallbackCanvas = document.createElement("canvas");
  fallbackCanvas.width = 1;
  fallbackCanvas.height = 1;
  const fallbackContext = fallbackCanvas.getContext("2d");
  if (fallbackContext) {
    fallbackContext.fillStyle = "#FFFFFF";
    fallbackContext.fillRect(0, 0, 1, 1);
  }
  const texture: THREE.Texture = new THREE.CanvasTexture(fallbackCanvas);
  texture.name = `chapter4-stair-${id}-fallback`;
  configureSurfaceTexture(texture);
  new THREE.ImageLoader().load(
    url,
    (image) => {
      if (generation !== textureLoadGeneration) {
        return;
      }
      const pixelTexture = new THREE.CanvasTexture(createPixelSurfaceImage(family, image));
      pixelTexture.name = `chapter4-stair-${id}`;
      configureSurfaceTexture(pixelTexture);
      const previousTexture = surfaceTextures.get(family);
      surfaceTextures.set(family, pixelTexture);
      materialCache.forEach((material, key) => {
        if (SURFACE_FAMILY_BY_MATERIAL[key] === family) {
          material.map = pixelTexture;
          material.needsUpdate = true;
        }
      });
      if (previousTexture && previousTexture !== pixelTexture) {
        previousTexture.dispose();
      }
      loadedSurfaceTextures.add(id);
      failedSurfaceTextures.delete(id);
    },
    undefined,
    () => {
      if (generation === textureLoadGeneration) {
        failedSurfaceTextures.add(id);
      }
    }
  );
  return texture;
}

function getSurfaceTexture(family: SurfaceFamily): THREE.Texture {
  const cached = surfaceTextures.get(family);
  if (cached) {
    return cached;
  }
  const texture = loadSurfaceTexture(family, SURFACE_MAP_URLS[family]);
  surfaceTextures.set(family, texture);
  return texture;
}

/** 调试快照只报告当前本地贴图加载情况，不暴露 URL 或运行时网络依赖。 */
export function getStairMaterialTextureStatus(): StairMaterialTextureStatus {
  return {
    setId: "ambientcg_cc0_pixel",
    expected: EXPECTED_SURFACE_TEXTURES,
    loaded: loadedSurfaceTextures.size,
    failed: [...failedSurfaceTextures].sort(),
    ready: loadedSurfaceTextures.size === EXPECTED_SURFACE_TEXTURES && failedSurfaceTextures.size === 0,
    pixelLevels: Object.fromEntries([...surfacePixelLevels.entries()].sort(([a], [b]) => a.localeCompare(b))),
    mappedMaterials: [...materialCache.entries()].filter(([, material]) => Boolean(material.map)).map(([key]) => key).sort(),
    pixelSizes: Object.fromEntries([...surfaceTextures.entries()].map(([family, texture]) => {
      const image = texture.image as { width?: number; height?: number } | null;
      return [family, [image?.width ?? 0, image?.height ?? 0] as const] as const;
    }).sort(([a], [b]) => a.localeCompare(b)))
  };
}

/**
 * 结构表面使用经像素化的 CC0 颜色贴图；轮廓、玻璃和警示保持纯色，
 * 全部仍由 MeshBasicMaterial 渲染，避免连续光照改变既有章节配色。
 */
export function createStairMaterial(key: StairMaterialKey): THREE.MeshBasicMaterial {
  const cached = materialCache.get(key);
  if (cached) {
    return cached;
  }
  const surfaceFamily = SURFACE_FAMILY_BY_MATERIAL[key];
  const material = new THREE.MeshBasicMaterial({
    color: MATERIAL_COLORS[key],
    map: surfaceFamily ? getSurfaceTexture(surfaceFamily) : null,
    fog: false,
    toneMapped: false
  });
  materialCache.set(key, material);
  return material;
}

/** 释放 createStairMaterial 的共享缓存（仅 Demo 整体销毁时调用）。 */
export function disposeStairMaterials(): void {
  materialCache.forEach((material) => material.dispose());
  materialCache.clear();
  textureLoadGeneration += 1;
  surfaceTextures.forEach((texture) => texture.dispose());
  surfaceTextures.clear();
  loadedSurfaceTextures.clear();
  failedSurfaceTextures.clear();
  surfacePixelLevels.clear();
}

/**
 * BoxGeometry 每个面使用独立 UV；按真实面尺寸缩放 UV 后，大墙、平台和台阶
 * 共用同一纹理密度，避免把一整张贴图拉伸到不同尺寸的盒体上。
 */
export function createStairBoxGeometry(
  width: number,
  height: number,
  depth: number,
  tileWorldSize = 2.4
): THREE.BoxGeometry {
  const geometry = new THREE.BoxGeometry(width, height, depth);
  const uv = geometry.getAttribute("uv") as THREE.BufferAttribute;
  const index = geometry.getIndex();
  for (const group of geometry.groups) {
    const face = group.materialIndex ?? 0;
    const [uWorld, vWorld] = face <= 1
      ? [depth, height]
      : face <= 3
        ? [width, depth]
        : [width, height];
    const vertices = new Set<number>();
    for (let offset = group.start; offset < group.start + group.count; offset += 1) {
      vertices.add(index ? index.getX(offset) : offset);
    }
    vertices.forEach((vertex) => {
      uv.setXY(vertex, uv.getX(vertex) * (uWorld / tileWorldSize), uv.getY(vertex) * (vWorld / tileWorldSize));
    });
  }
  uv.needsUpdate = true;
  return geometry;
}

/**
 * 为网格叠加 1–2px 深轮廓（§8.3）。
 * WebGL 线宽恒为 1 设备像素：在 480×270 内部缓冲绘制为 1px，
 * 整数倍放大到 960×540 画布后恰为 2px 的硬边轮廓，符合规范区间。
 * 返回的 LineSegments 作为子节点挂在 mesh 上，随机关刚体变换一起运动。
 */
export function addHardOutline(
  mesh: THREE.Mesh,
  color: string = STAIR_PALETTE.outline
): THREE.LineSegments {
  const outline = new THREE.LineSegments(
    new THREE.EdgesGeometry(mesh.geometry, 1),
    new THREE.LineBasicMaterial({ color, fog: false, toneMapped: false })
  );
  outline.name = `${mesh.name || "mesh"}-outline`;
  mesh.add(outline);
  return outline;
}

/**
 * 投影到地面的低分辨率硬边色块阴影（§8.2）。
 * 6 段低细分圆形 → 硬像素边缘的色块，不做实时柔化；
 * 机关运动时只需整体移动该 mesh。已按 XZ 地面摆平，调用方设置 x/z 即可。
 */
export function createBlobShadow(radius: number, opacity = 0.28): THREE.Mesh {
  const geometry = new THREE.CircleGeometry(radius, 6);
  const material = new THREE.MeshBasicMaterial({
    color: STAIR_PALETTE.outline,
    transparent: true,
    opacity,
    depthWrite: false,
    fog: false,
    toneMapped: false
  });
  const shadow = new THREE.Mesh(geometry, material);
  shadow.name = "blob-shadow";
  shadow.rotation.x = -Math.PI / 2;
  shadow.position.y = 0.02;
  shadow.renderOrder = 1;
  return shadow;
}

/** 低细分圆柱几何（§8.3：细分降到 4/6/8 段，避免平滑塑料感）。 */
export function lowSegCylinder(
  radiusTop: number,
  radiusBottom: number,
  height: number,
  radialSegments: 4 | 6 | 8 = 6
): THREE.CylinderGeometry {
  return new THREE.CylinderGeometry(radiusTop, radiusBottom, height, radialSegments, 1, false);
}

/** 低细分球体（装饰用，默认 6×4 段）。 */
export function lowSegSphere(radius: number, widthSegments = 6, heightSegments = 4): THREE.SphereGeometry {
  return new THREE.SphereGeometry(radius, widthSegments, heightSegments);
}

/**
 * 统一像素渲染配置（§8.1 / §8.2）。
 * 注意：抗锯齿只能在构造参数 `new THREE.WebGLRenderer({ antialias: false })` 保证，
 * 本函数无法事后关闭；这里负责像素比、色调映射与软阴影。
 * 内部缓冲 480×270 由渲染目标 / setSize 控制，画布 CSS 另设 image-rendering: pixelated。
 */
export function configurePixelRenderer(renderer: THREE.WebGLRenderer): void {
  // 像素比恒为 1：设备像素比不改变世界可见范围，也不启用超采样柔化。
  renderer.setPixelRatio(1);
  // 移除 ACES 等色调映射，材质颜色即最终像素颜色。
  renderer.toneMapping = THREE.NoToneMapping;
  renderer.toneMappingExposure = 1;
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  // 禁用实时阴影贴图（含软阴影）；阴影由 createBlobShadow 的硬边色块承担。
  renderer.shadowMap.enabled = false;
}

/** 最近邻纹理配置（§8.3）：NearestFilter、禁 mipmap、禁各向异性过滤。 */
export function nearestTexture<T extends THREE.Texture>(texture: T): T {
  texture.magFilter = THREE.NearestFilter;
  texture.minFilter = THREE.NearestFilter;
  texture.generateMipmaps = false;
  texture.anisotropy = 1;
  texture.needsUpdate = true;
  return texture;
}
