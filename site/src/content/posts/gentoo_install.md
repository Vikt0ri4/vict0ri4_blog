---
title: "Gentoo 安装记录"
published: 2026-03-15
description: "记录一次 Gentoo 安装过程及配置（Btrfs + Openrc + 自定义内核）"
tags: [Gentoo, Installation, Btrfs, Openrc, Kernel]
category: Guides
lang: zh
draft: false
---

# gentoo-installation-steps

## gentoo linux安装记录

### 引言
记录一次安装gentoo的过程，文档中可能存在不太合理的部分。请以官方文档为准，本篇文章只能作为参考。
先说我的安装条件  
**Gentoo版本**: [Gentoo Linux 23.0/openrc]  
**内核版本**: [7.2.2-cachyos-r4]  
**文件系统**: [btrfs,vfat]  
**启动方式**: [UEFI+grub]  

### 硬件信息
处理器 [AMD Ryzen r3 3300x]  
显卡 [AMD Radeon RX5700]  
内存 [16GB DDR4]  
硬盘 [256GB NVMe SSD]

### 准备工作
选择合适的方法安装Gentoo  
Gentoo可以以许多不同的方式安装。  
它可以从官方Gentoo安装介质（如我们的可引导ISO文件）下载和安装。安装介质可以安装在USB盘上或通过网络引导环境访问。 或者，Gentoo可以从非官方介质安装，如已安装的发行版或非Gentoo可启动磁盘（如 Linux Mint）。  
Gentoo LiveGUI提供 KDE 桌面环境的 LiveGUI 可能会使一些用户更容易安装 Gentoo。除了提供好用的桌面环境，LiveGUI 通过 NetworkManager 组件也提供了简单的 WiFi 设置。  
我是先去https://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/ 下载iso镜像，选install-amd64-minimal和livegui-amd64都行。我用livegui-amd64，方便复制粘贴。  

下载后使用烧录工具将镜像写入到u盘。   

### 进入livecd
插入写好镜像的u盘，进入live系统，连接wifi或插上网线。 

打开konsole命令控制台，输入  
`sudo passwd` # 先设置一个简单管理密码，因为这只是一个临时使用的live系统，非常复杂的密码反而会引起不便。  

输入`su`并输入刚才的设置的密码进入root用户。

接下来给磁盘分区，我用的是fdisk工具，livecd中也自带parted等分区工具，看个人习惯来使用吧。  
**注意！在分区之前务必及时备份数据！  
`fdisk /dev/nvme0n1`  # 如果是sata硬盘就应该是/dev/sda1  
以下是我的分区方案（仅供参考）
```bash
Disk /dev/nvme0n1: 232.89 GiB, 250059350016 bytes, 488397168 sectors
Disk model: WDC WDS250G2B0C-00PXH0
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 2A4768D8-9813-4CE2-BE64-1CB13C1F959A

Device           Start       End   Sectors   Size Type
/dev/nvme0n1p1    2048   1050623   1048576   512M EFI System
/dev/nvme0n1p2 1050624 488396799 487346176 232.4G Linux filesystem
```

格式化分区  
`mkfs.vfat -F 32 /dev/nvme0n1p1` # 给nvme0n1p2使用vfat文件系统  
`mkfs.btrfs -f /dev/nvme0n1p2` # 给nvme0n1p1使用btrfs文件系统  

之后给nvme0n1p2细分btrfs子卷  
`mkdir -p /mnt/btrfs`  
`mount -o subvolid=5 /dev/nvme0n1p2 /mnt/btrfs`  
`cd /mnt/btrfs`  
`btrfs subvolume create @`  
`btrfs subvolume create @home`  
`btrfs subvolume create @boot`  
`btrfs subvolume create @var`  
`btrfs subvolume create @snapshots`  
`btrfs subvolume set-default @ /mnt/btrfs`   # 设 @ 为默认子卷  
`btrfs subvolume list /mnt/btrfs`            # 验证一下  
`umount /mnt/btrfs`  

