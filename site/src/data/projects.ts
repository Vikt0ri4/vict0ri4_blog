/**
 * 项目页数据源（纯内容）。
 * 页面展示与筛选规则由 src/config/projectsConfig.ts 控制。
 */
import type { ProjectItem } from "@/types/projectsConfig";

export const projectsData: ProjectItem[] = [
  {
    key: "dwm",
    title: "dwm",
    summary: "dwm (dynamic window manager) is an extremely fast, small, and dynamic window manager for X, known for its minimalistic and hackable design.",
    category: "window-manager",
    phase: "shipped",
    technologies: ["C", "X11", "Linux"],
    icon: "material-symbols:window-outline",
    repository: "https://codeberg.org/kjrin710/dwm"
  },
  {
  key: "st",
  title: "st",
  summary: "st is a simple terminal implementation for X from the suckless project, focusing on simplicity, clarity, and frugality.",
  category: "terminal",
  phase: "shipped",
  technologies: ["C", "X11", "Linux"],
  icon: "material-symbols:code",
  repository: "https://codeberg.org/kjrin710/st"
  }
];

/** 获取所有项目数据列表 */
export function getProjectsList(): ProjectItem[] {
	return projectsData;
}
