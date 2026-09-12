---
title: "virt-manager 虚拟网络未激活修复记录"
published: 2026-06-19
description: "解决 libvirt 虚拟网络因 iptables 后端问题无法启动"
tags: [Gentoo, virt-manager, libvirt, iptables, nftables, OpenRC]
category: Guides
lang: zh
draft: false
---

# virt-manager 虚拟网络未激活修复记录

> 主机：Gentoo Linux（OpenRC）  
> 日期：2026-06-19

---

## 问题现象

virt-manager 中虚拟网络（如 `default` NAT 网络）显示「未激活」，无法启动。

```
# 尝试启动报错
sudo virsh net-start default
# 可能报：无法初始化 iptables/防火墙相关错误
```

## 根因

Gentoo 装 `nftables` 时如果没有同时启用 `xtables` USE 标志，就不会安装 `iptables-nft` 兼容层。  
libvirt 默认用 **iptables 命令** 来配虚拟网络的 NAT / 转发规则，找不到可用的 iptables 后端就会罢工。

---

## 修复步骤

### 1. 给 nftables 开启 xtables 支持

```bash
# 在 /etc/portage/package.use 中添加（如果不存在就新建）
echo "net-firewall/nftables xtables" | sudo tee -a /etc/portage/package.use/nftables

# 重新编译（会装上 iptables-nft 兼容层）
sudo emerge -av net-firewall/nftables
```

### 2. 切换系统默认 iptables 后端

```bash
# 列出可用的 iptables 实现
sudo eselect iptables list
```

输出类似：

```
Available iptables implementations:
  [1]   iptables-legacy
  [2]   xtables-nft-multi *
```

```bash
# 选 [2] xtables-nft-multi（这是 nftables 兼容模式，星号表示当前选中）
sudo eselect iptables set 2
```

验证：

```bash
sudo eselect iptables list
# [2] xtables-nft-multi *    ← 确认星号在 [2]
```

### 3. 重启 libvirt 并激活网络

```bash
sudo rc-service libvirtd restart
sudo virsh net-start default
sudo virsh net-autostart default   # 开机自启
```

---

## 恢复虚拟机默认配置（如果之前乱改过）

如果之前因为不知道原因改乱了虚拟机的 XML / 网络配置：

### 恢复默认虚拟网络

```bash
# 1. 销毁并取消定义
sudo virsh net-destroy default
sudo virsh net-undefine default

# 2. 重新创建默认网络
sudo virsh net-define /etc/libvirt/qemu/networks/default.xml
# 如果该文件不存在，手动创建它：
```

```xml
<!-- /etc/libvirt/qemu/networks/default.xml -->
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
```

```bash
# 3. 启动并自启
sudo virsh net-define /etc/libvirt/qemu/networks/default.xml
sudo virsh net-start default
sudo virsh net-autostart default
```

### 恢复虚拟机网卡为 NAT 模式

如果虚拟机网卡之前被改成了别的（bridged / macvtap），想回到默认 NAT：

1. virt-manager → 虚拟机详情 → 网卡设备 → 删除
2. 重新添加网卡，选 **NAT (default)**

---

## 相关知识点

| 概念 | 说明 |
|------|------|
| `iptables-legacy` | 传统 iptables（直接操作内核 netfilter） |
| `xtables-nft-multi` | iptables 命令语法 + nftables 内核后端（兼容桥） |
| `nftables` USE `xtables` | 编译时把 iptables 兼容工具链打包进去 |
| `eselect iptables` | Gentoo 选择系统级 `iptables` 命令指向哪个实现 |

> ⚠️ 如果你之前已经按另一篇教程写了**纯 nftables 规则**，做完本教程后 nftables 规则仍然有效——libvirt 用的是 iptables 兼容层，不会覆盖你的 nftables 规则。

---

## 与纯 nftables 防火墙的关系

两篇教程**互不冲突**：

- **本教程**：让 libvirt 能用 iptables 命令操作虚拟网络（NAT / DHCP / 转发）
- **nftables 防火墙教程**：保护主机本身，阻止校园网陌生人扫描

