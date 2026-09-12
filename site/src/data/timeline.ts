/**
 * 时间线页数据源（纯内容）。
 * 页面展示与筛选规则由 src/config/timelineConfig.ts 控制。
 */
import type { TimelineItem } from "@/types/timelineConfig";

export const timelineData: TimelineItem[] = [
  {
  title: "计算机应用技术",
  date: "2021.09 – 2024.06",
  category: "education",
  subtitle: "广西外国语学院",
  location: "南宁，中国",
  description: "主修计算机应用技术，涵盖程序设计基础、数据库管理、计算机网络及办公自动化，注重动手实践与团队协作能力的培养。",
  highlights: [
    "担任班级学习委员（2022–2024），负责教学信息传达、学习资料整理，获评校级“优秀学生干部”荣誉称号（2023年度）"
  ],
  tags: ["计算机应用技术", "学生干部", "沟通协调", "办公软件"],
  icon: "material-symbols:school-rounded"
  },
  {
		title: "科技写作",
		date: "2024.11",
		category: "life",
		subtitle: "第一次在网上进行科技文章写作",
		description:
			"我在网上发布了我的第一篇文章，并开始记录、探索和分享个人感悟。",
		tags: ["写作", "分享"],
		icon: "material-symbols:edit-note-rounded",
	},
];

/** 获取所有时间线数据列表 */
export function getTimelineList(): TimelineItem[] {
	return timelineData;
}
