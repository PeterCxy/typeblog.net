```json
{
  "title": "切换到LXQt桌面环境",
  "url": "switch-to-lxqt-desktop",
  "date": "2014-09-14",
  "parser": "Markdown"
}
```


在 `ArchLinux` 上用 `Gnome` 和 `Cinnamon` 都有一段时间了，用的过程中也发现了它们的不足，比如说不能更换窗口管理器，界面风格千篇一律等等。

昨天在 `ArchLinux Wiki` 上闲逛发现有介绍 [LXQt](https://wiki.archlinux.org/index.php/LXQt), 正好激发了我一直想换掉桌面环境的心。

<!--more-->

### 关于LXQt

[LXQt](http://lxqt.org/) 是 [LXDE](http://lxde.org) 的QT移植版，同样是一个轻量级的Linux桌面环境。根据官方介绍，这将是未来 `LXDE` 的继承者。

### 安装

在 `ArchLinux` 上的安装过程十分简单，从AUR上获取PKGBUILD然后直接编译安装即可。`ArchLinux Wiki` 上的介绍也十分详细。在其他Linux上也应当有相应的安装方法。我写这篇文章主要是介绍一下我的配置经验，也算留作记录。

### 登录管理器

图形化的登录管理器我还是推荐 `MintDM`, 也就是 `Linux Mint` 所用的图形化登录管理器。安装好 `LXQt` 以后，会话列表中会自动出现 `LXQt Desktop`.

### 窗口管理器

我更换桌面环境的一个重要原因就是希望使用自定义的窗口管理器，而不是被强制使用某一个窗口管理器。

`LXQt` 的默认窗口管理器是 `OpenBox`, 一个轻量级的窗口管理器。但是这个窗口管理器过于简陋，因此我希望把它替换成 `Compiz`, 它的特效和各种插件非常强大。从Wiki上可知，要更换窗口管理器非常简单。

先安装好 `Compiz` 窗口管理器，然后编辑 `~/.config/lxqt/session.conf`, 修改 `window_manager` 开头的一行，改成：

```
window_manager=compiz
```

保存，退出，重新登录即可。

Compiz的配置可以在 `Preferences->CompizConfig Settings Manager` 里面找到。

### GTK/Qt 主题

既然使用了基于Qt的桌面环境，那么这两种图形引擎风格的统一就是一个问题了。

关于主题的统一，可以使用 `QtCurve` 或其他同时支持Qt与GTK的主题。要在 `LXQt` 下配置GTK的界面风格，可以使用 `lxappearance` 这个软件，安装后可以在菜单里找到 `Customize Look and Feel`, 在里面选择主题使用即可。

### 窗口边框配置

由于我的 `Compiz` 内使用的窗口装饰程序是 `gtk-window-decorator`, 所以要修改窗口的边框风格，只能通过 `gnome-tweak-tool` 这个程序或者手动在命令行中修改。注意，`gnome-tweak-tool` 在 `LXQt` 下只对GTK的窗口边框有效。

### 截图快捷键

`LXQt` 和 `Compiz` 都没有自带的截图功能，所以我们只能借助于 `gnome-screenshot` 这个小程序。安装好以后，在 `CompizConfig` 里面开启 `Commands` 功能，并且像下两图一样键入内容

{% img /res/compiz-print1.png 600 %}
{% img /res/compiz-print2.png 600 %}

保存后可以测试一下， `Print Screen` 键是截取整个屏幕， `Shift + Print Screen` 是截取当前窗口， `Ctrl + Print Screen` 是截取自定义矩形区域。非常方便。

### 网络管理器

直接使用 `network-manager-applet`, 然后添加到LXQt的Panel里面即可。

### 截屏欣赏

![lxqt1](/content/images/2016/01/lxqt1.png)
![lxqt2](/content/images/2016/01/lxqt2.png)
![lxqt3](/content/images/2016/01/lxqt3.png)

- GTK主题: Numix
- Qt主题: QtCurve-Numix
- 窗口装饰: Numix
- 窗口管理器: Compiz
- 终端模拟器: LilyTerm
- 默认字体: 文泉驿 + 思源黑体
- 终端字体: Monaco

### 总结

`LXQt` 这种轻量级桌面可定制性非常高，特别适合我这种折腾党使用，但是需要一定的技术基础。如果偷懒，还是建议使用 `Gnome` 之流。
