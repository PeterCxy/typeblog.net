```json
{
  "title": "在 ArchLinux 上配置 shadowsocks + iptables + ipset 实现自动分流",
  "cover": "https://oa3o2340x.qnssl.com/wall.jpg",
  "url": "set-up-shadowsocks-with-iptables-and-ipset-on-archlinux",
  "date": "2016-07-30",
  "parser": "Markdown",
  "tags": ["Tech", "Linux"]
}
```

本来我是决定不再写这样的文章了的。但是呢，最近连续配置了两次 ArchLinux，在配置这种东西的时候连续撞到了同样的坑，加上今天 Issac 亲问我关于 Linux 下的 shadowsocks 的问题，所以我想了想还是写一篇记录一下吧，也免得自己以后再忘记了。

本篇的目标是使用 ipset 载入 chnroute 的 IP 列表并使用 iptables 实现带自动分流国内外流量的全局代理。为什么不用 PAC 呢？因为 PAC 这种东西只对浏览器有用。难道你在浏览器之外就不需要科学上网了吗？反正我是不信的……

### 前置条件

* 一个能使用的 shadowsocks 服务端，假设它的 IP 是 192.168.1.100, 端口是 6666, 加密方式是 chacha20, 密码是 1234
* 一个安装了 [shadowsocks-libev](https://www.archlinux.org/packages/community/x86_64/shadowsocks-libev/) 的 ArchLinux; 其他发行版不保证可用，但如果有 shadowsocks-libev 以及 shadowsocks-libev@.service 的话，步骤应该大同小异
* ipset 和 iptables 工具
* systemd ~~卖底裤~~全家桶

### 创建配置

首先创建配置目录 /etc/shadowsocks/config.json

```json
{
  "server": "192.168.1.100",
  "server_port": 6666,
  "local_port": 1080,
  "method": "chacha20",
  "password": "1234"
}
```

然后运行

```bash
systemctl start shadowsocks-libev@config
systemctl status shadowsocks-libev@config
```

看看有无异常输出，此时你也可以打开浏览器连接到 1080 端口的 socks5 代理测试服务器是否正常。

### 获取 IP 列表

接下来我们需要获取中国的 IP 列表。在此之前我们需要创建一个目录来储存需要的脚本和其他文件。我建议放在 $HOME 下，或者 /opt 下。这里假设我们创建并切换到了目录 /home/peter/shadowsocks

```bash
curl 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > chnroute.txt
```

这是来自 [ChinaDNS](https://github.com/shadowsocks/ChinaDNS) 的指令。

### 创建启动和关闭脚本

创建 /home/peter/shadowsocks/ss-up.sh

```bash
#!/bin/bash

# Setup the ipset
ipset -N chnroute hash:net maxelem 65536

for ip in $(cat '/home/peter/shadowsocks/chnroute.txt'); do
  ipset add chnroute $ip
done

# Setup iptables
iptables -t nat -N SHADOWSOCKS

# Allow connection to the server
iptables -t nat -A SHADOWSOCKS -d 192.168.1.100 -j RETURN

# Allow connection to reserved networks
iptables -t nat -A SHADOWSOCKS -d 0.0.0.0/8 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 10.0.0.0/8 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 127.0.0.0/8 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 169.254.0.0/16 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 172.16.0.0/12 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 192.168.0.0/16 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 224.0.0.0/4 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 240.0.0.0/4 -j RETURN

# Allow connection to chinese IPs
iptables -t nat -A SHADOWSOCKS -p tcp -m set --match-set chnroute dst -j RETURN

# Redirect to Shadowsocks
iptables -t nat -A SHADOWSOCKS -p tcp -j REDIRECT --to-port 1080

# Redirect to SHADOWSOCKS
iptables -t nat -A OUTPUT -p tcp -j SHADOWSOCKS
```

大部分代码还是来自 [shadowsocks-libev](https://github.com/shadowsocks/shadowsocks-libev) 项目。

这是在启动 shadowsocks 之前执行的脚本，用来设置 iptables 规则，对全局应用代理并将 chnroute 导入 ipset 来实现自动分流。注意要把服务器 IP 和本地端口相关的代码全部替换成你自己的。

这里就有一个坑了，就是在把 chnroute.txt 加入 ipset 的时候。因为 chnroute.txt 是一个 IP 段列表，而中国持有的 IP 数量上还是比较大的，所以如果使用 hash:ip 来导入的话会使内存溢出。我在第二次重新配置的时候就撞进了这个大坑……

但是你也不能尝试把整个列表导入 iptables。虽然导入 iptables 不会导致内存溢出，但是 iptables 是线性查表，即使你全部导入进去，也会因为低下的性能而抓狂。

然后再创建 /home/peter/ss-down.sh, 这是用来清除上述规则的脚本，比较简单

```bash
#!/bin/bash

iptables -t nat -D OUTPUT -p tcp -j SHADOWSOCKS
iptables -t nat -F SHADOWSOCKS
iptables -t nat -X SHADOWSOCKS
ipset destroy chnroute
```

接着执行

```bash
chmod +x ss-up.sh
chmod +x ss-down.sh
```

至此需要的脚本和配置文件已经全部准备完成了。

### 配置 systemd

首先，默认的 ss-local 并不能用来作为 iptables 流量转发的目标，因为它是 socks5 代理而非透明代理。我们至少要把 systemd 执行的程序改成 ss-redir。其次，上述两个脚本还不能自动执行，必须让 systemd 分别在启动 shadowsocks 之前和关闭之后将脚本执行，这样才能自动配置好 iptables 规则。

执行

```bash
sudo EDITOR=vim systemctl edit shadowsocks-libev@config
```

然后键入如下内容

```ini
[Service]
User=root
CapabilityBoundingSet=~CAP_SYS_ADMIN
ExecStart=
ExecStartPre=/home/peter/shadowsocks/ss-up.sh
ExecStart=/usr/bin/ss-redir -u -A -c /etc/shadowsocks/%i.json
ExecStopPost=/home/peter/shadowsocks/ss-down.sh
```

是的，那两个脚本必须以 root 权限才能执行，所以我把整个服务的执行用户都设为 root。这显然是存在安全隐患的，但是因为我的懒癌，所以我没有专门处理。如果要提高安全性的话，应该把两个脚本的执行单独抽出来做一个 shadowsocks-iptables.service, 然后利用 Systemd Unit 的依赖特性来实现自动执行。

至此，带自动国内外分流的 shadowsocks 客户端已经配置完毕。要启动的话

```bash
systemctl restart shadowsocks-libev@config
```

还可以设置自动启动

```bash
systemctl enable shadowsocks-libev@config
```

以上。

修订:

2016.9.24 - 由于 ArchLinux 更新，添加关于 CapabilityBoundingSet 的设定
