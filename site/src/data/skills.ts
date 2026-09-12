/**
 * 技能页数据源（纯内容）。
 * 页面展示与筛选规则由 src/config/skillsConfig.ts 控制。
 */
import type { SkillItem } from "@/types/skillsConfig";

export const skillsData: SkillItem[] = [
  {
    name: "Linux",
    description: "系统管理、性能调优、Shell 环境与服务器运维。",
    icon: "simple-icons:linux",
    category: "system",
    level: "advanced",
  },
  {
    name: "C",
    description: "底层系统编程、内存管理与高性能模块开发。",
    icon: "simple-icons:c",
    category: "backend",
    level: "intermediate",
  },
  {
    name: "Shell",
    description: "自动化脚本、任务编排与日常开发辅助。",
    icon: "simple-icons:gnubash",
    category: "system",
    level: "intermediate",
  },
  {
    name: "Python",
    description: "数据处理、服务自动化与快速原型构建。",
    icon: "simple-icons:python",
    category: "backend",
    level: "intermediate",
  },
  {
    name: "TOML",
    description: "配置文件编写、项目元数据与结构化配置。",
    icon: "simple-icons:toml",
    category: "tooling",
    level: "intermediate",
  },
  {
    name: "YAML",
    description: "声明式配置、CI/CD 流水线与 Kubernetes 资源。",
    icon: "simple-icons:yaml",
    category: "tooling",
    level: "intermediate",
  },
  {
    name: "Java",
    description: "企业级后端服务、面向对象设计与中间件开发。",
    icon: "simple-icons:openjdk",
    category: "backend",
    level: "beginner",
  },
  {
    name: "HTML5",
    description: "语义化结构、可访问性与现代 Web 标记。",
    icon: "simple-icons:html5",
    category: "frontend",
    level: "beginner",
  },
  {
    name: "CSS",
    description: "响应式布局、Flex/Grid 与样式系统设计。",
    icon: "simple-icons:css3",
    category: "frontend",
    level: "beginner",
  },
  {
    name: "JavaScript",
    description: "ES2020+ 语法、异步编程与 DOM 交互。",
    icon: "simple-icons:javascript",
    category: "frontend",
    level: "beginner",
  },
  {
    name: "MySQL",
    description: "关系建模、复杂查询与数据库性能优化。",
    icon: "simple-icons:mysql",
    category: "database",
    level: "beginner",
  },
];

/** 获取所有技能数据列表 */
export function getSkillsList(): SkillItem[] {
  return skillsData;
}
