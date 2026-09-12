#!/usr/bin/env bash
# vict0ri4_blog — Void Linux 构建兼容性测试
# 在 podman/docker 里拉起 Void 容器, 用 Void 自带的 nodejs/xbps 完整跑一遍项目构建。
# 用法: bash tests/void-build-test.sh
#   VOID_IMAGE=...  覆盖镜像 (默认 docker.io/voidlinux/voidlinux:latest)
#   VOID_MIRROR=... 覆盖镜像源 (默认清华 TUNA)
set -uo pipefail
cd "$(dirname "$0")/.."

if command -v docker >/dev/null 2>&1; then R=docker; else R=podman; fi
IMG="${VOID_IMAGE:-docker.io/voidlinux/voidlinux:latest}"
MIRROR="${VOID_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/voidlinux/current}"
SITE_DIR="$(pwd)/site"

echo "==> 运行时: $R | Void 镜像: $IMG"
echo "==> 源: $MIRROR"

OUT=$($R run --rm -v "$SITE_DIR:/src:ro" "$IMG" sh -c '
set -e
mkdir -p /etc/xbps.d
echo "repository='"$MIRROR"'" > /etc/xbps.d/00-repository-main.conf
xbps-install -Syu xbps -y >/tmp/a.log 2>&1 || { echo "XBPS_UPDATE_FAIL"; tail -3 /tmp/a.log; exit 1; }
xbps-install -Sy nodejs git curl bash python3 make gcc pkgconf -y >/tmp/b.log 2>&1 || { echo "XBPS_INSTALL_FAIL"; tail -5 /tmp/b.log; exit 1; }
echo "NODE=$(node -v)"
corepack enable >/dev/null 2>&1
corepack prepare pnpm@9.14.4 --activate >/dev/null 2>&1
echo "PNPM=$(pnpm --version)"
cp -r /src /work && cd /work
pnpm install --frozen-lockfile >/tmp/i.log 2>&1 || { echo "INSTALL_FAIL"; tail -5 /tmp/i.log; exit 1; }
echo "INSTALL=ok"
pnpm check >/tmp/c.log 2>&1 || { echo "CHECK_FAIL"; tail -5 /tmp/c.log; exit 1; }
echo "CHECK=ok"
(pnpm build >/tmp/bb.log 2>&1 || pnpm build >>/tmp/bb.log 2>&1) || { echo "BUILD_FAIL"; tail -8 /tmp/bb.log; exit 1; }
echo "BUILD=ok"
echo "HTML=$(find dist -name "*.html" | wc -l)"
echo "WOFF2=$(find dist -name "*.woff2" | wc -l)"
echo "PAGEFIND=$(ls dist/pagefind/*.js 2>/dev/null | wc -l)"
' 2>&1)

echo "$OUT" | sed 's/^/  /'

node_v=$(echo "$OUT" | sed -n 's/^NODE=//p' | head -1)
pnpm_v=$(echo "$OUT" | sed -n 's/^PNPM=//p' | head -1)
html=$(echo "$OUT" | sed -n 's/^HTML=//p' | head -1)
woff2=$(echo "$OUT" | sed -n 's/^WOFF2=//p' | head -1)
pf=$(echo "$OUT" | sed -n 's/^PAGEFIND=//p' | head -1)

if echo "$OUT" | grep -q 'BUILD=ok' && [ "${html:-0}" -gt 0 ]; then
  echo
  echo "✅ Void 构建兼容: node $node_v / pnpm $pnpm_v / html $html / woff2 $woff2 / pagefind $pf"
  exit 0
fi
echo
echo "❌ Void 构建失败 (见上方日志)"
exit 1
