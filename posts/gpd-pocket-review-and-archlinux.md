```json
{
  "title": "GPD Pocket 上手 & ArchLinux",
  "url": "gpd-pocket-review-and-archlinux",
  "date": "2017-11-18",
  "parser": "Markdown",
  "cover": "https://files.typeblog.net/blog/gpd/IMG_20171118_193751.jpg",
  "tags": ["Tech"]
}
```

之前在 `archlinux-cn-offtopic` 群组里偶然看见 `farseerfc` 教授在晒图，是一台看起来非常非常小的电脑，但是却赫然写着 `x86_64` 并运行着 ArchLinux。我当时就起了兴趣，因为我一直苦于整天搬着一台 1.7kg 重的 XPS15，想要一台比较迷你而且便携的 x86 设备。我想要 x86 设备的理由是在我眼里只有 x86 才能算是完整的 PC 体验：有些 ARM 平台确实性能很好，可是连主线 `Linux` 都跑不了，又能算什么 PC 呢……

在 YouTube 上逛了一圈以后，感觉负面评价不是很多，加上双十一又有一定程度的打折活动，自己又真的非常想要，就在本周早些入手了一台。入手价格是 3000 人民币。

于是，这里是一个简单的评测和对我装 ArchLinux 过程中遇到的坑的记录。

（本文有补充编辑的内容，可能下面提及的部分问题已经被我解决，如果想看请直接翻到最后。）

### 配置

首先看一下它的配置。

* __CPU__: Intel Atom x7-Z8750 (1.6GHz)
* __存储__: 128 GB __eMMC __(不是 SSD)
* __RAM__: 8 GB DDRIII 1066MHz
* __图形__: Intel HD Graphics 405
* __WiFi / Bluetooth__: BCM4356
* __显示屏__: 7吋 IPS 多点触控 (1920 x 1200)
* __音频__: Realtek ALC5645 双声道 (扬声器为单声道)
* __电池__: 7000 mAh
* __接口__: 1x USB Type-A, 1x 3.5mm 音频, 1x HDMI MINI, 1x USB Type-C (可充电, 使用 PD 协议)
* __系统__: 预装 Windows 10 Home, 可运行 Linux

