#!/usr/bin/env bash
# vict0ri4_blog — 宿主机引导 (podman/docker; 含 Void Linux / runit 发行版适配)
# 用法: bash scripts/setup-host.sh          # 检查 + 指引
#       sudo bash scripts/setup-host.sh     # 需 root 的一次性配置直接完成
set -uo pipefail

# ---- 发行版识别 ----
DISTRO="unknown"
if [ -r /etc/os-release ]; then
    . /etc/os-release
    DISTRO="${ID:-unknown}"
fi

R=""
command -v docker >/dev/null 2>&1 && R=docker
[ -z "$R" ] && command -v podman >/dev/null 2>&1 && R=podman

echo "==>[0/4] 发行版"
echo "  $DISTRO ($(uname -r))"

echo "==>[1/4] 容器运行时"
if [ -z "$R" ]; then
    echo "  !! 未找到 docker 或 podman, 安装方式:"
    case "$DISTRO" in
        void)   echo "     Void   : sudo xbps-install -S podman    # 或 docker"
                echo "     (若 xbps 拉取失败, 先配镜像源: echo 'repository=https://mirrors.tuna.tsinghua.edu.cn/voidlinux/current' | sudo tee /etc/xbps.d/00-repository-main.conf)" ;;
        gentoo) echo "     Gentoo : sudo emerge -av app-containers/podman" ;;
        debian|ubuntu) echo "     Debian : sudo apt install podman" ;;
        fedora) echo "     Fedora : sudo dnf install podman" ;;
        arch)   echo "     Arch   : sudo pacman -S podman" ;;
        *)      echo "     请用发行版包管理器安装 podman 或 docker" ;;
    esac
    exit 1
fi
echo "  ✓ 已安装: $R ($($R --version 2>/dev/null | head -1))"

echo "==>[2/4] 基础工具"
for t in ip curl bash python3; do
    if command -v "$t" >/dev/null 2>&1; then echo "  ✓ $t"; else
        echo "  ! 建议安装: $t"
        [ "$DISTRO" = void ] && echo "      sudo xbps-install -S $t"
    fi
done

echo "==>[3/4] 内核网络能力 (bridge 需要 xt_comment)"
if [ -e /sys/module/xt_comment ] || modinfo xt_comment >/dev/null 2>&1; then
    echo "  ✓ xt_comment 可用 → bridge 模式"
else
    echo "  ! 未检测到 xt_comment → 项目会自动降级为 pasta 模式(功能不受影响)"
    if [ "$DISTRO" = void ]; then
        echo "      Void: 自带内核通常包含该模块; 若缺失可尝试: sudo modprobe xt_comment"
        echo "            仍不可用时无需处理, scripts/run.sh 会自动使用 pasta"
    fi
fi

echo "==>[4/4] 低端口绑定 (rootless 发布 80 需要)"
port_start=$(cat /proc/sys/net/ipv4/ip_unprivileged_port_start 2>/dev/null || echo 1024)
rootless=0
if [ "$R" = docker ]; then
    $R info --format '{{json .SecurityOptions}}' 2>/dev/null | grep -q rootless && rootless=1
else
    [ "$($R info --format '{{.Host.Security.Rootless}}' 2>/dev/null)" = "true" ] && rootless=1
fi

if [ "$rootless" -eq 0 ]; then
    echo "  ✓ rootful 运行时, 可直接绑定 80"
elif [ "$port_start" -le 80 ]; then
    echo "  ✓ rootless 且 ip_unprivileged_port_start=$port_start"
else
    echo "  ! rootless 且 ip_unprivileged_port_start=$port_start (无法绑 80)"
    if [ "$(id -u)" -eq 0 ]; then
        echo 'net.ipv4.ip_unprivileged_port_start=0' > /etc/sysctl.d/99-unprivileged-ports.conf
        sysctl -w net.ipv4.ip_unprivileged_port_start=0 >/dev/null 2>&1 || true
        # Void 等发行版兼容: 同时写入 /etc/sysctl.conf
        grep -q '^net.ipv4.ip_unprivileged_port_start' /etc/sysctl.conf 2>/dev/null \
          || echo 'net.ipv4.ip_unprivileged_port_start=0' >> /etc/sysctl.conf
        echo "  ✓ 已写入并生效 (重启后由 sysctl.d / sysctl.conf 保持)"
    else
        echo "    执行(需 root):" 
        echo "      echo 'net.ipv4.ip_unprivileged_port_start=0' | sudo tee /etc/sysctl.d/99-unprivileged-ports.conf"
        echo "      echo 'net.ipv4.ip_unprivileged_port_start=0' | sudo tee -a /etc/sysctl.conf"
        echo "      sudo sysctl -w net.ipv4.ip_unprivileged_port_start=0"
        exit 1
    fi
fi

echo
echo "就绪。后续步骤:"
echo "  scripts/build.sh   # 构建镜像"
echo "  scripts/run.sh     # 启动服务"
if [ "$DISTRO" = void ]; then
    echo
    echo "Void/runit 用户可选: 用 runit/vict0ri4/run 做开机自启 (见该文件顶部注释)"
fi
