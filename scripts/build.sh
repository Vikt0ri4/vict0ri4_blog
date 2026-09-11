#!/usr/bin/env bash
# kjrin710_blog — 一键构建两个镜像 (自动探测 docker/podman)
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

if command -v docker >/dev/null 2>&1; then R=docker
elif command -v podman >/dev/null 2>&1; then R=podman
else echo "!! 未找到 docker 或 podman"; exit 1; fi
echo "==> 使用运行时: $R"

# 站点正式地址 (文档: 部署前更新 site); 默认取当前主出口 IP, 可用环境变量覆盖
SITE_URL="${SITE_URL:-$(site_url)}"
echo "==> 当前主出口 IP: $(detect_ip) (若访问不通, 先 ip -4 route get 1.1.1.1 查实际地址)"

echo "==> [1/2] 构建博客镜像 kjrin710-blog:latest (SITE_URL=$SITE_URL)"
$R build --build-arg SITE_URL="$SITE_URL" -t kjrin710-blog:latest . 2>&1 | tee /tmp/kjrin710_build.log

echo "==> [2/2] 构建反代镜像 kjrin710-proxy:latest"
$R build -t kjrin710-proxy:latest proxy/

echo "==> 完成:"
$R images | grep -E 'kjrin710-(blog|proxy)'