挂载  
`mount -o subvol=@,compress=zstd:1,commit=30,ssd,discard=async,space_cache=v2 /dev/nvme0n1p2 /mnt/gentoo`  
`mkdir -p /mnt/gentoo/{boot/efi,home,var}`  
`mount -o subvol=@boot   /dev/nvme0n1p2 /mnt/gentoo/boot`  
`mount -o subvol=@home,nodatacow /dev/nvme0n1p2 /mnt/gentoo/home`  
`mount -o subvol=@var,nodatacow   /dev/nvme0n1p2 /mnt/gentoo/var`  
`mount -o subvol=@snapshots       /dev/nvme0n1p2 /mnt/gentoo/.snapshots`  
`mount /dev/nvme0n1p1 /mnt/gentoo/boot/efi `  

进到刚挂载好的目录  
`cd /mnt/gentoo`  

### 安装 Gentoo 安装文件
下载stage3压缩包  
`links https://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/`  #在里面选择显示日期和时间的目录后回车，比如20260308T170100Z，这个显示日期和时间的目录一般会有好几个，我一般选择的是最新的，避免更新时间长。例如，我用systemd就选择stage3-amd64-systemd-20260308T170100Z.tar.xz  

`tar xpvf stage3-amd64-systemd-20250914T170345Z.tar.xz` # 解压  

`nano -w /mnt/gentoo/etc/portage/make.conf`  # 设置gcc编译选项
```bash
# detailed example.
COMMON_FLAGS="-march=native -O3 -pipe -finline-functions" #我用gcc -O3优化
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"
#CPU_FLAGS_X86="" # 此项待会再填
MAKEOPTS="-j9 -l8" #3300x有8线程，如果没有设置zram怕内存溢出导致livecd卡死就保守一点用-j6

# NOTE: This stage was built with the bindist USE flag enabled

# This sets the language of build output to English.
# Please keep this setting intact when reporting bugs.
LC_MESSAGES=C.utf8

CHOST="x86_64-pc-linux-gnu"
EMERGE_DEFAULT_OPTS="--with-bdeps=y --verbose=y --keep-going"
ACCEPT_LICENSE="*"
ACCEPT_KEYWORDS="amd64"
L10N="en-US zh-CN en zh"
LINGUAS="en-US zh-CN en zh"
AUTO_CLEAN="yes"
GRUB_PLATFORMS="efi-64"
VIDEO_CARDS="amdgpu radeonsi"
ALSA_CARDS="hda-intel"
INPUT_DEVICES="evdev"

PORTAGE_NICENESS="15"

GENTOO_MIRRORS="https://mirrors.tuna.tsinghua.edu.cn/gentoo https://mirrors.zju.edu.cn/gentoo/ http://mirrors.zju.edu.cn/gentoo/ https://mirrors.ustc.edu.cn/gentoo/ https://mirrors.nju.edu.cn/gentoo/ http://mirrors.nju.edu.cn/gentoo/ https://mirror.lzu.edu.cn/gentoo http://mirror.lzu.edu.cn/gentoo https://mirrors.aliyun.com/gentoo/ http://mirrors.aliyun.com/gentoo/ https://mirrors.163.com/gentoo/ http://mirrors.163.com/gentoo/ "


#gentoo的特色之一，gentoo的大部分软件包都会有不同的USE标志，在这里的设置是全局的，意思是你要给所有支持这个USE标志的软件包都默认启用这个标志，如果你只希望给单独的软件包设置特定的USE标志，别急，我后面点会讲到。
#USE="-pulseaudio -iptables -pipewire -jack -kde -gnome -xfce -wayland fortran lto pgo graphite openmp minizip elogind dbus policykit X cjk vdpau vaapi vulkan egl gles2 glfw opengl openal alsa nftables" #这是我会用到的USE标志，仅供参考。而且不推荐在刚安装系统时就同时启用这么多标志。这些后续我会一点一点的加上。
```

配置软件镜像源
`mkdir -p -v /mnt/gentoo/etc/portage/repos.conf`  
`cp -v /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf`  

