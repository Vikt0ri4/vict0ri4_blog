/**
 * 设备展示页数据源（纯内容）。
 * 页面展示与筛选规则由 src/config/devicesConfig.ts 控制。
 */
import type { DeviceItem } from "@/types/devicesConfig";

export const devicesData: DeviceItem[] = [
  {
    id: "ryzen-3300x-rx5700",
    name: "Custom Desktop",
    brand: "Custom",
    category: "desk",
    status: "active",
    specs: "AMD Ryzen 3 3300X / Radeon RX 5700 / 16GB RAM / 232GB Storage",
    description: "Custom-built desktop for development, gaming, and everyday productivity.",
    icon: "material-symbols:desktop-windows",
    featured: true,
    year: "2024",
    link: ""
  },
  {
    id: "lenovo-legion-y700-2022",
    name: "Lenovo Legion Y700 2022",
    brand: "Lenovo",
    category: "tablet",
    status: "active",
    specs: "Snapdragon 870 / 8GB or 12GB LPDDR5 RAM / 128GB or 256GB UFS 3.1 Storage / 8.8-inch 2.5K 120Hz LCD Display / 6550mAh Battery / 45W Charging",
    description: "A compact 8.8-inch gaming tablet featuring a 120Hz 2.5K display with 100% DCI-P3 coverage, Snapdragon 870 platform, LPDDR5 memory and UFS 3.1 storage, dual JBL speakers, dual X-axis linear motors, and an 8500mm² VC heat dissipation system for sustained gaming performance.",
    icon: "material-symbols:tablet",
    featured: false,
    year: "2022",
    link: "https://www.lenovo.com/"
  },
  {
    id: "moto-g9-power",
    name: "Moto G9 Power",
    brand: "Motorola",
    category: "phone",
    status: "active",
    specs: "Snapdragon 662 / 4GB RAM / 128GB Storage / 6.8-inch HD+ Display / 6000mAh Battery",
    description: "A budget-focused smartphone featuring a massive 6000mAh battery, a 6.8-inch HD+ IPS display, and a 64MP triple-camera setup, designed for exceptional endurance and everyday performance.[reference:0][reference:1]",
    icon: "material-symbols:smartphone",
    featured: true,
    year: "2020",
    link: "https://www.motorola.com/"
  },
  {
    id: "xperia-5",
    name: "Sony Xperia 5",
    brand: "Sony",
    category: "phone",
    status: "active",
    specs: "Snapdragon 855 / 6GB RAM / 64GB Storage / 6.1-inch FHD+ HDR OLED Display / 3140mAh Battery",
    description: "A compact flagship featuring a 6.1-inch 21:9 CinemaWide FHD+ HDR OLED display, powered by the Snapdragon 855 platform with 6GB RAM and 128GB storage, equipped with a versatile triple 12MP camera system and IP65/68 water resistance.[reference:0][reference:1][reference:2]",
    icon: "material-symbols:smartphone",
    featured: false,
    year: "2019",
    link: "https://www.sony.com/electronics/smartphones/xperia-5"
  },
  {
    id: "moondrop-chu-2",
    name: "Moondrop CHU II",
    brand: "Moondrop",
    category: "audio",
    status: "active",
    specs: "10mm Dynamic Driver / 18Ω Impedance / 119dB/Vrms Sensitivity / 15Hz-38kHz Frequency Response / 0.78mm 2-Pin Detachable Cable",
    description: "A high-performance wired in-ear monitor featuring an aluminum-magnesium alloy composite diaphragm dynamic driver, zinc alloy cast housing, replaceable acoustic filters, and ultra-low nonlinear distortion.",
    icon: "material-symbols:headphones-rounded",
    featured: false,
    year: "2023",
    link: "https://moondroplab.com/en/products/chu-ii"
  }
];

/** 获取所有设备数据列表 */
export function getDevicesList(): DeviceItem[] {
	return devicesData;
}
