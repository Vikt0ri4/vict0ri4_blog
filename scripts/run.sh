#!/usr/bin/env bash
# kjrin710_blog — 起 bridge 网络 + 两容器 (docker/podman 双兼容)
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

NET=kjrin710-net
BLOG=kjrin710-blog
PROXY=kjrin710-proxy
BLOG_IMG=kjrin710-blog:latest
PROXY_IMG=kjrin710-proxy:latest
NET_SUBNET=10.89.88.0/24
BLOG_IP=10.89.88.10

# --- 运行时探测 ---
if command -v docker >/dev/null 2>&1; then
  R=docker
elif command -v podman >/dev/null 2>&1; then
  R=podman
else
  echo "!! 未找到 docker 或 podman, 请执行: bash scripts/setup-host.sh"
  exit 1
fi
echo "==> 使用运行时: $R"

# --- 前置检查: rootless 运行时发布 80 需要挂载低端口 ---
rootless=0
if [ "$R" = docker ]; then
  $R info --format '{{json .SecurityOptions}}' 2>/dev/null | grep -q rootless && rootless=1
else
  [ "$($R info --format '{{.Host.Security.Rootless}}' 2>/dev/null)" = "true" ] && rootless=1
fi
if [ "$rootless" -eq 1 ]; then
  port_start=$(cat /proc/sys/net/ipv4/ip_unprivileged_port_start 2>/dev/null || echo 1024)
  if [ "$port_start" -gt 80 ]; then
    echo "!! $R 为 rootless 且 ip_unprivileged_port_start=$port_start, 无法发布 80。"
    echo "   请执行: bash scripts/setup-host.sh   (按提示以 root 完成一次性配置)"
    exit 1
  fi
fi

img_exists() { $R image inspect "$1" >/dev/null 2>&1; }
img_exists "$BLOG_IMG" || {
  echo "!! 缺少 $BLOG_IMG, 先跑 scripts/build.sh"
  exit 1
}
img_exists "$PROXY_IMG" || {
  echo "!! 缺少 $PROXY_IMG, 先跑 scripts/build.sh"
  exit 1
}

# --- 网络: 统一 bridge, 固定子网(博客静态 IP, 防重启漂移致反代缓存失效) ---
if [ "$R" = docker ]; then
  $R network inspect "$NET" >/dev/null 2>&1 || {
    echo "==> 创建网络 $NET ($NET_SUBNET)"
    $R network create --subnet="$NET_SUBNET" "$NET" >/dev/null
  }
else
  $R network exists "$NET" || {
    echo "==> 创建网络 $NET ($NET_SUBNET)"
    $R network create --subnet "$NET_SUBNET" "$NET" >/dev/null
  }
fi

# --- 清理残留容器后重建 ---
$R rm -f "$BLOG" "$PROXY" >/dev/null 2>&1 || true

echo "==> 启动 $BLOG (bridge 内网 $BLOG_IP:8080, 不发布端口)"
$R run -d --name "$BLOG" --network "$NET" --ip "$BLOG_IP" "$BLOG_IMG"

echo "==> 启动 $PROXY (唯一对外入口, 发布 80)"
$R run -d --name "$PROXY" --network "$NET" -p 80:80 "$PROXY_IMG"

sleep 2
echo "==> 状态:"
$R ps --format '{{.Names}}\t{{.Status}}\t{{.Ports}}'
echo
echo "==> 访问方式"
echo "  本机:      http://127.0.0.1/"
if ip_is_dynamic; then
  echo "  局域网:    本机地址由 DHCP 动态分配(会变), 请自行查询当前地址:"
  echo "               ip -4 route get 1.1.1.1     # 输出中 src 后面的就是本机地址"
  echo "             然后浏览器访问 http://<上面查到的地址>/"
else
  echo "  局域网:    http://$(detect_ip)/   (静态地址)"
fi