`nano -w /mnt/gentoo/etc/portage/repos.conf/gentoo.conf`  
```bash
[DEFAULT]
main-repo = gentoo
sync-uri = rsync://mirrors.ustc.edu.cn/gentoo-portage #加入中国源

[gentoo]
location = /var/db/repos/gentoo
...
```
### 安装 Gentoo 基础系统 
复制DNS信息  
`cp --dereference /etc/resolv.conf /mnt/gentoo/etc/`  

挂载系统必要环境，并进入Chroot环境  
`mount --types proc /proc /mnt/gentoo/proc`  
`mount --rbind /sys /mnt/gentoo/sys`  
`mount --make-rslave /mnt/gentoo/sys`  
`mount --rbind /dev /mnt/gentoo/dev`  
`mount --make-rslave /mnt/gentoo/dev`  
`mount --rbind /run /mnt/gentoo/run`  
`mount --make-rslave /mnt/gentoo/run`  
`chroot /mnt/gentoo /bin/bash`  
`mkdir -p /var/db/repos/gentoo`  
`env-update`  
`source /etc/profile`  
`export PS1="(chroot) ${PS1}"`  

安装 Gentoo ebuild 存储库的快照。该快照包含一组文件，这些文件通知 Portage 可用的软件标题（用于安装）、系统管理员可以选择的配置文件、打包或配置文件特定的新闻项目等。  
`emerge-webrsync`  

安装cpuid2cpuflags，检测cpu指令集  
`emerge --ask app-portage/cpuid2cpuflags`  
`cpuid2cpuflags`  # 将输出值全部拷贝到/mnt/gentoo/etc/portage/make.conf中，作为“CPU_FLAGS_X86= ”的值，并取消对“CPU_FLAGS_X86= ”这一行的注释。  

配置系统时区  
`nano -w /etc/locale.gen`  
将以下几项取消注释，如果没有就手动加上  
```bash
en_US ISO-8859-1
en_US.UTF-8 UTF-8
zh_CN GBK 
zh_CN.UTF-8 UTF-8
```

下一步是运行 locale-gen 命令。此命令生成 /etc/locale.gen 文件中指定的所有语言环境。  
`locale-gen`  

### （可选）重新将整个基本系统从stage1编译到stage3
目的是把原来官方提供的所有组件替换成自己编译的（包括GCC编译器和所有基本系统组件），这样一来整个系统的所有程序和组件都是针对自己电脑CPU架构优化编译的了，争取性能最大化。唯一的坏处就是会花费更多的精力和时间。如果你只是想简单的安装gentoo系统体验一下，就推荐跳过此步骤。  
`./var/db/repos/gentoo/scripts/bootstrap.sh`  # 这个脚本执行完检测后重新编译安装emerge包管理器，在我这台机器上花费了十多分钟的时间。  

重新编译安装完emerge包管理器后，bootstrap.sh脚本还会继续检测当前系统环境，最后很可能会警告提示你当前系统里的gcc编译器缺少对fortran的支持、zlib库缺少对minizip的支持，然后退出脚本。  
`nano -w /etc/portage/make.conf`  
```bash
...
USE="fortran lto pgo graphite openmp minizip"
```
先启用以上USE标志，其他USE标志继续注释着先。  

`emerge --ask gcc` # 重新编译gcc，你会看到你会看到刚才加上的那些use标志高亮了，意味着这次编译会应用上这些use标志。这会花费很长时间，大约2-3个小时吧。  

之后退出当前chroot环境再重新进入。  
`exit`  
`chroot /mnt/gentoo /bin/bash`  
`env-update && source /etc/profile && export PS1="(chroot) ${PS1}"`  

重新运行一次脚本检测。  
`./var/db/repos/gentoo/scripts/bootstrap.sh`  

不出意外的话最后会成功通过检测，并提示你系统已经成功“bootstrapped”了，并要求你执行emerge -e @system。那我们就从stage2到stage3（重新编译：基本系统的所有组件base system）。  
`emerge -e @system`
`emerge -e @world`  # 此过程将会非常耗时，3300x编译大约用了2个半小时  

### 接下来，正式安装gentoo系统 （如果选择跳过上面的可选步骤就直接从这里继续）

