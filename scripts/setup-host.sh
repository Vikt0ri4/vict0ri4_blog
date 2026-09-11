#!/usr/bin/env bash
# kjrin710_blog — 宿主机首次使用引导 (podman/docker 通用)
# 用法: bash scripts/setup-host.sh      # 只检查并给出指引
#       sudo bash scripts/setup-host.sh # 由 root 执行, 可直接写入 sysctl 配置
set -uo pipefail

R=""
command -v docker >/dev/null 2>&1 && R=docker
[ -z "$R" ] && command -v podman >/dev/null 2>&1 && R=podman

echo "==>[1/4] 容器运行时"
if [ -z "$R" ]; then
    echo "  !! 未找到 docker 或 podman, 请先安装其一, 例如:"
    echo "     Gentoo : sudo emerge -av app-containers/podman"
    echo "     Debian : sudo apt install podman"
    echo "     Fedora : sudo dnf install podman"
    echo "     Arch   : sudo pacman -S podman"
    exit 1
fi
echo "  ✓ 已安装: $R ($($R --version 2>/dev/null | head -1))"

echo "==>[2/4] 基础工具"
for t in ip curl bash; do
    if command -v "$t" >/dev/null 2>&1; then echo "  ✓ $t"; else echo "  ! 建议安装: $t"; fi
done

echo "==>[3/4] 内核网络能力 (bridge / xt_comment)"
if [ -e /sys/module/xt_comment ] || modinfo xt_comment >/dev/null 2>&1; then
    echo "  ✓ xt_comment 可用 (bridge 网络需要)"
else
    echo "  ! 未检测到 xt_comment: 内核需支持 netfilter bridge (现代发行版通常已内置)"
fi

echo "==>[4/4] 低端口绑定 (rootless 发布 80 端口需要)"
port_start=$(cat /proc/sys/net/ipv4/ip_unprivileged_port_start 2>/dev/null || echo 1024)
rootless=0
if [ "$R" = docker ]; then
    $R info --format '{{json .SecurityOptions}}' 2>/dev/null | grep -q rootless && rootless=1
else
    [ "$($R info --format '{{.Host.Security.Rootless}}' 2>/dev/null)" = "true" ] && rootless=1
fi

if [ "$rootless" -eq 0 ]; then
    echo "  ✓ 运行时为 rootful, 可直接绑定 80, 无需额外配置"
elif [ "$port_start" -le 80 ]; then
    echo "  ✓ rootless 且 ip_unprivileged_port_start=$port_start, 可绑 80"
else
    echo "  ! rootless 且 ip_unprivileged_port_start=$port_start (无法绑定 80)"
    if [ "$(id -u)" -eq 0 ]; then
        echo 'net.ipv4.ip_unprivileged_port_start=0' > /etc/sysctl.d/99-unprivileged-ports.conf
        sysctl -w net.ipv4.ip_unprivileged_port_start=0 >/dev/null
        echo "  ✓ 已由 root 写入并生效"
    else
        echo "    请执行(需 root, 一次性, 永久生效):"
        echo "      echo 'net.ipv4.ip_unprivileged_port_start=0' | sudo tee /etc/sysctl.d/99-unprivileged-ports.conf"
        echo "      sudo sysctl -w net.ipv4.ip_unprivileged_port_start=0"
        exit 1
    fi
fi

echo
echo "就绪。后续步骤:"
echo "  scripts/build.sh   # 构建镜像"
echo "  scripts/run.sh     # 启动服务"
