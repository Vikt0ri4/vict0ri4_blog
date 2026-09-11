# syntax=docker/dockerfile:1
# kjrin710_blog 反代容器 — docker/podman 双兼容 (统一走 bridge + 容器名 DNS)
FROM nginx:alpine

# 清掉官方默认 server 块, 避免与我们的 80 default_server 冲突
RUN rm -f /etc/nginx/conf.d/default.conf

COPY default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
