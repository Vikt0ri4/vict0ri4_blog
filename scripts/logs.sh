#!/usr/bin/env bash
# vict0ri4_blog — 查看容器日志 (默认反代, 可传参 blog)
set -euo pipefail
cd "$(dirname "$0")/.."

if command -v docker >/dev/null 2>&1; then R=docker
elif command -v podman >/dev/null 2>&1; then R=podman
else echo "!! 未找到 docker 或 podman"; exit 1; fi

TARGET="${1:-proxy}"
case "$TARGET" in
    blog)  NAME=vict0ri4-blog ;;
    proxy) NAME=vict0ri4-proxy ;;
    *)     echo "用法: $0 [blog|proxy]"; exit 1 ;;
esac

exec $R logs -f --tail 50 "$NAME"
