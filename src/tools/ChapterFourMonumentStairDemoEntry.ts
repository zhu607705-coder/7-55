import { mountChapterFourMonumentStairDemo } from "./ChapterFourMonumentStairDemo";

const root = document.querySelector<HTMLElement>("#stair-demo");
if (!root) throw new Error("Missing #stair-demo root.");

root.classList.add("is-standalone");
mountChapterFourMonumentStairDemo(root);
