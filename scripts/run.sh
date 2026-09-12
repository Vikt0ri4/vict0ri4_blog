#!/usr/bin/env bash
# vict0ri4_blog — 起网络 + 两容器 (docker/podman 双兼容; Void/runit 发行版亦适用)
#
# 网络策略(自动降级):
#   1) 首选 bridge 网络 + 容器名 DNS, 博客容器不发布端口(最干净)
#   2) 若内核缺少 xt_comment 等导致 netavark/bridge 建规则失败(常见于自制内核/Void 精简内核),
#      自动降级为 pasta: 博客发布到宿主 8080 作内部跳板, 反代经 host.containers.internal 访问
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

NET=vict0ri4-net
BLOG=vict0ri4-blog
PROXY=vict0ri4-proxy
BLOG_IMG=vict0ri4-blog:latest
PROXY_IMG=vict0ri4-proxy:latest
NET_SUBNET=10.89.88.0/24
BLOG_IP=10.89.88.10

# --- 运行时探测 ---
if command -v docker >/dev/null 2>&1; then R=docker
elif command -v podman >/dev/null 2>&1; then R=podman
else
    echo "!! 未找到 docker 或 podman, 请执行: bash scripts/setup-host.sh"
    exit 1
fi
echo "==> 使用运行时: $R"

# --- rootless 发布 80 的前置检查 ---
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
        echo "   请执行: bash scripts/setup-host.sh   (按提示完成一次性配置)"
        exit 1
    fi
fi

img_exists() { $R image inspect "$1" >/dev/null 2>&1; }
img_exists "$BLOG_IMG"  || { echo "!! 缺少 $BLOG_IMG, 先跑 scripts/build.sh"; exit 1; }
img_exists "$PROXY_IMG" || { echo "!! 缺少 $PROXY_IMG, 先跑 scripts/build.sh"; exit 1; }

cleanup_containers() { $R rm -f "$BLOG" "$PROXY" >/dev/null 2>&1 || true; }

bridge_possible() {
    # 测试/调试用: FORCE_PASTA=1 强制走降级路径
    [ "${FORCE_PASTA:-0}" = "1" ] && return 1
    # 内核缺 xt_comment 时 netavark 必然失败, 直接判定不可用
    if [ ! -e /sys/module/xt_comment ] && ! modinfo xt_comment >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

start_bridge() {
    if [ "$R" = docker ]; then
        $R network inspect "$NET" >/dev/null 2>&1 || $R network create --subnet="$NET_SUBNET" "$NET" >/dev/null
    else
        $R network exists "$NET" || $R network create --subnet "$NET_SUBNET" "$NET" >/dev/null
    fi
    cleanup_containers
    echo "==> [bridge] 启动 $BLOG (内网 $BLOG_IP:8080, 不发布端口)"
    $R run -d --name "$BLOG" --network "$NET" --ip "$BLOG_IP" "$BLOG_IMG" >/dev/null || return 1
    echo "==> [bridge] 启动 $PROXY (唯一对外入口, 发布 80)"
    $R run -d --name "$PROXY" --network "$NET" -p 80:80 \
        -e BLOG_UPSTREAM="$BLOG" "$PROXY_IMG" >/dev/null || return 1
    echo "    上游: http://$BLOG:8080 (容器名 DNS)"
    return 0
}

start_pasta() {
    cleanup_containers
    echo "==> [pasta 降级] 启动 $BLOG (宿主 8080 作内部跳板)"
    $R run -d --name "$BLOG" -p 0.0.0.0:8080:8080 "$BLOG_IMG" >/dev/null || return 1
    echo "==> [pasta 降级] 启动 $PROXY (唯一对外入口, 发布 80)"
    $R run -d --name "$PROXY" -p 80:80 \
        -e BLOG_UPSTREAM=host.containers.internal "$PROXY_IMG" >/dev/null || return 1
    echo "    上游: http://host.containers.internal:8080"
    return 0
}

MODE=""
if bridge_possible && start_bridge; then
    MODE=bridge
elif start_pasta; then
    MODE=pasta
else
    echo "!! 两种网络模式均启动失败, 请贴日志: $R logs $PROXY ; $R logs $BLOG"
    exit 1
fi

sleep 2
echo "==> 状态 ($MODE 模式):"
$R ps --format '{{.Names}}\t{{.Status}}\t{{.Ports}}'
echo
echo "==> 访问方式"
echo "  本机:      http://127.0.0.1/"
if ip_is_dynamic; then
    echo "  局域网:    本机地址由 DHCP 动态分配(会变), 请自行查询当前地址:"
    echo "               ip route get 1.1.1.1     # 输出中 src 后面的就是本机地址"
else
    echo "  局域网:    http://$(detect_ip)/   (静态地址)"
fi
if [ "$MODE" = "pasta" ]; then
    echo "  提示: 当前为 pasta 降级模式(内核不支持 bridge/netfilter 组合时自动启用),"
    echo "        博客静态页面会额外监听宿主 8080, 便于反代经宿主别名访问。"
fi
