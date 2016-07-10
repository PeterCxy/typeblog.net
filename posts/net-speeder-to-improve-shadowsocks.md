```
{
  "title": "有效降低DigitalOcean VPS高峰期丢包率",
  "url": "net-speeder-to-improve-shadowsocks",
  "date": "2014-12-20",
  "parser": "Markdown"
}
```


上次GitHub送免费的礼包，其中包含DigitalOcean的100美刀额度。除了用它建立网站以外，我还用它搭建了一个shadowsocks服务器用于  `科学上网`

但是DigitalOcean的三帆寺和纽约节点有个问题，在晚高峰期(特别是对于中国电信)，那丢包率简直酸爽，开个Google会 `NO RESPONSE` 好几次才能打开。即使配置了 `tcp_hybla` 模块，丢包率仍然惊人。

<!--more-->

shadowsocks有关讨论中无非就是调整sysctl参数，开启 `hybla`, 或者使用 `锐速` 之类。可惜，`锐速` 这玩意儿死活就是说不支持我的VPS，即使换成他支持列表里面的系统也不行，似乎哪怕内核名不一样也不让运行。不过我在找锐速的时候，看见了Google Code上的一个老项目:

<https://code.google.com/p/net-speeder/>

这是一个简单的网络加速器。根据作者的描述，这些国外VPS高丢包率的一个原因是延迟过高，路由跳数多，一旦一个环节出现丢包，就会被判断为拥塞，影响速度(<http://www.snooda.com/read/324>)

而net-speeder的作用，就是拦截所有数据包，并将它们发送两次。这样可以有效降低丢包率。

## 安装

我的VPS运行的是ArchLinux(具体请搜索在DigitalOcean上运行archlinux的脚本)，因此我是使用 `PKGBUILD` 编译安装的。我写的PKGBUILD已经上传到ArchLinux AUR，名为 `net-speeder` ，同时附在本文最后。

其他系统的安装方法可以参考Google code项目主页

## 使用

首先你需要知道你的网卡设备名，可以使用 `ifconfig` 查看。假设是eth0，那么调用方法是

```sh
sudo net_speeder eth0 "ip"
```

当然，如果你已经是root用户，就不需要sudo了。

你也可以像我一样，把它加入systemd服务，不过一定要注意 __要在网络可用之后启动__

该服务可能会输出一些错误信息，目前来看，不影响使用

## 效果

晚高峰期连接该VPS的shadowsocks测试，以前打开Google网页经常出现 `NO RESPONSE` 错误很多次才能成功加载，但VPS运行 `net-speeder` 以后不再出现。晚高峰期间，YouTube手机客户端观看720p视频基本无压力，而以前144p都卡顿之极。

可以说，这个小程序，在避免修改内核的情况下，效果还是非常出色的。加上 `hybla` 这样优秀的拥塞算法，科学上网几乎没有压力。

## 测试环境

本地网络 江苏电信20M宽带
客户端 shadowsocks-android
服务器 DigitalOcean SF1机房 512M套餐
服务端系统 ArchLinux
shadowsocks服务端 shadowsocks-go

## 附录

1. ArchLinux on DigitalOcean <https://github.com/gh2o/digitalocean-debian-to-arch>
2. shadowsocks-go-git AUR <https://aur.archlinux.org/packages/shadowsocks-go-git/>
3. net-speeder AUR <https://aur.archlinux.org/packages/net-speeder/>

## PKGBUILD

```sh
# Maintainer: Peter Cai <xqsx43cxy@gmail.com> 
pkgname=net-speeder 
pkgver=0.1 
pkgrel=1 
pkgdesc="A network optimizing tool for high-delay network environment (ROOT NEEDED)" 
url="https://code.google.com/p/net-speeder/" 
arch=('x86_64' 'i686') 
license=('Unknown') 
depends=('libnet' 'libpcap') 
source=("http://net-speeder.googlecode.com/files/net_speeder-v${pkgver}.tar.gz") 
md5sums=('bd828d3fa295deaf65938143ecdaa27f') 

build() { 
    cd "${srcdir}/net_speeder" sh build.sh 
} 

package() { 
    install -Dm755 "${srcdir}/net_speeder/net_speeder" "${pkgdir}/usr/bin/net_speeder" 
}
```
