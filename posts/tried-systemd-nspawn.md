```json
{
  "title": "systemd-nspawn 踩坑记",
  "url": "tried-systemd-nspawn",
  "date": "2018-04-08",
  "parser": "Markdown",
  "cover": "https://oa3o2340x.qnssl.com/containers.jpg",
  "tags": ["Tech"]
}
```

已经有半年没更新博客了，一方面是这段时间确实情绪之类的方方面面不太稳定导致一直没心情更新，另一方面是觉得没啥好更新的，无非是一些琐碎，所以就一直拖着拖着，直到今天才发现，已经半年了。

而正好最近把自己的网络服务都迁移到了一台新的服务器，尝试了全新的部署方式（`systemd-nspawn`），正好踩中了一些坑，所以随便写写记录一下，也算是重新开始做起博客这件事情了吧。

### What & Why

以前我使用的是一台在 `online.net` 捡来的特价独服，因为只有一个人使用，所以我直接在主机上开了很多个 KVM 虚拟机，使用（几乎是）一个服务一个虚拟机的方式来部署自己的服务。这在一个人使用的时候确实没有什么太大的问题，唯一的问题可能就是因为自己懒，而虚拟机的数量太多，所以经常忘记更新 / 维护那些虚拟机。

而这次则是捡特价弄了一台特别划算的 `E5-2680v2` 的独服（购买的时候下单的是 `E5-2660v1`，但是不知道是商家特别有钱还是那天机房小哥心情好，给弄了一台 `E5-2680v2`），几个人合用一台。因为是合用，所以大家各自开了一个 KVM 虚拟机，各自隔离。这时候，我就不能再使用虚拟机的方式来隔离自己的服务了，因为我本身已经被隔离在了一个虚拟机里，双重虚拟机可从来都不是什么好主意。

所以我转向了容器方案。其中，`Docker` 不太适合我的情况 —— 我并不是希望把所有服务都做成不可变的镜像然后到处部署，我的目的仅仅是简单的隔离（看起来整洁 / 给有些傲娇的应用提供最适合的环境）。因此，我转向了 `systemd-nspawn`，毕竟我是 `Systemd` 的~~卖底裤~~粉丝（雾），而且自带 `Systemd` 的 `ArchLinux` 在安装完成后就自带这个东西。

于是，我成功开始了踩坑之旅。（大量 `dirty fix` 预警）

### 非特权用户 (Private Users)

