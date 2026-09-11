# kjrin710_blog — kjrin710 博客部署实验台 (docker/podman 双兼容)

## 结构
```
kjrin710_blog/
├── Dockerfile          # 博客镜像: node:22-slim 构建 → nginx:alpine 托管 dist
├── nginx/default.conf  # 博客容器 nginx (监听 8080, gzip/缓存/安全头)
├── proxy/
│   ├── Dockerfile      # 反代镜像: nginx:alpine
│   └── default.conf    # 反代 80 → 容器名 kjrin710-blog:8080
├── compose.yaml        # docker compose 入口 (有 compose 时最省事)
├── site/               # 上游 LyraVoid/Shirone 克隆 (内容/配置都在这改)
├── scripts/            # build.sh / run.sh / stop.sh / logs.sh (自动探测 docker|podman)
└── init.d/kjrin710     # OpenRC 样例 (未安装, 验证后自行 rc-update)
```

## 拓扑 (docker/podman 完全一致)
- bridge 网络 `kjrin710-net`, 容器间用容器名 DNS 互访
- `kjrin710-blog`  监听 8080, **不发布端口**, 只存在于内部网络
- `kjrin710-proxy` 发布宿主 `80:80`, `proxy_pass http://kjrin710-blog:8080`
- 前置要求: 内核需支持 bridge + xt_comment (现代发行版默认都有);
  rootless 绑 80 需 sysctl (见下)

## 换新机器 (只有 docker 的 Linux)
1. 拷整个目录过去; 装好 docker
2. `scripts/build.sh` 或 `docker compose up -d --build`
3. 验证 `curl http://127.0.0.1/`
rootful docker 无需 sysctl; rootless docker/podman 绑 80 才需要。

## 前置条件 (首次使用先跑引导脚本)
```sh
bash scripts/setup-host.sh          # 检查运行时/工具/内核能力/低端口权限
sudo bash scripts/setup-host.sh     # 需要配置 sysctl 时用 root 跑一次
```
rootless 运行时绑 80 需要 `ip_unprivileged_port_start<=80`; rootful docker 无需配置。

## 使用
```sh
scripts/build.sh        # 构建 (自动探测运行时)
scripts/run.sh          # 起网络 + 两容器
scripts/logs.sh blog|proxy
scripts/stop.sh         # 停并删容器 (网络保留)
```

## 换内容 = 重新构建
静态站, 内容烘焙进镜像:
```sh
scripts/stop.sh && scripts/build.sh && scripts/run.sh
```
或 compose: `docker compose up -d --build`

## 测试
```sh
bash tests/stability.sh              # 全量 (S1 构建 / S2 生命周期 / S3 HTTP / S4 故障恢复 / S5 文档合规 / S6 docker 兼容)
bash tests/stability.sh s3 s5        # 指定缝
PATH="$PWD/tests/docker-shim:$PATH" bash tests/stability.sh   # 用 podman 垫片模拟 docker 跑全套
```
注: 本机无真实 docker, 用 `tests/docker-shim/docker`(转发 podman) 验证 docker 代码路径;
真实 docker 机器上建议再跑一次 `docker compose up -d --build` 确认 compose 路径。

## 文档合规记录
严格对照 docs.shirone.mysqil.com/guide/get-started/:
- ✅ Node >= 22.12 (node:22-slim) / pnpm 9.14.4 (corepack) / --frozen-lockfile
- ✅ 克隆自 LyraVoid/Shirone / .npmrc 版本强制 / 纯静态 dist (无 SSR adapter)
- ✅ 部署序列: site 注入 (build-arg SITE_URL, 宿主克隆保持纯净) → pnpm check → pnpm build → Pagefind
- ⚠️ 偏离: 文档另列 `pnpm type-check`, 但上游 HEAD 该命令自身为红 (TS9007/TS9011, isolatedDeclarations
  多处未标注), 上游 CI 只跑 check:manifest + build; 本镜像对齐上游真实标准, 不执行 type-check。
  测试: `bash tests/stability.sh s5`
