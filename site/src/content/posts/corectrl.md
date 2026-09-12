---
title: "解决 Gentoo 中 Corectrl 编译报错问题"
published: 2026-08-27
description: "解决因 dev-libs/quazip 移除 qt6 USE 标记导致 corectrl 无法编译的问题"
tags: [Gentoo, Corectrl, Portage, Ebuild]
category: Guides
lang: zh
draft: false
---

# gentoo-solution-corectrl
## 介绍
由于dev-libs/quazip-1.5版本中直接移除了qt5和qt6两个带有Qt版本选择的 USE 标记，导致在gentoo中编译kde-misc/corectrl-1.5.2时提示以下信息：
```bashemerge: there are no ebuilds built with USE flags to satisfy "dev-libs/quazip[qt6]".
!!! One of the following packages is required to complete your request:
- dev-libs/quazip-1.5::gentoo (Missing IUSE: qt6)
(dependency required by "kde-misc/corectrl-1.5.2::farmboy0" [ebuild])
(dependency required by "kde-misc/corectrl" [argument])
...
```
这个错误是因为 corectrl 的 ebuild 中写死了需要 dev-libs/quazip[qt6]（即安装了 qt6 USE 标志的 quazip），但新版的 quazip 已经默认且仅支持 Qt6，因此移除了 qt6 这个 USE 标志，导致 Portage 在依赖树中找不到满足条件的包。
```
```
## 解决方案
### 找到 corectrl 的 ebuild 文件
`find /var/db/repos -name "corectrl-1.5.2.ebuild" 2>/dev/null`
不出意外的话，路径会是 /var/db/repos/farmboy0/kde-misc/corectrl/corectrl-1.5.2.ebuild。
### 编辑 ebuild 文件
`sudo vi /var/db/repos/farmboy0/kde-misc/corectrl/corectrl-1.5.2.ebuild`
找到包含 dev-libs/quazip[qt6] 的那一行（通常在 RDEPEND 或 DEPEND 变量里），改为dev-libs/quazip[qt6(+)] 
### 重新生成 Manifest 文件
`cd /var/db/repos/farmboy0/kde-misc/corectrl/`
`sudo ebuild corectrl-1.5.2.ebuild manifest`
### 安装
`sudo emerge -av kde-misc/corectrl`

