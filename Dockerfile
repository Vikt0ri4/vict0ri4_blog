# syntax=docker/dockerfile:1
# ============================================================
# vict0ri4 博客 (部署实验台, docker/podman 双兼容)
# 上游: LyraVoid/Shirone (MIT, © 2024 saicaca) — site/ 源码已 vendor 入本仓库
# 严格遵循 https://docs.shirone.mysqil.com/guide/get-started/
#   环境要求: Node >= 22.12 | pnpm 9.x (仓库锁定 pnpm@9.14.4) | Git
# 拓扑: 与反代容器同处 bridge 网络, 本容器监听 8080 不发布端口,
#       由 vict0ri4-proxy 作为唯一对外入口发布 80。
# ============================================================

# 构建阶段
FROM node:22-slim AS builder

# 部署地址: 构建期注入 (site)
ARG SITE_URL=http://127.0.0.1/

ENV BUILD_SITE_URL=${SITE_URL}

# 文档推荐路径: corepack 启用 pnpm
ENV PNPM_HOME="/pnpm" \
  PATH="/pnpm:$PATH"

RUN corepack enable \
  && corepack prepare pnpm@9.14.4 --activate \
  && pnpm --version

WORKDIR /app

COPY site/package.json site/pnpm-lock.yaml site/.npmrc ./
RUN pnpm install --frozen-lockfile

COPY site/ ./

RUN sed -i "s|^\(\s*site: \).*|\1\"${BUILD_SITE_URL}\",|" src/config/siteConfig.ts \
  && pnpm check \
  && { ok=0; for i in 1 2 3; do \
         if pnpm build; then ok=1; break; fi; \
         echo "[build] attempt $i failed (font CDN flake), retrying in 10s"; sleep 10; \
       done; [ "$ok" = 1 ]; }

# 运行阶段 
FROM nginx:alpine

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
