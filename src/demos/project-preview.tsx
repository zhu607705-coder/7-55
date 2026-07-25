import { useEffect, useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import "@fontsource/fusion-pixel-12px-proportional-sc";
import teamConfig from "../../config/team-workstreams.json";
import "./project-preview.css";

type LinkState = "checking" | "available" | "missing" | "local";
type SectionId = "launch" | "structure" | "team" | "workflow" | "versions";

interface LaunchEntry {
  id: string;
  label: string;
  description: string;
  href: string;
  badge: string;
  ownerLane: string;
}

interface RepositoryArea {
  id: string;
  label: string;
  purpose: string;
  paths: string[];
  tracked: boolean;
  dependencies: string;
}

const LAUNCH_ENTRIES: LaunchEntry[] = [
  {
    id: "formal-game",
    label: "正式游戏",
    description: "从新存档或 DEV 检查点运行 React 与 Phaser 主版本。",
    href: "./index.html?dev=0",
    badge: "PRIMARY",
    ownerLane: "A + B"
  },
  {
    id: "campus-map",
    label: "校园地图独立演示",
    description: "只加载紫金港地图、人物、碰撞、镜头和输入，不写正式存档。",
    href: "./campus-map-demo.html",
    badge: "MAP",
    ownerLane: "C"
  },
  {
    id: "godot-migration",
    label: "Godot 迁移切片",
    description: "在已导出 Godot Web 产物的构建中预览双运行时桥。",
    href: "./index.html?engine=godot&dev=0&devCheckpoint=c2-library-gate",
    badge: "MIGRATION",
    ownerLane: "B + C"
  },
  {
    id: "developer-checkpoints",
    label: "开发检查点",
    description: "快速定位章节、谜题与结果状态，便于审查和录屏。",
    href: "./index.html?devCheckpoint=c1-alarm",
    badge: "QA",
    ownerLane: "B + D"
  }
];

const REPOSITORY_AREAS: RepositoryArea[] = [
  {
    id: "entry",
    label: "产品入口",
    purpose: "Web 启动、运行时切换和全局层装配。",
    paths: ["src/main.tsx", "src/App.tsx", "index.html"],
    tracked: true,
    dependencies: "可依赖 core、modules、components 与 scenes。"
  },
  {
    id: "domain",
    label: "共享领域层",
    purpose: "剧情事实、路由、任务、存档、事件和玩法控制器。",
    paths: ["src/core/**", "src/modules/**"],
    tracked: true,
    dependencies: "不得依赖具体 React 页面或 Phaser / Godot 场景。"
  },
  {
    id: "phone",
    label: "手机界面",
    purpose: "430×860 手机壳层、应用页面、弹窗、字幕和触控交互。",
    paths: ["src/scenes/phone/**", "src/components/**", "src/styles/**"],
    tracked: true,
    dependencies: "通过控制器和领域事件推进剧情。"
  },
  {
    id: "phaser",
    label: "Phaser RPG",
    purpose: "当前正式地图、室内场景、人物、镜头、碰撞和交互表现。",
    paths: ["src/scenes/rpg/**"],
    tracked: true,
    dependencies: "读取共享状态，通过 RpgBridge 发布领域请求。"
  },
  {
    id: "godot",
    label: "Godot 迁移",
    purpose: "Godot 工程、GDScript、Web 桥、导出配置和迁移测试。",
    paths: ["godot/**", "src/core/GodotBridge.ts", "scripts/*godot*.mjs"],
    tracked: true,
    dependencies: "迁移期由 React 状态提供事实，逐步取得场景运行权。"
  },
  {
    id: "content",
    label: "内容与数据",
    purpose: "剧情文案、任务配置、地图清单、音频时间线和素材索引。",
    paths: ["src/data/**", "src/assets/**"],
    tracked: true,
    dependencies: "数据文件不包含运行时副作用。"
  },
  {
    id: "automation",
    label: "自动化与测试",
    purpose: "构建、地图校验、测试运行器、CI 和交付检查。",
    paths: ["scripts/**", "tests/**", ".github/**"],
    tracked: true,
    dependencies: "任何新流程同时提供本地命令和 CI 入口。"
  },
  {
    id: "docs",
    label: "设计与协作文档",
    purpose: "策划、架构、验收、版本规则、迁移记录和发布说明。",
    paths: ["docs/**", "README.md", "CONTRIBUTING.md", "AGENTS.md"],
    tracked: true,
    dependencies: "行为变化与对应规范在同一 PR 更新。"
  },
  {
    id: "generated",
    label: "生成产物",
    purpose: "本地构建、离线演示、Godot 同步素材和浏览器证据。",
    paths: ["dist/**", "demo/**", "public/godot/**", "godot/assets/generated/**", "artifacts/**"],
    tracked: false,
    dependencies: "只能由脚本生成，禁止进入 Git 历史。"
  }
];

const DAILY_COMMANDS = [
  {
    label: "开始工作",
    command: "git switch main && git pull --ff-only && git switch -c feat/<用户名>/<模块>-<主题>"
  },
  {
    label: "同步主线",
    command: "git fetch origin && git rebase origin/main"
  },
  {
    label: "安全更新个人分支",
    command: "git push --force-with-lease"
  },
  {
    label: "提交前验证",
    command: "npm run verify:pr"
  }
];

function ProjectPreview() {
  const [activeSection, setActiveSection] = useState<SectionId>("launch");
  const [query, setQuery] = useState("");
  const [linkStates, setLinkStates] = useState<Record<string, LinkState>>({});
  const [copied, setCopied] = useState("");

  useEffect(() => {
    const next: Record<string, LinkState> = {};
    LAUNCH_ENTRIES.forEach((entry) => {
      next[entry.id] = window.location.protocol === "file:" ? "local" : "checking";
    });
    setLinkStates(next);
    if (window.location.protocol === "file:") return;

    let cancelled = false;
    Promise.all(LAUNCH_ENTRIES.map(async (entry) => {
      const target = new URL(entry.href, window.location.href);
      target.search = "";
      try {
        const response = await fetch(target, { method: "HEAD", cache: "no-store" });
        return [entry.id, response.ok ? "available" : "missing"] as const;
      } catch {
        return [entry.id, "missing"] as const;
      }
    })).then((entries) => {
      if (!cancelled) setLinkStates(Object.fromEntries(entries));
    });
    return () => {
      cancelled = true;
    };
  }, []);

  const filteredAreas = useMemo(() => {
    const needle = query.trim().toLocaleLowerCase("zh-CN");
    if (!needle) return REPOSITORY_AREAS;
    return REPOSITORY_AREAS.filter((area) => [
      area.label,
      area.purpose,
      area.dependencies,
      ...area.paths
    ].some((value) => value.toLocaleLowerCase("zh-CN").includes(needle)));
  }, [query]);

  async function copyCommand(command: string) {
    try {
      await navigator.clipboard.writeText(command);
      setCopied(command);
      window.setTimeout(() => setCopied((current) => current === command ? "" : current), 1800);
    } catch {
      setCopied("");
    }
  }

  function navigate(section: SectionId) {
    setActiveSection(section);
    document.getElementById(section)?.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  return (
    <main className="project-preview">
      <header className="preview-hero">
        <div className="preview-hero__eyebrow">REPOSITORY CONTROL ROOM</div>
        <div className="preview-hero__headline">
          <div>
            <span>7:55</span>
            <h1>仓库预览与四人协作门户</h1>
          </div>
          <p>统一试玩入口、文件归属、分支边界、合并顺序和发布规则。页面本身作为离线单文件构建，可随 Release 或评审包分发。</p>
        </div>
        <nav className="preview-nav" aria-label="门户导航">
          {([
            ["launch", "预览入口"],
            ["structure", "文件分类"],
            ["team", "四人分工"],
            ["workflow", "PR 流程"],
            ["versions", "版本规则"]
          ] as const).map(([id, label]) => (
            <button key={id} type="button" className={activeSection === id ? "is-active" : ""} onClick={() => navigate(id)}>
              {label}
            </button>
          ))}
        </nav>
      </header>

      <section id="launch" className="preview-section" aria-labelledby="launch-title">
        <div className="section-heading">
          <div>
            <small>01 / BUILDS</small>
            <h2 id="launch-title">统一预览入口</h2>
          </div>
          <p>所有演示从同一页进入，审查者无需记忆参数和检查点。</p>
        </div>
        <div className="launch-grid">
          {LAUNCH_ENTRIES.map((entry) => {
            const state = linkStates[entry.id] ?? "checking";
            return (
              <article key={entry.id} className="launch-card">
                <header>
                  <span>{entry.badge}</span>
                  <i data-state={state}>{formatLinkState(state)}</i>
                </header>
                <h3>{entry.label}</h3>
                <p>{entry.description}</p>
                <footer>
                  <small>负责通道 {entry.ownerLane}</small>
                  <a href={entry.href}>打开预览</a>
                </footer>
              </article>
            );
          })}
        </div>
      </section>

      <section id="structure" className="preview-section" aria-labelledby="structure-title">
        <div className="section-heading">
          <div>
            <small>02 / FILE MAP</small>
            <h2 id="structure-title">文件分类与依赖边界</h2>
          </div>
          <label className="structure-search">
            <span>筛选目录</span>
            <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="输入 Godot、存档、测试…" />
          </label>
        </div>
        <div className="structure-list" aria-live="polite">
          {filteredAreas.map((area) => (
            <article key={area.id} className="structure-row">
              <div className="structure-row__title">
                <span className={area.tracked ? "is-tracked" : "is-generated"}>{area.tracked ? "TRACK" : "BUILD"}</span>
                <h3>{area.label}</h3>
                <p>{area.purpose}</p>
              </div>
              <div className="path-list">
                {area.paths.map((path) => <code key={path}>{path}</code>)}
              </div>
              <p className="dependency-rule">{area.dependencies}</p>
            </article>
          ))}
          {filteredAreas.length === 0 ? <p className="empty-result">没有匹配的目录分类。</p> : null}
        </div>
      </section>

      <section id="team" className="preview-section" aria-labelledby="team-title">
        <div className="section-heading">
          <div>
            <small>03 / OWNERSHIP</small>
            <h2 id="team-title">四人并行开发通道</h2>
          </div>
          <p>职责来自 <code>config/team-workstreams.json</code>。填写四个 GitHub 用户名后即可成为团队事实来源。</p>
        </div>
        <div className="lane-grid">
          {teamConfig.lanes.map((lane) => (
            <article key={lane.id} className="lane-card">
              <header>
                <h3>{lane.label}</h3>
                <span>{lane.owner}</span>
              </header>
              <p>{lane.mission}</p>
              <div className="lane-paths">
                {lane.paths.map((path) => <code key={path}>{path}</code>)}
              </div>
              <small>交叉审查：{lane.reviewPartners.join("、")}</small>
            </article>
          ))}
        </div>
        <aside className="critical-paths">
          <strong>共享高风险文件</strong>
          <p>修改前在群内登记，PR 必须由另一个通道审查。禁止四人同时修改同一文件。</p>
          <div>{teamConfig.sharedCriticalPaths.map((path) => <code key={path}>{path}</code>)}</div>
        </aside>
      </section>

      <section id="workflow" className="preview-section" aria-labelledby="workflow-title">
        <div className="section-heading">
          <div>
            <small>04 / DELIVERY</small>
            <h2 id="workflow-title">分支、拉取与合并方式</h2>
          </div>
          <p>个人短分支直接面向 main；有依赖的改动使用堆叠 PR，基础 PR 合并后再改回 main。</p>
        </div>
        <ol className="workflow-steps">
          <li><strong>认领</strong><span>在 Issue 或群内登记负责人、路径、预期 PR 和依赖。</span></li>
          <li><strong>分支</strong><span>使用 <code>type/用户名/模块-主题</code>，一个分支只服务一个交付目标。</span></li>
          <li><strong>同步</strong><span>每天开始和提交前执行 fetch + rebase。个人分支允许 force-with-lease。</span></li>
          <li><strong>审查</strong><span>至少一名非作者批准，高风险共享文件由相邻通道审查。</span></li>
          <li><strong>合并</strong><span>检查全部通过后使用 Squash merge；main 禁止普通 force push。</span></li>
          <li><strong>回退</strong><span>线上问题使用 revert，保留可追踪的主线历史。</span></li>
        </ol>
        <div className="command-grid">
          {DAILY_COMMANDS.map((entry) => (
            <article key={entry.label}>
              <span>{entry.label}</span>
              <code>{entry.command}</code>
              <button type="button" onClick={() => copyCommand(entry.command)}>{copied === entry.command ? "已复制" : "复制"}</button>
            </article>
          ))}
        </div>
        <div className="stacked-pr">
          <strong>堆叠 PR 示例</strong>
          <pre>{`PR A  feat/alice/godot-foundation  → main\nPR B  feat/bob/campus-collision   → feat/alice/godot-foundation\nPR C  feat/carol/library-interior  → feat/bob/campus-collision\n\nA 合并后：B rebase main 并把 base 改为 main\nB 合并后：C rebase main 并把 base 改为 main`}</pre>
        </div>
      </section>

      <section id="versions" className="preview-section" aria-labelledby="versions-title">
        <div className="section-heading">
          <div>
            <small>05 / VERSIONING</small>
            <h2 id="versions-title">版本与发布规则</h2>
          </div>
          <p>产品版本、存档版本和桥协议版本分别递增，避免把三类兼容问题混在一起。</p>
        </div>
        <div className="version-grid">
          <article><span>产品版本</span><strong>v0.MINOR.PATCH</strong><p>新增完整玩法闭环提升 MINOR；修复与小范围改进提升 PATCH。</p></article>
          <article><span>候选版本</span><strong>v0.x.0-rc.N</strong><p>进入演示或答辩前建立候选标签，只接受缺陷修复。</p></article>
          <article><span>存档版本</span><strong>SaveEnvelope.version</strong><p>持久化结构发生变化时递增，并提供旧版本迁移测试。</p></article>
          <article><span>桥协议</span><strong>protocolVersion</strong><p>React、Phaser、Godot 的消息格式不兼容时独立递增。</p></article>
        </div>
        <footer className="preview-footer">
          <span>配置版本 {teamConfig.version}</span>
          <span>更新日期 {teamConfig.updatedAt}</span>
          <span>合并方式 {teamConfig.mergeMethod}</span>
        </footer>
      </section>
    </main>
  );
}

function formatLinkState(state: LinkState): string {
  if (state === "available") return "可打开";
  if (state === "missing") return "本构建未包含";
  if (state === "local") return "本地链接";
  return "检查中";
}

createRoot(document.getElementById("root") as HTMLElement).render(<ProjectPreview />);