买之前最担心的是 CPU 和 WiFi / 蓝牙 芯片。CPU 感觉性能可能不太足够，而 BCM4356 这个……看名字就知道，又是 BCM，进了 Linux 必然有坑 :( 斜眼看我的同样是 BCM 芯片的 XPS15……

但是担心终于没有战胜我想要剁手的心情。思考了几天之后我还是没忍住入手了。这也是我第一次发现某宝上还有 “拍下后联系卖家改优惠价” 一说 XD

### 上手

拿到手的第一感觉是这个东西真的很精致。7 英寸的身体看起来很娇小，但是拿在手里又感觉非常结实。重量 480g 可以算是一款比较轻便的设备了，装在口袋里也不显得比较沉，而且它 __确实__ 可以装进口袋里，是名副其实的「Pocket Device」。

![img_1](https://files.typeblog.net/blog/gpd/IMG_20171118_194005.jpg)

铝制的外壳看起来则非常 MacBook，正如大部分评测里所说的一样。我不想评价这是不是好事，我只能说这个外壳的手感算是我碰过的设备里最好的一个。而这块 IPS 屏幕则绝对是一个惊喜 —— 颜色非常正，没有坏点，也没有漏光问题。7吋的 1920x1200 屏幕看起来非常清晰（当然，这也导致了之后运行 Linux 的时候遇到的一些问题）。整个屏幕看起来的舒适程度要胜过我的 XPS15。当然，我手上的这台 XPS15 的屏幕有几个坏点，而且不属于 HiDPI 范围，似乎也没有什么可比较的……这里有一点要吐槽的是官方送的那一块贴膜的 __正反面标反了__，直接导致我把那块贴膜给贴废了……从其他几位用户那里得知这似乎是普遍情况，请各位想要购买的朋友注意了。

预装的是 Windows 10 Home。我不知道盒子上贴的序列号有什么用，因为一开机就已经是激活状态了 —— 也许是给重装使用的？我只开机了一次稍微测试了一下各种功能确认没有问题以后就把 Windows 10 格式化掉然后安装 ArchLinux 了。在讨论这个设备上安装 Linux 的过程之前，我想先讨论几个别的问题。

### 键盘

之所以把键盘单独拿出来说，是因为这个键盘是很多评测吐槽的对象。确实，因为只有 7 吋的大小，这个键盘的布局非常奇葩 —— 大写锁定缩的小小的被塞在 A 的左边，整个 A 行被往右平移了，退格在上删除在下，几个特殊符号被塞在了右下角。适应了全键盘以后，再使用这个键盘显得非常困难。

不过，把完整的键盘塞在这么小一个设备上也不是什么容易的事情。又要完整的键盘，又要键的大小足够手指敲击，相当的困难。GPD 家的前代作品 `GPD Win` 就有一个非常奇葩的键盘，我上上周使用过一会儿别人的 `GPD Win`，觉得那个超级迷你版的全键盘才更加的恐怖 —— 问题不在于布局，而在于那个东西上的键盘的键都只有不到一个指甲盖的大小……

在使用了两天之后，我觉得 `GPD Pocket` 的这块键盘还算可以接受。稍微适应以后双手打字并没有太大的问题，两个手也不会撞在一起，只是当用到一些键位特殊的键的时候需要反应一段时间。当然，我也不会建议谁在这个设备上输入大段的文字。还有一种操作方法是双手握持设备然后用拇指敲击键盘，但是这样的话使用指点杆稍微有点难受。说到指点杆，我觉得这个设备上使用指点杆简直是绝配了，有完整的鼠标体验而且节省了空间 —— 只可惜这个指点杆不支持中键滚动。

### 性能

性能是很多人关注的问题，而实话实说，这个设备的性能绝对不算好，也算是比较长的续航的代价之一吧。原装的 `Windows` 我没有详细测试过，但是我运行的 `GNOME` 时常有卡顿的现象存在。考虑到 `GNOME` 大量依赖 `JavaScript`，我猜测如果使用 `KDE Plasma` 的话可能会好很多。

不过我使用 `Firefox Nightly` 进行基本的网页浏览并没有遇到太大的问题，基本上都能够胜任。看 YouTube 1080P 也没有太大的压力，而 4K 则经常出现掉帧。在访问大量使用 JS 的网站的时候，例如淘宝，耗电量会有一定程度上的上升。这也在合情合理的范围之中。

我粗略尝试运行了一下 `Visual Studio Code`，发现基本的功能使用上是没问题的。虽然我不指望用这个进行什么高性能的开发，但是我估计应急写写代码也是完全可行的操作。在安装新字体更新 `fontcache` 的时候则会感受到明显的卡死现象，这时候 CPU 占用变成 100%，显然是性能不足了。好在这种操作也不会天天执行。

作为一个（伪）音乐爱好者，我也尝试了使用这个东西作为 MIDI 合成器，结果是几乎完美。只是扬声器比较烂，需要自己插耳机解决 :(

![img_midi](https://files.typeblog.net/blog/gpd/IMG_20171118_124805.jpg)

也算是终于不用拖老远的线把它接到我的笔记本电脑上了（这个键盘附近已经放不下我的大 XPS 了）

对于性能这个话题，总而言之，它不是一个高性能设备，如果你是为了性能而来，那有更多的设备可供选择。但是它是绝对可以满足基本的使用需求的，甚至可以进行一点低性能要求的开发工作。游戏运行我暂时没有测试，根据其他的评测所言，进行一些微调以后，这个 `Intel HD Graphics 405` 是足够胜任简单的 3D 游戏的。

P.S. 我并没有进行跑分，但是昨天晚上运行了一下 `openssl speed rsa2048` 和 `openssl speed ecdsap256`，结果分别是 `219.7 sign/s + 7584.8 verify/s` 和 `5965.6 sign/s + 2638.2 verify/s`，供各位参考。

### ArchLinux 安装

オニーチャン、ArchLinux をインストールしてください。

emmm 开玩笑的。不过说了这么多，是时候安装 `ArchLinux` 了。我们伟大的先驱者（雾）们已经在 ArchWiki 上给 GPDP 开了一个页面来描述可能遇到的问题和解决方案，链接在 [这里](https://wiki.archlinux.org/index.php/GPD_Pocket)。下面对于这些已经提及的问题可能就不再描述了。

首先是安装的方式。要从 USB 启动，你需要首先进入 BIOS 关闭 `Fast boot`。进入 BIOS 的方法是开机狂敲 Del。BIOS 内屏幕的方向是错误的，你需要把设备旋转过来才能操作。建议不要使用鼠标而是使用方向键来选择，电源键确认。关闭之后，插上 ArchLinux 引导介质，然后在开机的时候按 F7 (注意你需要按住 Fn 键以使用 F 系列按键)，即可选择 USB 引导。需要注意的是它只能使用 `UEFI` 的引导介质。

引导进入 ArchLinux 安装环境之后默认的屏幕旋转也是错误的。要想解决这个问题，需要在引导进入安装环境之前的启动菜单(systemd-boot)界面上按 e 编辑内核命令行，在最后加入 `fbcon=rotate:1`。如此操作之后启动就是正确的屏幕方向了。进入之后的命令行的字实在太小，可以暂时使用 `setfont sun12x22` 来获得一个稍微大点的字体。

之后的操作和标准的 ArchLinux 安装过程一样，只是磁盘路径比较特殊，是 `/dev/mmcblk0`，因为这个小家伙使用的是 eMMC。不过，在安装盘里是没法正常使用 WiFi 的，你可以选择使用 USB 有线网络或者干脆直接用安卓手机来共享网络进行安装。安装之后参照 ArchWiki 上的 WiFi 部分，把两个文件 `brcmfmac4356-pcie.{txt,bin}` 放入 `/lib/firmware/brcm/` 就可以正常使用无线网络了。

在设置声音的时候，似乎 ArchWiki 上提供的配置中的最后一行

```
set-sink-port alsa_output.platform-cht-bsw-rt5645.HiFi__hw_chtrt5645__sink [Out] Speaker
```

会导致 PulseAudio 直接启动不了。我直接删除了这一行，~~然后在桌面环境里选择默认输出，解决了这个问题。~~ 后来发现正确的配置应当是这样

```
set-card-profile alsa_card.platform-cht-bsw-rt5645 HiFi
set-default-sink alsa_output.platform-cht-bsw-rt5645.HiFi__hw_chtrt5645_0__sink
```

以上内容添加进 `/etc/pulse/default.pa` 即可

ArchLinux 默认安装的是主线内核。使用主线内核是可以正常启动 GPDP 的，大部分功能也是可用的，除了 亮度调节、蓝牙、电池充电状态 这些功能以外。另外，主线内核的音频还存在撕裂问题。要使用这些功能，你需要使用 `linux-jwrdegoede` —— 这是一个以前玩 `Allwinner` 的大佬做的内核，使用它的话几乎全部功能都正常（你需要学会如何给 ArchLinux 使用非默认内核，这个教程网上一大堆）。当然，蓝牙的话，需要手动载入一下 `btusb` 模块，编辑 `/etc/modules-load.d/` 里面的内容让它自动载入即可。

我一般习惯在安装环境里把命令行和网络配好就重启进入系统继续安装。在这里需要注意的问题是，当你配置 `bootloader` 的时候，__一定要记得__给内核命令行加上 `fbcon=rotate:1`，否则重启以后你的屏幕就又不对了 :(

### 桌面环境

桌面环境安装和标准方式一样，我选择了 GNOME，所以 `pacman -S gnome` 即可。由于 ArchWiki 上没有包含关于 GNOME Wayland 的内容，我在这里稍微描述一下遇到的问题。

首先是屏幕旋转。你需要编辑 `~/.config/monitors.xml` 用以下配置把它转过来（不知道为什么我的 GNOME 没有自动生成这个文件的默认内容，以下来自于 `farseerfc` 提供的配置）

```xml
<monitors version="2">
  <configuration>
    <logicalmonitor>
      <x>0</x>
      <y>0</y>
      <scale>2</scale>
      <primary>yes</primary>
      <transform>
        <rotation>right</rotation>
        <flipped>no</flipped>
      </transform>
      <monitor>
        <monitorspec>
          <connector>DSI-1</connector>
          <vendor>unknown</vendor>
          <product>unknown</product>
          <serial>unknown</serial>
        </monitorspec>
        <mode>
          <width>1200</width>
          <height>1920</height>
          <rate>60.384620666503906</rate>
        </mode>
      </monitor>
    </logicalmonitor>
  </configuration>
</monitors>
```

保存后重新进入 GNOME 即可。这会同时把显示内容缩放为两倍大小（一倍大小在旋转正确以后实在看不见任何内容……）但是两倍有点大了，要想使用分数缩放需要执行

```bash
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
```

然后继续编辑 `~/.config/monitors.xml` 把 `<scale>` 那边的数值改成 1.5 之类的就可以了。不过这样设置以后部分界面会显得有点模糊，大概得等 GNOME 和软件开发者们修复 HiDPI 的问题了。有的软件也有自己的缩放设置，可能需要单独调节。另外推荐在 GNOME Tweak Tool 里把字体缩放也设置成 1.1 或者更大，这样看起来舒服一些。

如果你想要把登录界面也转过来，你需要在 `/var/lib/gdm/.config/monitors.xml` 中键入同样的内容。~~不过我暂时没有找到让登录界面也使用分数缩放的方法，所以我直接让它两倍缩放了。~~ 请看本文最后 EDIT 部分中让登录界面（GDM）也能分数缩放的方法。

P.S. 我从奇怪的地方看见了下面这句东西

```bash
gsettings set org.gnome.desktop.interface scaling-factor 2
```

似乎也是设置缩放的，但好像并不管用。

### 总结

似乎要说的暂时就这么多，Linux 上的更多问题在 ArchWiki 上都有详细的说明。一篇博客也差不多水完了，下面是总结

__优点__:

* 便携
* x86 完整 PC 体验
* 屏幕养眼
* 做工精致
* 接口足够多

__缺点__:

* 性能较低
* 键盘布局很谜
* WiFi 信号似乎有时候不太好
* 自带扬声器不行，不过耳机输出还好
* BIOS 对屏幕默认旋转设置不对导致自己装系统有点麻烦
* 比较贵

这并不是针对每一个人的设备。如果你需要的是一个非常便携而且可爱的 x86 设备，而且你又是一个折腾党，喜欢玩各种各样的东西，那么它可能正是你的菜。否则，可能安卓平板会是更好的选择。当然，在购买之前请详细阅读各种 Wiki 和其他人的各种评测再做决定。

### 剩下的图

emm 还有几张和 XPS 的合照

![img_xps1](https://files.typeblog.net/blog/gpd/IMG_20171117_203256.jpg)  
![img_xps2](https://files.typeblog.net/blog/gpd/IMG_20171118_193917.jpg)

### EDIT1: 蓝牙耳机

之前蓝牙正常了一直没测试过，今天突然想起来测试一下蓝牙耳机是否可用，结果当然是 —— 默认配置下并不能工作。连接以后识别不出 A2DP，导致直接没办法输出音频……

我首先按照各种奇奇怪怪的论坛上的说明在 `/etc/pulse/system.pa` 里加入了

```
load-module module-bluez5-device
load-module module-bluez5-discover
```

然后按照 [ArchWiki](https://wiki.archlinux.org/index.php/Bluetooth_headset#A2DP_not_working_with_PulseAudio) 上的说明，我禁用了 `gdm` 开启的 `PulseAudio` （创建一个 `/var/lib/gdm/.config/systemd/user/pulseaudio.socket`，把它软链接到 `/dev/null` 即可），然后使用

```bash
bluetoothctl
pair YOUR_HEADPHONE_MAC_ADDRESS
connect YOUR_HEADPHONE_MAC_ADDRESS
```

手动连接。之后，使用 `pacmd ls` 查看你的蓝牙耳机的设备编号（假设它是 `INDEX`），然后执行

```
pacmd set-card-profile INDEX a2dp_sink
```

耳机就可用了。不过在这之后，每次连接的时候似乎都要重新连接几次并在 GNOME 的音频设置里手动选择耳机为音频设备以后才能使用…… 至少是能用啦。

### EDIT2: GDM 分数缩放

```bash
sudo machinectl gdm@
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
exit
```

以上命令会 __登录进__ gdm 用户并开启分数缩放功能。注意此处用 `sudo -u gdm` 或者 `su gdm` 是无效的。执行以后将 `/var/lib/gdm/.config/monitors.xml` 里面的 `<scale>` 设置为 1.5 然后重启即可。（如果没有这个文件，参考我上面的步骤，把自己用户目录下面的那个复制过去就好。）

### EDIT2: 右键模拟鼠标滚动

GPD Pocket 的指点杆不自带滚动功能，于是有人提出让它的右键变成一个模拟滚轮，也就是「按住右键并移动鼠标」这一动作来代替滚轮。

这是在 `Xorg` 下面可以通过配置 `libinput` 实现的功能，然而在 `Wayland` 下得看 `compositor` 的脸色 —— 很不幸，GNOME 并没有提供这个功能，于是很长一段时间我认为这是不可能的，然后忍受着没有滚轮功能的指点杆。

后来实在有点受不了，甚至试图修改内核来实现这个功能 —— 当然，因为不了解内核驱动，我瞎改了半天并没有起作用。后来晚上做梦的时候梦见了 `LD_PRELOAD`，突然惊醒，觉得我完全可以利用 `LD_PRELOAD` 来 hook 进 `libinput` 的函数，强行开启这个功能。

花了不到一个小时研究了一下 `libinput` 和使用 `LD_PRELOAD` 的方法，写出了这么一个简单的小程序 <https://github.com/PeterCxy/scroll-emulation>，按照使用说明编译后加入 `LD_PRELOAD` 即可。

基本原理是劫持桌面环境对 `libinput_device_get_name` 的调用，在返回之前使用这个指令序列

```c
libinput_device_config_middle_emulation_set_enabled(device, LIBINPUT_CONFIG_MIDDLE_EMULATION_ENABLED);
libinput_device_config_scroll_set_method(device, LIBINPUT_CONFIG_SCROLL_ON_BUTTON_DOWN);
libinput_device_config_scroll_set_button(device, 273);
```

对所有可以开启的设备开启 `libinput` 的中键滚动模拟功能。开启以后，即可使用「按住鼠标右键并移动鼠标」来模拟滚轮。

### EDIT2: 键位调整

GPD Pocket 上的键盘键位很谜，尤其是退格和 Delete 放在一起，以及那个超级小的大写锁定键。我本来也想通过 hook libinput 来解决，然而 `archlinux-cn-offtopic` 里的大佬给了我一个更好的解决方法，那就是使用 `udev` 自带的 `hwdb` 来修改 Keymap.

简单研究了一下这玩意怎么用，写出了下面这个配置：

```
evdev:input:b0003v258Ap0111*
 KEYBOARD_KEY_7004c=backspace
 KEYBOARD_KEY_7002a=delete
 KEYBOARD_KEY_70039=a
```

以上配置的作用是 1) 交换退格和删除键 2) 将大写锁定键去掉，改成另一个A键（大写锁定可以用按住 SHIFT 来代替）。将这个配置文件放在 `/etc/udev/hwdb.d/90-gpdp.hwdb` 即可。

<style>
img[alt*="img_"] {
  width: 80%;
}
</style>