按照 [ArchWiki](https://wiki.archlinux.org/index.php/Systemd-nspawn) 上的说明，使用各个发行版的 bootstrap 工具在 `/var/lib/machines` 下创建目录并部署系统是一个很快的工作。然而，当我部署成功并尝试启动容器的时候，我却根本看不到任何反应，无论 `machinectl status` 还是 `systemctl status` 都没法给出任何有用的信息。

再次查看 `/var/lib/machines` 下我部署的目录的时候，发现里面文件的权限全部被修改成了奇怪的 UID 和 GID 值。从 ArchWiki 上的描述来看，这似乎是启用了 `Private Users` 的正常现象。然而，死马当活马医，我尝试在 `/etc/systemd/nspawn/myContainer.nspawn` (myContainer 是我的容器的名字) 里面加入了

```ini
[Exec]
PrivateUsers=no
```

然后容器就神奇般地可以启动了。不过这样启动以后，尝试访问容器的时候，会发现里面的程序一定会报一大堆权限问题 —— 因为之前已经用 Private User 起过容器。所以，我的做法是，直接重新部署一遍……

然而这个问题并没有被彻底解决，我到现在也不能理解为什么使用 Private User 会导致无法启动，而且 `systemd-nspawn` 完全没有给我任何有用的错误信息。更奇怪的是，我直接用命令行的 `systemd-nspawn` 去启动容器是完全正常的，而使用 `systemd-nspawn@.service` 就必须关掉 Private Users 才能正常使用。鉴于我的使用场景并不需要多么严格的安全策略（另一方面，Linux 下的容器这个概念本身也不是用来做安全的），我暂时并没有去处理这个问题。所以，这算是一个 `dirty fix` 吧。

### 无法访问容器的 TTY

容器起来了，我遇到的第二个问题就是无法访问容器的 TTY。

尝试执行 `machinectl login myContainer`, 直接给我扔了一个 `protocol error` 出来。在 Google 上找了很久也没有找到任何一个人遇到类似的问题。最多只有进入了容器的登录界面却无法登录的问题，而遇到那种问题的人至少已经获得了容器的一个 Login Shell, 而我则是什么都没有……

是的，这个问题我也完全不知道怎么解决。当时我折腾了很久，然后怀疑是一个临时性的 bug —— 毕竟 ArchLinux 喜欢 break 东西。所以我决定作为一个临时的解决方案，先手动使用 `systemd-nspawn` 命令启动容器进去，配置好 `openssh`，然后用 `machinectl` 启动容器，并在外面直接使用 `ssh` 访问容器内部的 shell。是的，你没有看错，直接在 `/var/lib/machines` 使用 `systemd-nspawn -b -D myContainer` 命令启动容器是完全可以访问容器内的 shell 的，而从外面使用 `machinectl login` 或者 `machinectl shell` 就是不行的……

而当我下笔写这篇博客的时候，我尝试再次复现这个错误，却发现现在已经完全正常了，使用 `machinectl login` 可以获取到容器的正常的 Login Shell... 天知道把我折腾的要死要活的那个问题是怎么回事…… 而且从出现那个问题到现在我并没有更新服务器上的任何软件，也没有针对这个问题做任何处理…… 而当时我重启了不知道多少遍都完全没有作用。

假如你遇到这个问题，也许你坐和放宽一下，就好了。

### 容器内的内核模块问题 (OverlayFS / ip6tables / FUSE ...)

遇到这种问题其实觉得自己很智障，但是还是要花几句话说一次，容器内是没有办法加载内核模块的，而 Linux 启动的时候默认很多模块都没有加载。那些模块正常情况下会被使用它们的程序自动加载，但是在容器里这是不行的。所以如果你在使用程序的时候遇到这种问题，请记住在主机里加载它需要的模块后再试 （推荐加入 `/etc/modules-load.d/` 自动载入）

### Systemd-nspawn 内运行 Docker

这个需求看起来很无厘头，但是我觉得我的使用场景是有道理的。我有一个 `Mastodon` 节点，这个东西是主要使用 `Ruby on Rails` 编写但同时有很多其他依赖的东西。在以前的机器上，我是使用 `docker-compose` 通过容器的组合在一个虚拟机里直接部署上这一系列依赖。而现在我需要迁移到我的新独服上，我不能使用虚拟机，也不想自找麻烦手动部署，也不想让 `Docker` 产生的一大堆网络接口之类的东西挂在主机的 namespace 里。总而言之，因为这种 `Ruby on Rails` 程序是好多个大怪兽，虽然各自有笼子，但是因为数量比较多，分散放置还是感觉很凌乱，所以我想进一步把它们的笼子也都关进一个动物园里统一管理。

但是问题来了，`systemd-nspawn` 似乎并不支持在它内部再启动 `Docker` 容器。尝试使用 `Docker` 容器会直接带来 `Operation not permitted` 异常。从 <https://github.com/opencontainers/runc/issues/1456> 了解到，`Docker` 依赖了 `cgroups` 功能，并且需要比较高的权限，而在默认情况下，`systemd-nspawn` 是隔离了 `cgroup` 命名空间的，而且也没有给予不必要的权限。所以，作为测试，我在 `/etc/systemd/nspawn/myContainer.nspawn` 里加入了

```ini
[Exec]
Capability=all

[Files]
Bind=/sys/fs/cgroup
```

这在事实上把主机的 `cgroup` 命名空间共享给了容器里的系统，并给予了所有可以给予的 `Capabilities`。同时，还需要关闭 `systemd-nspawn` 的 `cgroup` 隔离功能，只需要 `systemctl edit systemd-nspawn@myContainer`

```ini
[Service]
Environment=SYSTEMD_NSPAWN_USE_CGNS=0
```

到了这一步，我期望 `Docker` 已经可以使用了，但是很不幸的是，并不能。这回出现的是一个莫名奇妙的 `session key` 无法创建的异常。这次这个异常我就完全没有看懂了……

还好，经过一番 Google，我了解到这其实是因为 `Docker` 在尝试使用 `kernel keyring`，而这个功能是不支持(ref: <https://github.com/moby/moby/issues/10939>)命名空间隔离的。所以，为了安全，`systemd-nspawn` 默认把与此相关的系统调用都过滤掉了，不允许内部的系统调用。因此，只需要开启这两个系统调用的权限（在 `/etc/systemd/nspawn/myContainer.nspawn` 的 `[Exec]` 段中加入）

```ini
SystemCallFilter=add_key keyctl
```

然后重启 `nspawn` 容器即可使用 `Docker`。

在 `Docker` 正常运行之后，我发现一个问题，那就是它在使用非常慢、非常不科学的 `vfs` 作为存储后端。根据[文档](https://docs.docker.com/storage/storagedriver/vfs-driver/)，这个存储后端会对每个 layer 都创建一个拷贝。于是我想起来了遇到的上一个问题 —— 主机没有加载 OverlayFS 的内核模块，因此默认的 `overlay2` 存储后端加载失败了。尝试在主机上加载 `overlay` 模块，然后重新启动容器里的 `Docker`，发现 `overlay2` 存储后端果然已经在正确运行了。

以上文档我已经写入 `ArchWiki` 上的[对应章节](https://wiki.archlinux.org/index.php/Systemd-nspawn#Run_docker_in_systemd-nspawn), 因为我发现我在整个网络上都找不到关于这件事情的文档，有的只是一段 [Twitter 对话](https://twitter.com/evanphx/status/683114646660763649?lang=en)，而且他们其实还并没有解决这个问题……希望我并不是唯一一个有这种奇葩需求的人吧。

当然，这么做以后，这个 `nspawn` 容器就成为了名副其实的特权容器，拥有很多很多高权限操作的能力。考虑到我的本意仅仅是出于洁癖一般的理由，这个问题我觉得并不是非常大……总之，给大家一个参考。

### 容器内使用 FUSE

`FUSE` 是指用户态文件系统，比如 `sshfs`, `ntfs-3g` 等。想要直接在 `systemd-nspawn` 容器里使用它们是会直接失败的。当然，这个解决办法很简单，因为这仅仅是因为容器里没有 `/dev/fuse`。

首先要确保主机上加载了 `fuse` 内核模块。然后，你需要在 `/etc/systemd/nspawn/myContainer.nspawn` 加入

```ini
[Exec]
Capability=CAP_MKNOD
DeviceAllow=/dev/fuse rwm
```
（注：如果你前面已经 `Capability` 设为 `all` 了，那就不用再单独设置一次 `CAP_MKNOD` 了）

然后在容器里执行

```bash
mknod /dev/fuse c 10 229
```

即可。

### 其他：网络配置

网络配置这算是一点附加说明，就是如果你想要给容器使用静态 IP，或者你想给容器使用 IPv6，你需要首先在 `/etc/systemd/nspawn/myContainer.nspawn` 里给容器增加一个网络接口

```ini
[Network]
VirtualEthernetExtra=name_on_host:name_in_container
```

然后分别在主机和容器里配置对应的网络接口即可。

当然，你可能也需要

```ini
[Network]
Private=true
VirtualEthernet=true
```

虽然这些应该是默认的。

### 结论

`Systemd` 坑很多，而且很玄学，但这并不影响我卖底裤（笑）。