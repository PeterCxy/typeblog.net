```
{
  "title": "在Android上运行Linux发行版",
  "url": "run-chrooted-linux-on-android",
  "date": "2015-09-27",
  "parser": "Markdown"
}
```


定制可以在 `Android` 手机/平板上运行的Linux发行版镜像，使用 `chroot`

在很久以前，我曾发现过一个App，叫 `LinuxOnAndroid`, 也在以前的米1上面玩过，那时候这个东西的确能够运行很多Linux发行版。可惜，后来这个项目停止维护了，里面的镜像都已经太老旧以至于更新一下都可能失败。后来换了米2，更新了 `Android 5.0`, 由于它要求 `ARM PIE` 而 `LinuxOnAndroid` 的镜像里面并没有开启这个，所以我认为它会失败而很久没有折腾。直到前天，在 `##Orz` 大水群里面，有人告诉我在 `chroot` 环境里面是不会被这个限制影响的，因为这个限制是在Android的 `linker` 里面而不是内核里面，一旦切换根目录就会被替换掉。

正好，我也长期苦于在手机上没有好办法使用 `git`, 以及难以调试 `nodejs` `Python` 之类的东西，所以趁着中秋假期借鉴LinuxOnAndroid的经验自己跑起来一个Linux。

### 准备

由于我不可能把所有发行版都装一次，也不可能在各种手机上都测试一遍，所以我只能以如下的环境为例

* armv7h 设备 (如MSM8974)
* Android 5.x 和 busybox 完整支持 以及 root 权限
* 至少 4GiB 的sdcard(内置存储)空闲空间
* 至少 2GiB 的总运行内存
* 自备终端模拟器和SSH客户端(如JuiceSSH)
* 以安装和配置 ArchLinuxARM 为例

我们的目标是

* 将目标Linux发行版安装至一个虚拟分区内
* 能够在chroot下正常工作
* 能够访问网络/sdcard
* 能够通过ssh访问

注意，本文中的终端模拟器下执行的命令请全部在root权限下执行。(SSH下的命令请注意看说明)

如果你在过程中遇到了问题，您可以参考本文最后处的FAQ

### Bootstrap

任何 `Linux` 发行版的安装，都要解决一个先有鸡还是先有蛋的问题，这个过程就是 `bootstrap`, 只不过在某些发行版的安装过程中被自动化了。在Android上安装，同样要经过这个过程。

首先，你得在你的sdcard(内置存储)上找一个空的目录以便管理文件，我们认为它的路径是 `/sdcard/linux`. 那么现在，打开终端模拟器，创建好这个目录。然后，运行下面的指令来创建一个4GB容量的空文件作为我们的虚拟磁盘

```bash
dd if=/dev/zero of=/sdcard/linux/root.img bs=1048576 count=4096
```

这条命令创建了一个包含4096块、每块大小是1M的文件，也就是一个4G的空文件 `root.img`, 接下来我们需要对它进行格式化以准备使用

```bash
mke2fs -t ext4 -F /sdcard/linux/root.img
```

这样我们就在这个空文件上创建了一个 `ext4` 文件系统，接下来我们把它挂载到 `/sdcard/linux/root`

```bash
mkdir /sdcard/linux/root
mount -t ext4 -o loop /sdcard/linux/root.img /sdcard/linux/root
```

然后我们需要下载 `ArchLinuxARM` 的bootstrap包。由于我们身处中国，从官网软件源下载速度并不是很快，所以我推荐大家使用USTC的镜像下载

<http://mirrors.ustc.edu.cn/archlinuxarm/os/>

打开这个URL，在里面找到你需要的bootstrap压缩包。比如说我的设备是 `MSM8974` 平台，那我就要下载 `ArchLinuxARM-armv7-latest.tar.gz`, 如果是其他平台则要把armv7换成其他的平台名称，比如说64位的手机应该下载 `ArchLinuxARM-aarch64-generic-latest.tar.gz`

我们假设这个文件下载后存储在 `/sdcard/Downloads/ArchLinux.tar.gz`

现在，把它拷贝进刚刚挂载出来的那个分区，并解压。