到这里就可以把make.conf文件中剩下的use都启用上了，然后更新一下。  
`emerge -avuDN @world`  

`eselect profile list`  
`eselect profile set X`  # 我打算用openrc+窗口管理器，所以选了default/linux/amd64/23.0/，有其他需求的就选择其他对应的profile  
`env-update`  
如果profile发生了改变，也应该再次更新软件包。  
`emerge -avuDN @world`  

设置系统locale  
`eselect locale list`  
`eselect locale set X`  # 这里建议选择en-US.utf8，大部分TTY终端都不支持中文。  

创建并配置/etc/fstab文件，用以指示系统开机自动挂载的必要设备/分区  
`blkid >> /etc/fstab`  # 将输出结果追加到fstab配置文件末尾，然后根据追加的内容进行下述修改  
`nano -w /etc/fstab`  # 请参考我的配置，建议使用uuid的形式设置（不建议使用/dev/sdX？的形式）(是uuid，而不是partuuid哦)  
```bash
# <fs>			                           <mountpoint>	<type> <opts>		                                              <dump> <pass>
UUID=bd7589dd-daa7-4245-9ce5-4d1cc9e128cb  /            btrfs  defaults,noatime,ssd,commit=60,nodiscard,subvol=@          0 0
UUID=bd7589dd-daa7-4245-9ce5-4d1cc9e128cb  /home        btrfs  defaults,noatime,ssd,commit=60,nodiscard,subvol=@home      0 0
UUID=bd7589dd-daa7-4245-9ce5-4d1cc9e128cb  /boot        btrfs  defaults,noatime,ssd,commit=60,nodiscard,subvol=@boot      0 0
UUID=bd7589dd-daa7-4245-9ce5-4d1cc9e128cb  /var         btrfs  defaults,noatime,ssd,commit=60,nodiscard,subvol=@var       0 0
UUID=bd7589dd-daa7-4245-9ce5-4d1cc9e128cb  /.snapshots  btrfs  defaults,noatime,ssd,commit=60,nodiscard,subvol=@snapshots 0 0
tmpfs  /tmp  tmpfs  defaults,noatime,mode=1777,size=4G  0 0

```

安装必须的文件系统支持，否则无法访问硬盘上的分区！！  
`emerge --ask sys-fs/e2fsprogs`     #ext4  
`emerge --ask sys-fs/xfsprogs`      #xfs  
`emerge --ask sys-fs/dosfstools`    #fat32  
`emerge --ask sys-fs/ntfs3g`        #ntfs  
`emerge --ask sys-fs/fuse-exfat`    #exfat  
`emerge --ask sys-fs/exfat-utils`   #exfat  
`emerge --ask sys-fs/btrfs-progs`   #btrfs

### 配置 Linux 内核 
编译内核前，先安装一些必要工具  
`emerge --ask eix sudo pciutils usbutils hwinfo gentoolkit euses dev-vcs/git eselect-repository`  

可选工具  
`emerge --ask neovim fastfetch zsh bottom`  

下载安装wifi网卡和intel核显的必要驱动固件  
`emerge --ask sys-kernel/linux-firmware`  

安装更新Intel CPU的微码文件  
`emerge --ask sys-firmware/intel-microcode sys-apps/iucode_tool`  

gentoo的特色之二，就是鼓励自行配置系统内核。  
编译内核的方式与过程多种多样，下面我来详细说说。  
从以下两个方法中选一个。  
第一种方法：直接安装gentoo-kernel-bin软件包  
`emerge --ask gentoo-kernel-bin` # 此命令能自动完成内核编译，主打一个方便。但这样的缺点也很明显，没有改变任何内核设置。几乎所有功能都包含在了内核里面。一般想省时省事用这个方法比较合适。  

第二种方法：自定义内核  
使用genkernel工具  
`emerge --ask gentoo-sources`  # 先安装内核源码  
`emerge --ask genkernel`  # 安装genkernel
`eselect kernel list`  # 查看内核  
`eselect kernel set X`  # 选择内核  
`genkernel --menuconfig kernel`  # 进到linux内核配置界面，genkernel默认使用gentoo-kernel的内核配置，此配置通常开箱即用，你也可以在此基础上做精简，比如精简掉你用不到的网卡、声卡、显卡等驱动和文件系统等。  
除了可以设为N或Y还可以将一些配置以模块形式加载（即设为M）。还请避免过度精简导致开机时内核启动卡住，这时就需要自己排除问题了。  

