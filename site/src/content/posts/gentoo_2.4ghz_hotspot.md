---
title: "Gentoo 2.4GHz WiFi 热点搭建教程"
published: 2026-08-27
description: "把 USB WiFi 网卡变成手机能连的 AP，三步搞定"
tags: [Gentoo, WiFi, Hotspot, OpenRC, hostapd, dnsmasq]
category: Guides
lang: zh
draft: false
---

# Gentoo 2.4GHz WiFi 热点搭建教程

> 把一根 USB WiFi 网卡变成手机能连的 AP，三步搞定。
> 适用：Gentoo + OpenRC + mt7921u（其他网卡同理）

---

## 前提

```bash
# 确认网卡名称（我的是 wlp3s0f0u3）
ip link show | grep wl

# 确认有线网卡名称（我的是 enp37s0）
ip link show | grep en
```

---

## 第一步：装软件

```bash
sudo emerge -av wirelesstools hostapd dnsmasq wireless-regdb
```

---

## 第二步：写配置

### 2.1 AP 配置

```bash
sudo nano /etc/hostapd/hostapd_2g.conf
```

写入（把 `wlp3s0f0u3` 换成你的网卡名，密码改掉）：

```ini
interface=wlp3s0f0u3
driver=nl80211
ssid=MyHotspot
hw_mode=g
channel=6
ieee80211n=1
wmm_enabled=1
auth_algs=1
wpa=2
wpa_passphrase=你的密码
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
rsn_pairwise=CCMP
```

### 2.2 DHCP 配置

```bash
sudo nano /etc/dnsmasq.d/hotspot.conf
```

```ini
interface=wlp3s0f0u3
bind-interfaces
dhcp-range=192.168.42.100,192.168.42.200,12h
dhcp-option=3,192.168.42.1
dhcp-option=6,223.5.5.5
```

---

## 第三步：一键启动

把下面保存为任意脚本跑一遍就行：

```bash
#!/bin/bash
IFACE=wlp3s0f0u3
UPLINK=enp37s0

# 监管域
iw reg set CN

# 拉网卡
ip link set $IFACE up
ip addr add 192.168.42.1/24 dev $IFACE 2>/dev/null

# 转发
sysctl -w net.ipv4.ip_forward=1

# 防火墙：允许手机 DHCP/DNS 进来
nft add rule inet filter input iifname "$IFACE" accept

# 桥接 NAT
iptables -A FORWARD -i $IFACE -o $UPLINK -j ACCEPT 2>/dev/null
iptables -A FORWARD -i $UPLINK -o $IFACE -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null
iptables -t nat -A POSTROUTING -o $UPLINK -j MASQUERADE 2>/dev/null

# 启动
dnsmasq --conf-file=/etc/dnsmasq.d/hotspot.conf
hostapd -B /etc/hostapd/hostapd_2g.conf

echo "✅ 热点已就绪 —— SSID: MyHotspot"
```

---

## 🔧 进阶：做成开机自启服务

新建 `/etc/init.d/hotspot`：

```bash
#!/sbin/openrc-run

IFACE=wlp3s0f0u3
UPLINK=enp37s0
GATEWAY=192.168.42.1

start() {
    iw reg set CN 2>/dev/null
    ip link set $IFACE up
    ip addr add $GATEWAY/24 dev $IFACE 2>/dev/null
    sysctl -w net.ipv4.ip_forward=1 >/dev/null

    # nft: 删光旧规则再加唯一一条
    nft -a list chain inet filter input 2>/dev/null | \
        grep "iifname \"$IFACE\" accept" | \
        grep -oP 'handle \K\d+' | \
        while read h; do nft delete rule inet filter input handle $h 2>/dev/null; done
    nft add rule inet filter input iifname "$IFACE" accept

    iptables -A FORWARD -i $IFACE -o $UPLINK -j ACCEPT 2>/dev/null
    iptables -A FORWARD -i $UPLINK -o $IFACE -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null
    iptables -t nat -A POSTROUTING -o $UPLINK -j MASQUERADE 2>/dev/null

    dnsmasq --conf-file=/etc/dnsmasq.d/hotspot.conf --pid-file=/run/hotspot_dnsmasq.pid
    sleep 1
    hostapd -B -P /run/hotspot_hostapd.pid /etc/hostapd/hostapd_2g.conf
}

stop() {
    [ -f /run/hotspot_hostapd.pid ] && kill $(cat /run/hotspot_hostapd.pid) 2>/dev/null
    [ -f /run/hotspot_dnsmasq.pid ] && kill $(cat /run/hotspot_dnsmasq.pid) 2>/dev/null

    nft -a list chain inet filter input 2>/dev/null | \
        grep "iifname \"$IFACE\" accept" | \
        grep -oP 'handle \K\d+' | \
        while read h; do nft delete rule inet filter input handle $h 2>/dev/null; done

    iptables -D FORWARD -i $IFACE -o $UPLINK -j ACCEPT 2>/dev/null
    iptables -D FORWARD -i $UPLINK -o $IFACE -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null
    iptables -t nat -D POSTROUTING -o $UPLINK -j MASQUERADE 2>/dev/null
}
```

加载：

```bash
sudo chmod +x /etc/init.d/hotspot
sudo rc-update add hotspot default
sudo rc-service hotspot start
```

---

## 防坑两行

```bash
# 1. 别让 dhcpcd 抢 WiFi 网卡
echo 'denyinterfaces wlp3s0f0u3' | sudo tee -a /etc/dhcpcd.conf
sudo rc-service dhcpcd restart

# 2. ch6 不行就换 ch1
sudo sed -i 's/channel=6/channel=1/' /etc/hostapd/hostapd_2g.conf
```

---

## 与 libvirt 虚拟机共存

系统里同时跑热点和 libvirt 虚拟机时，防火墙各用各的、互不污染：

| | 热点 | 虚拟机 |
|---|---|---|
| 防火墙 | `nft` 原生 (`inet filter input`) | `iptables` (`ip filter FORWARD`, `ip nat POSTROUTING`) |
| 网段 | 192.168.42.0/24 | 192.168.122.0/24 |
| 接口 | wlp3s0f0u3 | virbr0 |

关键一步——让 libvirt 用 iptables 而非 nft：

```bash
echo 'firewall_backend = "iptables"' | sudo tee /etc/libvirt/network.conf
sudo rc-service libvirtd restart
sudo virsh net-start default
sudo virsh net-autostart default
```

两者网段不重叠，`rc-service hotspot restart` 和 `virsh net-start default` 各自独立，永不打架。

---

## 日常

```bash
sudo rc-service hotspot start   # 开
sudo rc-service hotspot stop    # 关
sudo rc-service hotspot restart # 重启
```

