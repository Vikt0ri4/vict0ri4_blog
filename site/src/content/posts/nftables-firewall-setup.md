---
title: "nftables 防火墙搭建记录"
published: 2026-06-19
description: "Gentoo 上使用 nftables 建立白名单防火墙策略"
tags: [Gentoo, nftables, Firewall, Security, OpenRC]
category: Guides
lang: zh
draft: false
---

# nftables 防火墙搭建记录

> 主机：Gentoo Linux（OpenRC）  
> 网络：校园网台式机  
> 日期：2026-06-19

---

## 背景

- 校园网是巨型二层局域网，成百上千人同网段，需要防火墙
- 主机还跑着 libvirt（virt-manager）虚拟机（Win11，macvtap bridge）
- 之前 nftables 开机报错：libvirt 的 iptables 兼容规则（`virbr0`）与 nftables 冲突

## 解决方案

**直接用纯 nftables 原生命令，全覆盖旧规则，极简白名单入站策略。**

---

## 操作步骤

### 1. 清空旧规则 & 建表

```bash
sudo nft flush ruleset
sudo nft add table inet filter
```

### 2. 建链

```bash
# 入站：默认丢弃（白名单策略）
sudo nft add chain inet filter input \
  '{ type filter hook input priority 0; policy drop; }'

# 出站：默认放行
sudo nft add chain inet filter output \
  '{ type filter hook output priority 0; policy accept; }'

# 转发：默认放行（IP 转发默认关闭，无害）
sudo nft add chain inet filter forward \
  '{ type filter hook forward priority 0; policy accept; }'
```

### 3. 添加放行规则

```bash
# 本机回环
sudo nft add rule inet filter input iif lo accept

# 允许已建立/相关连接（你自己主动发出的，回复要放回来）
sudo nft add rule inet filter input ct state established,related accept

# 允许 ping
sudo nft add rule inet filter input icmp type echo-request accept
sudo nft add rule inet filter input ip6 nexthdr icmpv6 accept

# SSH（如果需要从别的机器连进来）
sudo nft add rule inet filter input tcp dport 22 accept
```

### 4. 持久化规则

> ⚠️ `sudo ... > file` 红色大坑：重定向是 shell 做的而不是 sudo，会 Permission denied！

```bash
# 正确写法
sudo nft list ruleset | sudo tee /var/lib/nftables/rules-save
```

### 5. 开机自启

```bash
sudo rc-update add nftables default
sudo rc-service nftables start
```

---

## 最终规则集

```
table inet filter {
    chain input {
        type filter hook input priority filter; policy drop;
        iif "lo" accept
        ct state established,related accept
        icmp type echo-request accept
        ip6 nexthdr ipv6-icmp accept
        tcp dport 22 accept
    }

    chain output {
        type filter hook output priority filter; policy accept;
    }

    chain forward {
        type filter hook forward priority filter; policy accept;
    }
}
```

---

## 常用维护命令

| 操作 | 命令 |
|------|------|
| 查看规则 | `sudo nft list ruleset` |
| 添加端口 | `sudo nft add rule inet filter input tcp dport <端口> accept` |
| 删除规则 | `sudo nft -a list chain inet filter input` 查 handle → `sudo nft delete rule inet filter input handle <编号>` |
| 临时停用 | `sudo rc-service nftables stop` |
| 重新加载 | `sudo rc-service nftables restart` |
| 添加规则后持久化 | `sudo nft list ruleset \| sudo tee /var/lib/nftables/rules-save` |

---

## 如果要加更多端口

```bash
# HTTP / HTTPS
sudo nft add rule inet filter input tcp dport {80, 443} accept

# Minecraft
sudo nft add rule inet filter input tcp dport 25565 accept

# 自定义范围
sudo nft add rule inet filter input tcp dport 8000-8100 accept

# 最后记得保存！
sudo nft list ruleset | sudo tee /var/lib/nftables/rules-save
```

---

## 已知问题 & 教训

1. **libvirt `virbr0` 与 nftables 冲突**：libvirt 默认网络会注入 iptables 规则，nftables iptables 兼容层解析不了。用 macvtap bridge 无影响，如果以后启用 NAT 虚拟网络需要额外处理。
2. **`>` 重定向不跟着 sudo**：必须用 `tee` 或用 `sudo sh -c '...'` 包起来。