**TIPS：**genkernel还有一些其他的用法，可以使用genkernel --help来查看或者去看gentoo的genkernel文档，等下就会说到如何用genkernel来配置initramfs，https://wiki.gentoo.org/wiki/Genkernel/zh-cn。  

或者直接进linux内核目录，手动完成整个编译流程  
`emerge --ask gentoo-sources`  # 先安装内核源码  
`eselect kernel list`  # 查看当前内核  
`eselect kernel set X`  # 选择当前内核  
`cd /usr/src/linux`  #进入linux内核目录  

(可选)如果之前已经安装过genkernel，会把linux的默认配置换成gentoo-kernel的内核配置，如果只想用linux的默认配置就执行以下命令。  
`mv .config bak.config` # 备份gentoo-kernel的内核配置（如果还需要此配置的话）  
`make x86_64_defconfig` # 使用linux默认配置  
使用linux默认配置通常不能开箱即用，你需要检查文件系统(vfat、ext4等)、驱动(声卡、网卡、显卡等)、init子系统(systemd or openrc)、启动项(bios or uefi)等配置是否合理开启，只有满足条件内核才能正常启动运行。  

`make menuconfig`  # 进入内核配置界面  
`make -j6`  #用6线程来编译内核  
`make modules_install`  #编译模块  
`make install`  #完成整个内核编译过程  

若使用以上第二或第三种方法安装linux内核，可能还需要配置initramfs，可以用genkernel也可以用dracut，推荐用genkernel。  
`genkernel --install initramfs`  

使用以上三种方法的任意一种来完成内核安装操作后，一定需要配置引导加载程序。  
配置引导加载程序也有很多种，推荐以grub为主，https://wiki.gentoo.org/wiki/Grub。  
要配置grub，请执行以下命令。  
`emerge --ask sys-boot/grub`  # 安装grub  
`grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Gentoo`  
`grub-mkconfig -o /boot/grub/grub.cfg`  

### 配置时间
systemd随附了`timedatectl`命令，用于管理时区，要查看当前时区请执行该命令。  
之后执行`timedatectl list-timezones`命令来列出可用的时区。  
要更改时区（例如，更改至德国的时区），使用命令`timedatectl set-timezone Europe/Berlin`即可。  

### 配置网络  
emerge --ask dhcpcd  
如果你需要连接无线网络，我推荐iwd这个软件包。  
emerge --ask net-wireless/iwd  
具体请看官方文档，内核配置也要根据文档中的配置来更改。  
https://wiki.gentoo.org/wiki/Iwd  

启动网络服务  
systemctl enable dhcpcd iwd  

### 配置系统用户  
`visudo`  
把“%wheel ALL=(ALL) ALL”这一行去掉注释  

`useradd -m -G users,wheel,audio,usb,video -s /bin/bash <你的用户名> `  
`passwd root` #更改root账户密码  
`passwd <你的用户名>` #更改你自己的用户密码  
`echo <主机名> > /etc/hostname`  

### 最后的安装收尾和清理工作，卸载之前挂载的分区
`rm /stage3-*.tar.xz`  
`exit` # 退出chroot环境  
`umount -lR /mnt/gentoo`  
到此整个gentoo系统就安装结束了，重启电脑进入你的新系统好好享受吧  

### (可选)备份gentoo
第一种备份方式：以压缩包形式备份  
切换到根目录  
`cd /`  

创建备份（排除临时和虚拟文件系统）,可根据自己需要来选择排除掉的文件，比如不需要排除/home中的文件就把--exclude=/home 删掉。  
`tar --create --gzip --file /backup.tar.gz --exclude=/backup.tar.gz --exclude=/home --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/run --exclude=/tmp --exclude=/mnt --exclude=/media --exclude=/lost+found /` # 实测从刚安装结束时就压缩文件大小约为2G左右，请自行保存好该压缩包。  

