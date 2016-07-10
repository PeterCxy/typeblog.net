```
{
  "title": "迁移到GPT+UEFI",
  "url": "migrate-to-gpt-with-uefi",
  "date": "2015-02-26",
  "parser": "Markdown"
}
```



我这台电脑的主板(H77)默认是打开 `UEFI` 的。但是两年前，装机的时候，因为当时我还是一个彻头彻尾的Linux小白，只会跟着 `Ubuntu Installer` 安装，而当时的 `Ubuntu Installer` 又恰好在UEFI模式下工作不正常，所以我就关了UEFI。后来我折腾 `ArchLinux` 和 `Gentoo Linux` 的时候，遭遇了各种由 `bootloader` 导致的问题，比如说 `GRUB` 跟我闹别扭死活不引导的奇葩问题。而 `UEFI` 模式可以不需要 `GRUB` 之流的引导程序，再加上我好奇~~不折腾会死~~的心理，我决定迁移到 `GPT + UEFI`

<!--more-->

阿卡林现在使用的是 `Gentoo Linux x86_64` 和 `systemd` (拒绝圣战)，也就是寒假伊始我作死折腾的那个。但是，由于 `Gentoo Wiki` 实在是不够完整，所以我参考了很多 `Arch Wiki` 的内容。

### 转换分区

这一步我是在系统里直接操作的。根据 [Arch Wiki](https://wiki.archlinux.org/index.php/GUID_Partition_Table) 上的内容，我们可以使用 `gdisk` 工具来转换MBR分区表到GPT分区表。

```bash
emerge gptfdisk
gdisk /dev/sda # /dev/sda是你的硬盘设备路径
```

然后直接输入w回车，`gdisk` 会自动把你的MBR转换为GPT。

做这一步的时候可以顺便记住你的活动分区号，一般是 `/boot` 的分区号，我们假设它为 `/dev/sda2`

### 配置内核

其实如果转换好分区没有重启的话，是可以在系统里直接操作的，可是阿卡林是那种比较谨慎小心~~蛋疼无比~~的人，所以我自己是从 `Gentoo LiveCD` 启动进行配置的。当然，LiveCD是不支持UEFI模式的，你可以通过BIOS引导进CD，或者使用 `SystemRescueCD`，步骤是一样的。

进入光盘系统后，首先按照 `Gentoo Handbook` 上的内容，配置好网络，并把硬盘上的整个系统挂载到 `/mnt/gentoo` 下。然后，使用 `chroot` 进入 `/mnt/gentoo`

接下来，我们需要切换到 `/usr/src/linux` 。根据Wiki上的内容，现在需要打开以下内核配置

* CONFIG_EFI_PARTITION
* CONFIG_EFI_STUB
* CONFIG_EFI_VARS

可以用 `make menuconfig` 进行配置，也可以手动编辑 `.config`

接下来我推荐把内核命令(Kernel Command Line)也编译进内核，因为EFI默认是不传递内核参数的。只需配置

```
CONFIG_CMDLINE=root=/dev/sdaX init=/usr/lib/systemd/systemd
```

即可。我没有使用 `initramfs` ，所以没有加上。

然后，执行 `make` 编译即可。

### 安装内核

首先，退出 `chroot` 环境，并卸载 `/mnt/gentoo/boot`

```bash
mkfs.msdos -F 32 /dev/sda2
mount /dev/sda2 /mnt/gentoo/boot
chroot /mnt/gentoo /bin/bash
cd /usr/src/linux
make modules_install && make install
mkdir -p /boot/EFI/Boot
mv /boot/vmlinuz-* /boot/EFI/Boot/bootx64.efi
```

以上命令是把启动分区 `/dev/sda2` 格式化为FAT32并重新进入 `chroot` 环境，将内核安装到 `/boot/EFI/Boot/bootx64.efi`

接下来，就可以退出光盘，重启到BIOS里打开UEFI，然后硬盘启动。

### 后续

UEFI自带启动管理器，所以即使有多系统（比如说一个急救环境，如 `sysrccd`）也不需要什么 `grub` 之流。可以直接在Linux下用 `efibootmgr` 管理启动项。具体可见 [Gentoo Wiki](http://wiki.gentoo.org/wiki/Efibootmgr)

**千万不要开Secure Boot!!!!**

### 总结

原以为要折腾很久，但实际上以上步骤我一共只花了20分钟的时间就完成了，还不到我第一次配置 `bootloader`
 的时间。

UEFI大法好好好好好！！！！！