```bash
cp /sdcard/Downloads/ArchLinux.tar.gz /sdcard/linux/root/
cd /sdcard/linux/root
tar xzvf *.tar.gz
```

接下来我们要切换软件源到 `USTC`. 使用busybox里面的vim或vi编辑文件 `/sdcard/linux/root/etc/pacman.d/mirrorlist`, 将原来的 `Server = xxxx` 那一行注释掉 (前面加个#)，然后在最前面重新添加一行

```
Server = https://mirrors.ustc.edu.cn/archlinuxarm/$arch/$repo
```

然后需要配置 `DNS`. 先用`rm`命令删除原有的 `/sdcard/linux/root/etc/resolv.conf`, 然后重新建立这个文件并编辑，键入DNS服务器配置

```
nameserver 8.8.8.8
nameserver 8.8.4.4
```

完成以后，我们就基本上完成了 `bootstrap` 过程，可以准备 `chroot` 进去了，但在这之前，我们得先把运行需要的目录挂载到虚拟根目录里面去

```bash
mount -o bind /dev /sdcard/linux/root/dev
mount -o bind /sys /sdcard/linux/root/sys
mount -o bind /proc /sdcard/linux/root/proc
mount -t tmpfs tmpfs /sdcard/linux/root/tmp
ln -s /proc/self/fd /dev/fd
```

最后一条指令是为了修复在子系统内执行一些包管理器会需要 `/dev/fd` 而出现的问题。如果不加这一条语句，那么在之后我们配置 `pacaur` 之类的从AUR安装软件的工具时会出现错误。

接下来，我们可以 `chroot` 进入刚刚创建好的基本系统了

```bash
chroot /sdcard/linux/root /bin/bash
```

### 配置基本系统

现在我们已经进入了这个基本系统，你可以看到命令提示符已经发生了变化。首先，我们最好先做一次全系统升级

```bash
pacman -Syu
```

然后安装一些工具

```bash
pacman -S base-devel vim sudo
```

接下来配置一个新用户，我们假设这个用户的名称是peter

```bash
useradd -m peter
passwd peter
```

运行第二行命令以后请键入为这个用户设置的密码。接下来用刚刚安装的 `vim` 编辑 `/etc/sudoers`, 添加这样一行

```
peter ALL=(ALL) ALL
```

这样 `peter` 就有了sudo权限。别忘了给 `root` 用户也设置一个密码，而且最好是强密码(反正平时用不到)。

然后我们准备启动 `sshd` 服务。先生成 `ssh host key`, 再启动sshd

```
ssh-keygen -A
/bin/sshd
```

这样你已经在后台启动了一个 `ssh` 服务。现在你可以关闭这个终端模拟器了，我们将使用 `SSH` 登入。

打开SSH客户端，新建一个链接，服务端IP写本地(127.0.0.1), 端口为默认的22, 使用刚刚新增的用户和其对应的密码登录(不要使用root)

### 配置网络

如果是在其他的Linux发行版上配置chroot环境，那么这个教程到这里就可以结束了。但是很可惜的是，我们使用的是 `Android`. `Android` 魔改的内核导致只有特定的用户组才能访问网络。所以我们在chroot的环境里面仍然需要配置对应的用户组才能在非root下正常使用网络。

```bash
sudo groupadd -g 3001 android_bt
sudo groupadd -g 3002 android_bt-net
sudo groupadd -g 3003 android_inet
sudo groupadd -g 3004 android_net-raw
sudo gpasswd -a peter android_bt
sudo gpasswd -a peter android_bt-net
sudo gpasswd -a peter android_inet
sudo gpasswd -a peter android_net-raw
```

然后退出ssh重新登录即可。

### 配置SD卡(内置存储)访问

由于我们创建的虚拟磁盘只有4G，可能不够存储使用，所以我们需要在子系统内访问SD卡。但是，Android同样是禁止普通用户直接访问SD卡的。所以，我们同样要进行相应的处理。

先打开一个终端模拟器，把SD卡挂载到虚拟根目录内

```bash
mkdir /sdcard/linux/root/mnt/sdcard
mount -o bind /sdcard /sdcard/linux/root/mnt/sdcard
```

然后关闭这个终端。

接下来一样要创建用户组，在ssh里面执行

```bash
sudo groupadd -g 1015 sdcard-rw
sudo groupadd -g 1028 sdcard-r
sudo gpasswd -a peter sdcard-rw
sudo gpasswd -a peter sdcard-r
```

然后尝试 `ls /mnt/sdcard`, 应该已经可以使用了。

### 配置区域和语言

在chroot出来的环境里面，我们没有 `systemd` 和任何其他初始化系统支持，所以不能自动设置语言。我们必须手动配置。

在ssh内编辑 `/etc/locale.gen`, 去掉 `en_US.UTF-8` 一行前面的注释符号，然后运行

```bash
locale-gen
```

接着编辑 `~/.bashrc` (如果你使用了其他的shell那么请编辑这个shell的初始化脚本)，添加这些到尾部

```bash
export LC=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

然后重新登录ssh即可。

### 配置启动脚本

这些挂载出来的虚拟分区在重启手机后会被取消挂载，如果每次都手动重新挂载和启动sshd会非常麻烦。所以，我们可以创建一个shell脚本，自动挂载分区并启动sshd

```bash
#!/system/bin/sh

mount -t ext4 -o loop /sdcard/linux/root.img /sdcard/linux/root

mount -o bind /sys /sdcard/linux/root/sys
mount -o bind /proc /sdcard/linux/root/proc
mount -o bind /dev /sdcard/linux/root/dev
mount -t tmpfs tmpfs /sdcard/linux/root/tmp

mount -o bind /sdcard /sdcard/linux/root/mnt/sdcard

ln -s /proc/self/fd /dev/fd

chroot /sdcard/linux/root /bin/sshd
```

这个脚本会将运行所需分区全部挂载上，并在 `chroot` 环境内启动一个sshd，这样你就可以直接使用ssh客户端连接到内部的系统了。这样，每次手机重启以后，你只需要开终端模拟器执行一下这个shell脚本就可以了。

### 以后

现在，一个Linux发行版已经在你的Android上运行起来了。你可以尽情地调戏，只要记住这是ARM平台而非和PC一样的平台。你甚至可以在里面运行一个VNC服务器，用 `VNC` 客户端连接，可以运行一个桌面环境，等等。

另外，我非常推荐修改ssh设置把ssh服务端的监听IP改成 `127.0.0.1`, 以防止别有用心之人。

如果需要从AUR上安装软件，你需要 `pacaur` 之类的命令，但是注意不要通过添加 `pacman` 软件源的方式安装，因为那些软件源都不支持ARM平台。要安装这类的工具，你得先从 `AUR` 上下载它们的 `PKGBUILD`, 然后放在当前目录里执行 `makepkg -i` 进行编译安装。

### FAQs

Q: 如何使用初始化系统如systemd来管理服务？  
A: 并不能使用，建议使用supervisord来替代。使用supervisord以后，可以在启动脚本里把执行sshd的代码改成执行supervisord的。

Q: SSH失败，提示PTY allocation failed on channel 0?  
A: 尝试执行以下代码

```bash
umount /dev/pts
mount -t devpts devpts /dev/pts
```

### 后记

我在这个Linux环境里面运行了 `node.js` 和 `Python 3.4`，性能表现非常不错。但是，里面运行的 `jekyll` 较之PC却慢了很多，不过至少我终于可以用手机预览我的新博客文章了。在chroot里面，除了不能换内核以外，几乎可以把它当成一个完整的Linux发行版。加之 `ArchLinuxARM` 的支持非常好，你可以做任何PC上的 `ArchLinux` 能做到的事情，包括编译安装软件等等。

后来我在里面测试了 `git`, 几乎一切正常，但是在修改配置时，比如 `git remote add`, 如果当前目录在SD卡上，则会报错。此时，你应该在命令前加上一个 `sudo`

其他的，我也不想再一一赘述，总而言之，这就是一个全功能的Linux环境。
