```json
{
  "title": "使用UML合租VPS",
  "url": "how-did-i-share-aliyun",
  "date": "2016-03-13",
  "parser": "Markdown",
  "tags": ["Linux", "Tech", "UML"]
}
```

我是从 [微林](https://vnet.link) 那里发现阿里云的新加坡节点的。那个时候我在用 [Conoha](https://conoha.jp)，因为它到国内的线路越来越玄学，从以前的70ms延迟飙升到300ms，丢包率极高，所以我到微林那里去寻求一个中转服务。我本来只想用那个阿里云香港节点，但是正好看见不知何时他们加上了一个阿里云新加坡节点。因为香港的流量费实在太可怕，我就抱着试试看的心态开了一个新加坡的中转。谁知道这个中转的效果非常好，因为这个新加坡节点到中国电信有双向的CN2线路连接。然而微林的流量费还是太高：阿里云的官方流量价格只有0.53元/GiB，而最低配置的主机价格也就90元的样子。使用微林中转，我仍然需要一个国外VPS来搭建网站，倒不如直接使用阿里云提供的服务……

### 合租

然而，对于我这个学生党来说，94元/月的配置费仍然是高了一些。所以我想到了合租，几个人可以稍微分担一下配置费用。然而要合租的话，就需要想办法分割各自的用户空间。我首先想到的是用 `LXC` 或者 `systemd-nspawn`, 但是使用这些的话，各个用户都必须共享同一个内核。而阿里云这东西比较奇葩的是不允许自定义内核，这样总让我觉得有些不舒服。

在虚拟机里再跑全虚拟化的虚拟机显然是不合适的。而我以前也在 `HawkHost` 的 `OpenVZ VPS` 上使用过 `User Mode Linux`，显然，这是个比较好的解决方案。

于是我找了两个朋友， [Touko](https://touko.moe) 和 `BroncoTc`，共同使用一台阿里云新加坡VPS。正好，之前我那篇关于UML的文章被我删除了，我也就可以用这篇补上这个空白了。

### User Mode Linux

于是首先应该配置好 `User Mode Linux`, 简称 `UML`。

`User Mode Linux` 是一个对Linux内核到其自身的适配。它可以将一个 `Linux` 运行在用户空间，同时却具有几乎全部内核支持的功能，包括但不限于自己的文件系统、自己的TCP/IP协议栈。当使用 `OpenVZ` 这类的VPS，需要自己挂载文件系统或使用 `Tunnelbroker` 一类的东西的时候，UML就十分有用了。而阿里云也不让自己换内核，即使不用和其他人合租，UML也是十分有用的东西。

因为偷懒，我在 `ArchLinux AUR` 上找到了一个UML的 [PKGBUILD](https://aur.archlinux.org/packages/linux-usermode/)，从里面拿出了内核配置文件，打算直接使用。然而，这个内核配置文件存在一些问题，比如说关于 `Netfilter` (iptables) 的内核配置全部没有打开，文件系统的支持也不是很完全。所以，我们得手工编辑这个配置文件，打开需要的选项。当然，使用内核自带的图形化配置工具，也是可以的。

我在 [kernel.org](https://kernel.org) 上选择了最新的LTS版本 `4.1.19`，下载下来，解包，然后把那个改好的配置文件放了进去。然后，直接执行

```bash
make ARCH=um vmlinux
```

就可以获得一个名为 `vmlinux` 的可执行文件，这就是 `User Mode Linux` 的可执行文件了。

### Bootstrap

然而，在使用UML之前，我们还必须先为UML配置一份自己的用户空间，即为UML虚拟出来的环境安装一个发行版。

由于UML可以从文件内的文件系统镜像启动，所以我创建了一些文件作为 `虚拟磁盘` 使用

```bash
fallocate -l 10G image
mkfs.xfs image
```

接下来就得把它挂载到一个临时挂载点

```bash
mount image /mnt
cd /mnt
```

以安装 `ArchLinux` 为例，首先得下载它的 `bootstrap` 压缩包然后解压。对应的bootstrap包可以在各大 `ArchLinux` 镜像里面找到，往往和 `ISO` 文件放在一起，如 <http://mirror.rackspace.com/archlinux/iso/2016.03.01/archlinux-bootstrap-2016.03.01-i686.tar.gz>。

```bash
tar zxvf bootstrap_file.tar.gz
mv root.x86_64/* ./
```

如果要使用 `Debian`, 则上述过程都可以通过 `debootstrap` 脚本来完成，只要指定目标目录是挂载出来的 `/mnt` 即可。

此时需要将必须目录映射进挂载出来的磁盘

```bash
mount --rbind /dev /mnt/dev
mount --rbind /sys /mnt/sys
mount --rbind /proc /mnt/proc
mount --rbind /tmp /mnt/tmp
```

然后执行更新软件包之类的操作。接着需要配置好root密码、配置好locale等。在编辑 `fstab` 时，请注意，根磁盘应该是 `/dev/ubda`，这将在稍后的UML启动命令行中体现。

这里有一个大坑：__千万不要在UML内系统的fstab里添加swapfile!__ 这会导致 `udev` 在启动时卡死。如果一定要用swap，请写一个开机启动的服务来启用。

### Networking

UML的网络配置也是一个坑。要对UML启用网络，我们必须使用 `tap` 设备。例如，我们可以创建一个 `tap0`:

```bash
ip tuntap add tap0 mode tap
ip addr add 192.168.1.1/24 dev tap0
ip link set tap0 up
```

注意，在阿里云上，只有 `192.168.0.0/16` 这个内网网段是可用的。这里我们把主机IP设为 `192.168.1.1`, 假设我们将把UML客户机的IP设为 `192.168.1.2`

稍后启动UML时，我们将通过这个参数(假设MAC地址设为23:33:33:44:66:66)

```
eth0=tuntap,tap0,23:33:33:44:66:66,192.168.1.2
```

来将网络设备映射到UML内部。

为了使UML能访问网络，我们得添加 `MASQUERADE` 规则。在阿里云上，公网设备是 `eth1` 

```bash
iptables -t nat -A POSTROURING -o eth1 -j MASQUERADE
```

我们还需要映射一定范围的端口到UML内部，以便外网访问。

```bash
iptables -t nat -A PREROUTING -i eth1 -p tcp --dport 10000:20000 -j DNAT --to-destination 192.168.1.2
```

UDP也同理。请记得把UML内部的 `sshd` 监听的端口改到这个范围之内！

对于 `80` 和 `443` 端口，如果只有一个人使用，那么把它映射进UML是没有问题的。如果要多人使用，那就只能依靠主机 `haproxy`，按照域名来区分了。这要参考 `haproxy` 的SNI配置，我不再赘述。有一个小小的Tip，那就是在 `haproxy` 配置中可以使用 `hdr_end` 或 `-m end` 指令匹配域名尾部以达到泛域名匹配的效果。

建议将这些网络设备的启动脚本加入主机的启动服务。在UML中，只需要配置 `eth0` 上的网络，把网关设为 `192.168.1.1` 就可以了。

```ini
[Match]
Name=eth0

[Network]
Address=192.168.1.2/24
Gateway=192.168.1.1
```

这是 `systemd-networkd` 的配置。

### Boot up

现在已经可以启动UML了。首先我们需要把刚刚挂载出来的目录全部卸载，这一步推荐通过重启完成。然后可以启动

```bash
/path/to/vmlinux ubd0=/path/to/image eth0=tuntap,tap0,23:33:33:44:66:66,192.168.1.2 mem=512m con=pts
```

内存被限制在了 `512m`。如果你的UML中运行了 `sshd`, 那么你已经可以用暴露的端口访问内部运行的系统了。如果出现问题，你也可以直接通过 `screen /dev/pts/X` (X是一个数字，自行ls查看) 来获得一个客户机的 `Login shell`

当然，我比较推荐的是把这些过程全部写成一个脚本，并且让它能够读取配置文件，这样再将它包装成一个 `systemd` 服务，就可以方便地管理多用户和开机启动了。

### 流量监控

在多人共享阿里云时，流量是个大问题，因为阿里云按照流量计费。因而，我们需要一个好用的流量统计工具。

我看中的是 `vnstat`, 因为它可以单独统计每个网络接口的流量。而UML的每个实例又单独享有一个 `tap` 接口，这就使流量统计非常方便了。

在CentOS上安装和启用非常简单

```bash
yum install vnstat
systemctl start vnstat
systemctl enable vnstat
```

过一段时间以后，使用 `vnstat -q` 即可查看统计数据。当然，为了方便其他用户查看，我还利用 [bashttpd](https://github.com/avleen/bashttpd) 搭建了一个服务器，调用 `vnstat -q -i tapN` 来返回各个接口的统计数据。这十分方便。

在 `bashttpd.conf` 中只需要这几行

```bash
serve_vnstat() {
    add_response_header "Content-Type" "text/plain"
    send_response_ok_exit <<< "$(vnstat -q -i tap$2)"
}
on_uri_match '^/tap([0-9])$' serve_vnstat
```

然后按照官方文档使用 `socat` 启动服务，即可在 `YOUR_URL/tapN` 访问到对应设备的流量统计。

### 后记

虽然我们总不太喜欢BAT这类公司，但是阿里云新加坡的这个线路是真的很良心，在价格比较低的同时拥有货真价实的双向CN2，在中国国内的速度十分可观，尤其是电信。对于很多地方的联通，速度也在能够接受的范围之内。而移动，自然是不用说了。

使用UML，不仅仅可以分担费用，还有一定的防止 `云盾` 抽风的能力，因为云盾目前并不能透过UML控制其内部的环境。虽然并不是说有多安全，至少不会发生云盾炸掉整个环境的糗事。就目前的配置来看，即使外面环境挂了，只要UML进程还在运行，就不会出现任何严重问题。
