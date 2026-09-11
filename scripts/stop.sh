#!/usr/bin/env bash
# kjrin710_blog — 停止并移除容器 (自动探测 docker/podman)
set -euo pipefail
cd "$(dirname "$0")/.."

if command -v docker >/dev/null 2>&1; then R=docker
elif command -v podman >/dev/null 2>&1; then R=podman
else echo "!! 未找到 docker 或 podman"; exit 1; fi
echo "==> 使用运行时: $R"

echo "==> 移除容器 kjrin710-blog / kjrin710-proxy"
$R rm -f kjrin710-blog kjrin710-proxy >/dev/null 2>&1 || echo "(无残留容器)"

echo "==> 网络 kjrin710-net 保留(重建容器直接复用); 如需彻底删除: $R network rm kjrin710-net"
