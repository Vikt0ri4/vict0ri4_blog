#!/usr/bin/env bash
# vict0ri4_blog — 停止并移除容器 (自动探测 docker/podman)
set -euo pipefail
cd "$(dirname "$0")/.."

if command -v docker >/dev/null 2>&1; then R=docker
elif command -v podman >/dev/null 2>&1; then R=podman
else echo "!! 未找到 docker 或 podman"; exit 1; fi
echo "==> 使用运行时: $R"

echo "==> 移除容器 vict0ri4-blog / vict0ri4-proxy"
$R rm -f vict0ri4-blog vict0ri4-proxy >/dev/null 2>&1 || echo "(无残留容器)"

echo "==> 网络 vict0ri4-net 保留(重建容器直接复用); 如需彻底删除: $R network rm vict0ri4-net"
