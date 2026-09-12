# syntax=docker/dockerfile:1
# vict0ri4_blog 反代容器 — docker/podman 双兼容, 且兼容 Void Linux 等 runit 发行版
# upstream 经模板 envsubst 注入: bridge 模式=vict0ri4-blog, pasta 降级=host.containers.internal
FROM nginx:alpine

# 清掉官方默认 server 块, 避免与我们的 80 default_server 冲突
RUN rm -f /etc/nginx/conf.d/default.conf

COPY default.conf.template /etc/nginx/templates/default.conf.template

ENV BLOG_UPSTREAM=vict0ri4-blog

EXPOSE 80
