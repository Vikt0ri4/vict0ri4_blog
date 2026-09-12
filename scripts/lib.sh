#!/usr/bin/env bash
# vict0ri4_blog 共享函数库 (被 build.sh / run.sh source)

# 探测本机主出口 IP (默认路由 src): 机器 IP 由 DHCP 动态分配, 禁止写死。
detect_ip() {
    local ip=""
    ip=$(ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.*src \([0-9.]*\).*/\1/p')
    [ -z "$ip" ] && ip=$(ip -4 route get default 2>/dev/null | sed -n 's/.*src \([0-9.]*\).*/\1/p')
    [ -z "$ip" ] && ip=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)
    echo "${ip:-127.0.0.1}"
}

# 完整访问地址 (不带尾斜杠的 IP 由调用方拼)
site_url() {
    echo "http://$(detect_ip)/"
}

# 当前主出口 IP 是否由 DHCP 动态分配 (动态则不应向用户展示固定地址)
ip_is_dynamic() {
    ip -4 -o addr show scope global 2>/dev/null \
        | grep -F "$(detect_ip)/" | grep -q 'dynamic'
}