如果你要恢复该备份，请在此之前先保存好自己在该硬盘中想要保存的数据。然后用u盘进livecd系统把原本的系统盘格式化，请务必考虑清楚后再执行以下操作。  
进入livecd环境  
`mkfs.btrfs -f /dev/nvme0n1p1` #给nvme0n1p1使用btrfs文件系统  
`mkfs.vfat -F 32 /dev/nvme0n1p2` #给nvme0n1p2使用vfat文件系统  
重新挂载分区  
`mount /dev/nvme0n1p1 /mnt/gentoo`  
`mkdir /mnt/gentoo/boot`  
`mount /dev/nvme0n1p2 /mnt/gentoo/boot`  
进到挂载nvme0n1p1的目录  
`cd /mnt/gentoo`  
将备份的压缩包复制到/mnt/gentoo目录中。  
`cp <你所备份的压缩包路径> ./`  
解压压缩包  
`tar xpvf backup.tar.gz`  
复制DNS信息  
`cp --dereference /etc/resolv.conf /mnt/gentoo/etc/`  
挂载系统必要环境，并进入Chroot环境  
`mount --types proc /proc /mnt/gentoo/proc`  
`mount --rbind /sys /mnt/gentoo/sys`  
`mount --make-rslave /mnt/gentoo/sys`  
`mount --rbind /dev /mnt/gentoo/dev`  
`mount --make-rslave /mnt/gentoo/dev`  
`mount --rbind /run /mnt/gentoo/run`  
`mount --make-rslave /mnt/gentoo/run`  
`chroot /mnt/gentoo /bin/bash`  
`mkdir -p /var/db/repos/gentoo`  
`env-update`  
`source /etc/profile`  
`export PS1="(chroot) ${PS1}"`  
  
第二种方式：如果你和我一样都使用btrfs文件系统，可以利用btrfs特性来创建快照。  
备份系统  
`cd /` # 回到根目录  
`mkdir -p /mnt/.snapshots` # 创建备份目录  
`mount -o compress=zstd:3,subvol=/ /dev/nvme0n1p1 /mnt` # 挂载btrfs根分区  
`rm -rf /var/cache/portage/*` # 清理gentoo的软件包缓存（减少快照体积）  
`btrfs subvolume snapshot -r /mnt/@ /mnt/.snapshots/@-$(date +"%Y%m%d")` # 创建只读快照  
`umount /mnt` # 卸载临时挂载  

恢复系统  
进入livecd环境  
`mount -o compress=zstd:3,subvol=/ /dev/nvme0n1p1 /mnt` # 挂载 btrfs 根分区  
`btrfs subvolume snapshot /mnt/.snapshots/@-yyyymmdd /mnt/@-restore` # 从快照创建临时恢复子卷  
修改 fstab 指向临时子卷  
`vi /etc/fstab` # 将"subvol=@" 改为 "subvol=@-restore"  
`cp /etc/fstab /mnt/@-restore/etc/fstab` # 同步修改到临时子卷的fstab  
`grub-mkconfig -o /boot/grub/grub.cfg` # 重建 Grub 引导配置  
`reboot` # 重启系统  
这样备份系统快速方便，过程不算太复杂。缺点就是只能在btrfs文件系统上这样备份。

如果你格式化或迁移了硬盘，fstab的内容也要做出相应的修改。  
重新更新引导加载程序  
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Gentoo  
grub-mkconfig -o /boot/grub/grub.cfg  
重启后备份完成，这种备份方式兼容性强，支持各文件系统，就是压缩解压要花点时间。  

两种备份方式也可以一起使用，最后也没什么要说的了，祝你使用gentoo愉快~  

# 参考文献  
Gentoo Linux amd64 Handbook: Installing Gentoo https://wiki.gentoo.org/wiki/Handbook:AMD64/Full/Installation  
Gentoo安装流程分享(step by step)，第一篇之基本系统的安装 https://zhuanlan.zhihu.com/p/122222365  

